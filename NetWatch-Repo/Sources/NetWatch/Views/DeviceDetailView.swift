import SwiftUI

struct DeviceDetailView: View {
    @EnvironmentObject var deviceStore: DeviceStore
    var device: Device
    @State private var pingOutput: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 11).fill(Theme.accentTeal.opacity(0.14))
                        Image(systemName: iconName).foregroundColor(Theme.accentTeal)
                    }
                    .frame(width: 44, height: 44)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(device.displayName).font(.system(size: 14, weight: .bold))
                        HStack(spacing: 5) {
                            StatusDot(online: device.isOnline)
                            Text(device.isOnline ? "Online" : "Offline")
                                .font(.system(size: 10.5)).foregroundColor(device.isOnline ? Theme.online : Theme.textTertiary)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 0) {
                    SectionLabel(text: "Details")
                    kv("IP Address", device.ip)
                    kv("MAC Address", device.mac)
                    kv("Vendor", device.vendor ?? "Unknown")
                    kv("Type", device.deviceType)
                    kv("First seen", device.firstSeen.formatted(date: .abbreviated, time: .shortened))
                    kv("Last seen", device.lastSeen.formatted(date: .abbreviated, time: .shortened))
                    kv("Open ports", device.openPorts.isEmpty ? "None found" : device.openPorts.map(String.init).joined(separator: ", "))
                    kv("Approved", device.isApproved ? "Yes" : "No")
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Button("Ping") { runPing() }
                        Button("Approve") { deviceStore.approve(device) }
                        Button("Wake") { WakeOnLANService.wake(mac: device.mac) }
                    }
                    if !pingOutput.isEmpty {
                        Text(pingOutput)
                            .font(.system(size: 10.5, design: .monospaced))
                            .foregroundColor(Theme.online)
                            .padding(8)
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(6)
                    }
                }
            }
            .padding(18)
        }
        .background(Theme.bgBase)
    }

    var iconName: String {
        switch device.deviceType {
        case "Router": return "wifi.router"
        case "Laptop": return "laptopcomputer"
        case "Mobile": return "iphone"
        case "Storage": return "externaldrive.connected.to.line.below"
        case "Gaming": return "gamecontroller"
        case "IoT": return "sensor"
        case "TV": return "tv"
        case "Camera": return "video"
        default: return "questionmark.circle"
        }
    }

    func kv(_ k: String, _ v: String) -> some View {
        HStack {
            Text(k).font(.system(size: 11.5)).foregroundColor(Theme.textSecondary)
            Spacer()
            Text(v).font(.system(size: 11, design: .monospaced))
        }
        .padding(.vertical, 5)
        .overlay(Rectangle().frame(height: 1).foregroundColor(Theme.borderSoft), alignment: .bottom)
    }

    func runPing() {
        pingOutput = ""
        PingService.ping(host: device.ip, onLine: { line in pingOutput += line }, completion: { _ in })
    }
}
