import UIKit

public protocol WaitingRoomViewDelegate: AnyObject {
    @MainActor func notifyViewUserExited()
    @MainActor func notifyViewUserClosed()
    @MainActor func notifyViewSessionRestart()
    @MainActor func notifyQueuePassed(info: QueuePassedInfo?)
    @MainActor func notifyViewQueueDidAppear()
    @MainActor func notifyViewQueueWillOpen()
    @MainActor func notifyViewUpdatePageUrl(urlString: String?)
}

public final class WaitingRoomView {
    weak var host: UIViewController?
    public weak var delegate: WaitingRoomViewDelegate?
    weak var currentWebView: WebViewController?

    private var eventId: String
    private var delayInterval: Int = 0

    public init(host: UIViewController, eventId: String) {
        self.host = host
        self.eventId = eventId
    }

    @MainActor public func show(queueUrl: String, targetUrl: String) {
        raiseQueueViewWillOpen()

        let queueWKVC = WebViewController(
            queueUrl: queueUrl,
            eventTargetUrl: targetUrl,
            eventId: eventId
        )

        queueWKVC.delegate = self

        if #available(iOS 13.0, *) {
            queueWKVC.modalPresentationStyle = UIModalPresentationStyle.fullScreen
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(delayInterval)) { [weak self] in
            guard let self else {
                return
            }
            self.host?.present(queueWKVC, animated: true, completion: { [weak self] in
                guard let self else {
                    return
                }
                self.currentWebView = queueWKVC
                self.currentWebView?.loadWebView()
                self.delegate?.notifyViewQueueDidAppear()
            })
        }
    }

    public func setViewDelay(_ delayInterval: Int) {
        self.delayInterval = delayInterval
    }
}

extension WaitingRoomView: WebViewControllerDelegate {
    @MainActor func notifyViewControllerClosed() {
        delegate?.notifyViewUserClosed()
        close()
    }

    @MainActor func notifyViewControllerUserExited() {
        delegate?.notifyViewUserExited()
    }

    @MainActor func notifyViewControllerSessionRestart() {
        delegate?.notifyViewSessionRestart()
        close()
    }

    @MainActor func notifyViewControllerQueuePassed(queueToken: String?) {
        let queuePassedInfo = QueuePassedInfo(queueitToken: queueToken)
        delegate?.notifyQueuePassed(info: queuePassedInfo)
        close()
    }

    @MainActor func notifyViewControllerPageUrlChanged(urlString: String?) {
        delegate?.notifyViewUpdatePageUrl(urlString: urlString)
    }
}

private extension WaitingRoomView {
    @MainActor func close(onComplete: (() -> Void)? = nil) {
        DispatchQueue.main.async { [weak self] in
            guard let self, let host else {
                return
            }
            host.dismiss(animated: true)
        }
    }

    @MainActor func raiseQueueViewWillOpen() {
        delegate?.notifyViewQueueWillOpen()
    }
}
