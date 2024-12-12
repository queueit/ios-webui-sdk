struct Status: Sendable {
    let queueId: String
    let queueUrlString: String
    let eventTargetUrl: String
    let queueitToken: String

    init(queueId: String, queueUrl: String, eventTargetUrl: String, queueitToken: String) {
        self.queueId = queueId
        self.queueUrlString = queueUrl
        self.eventTargetUrl = eventTargetUrl
        self.queueitToken = queueitToken
    }

    init(dictionary: [String: Any]) {
        self.init(
            queueId: dictionary[Constants.KEY_QUEUE_ID] as? String ?? "",
            queueUrl: dictionary[Constants.KEY_QUEUE_URL] as? String ?? "",
            eventTargetUrl: dictionary[Constants.KEY_EVENT_TARGET_URL] as? String ?? "",
            queueitToken: dictionary[Constants.KEY_QUEUEIT_TOKEN] as? String ?? ""
        )
    }
}

private extension Status {
    enum Constants {
        static let KEY_QUEUE_ID = "QueueId"
        static let KEY_QUEUE_URL = "QueueUrl"
        static let KEY_EVENT_TARGET_URL = "EventTargetUrl"
        static let KEY_QUEUEIT_TOKEN = "QueueitToken"
    }
}
