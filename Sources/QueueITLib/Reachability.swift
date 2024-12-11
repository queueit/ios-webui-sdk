import Foundation
import Network
import SystemConfiguration


extension Notification.Name {
    static let reachabilityChanged = Notification.Name("kNetworkReachabilityChangedNotification")
}

final class Reachability {
    private var monitor: NWPathMonitor?
    private var isMonitoringLocalWiFi: Bool = false
    private var queue = DispatchQueue.global(qos: .background)

    private init() {}

    static func reachabilityWithHostName(_ hostName: String) -> Reachability {
        let reachability = Reachability()
        reachability.startMonitoringHost(hostName: hostName)
        return reachability
    }

    static func reachabilityWithAddress(_ hostAddress: sockaddr_in) -> Reachability {
        let reachability = Reachability()
        reachability.startMonitoringIP(address: hostAddress)
        return reachability
    }

    static func reachabilityForInternetConnection() -> Reachability {
        let reachability = Reachability()
        reachability.startMonitoringInternet()
        return reachability
    }

    static func reachabilityForLocalWiFi() -> Reachability {
        let reachability = Reachability()
        reachability.startMonitoringWiFi()
        return reachability
    }

    func startNotifier() -> Bool {
        guard monitor == nil else { return true }
        monitor = NWPathMonitor()
        monitor?.pathUpdateHandler = { [weak self] _ in
            NotificationCenter.default.post(name: .reachabilityChanged, object: nil)
        }
        monitor?.start(queue: queue)
        return true
    }

    func stopNotifier() {
        monitor?.cancel()
        monitor = nil
    }

    func currentReachabilityStatus() -> NetworkStatus {
        guard let monitor = monitor else { return .notReachable }
        let path = monitor.currentPath
        if path.status == .unsatisfied {
            return .notReachable
        }
        if path.usesInterfaceType(.wifi) {
            return .reachableViaWiFi
        }
        if path.usesInterfaceType(.cellular) {
            return .reachableViaWWAN
        }
        return .notReachable
    }

    func connectionRequired() -> Bool {
        guard let monitor = monitor else { return false }
        return monitor.currentPath.status != .satisfied
    }
}

extension Reachability {
    enum NetworkStatus: Int {
        case notReachable = 0
        case reachableViaWiFi
        case reachableViaWWAN
    }
}

private extension Reachability {
    func startMonitoringHost(hostName _: String) {
        monitor = NWPathMonitor(requiredInterfaceType: .other)
        monitor?.pathUpdateHandler = { _ in
            NotificationCenter.default.post(name: .reachabilityChanged, object: nil)
        }
        monitor?.start(queue: queue)
    }

    func startMonitoringIP(address _: sockaddr_in) {
        monitor = NWPathMonitor()
        monitor?.pathUpdateHandler = { _ in
            NotificationCenter.default.post(name: .reachabilityChanged, object: nil)
        }
        monitor?.start(queue: queue)
    }

    func startMonitoringInternet() {
        monitor = NWPathMonitor()
        monitor?.pathUpdateHandler = { _ in
            NotificationCenter.default.post(name: .reachabilityChanged, object: nil)
        }
        monitor?.start(queue: queue)
    }

    func startMonitoringWiFi() {
        isMonitoringLocalWiFi = true
        monitor = NWPathMonitor(requiredInterfaceType: .wifi)
        monitor?.pathUpdateHandler = { _ in
            NotificationCenter.default.post(name: .reachabilityChanged, object: nil)
        }
        monitor?.start(queue: queue)
    }
}
