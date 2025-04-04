import UIKit

public protocol QueueItEngineDelegate: AnyObject {
    @MainActor func notifyQueuePassed(info: QueuePassedInfo?)
    @MainActor func notifyQueueViewWillOpen()
    @MainActor func notifyQueueDisabled(queueDisabledInfo: QueueDisabledInfo?)
    @MainActor func notifyQueueUnavailable(errorMessage: String)
    @MainActor func notifyQueueError(errorMessage: String, errorCode: Int)
    @MainActor func notifyViewClosed()
    @MainActor func notifyUserExited()
    @MainActor func notifySessionRestart()
    @MainActor func notifyQueueUrlChanged(url: String)
    @MainActor func notifyQueueViewDidAppear()
}

@MainActor
public final class QueueItEngine {
    public weak var delegate: QueueItEngineDelegate?

    public weak var host: UIViewController?
    private var waitingRoomProvider: WaitingRoomProvider
    private var waitingRoomView: WaitingRoomView

    public init(host: UIViewController, customerId: String, eventOrAliasId: String, layoutName: String?, language: String?) {
        self.host = host

        waitingRoomProvider = WaitingRoomProvider(
            customerId: customerId,
            eventOrAliasId: eventOrAliasId,
            layoutName: layoutName,
            language: language
        )
        waitingRoomView = WaitingRoomView(host: host, eventId: eventOrAliasId)
        waitingRoomView.delegate = self
        waitingRoomProvider.delegate = self
    }

    public func setViewDelay(_ delayInterval: Int) {
        waitingRoomView.setViewDelay(delayInterval)
    }

    public func isRequestInProgress() -> Bool {
        return waitingRoomProvider.isRequestInProgress()
    }

    public func run(withEnqueueKey enqueueKey: String) async throws {
        try await waitingRoomProvider.tryPassWithEnqueueKey(enqueueKey)
    }

    public func run(withEnqueueToken enqueueToken: String) async throws {
        try await waitingRoomProvider.tryPassWithEnqueueToken(enqueueToken)
    }
    
    @MainActor
    public func run() {
        Task { @MainActor in
            try await waitingRoomProvider.tryPass()
        }
    }

    @MainActor public func showQueue(queueUrl: String, targetUrl: String) {
        waitingRoomView.show(queueUrl: queueUrl, targetUrl: targetUrl)
    }
}

extension QueueItEngine: WaitingRoomViewDelegate {
    @MainActor public func notifyViewUserExited() {
        delegate?.notifyUserExited()
    }

    @MainActor public func notifyViewUserClosed() {
        delegate?.notifyViewClosed()
    }

    @MainActor public func notifyViewSessionRestart() {
        delegate?.notifySessionRestart()
    }

    @MainActor public func notifyQueuePassed(info: QueuePassedInfo?) {
        delegate?.notifyQueuePassed(info: info)
    }

    @MainActor public func notifyViewQueueDidAppear() {
        delegate?.notifyQueueViewDidAppear()
    }

    @MainActor public func notifyViewQueueWillOpen() {
        delegate?.notifyQueueViewWillOpen()
    }

    @MainActor public func notifyViewUpdatePageUrl(urlString: String) {
        delegate?.notifyQueueUrlChanged(url: urlString)
    }
}

extension QueueItEngine: WaitingRoomProviderDelegate {
    @MainActor public func notifyProviderSuccess(queuePassResult: TryPassResult) async {
        switch queuePassResult.redirectType {
        case "safetynet":
            let queuePassedInfo = QueuePassedInfo(queueitToken: queuePassResult.queueToken)
            delegate?.notifyQueuePassed(info: queuePassedInfo)
        case "disabled", "idle", "afterevent":
            let queueDisabledInfo = QueueDisabledInfo(queueitToken: queuePassResult.queueToken)
            delegate?.notifyQueueDisabled(queueDisabledInfo: queueDisabledInfo)
        default:
            showQueue(queueUrl: queuePassResult.queueUrl, targetUrl: queuePassResult.targetUrl)
        }
    }

    @MainActor public func notifyProviderFailure(errorMessage: String, errorCode: Int) async {
        if errorCode == 3 {
            delegate?.notifyQueueUnavailable(errorMessage: errorMessage)
        }
        delegate?.notifyQueueError(errorMessage: errorMessage, errorCode: errorCode)
    }
}
