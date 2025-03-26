import Foundation

@MainActor
public protocol WaitingRoomProviderDelegate: AnyObject {
    func notifyProviderSuccess(queuePassResult: TryPassResult) async
    func notifyProviderFailure(errorMessage: String?, errorCode: Int) async
}

enum QueueITRuntimeError: Int {
    case networkUnavailable = -100
    case requestAlreadyInProgress = 10

    static let errorMessages = [
        networkUnavailable: "Network connection is unavailable",
        requestAlreadyInProgress: "Enqueue request is already in progress",
    ]
}

@MainActor
public final class WaitingRoomProvider {
    static let maxRetrySec = 10
    static let initialWaitRetrySec = 1

    public weak var delegate: WaitingRoomProviderDelegate?

    private let customerId: String
    private let eventOrAliasId: String
    private let layoutName: String?
    private let language: String?

    private var apiClient: ApiClient?
    private var deltaSec: Int = WaitingRoomProvider.initialWaitRetrySec
    private var requestInProgress: Bool = false
    private let internetReachability: Reachability

    public init(customerId: String, eventOrAliasId: String, layoutName: String? = nil, language: String? = nil) {
        self.customerId = customerId
        self.eventOrAliasId = eventOrAliasId
        self.layoutName = layoutName
        self.language = language
        internetReachability = Reachability.reachabilityForInternetConnection()
    }

    @MainActor
    public func tryPass() {
        Task {
            try await tryEnqueue(enqueueToken: nil, enqueueKey: nil)
        }
    }

    public func tryPassWithEnqueueToken(_ enqueueToken: String?) async throws {
        try await tryEnqueue(enqueueToken: enqueueToken, enqueueKey: nil)
    }

    public func tryPassWithEnqueueKey(_ enqueueKey: String?) async throws {
        try await tryEnqueue(enqueueToken: nil, enqueueKey: enqueueKey)
    }

    public func isRequestInProgress() -> Bool {
        return requestInProgress
    }
}

private extension WaitingRoomProvider {
    func tryEnqueue(enqueueToken: String?, enqueueKey: String?) async throws {
        guard checkConnection() else {
            throw NSError(
                domain: "QueueITRuntimeException",
                code: QueueITRuntimeError.networkUnavailable.rawValue,
                userInfo: nil
            )
        }

        if requestInProgress {
            throw NSError(
                domain: "QueueITRuntimeException",
                code: QueueITRuntimeError.requestAlreadyInProgress.rawValue,
                userInfo: nil
            )
        }

        requestInProgress = true

        let userAgent = await Utils.getUserAgent()
        do {
            try await self.tryEnqueueWithUserAgent(
                secretAgent: userAgent,
                enqueueToken: enqueueToken,
                enqueueKey: enqueueKey
            )
        } catch {
            self.requestInProgress = false
            await delegate?.notifyProviderFailure(
                errorMessage: error.localizedDescription,
                errorCode: (error as NSError).code
            )
        }
    }

    func tryEnqueueWithUserAgent(secretAgent: String, enqueueToken: String?, enqueueKey: String?) async throws {
        let userId = await Utils.getUserId()
        let userAgent = "\(secretAgent);\(Utils.getLibraryVersion())"
        let sdkVersion = Utils.getSdkVersion()
        apiClient = ApiClient()

        do {
            let status = try await apiClient?.enqueue(
                customerId: customerId,
                eventOrAliasId: eventOrAliasId,
                userId: userId,
                userAgent: userAgent,
                sdkVersion: sdkVersion,
                layoutName: layoutName,
                language: language,
                enqueueToken: enqueueToken,
                enqueueKey: enqueueKey
            )
            guard let status else {
                await self.enqueueRetryMonitor(enqueueToken: enqueueToken, enqueueKey: enqueueKey)
                return
            }

            await self.handleAppEnqueueResponse(
                queueURL: status.queueUrlString,
                eventTargetURL: status.eventTargetUrl,
                queueItToken: status.queueitToken
            )
            self.requestInProgress = false
        } catch {
            let nsError = error as NSError
            if nsError.code >= 400, nsError.code < 500 {
                await self.delegate?.notifyProviderFailure(errorMessage: "", errorCode: nsError.code)
            } else {
                await self.enqueueRetryMonitor(enqueueToken: enqueueToken, enqueueKey: enqueueKey)
            }
        }
    }

    func handleAppEnqueueResponse(
        queueURL: String,
        eventTargetURL: String?,
        queueItToken: String?
    ) async {
        let isPassedThrough = !(queueItToken?.isEmpty ?? true)
        let redirectType = getRedirectType(fromToken: queueItToken)

        let tryPassResult = TryPassResult(
            queueUrl: queueURL,
            targetUrl: eventTargetURL,
            redirectType: redirectType,
            isPassedThrough: isPassedThrough,
            queueToken: queueItToken
        )
        await delegate?.notifyProviderSuccess(queuePassResult: tryPassResult)
    }

    func enqueueRetryMonitor(enqueueToken: String?, enqueueKey: String?) async {
        if deltaSec < WaitingRoomProvider.maxRetrySec {
            try? await tryEnqueue(enqueueToken: enqueueToken, enqueueKey: enqueueKey)
            try? await Task.sleep(nanoseconds: UInt64(deltaSec * 1_000_000_000))
            deltaSec *= 2
        } else {
            deltaSec = WaitingRoomProvider.initialWaitRetrySec
            requestInProgress = false
            await delegate?.notifyProviderFailure(errorMessage: "Error! Queue is unavailable.", errorCode: 3)
        }
    }

    func checkConnection() -> Bool {
        for _ in 0 ..< 5 {
            if internetReachability.currentReachabilityStatus() != .notReachable {
                return true
            }
            Thread.sleep(forTimeInterval: 1.0)
        }
        return false
    }

    func getRedirectType(fromToken queueToken: String?) -> String {
        guard let token = queueToken, !token.isEmpty else {
            return "queue"
        }

        let pattern = "\\~rt_(.*?)\\~"
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: token, range: NSRange(token.startIndex..., in: token))
        {
            return String(token[Range(match.range(at: 1), in: token)!])
        }
        return "queue"
    }
}
