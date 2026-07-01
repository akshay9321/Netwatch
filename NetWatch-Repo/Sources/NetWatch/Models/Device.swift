import Foundation

struct Device: Identifiable, Codable, Equatable {
    var id: String            // MAC address, uppercased
    var ip: String
    var mac: String
    var hostname: String?
    var vendor: String?
    var deviceType: String
    var isOnline: Bool
    var isRouter: Bool
    var firstSeen: Date
    var lastSeen: Date
    var openPorts: [Int]
    var isApproved: Bool = false

    var displayName: String {
        hostname ?? vendor ?? mac
    }
}
