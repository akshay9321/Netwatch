import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: SettingsStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Toggle("Launch at login", isOn: $settings.launchAtLogin)
                Toggle("Enable notifications", isOn: $settings.notificationsEnabled)
                Toggle("Dark appearance", isOn: $settings.isDarkMode)
                Stepper("Auto-scan every \(settings.autoScanIntervalMinutes) min", value: $settings.autoScanIntervalMinutes, in: 5...240, step: 5)

                Text("Launch at login requires macOS 13 or later. On macOS 12, add the app manually via System Settings → General → Login Items.")
                    .font(.system(size: 10.5)).foregroundColor(Theme.textTertiary)
            }
            .padding(20)
        }
        .background(Theme.bgBase)
    }
}
