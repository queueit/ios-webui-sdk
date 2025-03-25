import Foundation

public struct TryPassResult {
    public let queueUrl: String?
    public let targetUrl: String?
    public let redirectType: String
    public let isPassedThrough: Bool
    public let queueToken: String?
}
