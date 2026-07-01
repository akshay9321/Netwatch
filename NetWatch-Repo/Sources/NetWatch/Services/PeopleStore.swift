import Foundation

@MainActor
final class PeopleStore: ObservableObject {
    @Published var people: [Person] = []
    private let fileURL: URL

    init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("NetWatch", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("people.json")
        load()
    }

    func add(name: String) {
        people.append(Person(name: name, deviceMACs: []))
        save()
    }

    func assign(deviceMAC: String, to personId: UUID) {
        guard let idx = people.firstIndex(where: { $0.id == personId }) else { return }
        if !people[idx].deviceMACs.contains(deviceMAC) { people[idx].deviceMACs.append(deviceMAC) }
        save()
    }

    func isHome(_ person: Person, devices: [Device]) -> Bool {
        devices.contains { person.deviceMACs.contains($0.id) && $0.isOnline }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(people) else { return }
        try? data.write(to: fileURL)
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([Person].self, from: data) else { return }
        people = decoded
    }
}
