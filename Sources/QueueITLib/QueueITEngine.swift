import UIKit

public protocol QueuePassedDelegate: AnyObject {
    func notifyYourTurn(queuePassedInfo: QueuePassedInfo?)
}

public protocol QueueViewWillOpenDelegate: AnyObject {
    func notifyQueueViewWillOpen()
}

public protocol QueueDisabledDelegate: AnyObject {
    func notifyQueueDisabled(queueDisabledInfo: QueueDisabledInfo?)
}

public protocol QueueUnavailableDelegate: AnyObject {
    func notifyQueueITUnavailable(errorMessage: String)
}

public protocol QueueErrorDelegate: AnyObject {
    func notifyQueueError(errorMessage: String, errorCode: Int)
}

public protocol QueueViewClosedDelegate: AnyObject {
    func notifyViewClosed()
}

public protocol QueueUserExitedDelegate: AnyObject {
    func notifyUserExited()
}

public protocol QueueSessionRestartDelegate: AnyObject {
    func notifySessionRestart()
}

public protocol QueueUrlChangedDelegate: AnyObject {
    func notifyQueueUrlChanged(url: String)
}

public protocol QueueViewDidAppearDelegate: AnyObject {
    func notifyQueueViewDidAppear()
}

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

    public func run(withEnqueueKey enqueueKey: String) throws {
        try waitingRoomProvider.tryPassWithEnqueueKey(enqueueKey)
    }

    public func run(withEnqueueToken enqueueToken: String) throws {
        try waitingRoomProvider.tryPassWithEnqueueToken(enqueueToken)
    }

    public func run() throws {
        try waitingRoomProvider.tryPass()
    }

    public func showQueue(queueUrl: String, targetUrl: String) {
        waitingRoomView.show(queueUrl: queueUrl, targetUrl: targetUrl)
    }
}

extension QueueItEngine: WaitingRoomViewDelegate {
    public func notifyViewUserExited() {
        queueUserExitedDelegate?.notifyUserExited()
    }

    public func notifyViewUserClosed() {
        queueViewClosedDelegate?.notifyViewClosed()
    }

    public func notifyViewSessionRestart() {
        queueSessionRestartDelegate?.notifySessionRestart()
    }

    public func notifyQueuePassed(info: QueuePassedInfo?) {
        queuePassedDelegate?.notifyYourTurn(queuePassedInfo: info)
    }

    public func notifyViewQueueDidAppear() {
        queueViewDidAppearDelegate?.notifyQueueViewDidAppear()
    }

    public func notifyViewQueueWillOpen() {
        queueViewWillOpenDelegate?.notifyQueueViewWillOpen()
    }

    public func notifyViewUpdatePageUrl(urlString: String?) {
        // TODO: fix optional parameter
        queueUrlChangedDelegate?.notifyQueueUrlChanged(url: urlString ?? "")
    }
}

extension QueueItEngine: WaitingRoomProviderDelegate {
    public func notifyProviderSuccess(queuePassResult: TryPassResult) {
        switch queuePassResult.redirectType {
        case "safetynet":
            let queuePassedInfo = QueuePassedInfo(queueitToken: queuePassResult.queueToken)
            queuePassedDelegate?.notifyYourTurn(queuePassedInfo: queuePassedInfo)
        case "disabled", "idle", "afterevent":
            let queueDisabledInfo = QueueDisabledInfo(queueitToken: queuePassResult.queueToken)
            queueDisabledDelegate?.notifyQueueDisabled(queueDisabledInfo: queueDisabledInfo)
        default:
            // TODO: fix optional parameter
            showQueue(queueUrl: queuePassResult.queueUrl ?? "", targetUrl: queuePassResult.targetUrl ?? "")
        }
    }

    public func notifyProviderFailure(errorMessage: String?, errorCode: Int) {
        // TODO: fix optional parameter
        let errorMessage = errorMessage ?? ""
        if errorCode == 3 {
            queueUnavailableDelegate?.notifyQueueITUnavailable(errorMessage: errorMessage)
        }
        queueErrorDelegate?.notifyQueueError(errorMessage: errorMessage, errorCode: errorCode)
    }
}
