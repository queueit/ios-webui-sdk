import UIKit
@preconcurrency import WebKit

protocol WebViewControllerDelegate: AnyObject {
    @MainActor func notifyViewControllerClosed()
    @MainActor func notifyViewControllerUserExited()
    @MainActor func notifyViewControllerSessionRestart()
    @MainActor func notifyViewControllerQueuePassed(queueToken: String?)
    @MainActor func notifyViewControllerPageUrlChanged(urlString: String?)
}

final class WebViewController: UIViewController {
    weak var delegate: WebViewControllerDelegate?

    private var webView: WKWebView?
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
        webView.backgroundColor = .white

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

extension WebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, preferences: WKWebpagePreferences) async -> (WKNavigationActionPolicy, WKWebpagePreferences) {
        if !isQueuePassed {
            let request = navigationAction.request
            let urlString = request.url?.absoluteString
            let targetUrlString = eventTargetUrl
            if let urlString, urlString != "about:blank" {
                let url = URL(string: urlString)!
                let targetUrl = URL(string: targetUrlString)!
                let isQueueUrl = queueUrl.contains(url.host!)
                let isNotFrame = request.url?.absoluteString == request.mainDocumentURL?.absoluteString


                if url.absoluteString == Constants.queueCloseUrl {
                    delegate?.notifyViewControllerClosed()
                    return (.cancel, preferences)
                } else if url.absoluteString == Constants.queueRestartSessionUrl {
                    delegate?.notifyViewControllerSessionRestart()
                    return (.cancel, preferences)
                }

                if isBlockedUrl(destinationUrl: url) {
                    return (.cancel, preferences)
                }

                if isNotFrame {
                    if isQueueUrl {
                        raiseQueuePageUrl(urlString)
                    }
                    if isTargetUrl(targetUrl: targetUrl, destinationUrl: url) {
                        isQueuePassed = true
                        let queueitToken = extractQueueToken(urlString)
                        delegate?.notifyViewControllerQueuePassed(queueToken: queueitToken)
                        return (.cancel, preferences)
                    }
                }

                if navigationAction.navigationType == .linkActivated && !isQueueUrl {
                    await UIApplication.shared.open(request.url!)
                    return (.cancel, preferences)
                }
            }
        }
        
        return (.allow, preferences)
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

private extension WebViewController {
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
