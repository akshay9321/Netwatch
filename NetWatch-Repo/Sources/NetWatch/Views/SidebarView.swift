import SwiftUI

enum Tab: String, CaseIterable, Identifiable {
    case overview = "Home"
    case devices = "Devices"
    case people = "People"
    case internetTab = "Internet"
    case security = "Security"
    case tools = "Tools"
    case timeline = "Timeline"
    case settings = "Settings"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .overview: return "house"
        case .devices: return "circle.grid.2x2"
        case .people: return "person.2"
        case .internetTab: return "wifi"
        case .security: return "lock.shield"
        case .tools: return "wrench.and.screwdriver"
        case .timeline: return "clock.arrow.circlepath"
        case .settings: return "gearshape"
        }
    }
}

struct SidebarView: View {
    @Binding var selection: Tab
    @EnvironmentObject var deviceStore: DeviceStore
    @EnvironmentObject var eventLog: EventLogStore

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Circle().fill(Theme.online).frame(width: 8, height: 8)
                    Text(NetworkScanner.localInterface()?.subnetPrefix ?? "No network")
                        .font(.system(size: 12, weight: .semibold))
                }
                Text("\(deviceStore.devices.count) devices tracked")
                    .font(.system(size: 10.5, design: .monospaced))
                    .foregroundColor(Theme.textSecondary)
            }
            .padding(11)
            .background(Theme.bgElevated)
            .cornerRadius(10)
            .padding(.bottom, 14)

            ForEach(Tab.allCases) { tab in
                Button {
                    selection = tab
                } label: {
                    HStack(spacing: 9) {
                        Image(systemName: tab.icon).frame(width: 15)
                        Text(tab.rawValue).font(.system(size: 12.3))
                        Spacer()
                        if tab == .devices {
                            Text("\(deviceStore.devices.count)")
                                .font(.system(size: 9.5, design: .monospaced))
                                .foregroundColor(Theme.textTertiary)
                        }
                    }
                    .padding(.horizontal, 9).padding(.vertical, 7)
                    .background(selection == tab ? Theme.accentTeal.opacity(0.14) : Color.clear)
                    .foregroundColor(selection == tab ? Theme.accentTeal : Theme.textSecondary)
                    .cornerRadius(7)
                }
                .buttonStyle(.plain)
            }

            Spacer()

            Button {
                deviceStore.scan(eventLog: eventLog)
            } label: {
                HStack {
                    Spacer()
                    if deviceStore.isScanning {
                        ProgressView().scaleEffect(0.6)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                    Text(deviceStore.isScanning ? "Scanning…" : "Scan Network")
                        .font(.system(size: 12.5, weight: .bold))
                    Spacer()
                }
                .padding(.vertical, 9)
                .background(Theme.accentTeal)
                .foregroundColor(Color.black.opacity(0.85))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .disabled(deviceStore.isScanning)
        }
        .padding(9)
        .frame(width: 210)
        .background(Theme.bgSidebar)
    }
}
