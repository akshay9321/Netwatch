import Foundation

struct Person: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var deviceMACs: [String]
}
