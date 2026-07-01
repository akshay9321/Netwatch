import SwiftUI

@main
struct NetWatchApp: App {
    @StateObject private var deviceStore = DeviceStore()
    @StateObject private var eventLog = EventLogStore()
    @StateObject private var peopleStore = PeopleStore()
    @StateObject private var settings = SettingsStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(deviceStore)
                .environmentObject(eventLog)
                .environmentObject(peopleStore)
                .environmentObject(settings)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1200, height: 760)
    }
}
