import Foundation

final class Connection: ApiClient {
    private var connectionRequest: ConnectionRequest?

    override func submitRequest(
        with url: URL,
        method httpMethod: String,
        body bodyDict: [String: Any],
        expectedStatus: Int,
        success: @escaping QueueServiceSuccess,
        failure: @escaping QueueServiceFailure
    ) {
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: bodyDict, options: [])
            request.httpBody = jsonData
        } catch {
            failure(error, "Failed to serialize request body.")
            return
        }

        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        connectionRequest = ConnectionRequest(
            request: request,
            expectedStatusCode: expectedStatus,
            success: success,
            failure: failure,
            delegate: self
        )
    }
}

extension Connection: ConnectionRequestDelegate {
    func requestDidComplete(_: ConnectionRequest) {
        // Handle the completion of the request if needed
    }
}
