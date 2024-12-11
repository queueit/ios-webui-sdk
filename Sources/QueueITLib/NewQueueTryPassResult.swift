import Foundation

struct QueueTryPassResult {
    let queueUrl: String?
    let targetUrl: String?
    let redirectType: String
    let isPassedThrough: Bool
    let queueToken: String?
}
