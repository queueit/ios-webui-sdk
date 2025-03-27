import UIKit

public protocol QueuePassedDelegate: AnyObject {
    @MainActor func notifyYourTurn(queuePassedInfo: QueuePassedInfo?)
}

public protocol QueueViewWillOpenDelegate: AnyObject {
    @MainActor func notifyQueueViewWillOpen()
}

public protocol QueueDisabledDelegate: AnyObject {
    @MainActor func notifyQueueDisabled(queueDisabledInfo: QueueDisabledInfo?)
}

public protocol QueueUnavailableDelegate: AnyObject {
    @MainActor func notifyQueueITUnavailable(errorMessage: String)
}

public protocol QueueErrorDelegate: AnyObject {
    @MainActor func notifyQueueError(errorMessage: String, errorCode: Int)
}

public protocol QueueViewClosedDelegate: AnyObject {
    @MainActor func notifyViewClosed()
}

public protocol QueueUserExitedDelegate: AnyObject {
    @MainActor func notifyUserExited()
}

public protocol QueueSessionRestartDelegate: AnyObject {
    @MainActor func notifySessionRestart()
}

public protocol QueueUrlChangedDelegate: AnyObject {
    @MainActor func notifyQueueUrlChanged(url: String)
}

public protocol QueueViewDidAppearDelegate: AnyObject {
    @MainActor func notifyQueueViewDidAppear()
}

@MainActor
public final class QueueItEngine {
    public weak var queuePassedDelegate: QueuePassedDelegate?
    public weak var queueViewWillOpenDelegate: QueueViewWillOpenDelegate?
    public weak var queueDisabledDelegate: QueueDisabledDelegate?
    public weak var queueUnavailableDelegate: QueueUnavailableDelegate?
    public weak var queueErrorDelegate: QueueErrorDelegate?
    public weak var queueViewClosedDelegate: QueueViewClosedDelegate?
    public weak var queueUserExitedDelegate: QueueUserExitedDelegate?
    public weak var queueSessionRestartDelegate: QueueSessionRestartDelegate?
    public weak var queueUrlChangedDelegate: QueueUrlChangedDelegate?
    public weak var queueViewDidAppearDelegate: QueueViewDidAppearDelegate?

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

    public func run() async throws {
        try await waitingRoomProvider.tryPass()
    }

    @MainActor public func showQueue(queueUrl: String, targetUrl: String) {
        waitingRoomView.show(queueUrl: queueUrl, targetUrl: targetUrl)
    }
}

extension QueueItEngine: WaitingRoomViewDelegate {
    @MainActor public func notifyViewUserExited() {
        queueUserExitedDelegate?.notifyUserExited()
    }

    @MainActor public func notifyViewUserClosed() {
        queueViewClosedDelegate?.notifyViewClosed()
    }

    @MainActor public func notifyViewSessionRestart() {
        queueSessionRestartDelegate?.notifySessionRestart()
    }

    @MainActor public func notifyQueuePassed(info: QueuePassedInfo?) {
        queuePassedDelegate?.notifyYourTurn(queuePassedInfo: info)
    }

    @MainActor public func notifyViewQueueDidAppear() {
        queueViewDidAppearDelegate?.notifyQueueViewDidAppear()
    }

    @MainActor public func notifyViewQueueWillOpen() {
        queueViewWillOpenDelegate?.notifyQueueViewWillOpen()
    }

    @MainActor public func notifyViewUpdatePageUrl(urlString: String?) {
        // TODO: fix optional parameter
        queueUrlChangedDelegate?.notifyQueueUrlChanged(url: urlString ?? "")
    }
}

extension QueueItEngine: WaitingRoomProviderDelegate {
    @MainActor public func notifyProviderSuccess(queuePassResult: TryPassResult) async {
        switch queuePassResult.redirectType {
        case "safetynet":
            let queuePassedInfo = QueuePassedInfo(queueitToken: queuePassResult.queueToken)
            queuePassedDelegate?.notifyYourTurn(queuePassedInfo: queuePassedInfo)
        case "disabled", "idle", "afterevent":
            let queueDisabledInfo = QueueDisabledInfo(queueitToken: queuePassResult.queueToken)
            queueDisabledDelegate?.notifyQueueDisabled(queueDisabledInfo: queueDisabledInfo)
        default:
            showQueue(queueUrl: queuePassResult.queueUrl, targetUrl: queuePassResult.targetUrl)
        }
    }

    @MainActor public func notifyProviderFailure(errorMessage: String?, errorCode: Int) async {
        // TODO: fix optional parameter
        let errorMessage = errorMessage ?? ""
        if errorCode == 3 {
            queueUnavailableDelegate?.notifyQueueITUnavailable(errorMessage: errorMessage)
        }
        queueErrorDelegate?.notifyQueueError(errorMessage: errorMessage, errorCode: errorCode)
    }
}
