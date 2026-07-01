import Foundation
import ServiceManagement

@MainActor
final class SettingsStore: ObservableObject {
    @Published var launchAtLogin: Bool { didSet { setLaunchAtLogin(launchAtLogin) } }
    @Published var notificationsEnabled: Bool { didSet { UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled") } }
    @Published var autoScanIntervalMinutes: Int { didSet { UserDefaults.standard.set(autoScanIntervalMinutes, forKey: "autoScanIntervalMinutes") } }
    @Published var isDarkMode: Bool { didSet { UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode") } }

    init() {
        launchAtLogin = UserDefaults.standard.bool(forKey: "launchAtLogin")
        notificationsEnabled = UserDefaults.standard.object(forKey: "notificationsEnabled") as? Bool ?? true
        autoScanIntervalMinutes = UserDefaults.standard.object(forKey: "autoScanIntervalMinutes") as? Int ?? 60
        isDarkMode = UserDefaults.standard.object(forKey: "isDarkMode") as? Bool ?? true
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "launchAtLogin")
        if #available(macOS 13.0, *) {
            do {
                if enabled { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
            } catch {
                print("Launch at login error: \(error)")
            }
        }
    }
}
