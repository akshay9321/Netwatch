import Foundation

struct SecurityCheck {
    var title: String
    var passed: Bool
    var detail: String
}

enum SecurityCheckService {
    static let portRisk: [Int: String] = [
        21: "High", 23: "High", 3389: "High",
        22: "Medium", 5555: "Medium",
        80: "Low", 443: "Low", 554: "Low"
    ]

    static func evaluateRouter(_ router: Device) -> [SecurityCheck] {
        let risky = router.openPorts.filter { portRisk[$0] == "High" }
        return [SecurityCheck(
            title: "Router Open Ports",
            passed: risky.isEmpty,
            detail: risky.isEmpty ? "No high-risk ports exposed" : "High-risk ports open: \(risky.map(String.init).joined(separator: ", "))"
        )]
    }

    static func findHiddenCameras(devices: [Device]) -> [Device] {
        devices.filter { $0.openPorts.contains(554) || $0.openPorts.contains(8554) || $0.deviceType == "Camera" }
    }

    static func score(devices: [Device], routerChecks: [SecurityCheck]) -> Int {
        var score = 100
        score -= routerChecks.filter { !$0.passed }.count * 20
        let unapproved = devices.filter { !$0.isApproved }.count
        score -= min(unapproved * 5, 30)
        return max(0, min(100, score))
    }
}
