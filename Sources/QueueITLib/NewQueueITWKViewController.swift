import UIKit
import WebKit

protocol QueueITViewControllerDelegate: AnyObject {
    func notifyViewControllerClosed()
    func notifyViewControllerUserExited()
    func notifyViewControllerSessionRestart()
    func notifyViewControllerQueuePassed(queueToken: String?)
    func notifyViewControllerPageUrlChanged(urlString: String?)
}

final class QueueITWKViewController: UIViewController {
    weak var delegate: QueueITViewControllerDelegate?
    weak var webView: WKWebView?

    private var spinner: UIActivityIndicatorView?
    private var isQueuePassed: Bool

    private var queueUrl: String
    private var eventTargetUrl: String
    private var eventId: String

    private let JAVASCRIPT_GET_BODY_CLASSES = "document.getElementsByTagName('body')[0].className"

    init(queueUrl: String, eventTargetUrl: String, eventId: String) {
        self.queueUrl = queueUrl
        self.eventTargetUrl = eventTargetUrl
        self.eventId = eventId
        isQueuePassed = false
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true

        let config = WKWebViewConfiguration()
        config.preferences = preferences

        spinner = UIActivityIndicatorView(frame: view.bounds)
        webView = WKWebView(frame: view.bounds, configuration: config)

        guard let spinner, let webView else {
            return
        }

        spinner.color = .gray
        webView.navigationDelegate = self
        webView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        webView.isOpaque = false
        webView.backgroundColor = .clear

        view.addSubview(webView)
        view.addSubview(spinner)

        webView.frame = view.bounds
        spinner.frame = view.bounds
    }

    func loadWebView() {
        guard let spinner,
              let webView,
              let url = URL(string: queueUrl)
        else {
            return
        }
        spinner.startAnimating()
        webView.load(URLRequest(url: url))
    }
}

extension QueueITWKViewController: WKNavigationDelegate {
    func webView(
        _: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        if !isQueuePassed {
            let request = navigationAction.request
            let urlString = request.url?.absoluteString
            let targetUrlString = eventTargetUrl
            if let urlString, urlString != "about:blank" {
                let url = URL(string: urlString)!
                let targetUrl = URL(string: targetUrlString)!
                let isQueueUrl = queueUrl.contains(url.host!)
                let isNotFrame = request.url?.absoluteString == request.mainDocumentURL?.absoluteString


                if url.absoluteString == QueueConsts.queueCloseUrl {
                    delegate?.notifyViewControllerClosed()
                    decisionHandler(.cancel)
                    return
                } else if url.absoluteString == QueueConsts.queueRestartSessionUrl {
                    delegate?.notifyViewControllerSessionRestart()
                    decisionHandler(.cancel)
                    return
                }

                if isBlockedUrl(destinationUrl: url) {
                    decisionHandler(.cancel)
                    return
                }

                if isNotFrame {
                    if isQueueUrl {
                        raiseQueuePageUrl(urlString)
                    }
                    if isTargetUrl(targetUrl: targetUrl, destinationUrl: url) {
                        isQueuePassed = true
                        let queueitToken = extractQueueToken(urlString)
                        delegate?.notifyViewControllerQueuePassed(queueToken: queueitToken)
                        decisionHandler(.cancel)
                        return
                    }
                }

                if navigationAction.navigationType == .linkActivated && !isQueueUrl {
                    UIApplication.shared.open(request.url!)
                    decisionHandler(.cancel)
                    return
                }
            }
        }

        decisionHandler(.allow)
    }

    func webView(_: WKWebView, didStartProvisionalNavigation _: WKNavigation!) {}

    func webView(_: WKWebView, didFinish _: WKNavigation!) {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive(_:)),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )

        guard let spinner, let webView else {
            return
        }

        spinner.stopAnimating()
        webView.evaluateJavaScript(JAVASCRIPT_GET_BODY_CLASSES) { [weak self] result, error in
            guard let self else {
                return
            }
            if let error {
                print("evaluateJavaScript error: \(error.localizedDescription)")
            } else if let resultString = result as? String {
                let htmlBodyClasses = resultString.split(separator: " ")
                let isExitClassPresent = htmlBodyClasses.contains("exit")
                if isExitClassPresent {
                    self.delegate?.notifyViewControllerUserExited()
                }
            }
        }
    }
}

private extension QueueITWKViewController {
    func isTargetUrl(targetUrl: URL, destinationUrl: URL) -> Bool {
        return destinationUrl.host == targetUrl.host && destinationUrl.path == targetUrl.path
    }

    func isBlockedUrl(destinationUrl: URL) -> Bool {
        return destinationUrl.path.hasPrefix("/what-is-this.html")
    }

    func extractQueueToken(_ url: String) -> String? {
        let tokenKey = "queueittoken="
        if let range = url.range(of: tokenKey) {
            var token = String(url[range.upperBound...])
            if let ampersandRange = token.range(of: "&") {
                token = String(token[..<ampersandRange.lowerBound])
            }
            return token
        }
        return nil
    }

    func raiseQueuePageUrl(_ urlString: String) {
        delegate?.notifyViewControllerPageUrlChanged(urlString: urlString)
    }

    @objc func appWillResignActive(_: Notification) {}
}
