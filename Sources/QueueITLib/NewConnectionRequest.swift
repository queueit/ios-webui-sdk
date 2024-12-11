import Foundation

protocol ConnectionRequestDelegate: AnyObject {
    func requestDidComplete(_ request: ConnectionRequest)
}

final class ConnectionRequest {
    let uniqueIdentifier: String

    private var request: URLRequest
    private var response: URLResponse?
    private var data: Data
    private var successCallback: QueueServiceSuccess
    private var failureCallback: QueueServiceFailure
    private weak var delegate: ConnectionRequestDelegate?
    private var expectedStatusCode: Int
    private var actualStatusCode: Int = NSNotFound

    init(
        request: URLRequest,
        expectedStatusCode: Int,
        success: @escaping QueueServiceSuccess,
        failure: @escaping QueueServiceFailure,
        delegate: ConnectionRequestDelegate?
    ) {
        self.request = request
        self.expectedStatusCode = expectedStatusCode
        successCallback = success
        failureCallback = failure
        self.delegate = delegate
        uniqueIdentifier = UUID().uuidString
        data = Data()
        initiateRequest()
    }
}

private extension ConnectionRequest {
    func initiateRequest() {
        response = nil
        data = Data()

        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self else { return }

            if let error = error {
                DispatchQueue.main.async {
                    self.failureCallback(error, "Unexpected failure occurred.")
                    self.delegate?.requestDidComplete(self)
                }
                return
            }

            if let response = response as? HTTPURLResponse {
                self.actualStatusCode = response.statusCode
                self.response = response
            }

            if let receivedData = data {
                self.data.append(receivedData)
            }

            DispatchQueue.main.async {
                self.handleResponse()
            }
        }
        task.resume()
    }

    func handleResponse() {
        if hasExpectedStatusCode() {
            successCallback(data)
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

            let error = NSError(domain: "QueueService",
                                code: actualStatusCode,
                                userInfo: [NSLocalizedDescriptionKey: message])
            failureCallback(error, message)
        }

        delegate?.requestDidComplete(self)
    }

    func hasExpectedStatusCode() -> Bool {
        return actualStatusCode == expectedStatusCode
    }
}
