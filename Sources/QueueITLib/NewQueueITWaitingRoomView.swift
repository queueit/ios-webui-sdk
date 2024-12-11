import UIKit

protocol QueueITWaitingRoomViewDelegate: AnyObject {
    func notifyViewUserExited()
    func notifyViewUserClosed()
    func notifyViewSessionRestart()
    func notifyQueuePassed(info: QueuePassedInfo?)
    func notifyViewQueueDidAppear()
    func notifyViewQueueWillOpen()
    func notifyViewUpdatePageUrl(urlString: String?)
}

final class QueueITWaitingRoomView {
    weak var host: UIViewController?
    weak var delegate: QueueITWaitingRoomViewDelegate?
    weak var currentWebView: QueueITWKViewController?

    private var eventId: String
    private var delayInterval: Int = 0

    init(host: UIViewController, eventId: String) {
        self.host = host
        self.eventId = eventId
    }

    func show(queueUrl: String, targetUrl: String) {
        raiseQueueViewWillOpen()

        let queueWKVC = QueueITWKViewController(
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

    func setViewDelay(_ delayInterval: Int) {
        self.delayInterval = delayInterval
    }
}

extension QueueITWaitingRoomView: QueueITViewControllerDelegate {
    func notifyViewControllerClosed() {
        delegate?.notifyViewUserClosed()
        close()
    }

    func notifyViewControllerUserExited() {
        delegate?.notifyViewUserExited()
    }

    func notifyViewControllerSessionRestart() {
        delegate?.notifyViewSessionRestart()
        close()
    }

    func notifyViewControllerQueuePassed(queueToken: String?) {
        let queuePassedInfo = QueuePassedInfo(queueitToken: queueToken)
        delegate?.notifyQueuePassed(info: queuePassedInfo)
        close()
    }

    func notifyViewControllerPageUrlChanged(urlString: String?) {
        delegate?.notifyViewUpdatePageUrl(urlString: urlString)
    }
}

private extension QueueITWaitingRoomView {
    func close(onComplete: (() -> Void)? = nil) {
        DispatchQueue.main.async { [weak self] in
            guard let self, let host else {
                return
            }
            host.dismiss(animated: true)
        }
    }

    func raiseQueueViewWillOpen() {
        delegate?.notifyViewQueueWillOpen()
    }
}
