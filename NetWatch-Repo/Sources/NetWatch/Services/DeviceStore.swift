import Foundation
import Combine

@MainActor
final class DeviceStore: ObservableObject {
    @Published var devices: [Device] = []
    @Published var isScanning = false
    @Published var scanStatus: String = ""
    @Published var lastScanDate: Date?

    private let fileURL: URL

    init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("NetWatch", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("devices.json")
        load()
    }

    func scan(eventLog: EventLogStore) {
        guard !isScanning else { return }
        isScanning = true
        scanStatus = "Starting scan…"
        Task {
            let found = await NetworkScanner.scan { status in
                Task { @MainActor in self.scanStatus = status }
            }
            self.merge(found: found, eventLog: eventLog)
            self.isScanning = false
            self.lastScanDate = Date()
            self.scanStatus = ""
            self.save()
        }
    }

    private func merge(found: [Device], eventLog: EventLogStore) {
        var byId = Dictionary(uniqueKeysWithValues: devices.map { ($0.id, $0) })
        var seenIds = Set<String>()

        for device in found {
            seenIds.insert(device.id)
            if var existing = byId[device.id] {
                existing.ip = device.ip
                existing.isOnline = true
                existing.lastSeen = Date()
                existing.openPorts = device.openPorts
                if existing.hostname == nil { existing.hostname = device.hostname }
                byId[device.id] = existing
            } else {
                var newDevice = device
                newDevice.firstSeen = Date()
                newDevice.lastSeen = Date()
                byId[device.id] = newDevice
                eventLog.log(.joined, "\(newDevice.displayName) joined the network")
            }
        }

        for key in byId.keys where !seenIds.contains(key) {
            if byId[key]!.isOnline {
                byId[key]!.isOnline = false
                eventLog.log(.left, "\(byId[key]!.displayName) went offline")
            }
        }

        devices = byId.values.sorted { $0.ip.localizedStandardCompare($1.ip) == .orderedAscending }
    }

    func approve(_ device: Device) {
        guard let idx = devices.firstIndex(where: { $0.id == device.id }) else { return }
        devices[idx].isApproved = true
        save()
    }

    func rename(_ device: Device, to name: String) {
        guard let idx = devices.firstIndex(where: { $0.id == device.id }) else { return }
        devices[idx].hostname = name
        save()
    }

    var router: Device? { devices.first(where: { $0.isRouter }) }

    private func save() {
        guard let data = try? JSONEncoder().encode(devices) else { return }
        try? data.write(to: fileURL)
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([Device].self, from: data) else { return }
        devices = decoded
    }
}
