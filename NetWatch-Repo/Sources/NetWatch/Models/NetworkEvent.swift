import Foundation

enum EventKind: String, Codable {
    case joined, left, warning, test, security
}

struct NetworkEvent: Identifiable, Codable {
    var id: UUID = UUID()
    var kind: EventKind
    var title: String
    var timestamp: Date
}
