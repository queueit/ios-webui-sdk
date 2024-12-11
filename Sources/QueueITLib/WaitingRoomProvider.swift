import Foundation

protocol WaitingRoomProviderDelegate: AnyObject {
    func notifyProviderSuccess(queuePassResult: TryPassResult)
    func notifyProviderFailure(errorMessage: String?, errorCode: Int)
}

enum QueueITRuntimeError: Int {
    case networkUnavailable = -100
    case requestAlreadyInProgress = 10

    static let errorMessages = [
        networkUnavailable: "Network connection is unavailable",
        requestAlreadyInProgress: "Enqueue request is already in progress",
    ]
}

final class WaitingRoomProvider {
    static let maxRetrySec = 10
    static let initialWaitRetrySec = 1

    weak var delegate: WaitingRoomProviderDelegate?

    private let customerId: String
    private let eventOrAliasId: String
    private let layoutName: String?
    private let language: String?

    private var deltaSec: Int = WaitingRoomProvider.initialWaitRetrySec
    private var requestInProgress: Bool = false
    private let internetReachability: Reachability

    init(customerId: String, eventOrAliasId: String, layoutName: String? = nil, language: String? = nil) {
        self.customerId = customerId
        self.eventOrAliasId = eventOrAliasId
        self.layoutName = layoutName
        self.language = language
        internetReachability = Reachability.reachabilityForInternetConnection()
    }

    func tryPass() throws {
        try tryEnqueue(enqueueToken: nil, enqueueKey: nil)
    }

    func tryPassWithEnqueueToken(_ enqueueToken: String?) throws {
        try tryEnqueue(enqueueToken: enqueueToken, enqueueKey: nil)
    }

    func tryPassWithEnqueueKey(_ enqueueKey: String?) throws {
        try tryEnqueue(enqueueToken: nil, enqueueKey: enqueueKey)
    }

    func isRequestInProgress() -> Bool {
        return requestInProgress
    }
}

private extension WaitingRoomProvider {
    func tryEnqueue(enqueueToken: String?, enqueueKey: String?) throws {
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

        Utils.getUserAgent { [weak self] userAgent in
            guard let self else {
                return
            }
            do {
                try self.tryEnqueueWithUserAgent(
                    secretAgent: userAgent,
                    enqueueToken: enqueueToken,
                    enqueueKey: enqueueKey
                )
            } catch {
                self.requestInProgress = false
                self.delegate?.notifyProviderFailure(
                    errorMessage: error.localizedDescription,
                    errorCode: (error as NSError).code
                )
            }
        }
    }

    func tryEnqueueWithUserAgent(secretAgent: String, enqueueToken: String?, enqueueKey: String?) throws {
        let userId = Utils.getUserId()
        let userAgent = "\(secretAgent);\(Utils.getLibraryVersion())"
        let sdkVersion = Utils.getSdkVersion()
        let apiClient = ApiClient.getInstance()

        apiClient.enqueue(
            customerId: customerId,
            eventOrAliasId: eventOrAliasId,
            userId: userId,
            userAgent: userAgent,
            sdkVersion: sdkVersion,
            layoutName: layoutName,
            language: language,
            enqueueToken: enqueueToken,
            enqueueKey: enqueueKey,
            success: { [weak self] Status in
                guard let self else {
                    return
                }
                guard let Status else {
                    self.enqueueRetryMonitor(enqueueToken: enqueueToken, enqueueKey: enqueueKey)
                    return
                }

                self.handleAppEnqueueResponse(
                    queueURL: Status.queueUrlString,
                    eventTargetURL: Status.eventTargetUrl,
                    queueItToken: Status.queueitToken
                )
                self.requestInProgress = false
            },
            failure: { [weak self] error, errorMessage in
                guard let self else {
                    return
                }
                if let nsError = error as? NSError {
                    if nsError.code >= 400, nsError.code < 500 {
                        self.delegate?.notifyProviderFailure(errorMessage: errorMessage, errorCode: nsError.code)
                    } else {
                        self.enqueueRetryMonitor(enqueueToken: enqueueToken, enqueueKey: enqueueKey)
                    }
                }
            }
        )
    }

    func handleAppEnqueueResponse(
        queueURL: String,
        eventTargetURL: String?,
        queueItToken: String?
    ) {
        let isPassedThrough = !(queueItToken?.isEmpty ?? true)
        let redirectType = getRedirectType(fromToken: queueItToken)

        let TryPassResult = TryPassResult(
            queueUrl: queueURL,
            targetUrl: eventTargetURL,
            redirectType: redirectType,
            isPassedThrough: isPassedThrough,
            queueToken: queueItToken
        )
        delegate?.notifyProviderSuccess(queuePassResult: TryPassResult)
    }

    func enqueueRetryMonitor(enqueueToken: String?, enqueueKey: String?) {
        if deltaSec < WaitingRoomProvider.maxRetrySec {
            try? tryEnqueue(enqueueToken: enqueueToken, enqueueKey: enqueueKey)
            Thread.sleep(forTimeInterval: TimeInterval(deltaSec))
            deltaSec *= 2
        } else {
            deltaSec = WaitingRoomProvider.initialWaitRetrySec
            requestInProgress = false
            delegate?.notifyProviderFailure(errorMessage: "Error! Queue is unavailable.", errorCode: 3)
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
