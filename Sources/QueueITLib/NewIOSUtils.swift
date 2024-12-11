import Foundation
import WebKit

enum IOSUtils {
    static func getUserId() -> String {
        let device = UIDevice()
        if let deviceId = device.identifierForVendor {
            return deviceId.uuidString
        }
        return ""
    }

    static func getUserAgent(completionHandler: @escaping (String) -> Void) {
        DispatchQueue.main.async {
            let view = WKWebView(frame: .zero)
            view.evaluateJavaScript("navigator.userAgent") { result, error in
                if let userAgent = result as? String, error == nil {
                    completionHandler(userAgent)
                } else {
                    completionHandler("")
                }
            }
        }
    }

    static func getLibraryVersion() -> String {
        if let infoDictionary = Bundle.main.infoDictionary,
           let libName = infoDictionary[kCFBundleNameKey as String] as? String,
           let major = infoDictionary["CFBundleShortVersionString"] as? String,
           let minor = infoDictionary[kCFBundleVersionKey as String] as? String
        {
            return "\(libName)-\(major).\(minor)"
        }
        return ""
    }

    static func getSdkVersion() -> String {
        return QueueConsts.sdkVersion
    }
}
