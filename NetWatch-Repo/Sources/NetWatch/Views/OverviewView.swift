import SwiftUI

struct OverviewView: View {
    @EnvironmentObject var deviceStore: DeviceStore
    @EnvironmentObject var eventLog: EventLogStore

    var onlineCount: Int { deviceStore.devices.filter { $0.isOnline }.count }
    var offlineCount: Int { deviceStore.devices.count - onlineCount }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 280, maximum: 360), spacing: 16)], spacing: 16) {
                WidgetCard(title: "Connected Devices") {
                    Text("\(deviceStore.devices.count)")
                        .font(.system(size: 30, weight: .heavy, design: .monospaced))
                    Text("\(onlineCount) online · \(offlineCount) offline")
                        .font(.system(size: 11)).foregroundColor(Theme.textTertiary)
                }
                WidgetCard(title: "Security Profile") {
                    HStack(spacing: 16) {
                        GaugeView(value: 0.82, color: Theme.online, label: "82")
                            .frame(width: 60, height: 60)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Run the Security tab for live checks")
                                .font(.system(size: 11)).foregroundColor(Theme.textSecondary)
                        }
                    }
                }
                WidgetCard(title: "Who's Online") {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(deviceStore.devices.filter { $0.isOnline }.prefix(4)) { d in
                            HStack {
                                StatusDot(online: true)
                                Text(d.displayName).font(.system(size: 12))
                            }
                        }
                        if onlineCount == 0 {
                            Text("Run a scan to see who's online").font(.system(size: 11)).foregroundColor(Theme.textTertiary)
                        }
                    }
                }
                WidgetCard(title: "Recent Activity") {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(eventLog.events.prefix(4)) { e in
                            Text(e.title).font(.system(size: 11)).foregroundColor(Theme.textSecondary)
                        }
                        if eventLog.events.isEmpty {
                            Text("No events yet").font(.system(size: 11)).foregroundColor(Theme.textTertiary)
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(Theme.bgBase)
    }
}
