import Foundation

@MainActor
final class EventLogStore: ObservableObject {
    @Published var events: [NetworkEvent] = []
    private let fileURL: URL

    init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("NetWatch", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("events.json")
        load()
    }

    func log(_ kind: EventKind, _ title: String) {
        events.insert(NetworkEvent(kind: kind, title: title, timestamp: Date()), at: 0)
        if events.count > 500 { events.removeLast(events.count - 500) }
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(events) else { return }
        try? data.write(to: fileURL)
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([NetworkEvent].self, from: data) else { return }
        events = decoded
    }
}
