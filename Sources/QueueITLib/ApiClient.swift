import Foundation

typealias QueueServiceSuccess = (Data) -> Void
typealias QueueServiceFailure = (Error, String) -> Void

@MainActor
final class ApiClient {
    static let API_ROOT = "https://%@.queue-it.net/api/mobileapp/queue"
    static let TESTING_API_ROOT = "https://%@.test.queue-it.net/api/mobileapp/queue"
    private var testingIsEnabled = false

    func setTesting(_ enabled: Bool) {
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
        enqueueKey: String?
    ) async throws -> Status? {
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

        let apiRoot = testingIsEnabled ? ApiClient.TESTING_API_ROOT : ApiClient.API_ROOT
        var urlAsString = String(format: apiRoot, customerId)
        urlAsString += "/\(customerId)"
        urlAsString += "/\(eventOrAliasId)"
        urlAsString += "/enqueue"

        let data = try await submitPOSTPath(path: urlAsString, body: bodyDict)
        do {
            if let userDict = try JSONSerialization.jsonObject(
                with: data,
                options: []
            ) as? [String: Any] {
                return Status(dictionary: userDict)
            } else {
                return nil
            }
        } catch {
            return nil
        }
    }
}

private extension ApiClient {
    func submitPOSTPath(
        path: String,
        body bodyDict: [String: Any]
    ) async throws -> Data {
        guard let url = URL(string: path) else {
            let error = NSError(
                domain: "ApiClient",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]
            )
            throw error
        }

        return try await submitRequest(
            with: url,
            method: "POST",
            body: bodyDict
        )
    }

    func submitRequest(
        with url: URL,
        method httpMethod: String,
        body bodyDict: [String: Any]
    ) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: bodyDict, options: [])
            request.httpBody = jsonData
        } catch {
            throw error
        }

        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        return try await initiateRequest(request: request)
    }

    func initiateRequest(request: URLRequest) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let response = response as? HTTPURLResponse else {
            throw ApiClientError.nilResponse
        }

        let actualStatusCode = response.statusCode
        if actualStatusCode == 200 {
            return data
        } else {
            var message = "Unexpected response code: \(actualStatusCode)"
            if actualStatusCode >= 400, actualStatusCode < 500 {
                if let decodedMessage = String(data: data, encoding: .ascii) {
                    message = decodedMessage
                }
            } else if let json = try? JSONSerialization.jsonObject(with: data, options: []),
                      let jsonDict = json as? [String: Any],
                      let errorMessage = jsonDict["error"] as? String
            {
                message = errorMessage
            }

            throw NSError(
                domain: "QueueService",
                code: actualStatusCode,
                userInfo: [NSLocalizedDescriptionKey: message]
            )
        }
    }
}

enum ApiClientError: Error {
    case nilResponse
}
