import Foundation

typealias QueueServiceSuccess = (Data) -> Void
typealias QueueServiceFailure = (Error, String) -> Void

class QueueITApiClient {
    static let API_ROOT = "https://%@.queue-it.net/api/mobileapp/queue"
    static let TESTING_API_ROOT = "https://%@.test.queue-it.net/api/mobileapp/queue"
    private static var testingIsEnabled = false
    private static var sharedInstance: QueueITApiClient?

    static func getInstance() -> QueueITApiClient {
        if sharedInstance == nil {
            sharedInstance = Connection()
        }
        return sharedInstance!
    }

    static func setTesting(_ enabled: Bool) {
        testingIsEnabled = enabled
    }

    func enqueue(
        customerId: String,
        eventOrAliasId: String,
        userId: String,
        userAgent: String,
        sdkVersion: String,
        layoutName: String?,
        language: String?,
        enqueueToken: String?,
        enqueueKey: String?,
        success: @escaping (QueueStatus?) -> Void,
        failure: @escaping QueueServiceFailure
    ) -> String {
        var bodyDict: [String: Any] = [
            "userId": userId,
            "userAgent": userAgent,
            "sdkVersion": sdkVersion,
        ]

        if let layoutName = layoutName {
            bodyDict["layoutName"] = layoutName
        }

        if let language = language {
            bodyDict["language"] = language
        }

        if let enqueueToken = enqueueToken {
            bodyDict["enqueueToken"] = enqueueToken
        }

        if let enqueueKey = enqueueKey {
            bodyDict["enqueueKey"] = enqueueKey
        }

        let apiRoot = QueueITApiClient.testingIsEnabled ? QueueITApiClient.TESTING_API_ROOT : QueueITApiClient.API_ROOT
        var urlAsString = String(format: apiRoot, customerId)
        urlAsString += "/\(customerId)"
        urlAsString += "/\(eventOrAliasId)"
        urlAsString += "/enqueue"

        return submitPOSTPath(
            path: urlAsString,
            body: bodyDict,
            success: { data in
                do {
                    if let userDict = try JSONSerialization.jsonObject(
                        with: data,
                        options: []
                    ) as? [String: Any] {
                        let queueStatus = QueueStatus(dictionary: userDict)
                        success(queueStatus)
                    } else {
                        success(nil)
                    }
                } catch {
                    success(nil)
                }
            },
            failure: failure
        )
    }

    func submitPOSTPath(
        path: String,
        body bodyDict: [String: Any],
        success: @escaping QueueServiceSuccess,
        failure: @escaping QueueServiceFailure
    ) -> String {
        guard let url = URL(string: path) else {
            let error = NSError(
                domain: "QueueITApiClient",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]
            )
            failure(error, "Invalid URL")
            return ""
        }

        return submitRequest(
            with: url,
            method: "POST",
            body: bodyDict,
            expectedStatus: 200,
            success: success,
            failure: failure
        )
    }

    func submitRequest(
        with _: URL,
        method _: String,
        body _: [String: Any],
        expectedStatus _: Int,
        success _: @escaping QueueServiceSuccess,
        failure _: @escaping QueueServiceFailure
    ) -> String {
        return ""
    }
}
