import SwiftUI

struct ContentView: View {
    @State private var selection: Tab = .overview
    @EnvironmentObject var deviceStore: DeviceStore
    @EnvironmentObject var eventLog: EventLogStore

    var body: some View {
        HStack(spacing: 0) {
            SidebarView(selection: $selection)
            Divider()
            Group {
                switch selection {
                case .overview: OverviewView()
                case .devices: DevicesView()
                case .people: PeopleView()
                case .internetTab: InternetView()
                case .security: SecurityView()
                case .tools: ToolsView()
                case .timeline: TimelineView()
                case .settings: SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 1000, minHeight: 640)
        .preferredColorScheme(.dark)
        .onAppear {
            if deviceStore.devices.isEmpty {
                deviceStore.scan(eventLog: eventLog)
            }
        }
    }
}
