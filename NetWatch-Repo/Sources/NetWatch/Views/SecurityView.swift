import SwiftUI

struct SecurityView: View {
    @EnvironmentObject var deviceStore: DeviceStore
    @State private var checks: [SecurityCheck] = []
    @State private var cameras: [Device] = []

    var score: Int { SecurityCheckService.score(devices: deviceStore.devices, routerChecks: checks) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 20) {
                    GaugeView(value: Double(score) / 100, color: Theme.online, label: "\(score)")
                        .frame(width: 110, height: 110)
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(checks, id: \.title) { check in
                            HStack {
                                Image(systemName: check.passed ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                    .foregroundColor(check.passed ? Theme.online : Theme.warn)
                                VStack(alignment: .leading) {
                                    Text(check.title).font(.system(size: 12.5, weight: .semibold))
                                    Text(check.detail).font(.system(size: 10.5)).foregroundColor(Theme.textTertiary)
                                }
                            }
                        }
                        Button("Run Router Vulnerability Check") { runChecks() }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    SectionLabel(text: "Find Hidden Camera")
                    if cameras.isEmpty {
                        Text("No camera-like devices detected on port 554/8554").font(.system(size: 11.5)).foregroundColor(Theme.textSecondary)
                    } else {
                        ForEach(cameras) { d in
                            Text("⚠ \(d.displayName) — \(d.ip)").font(.system(size: 11.5)).foregroundColor(Theme.warn)
                        }
                    }
                    Button("Scan for Cameras") { cameras = SecurityCheckService.findHiddenCameras(devices: deviceStore.devices) }
                }

                VStack(alignment: .leading, spacing: 8) {
                    SectionLabel(text: "Unapproved Devices")
                    ForEach(deviceStore.devices.filter { !$0.isApproved }) { d in
                        HStack {
                            Text(d.displayName).font(.system(size: 11.5))
                            Spacer()
                            Button("Approve") { deviceStore.approve(d) }
                        }
                    }
                    if deviceStore.devices.allSatisfy({ $0.isApproved }) {
                        Text("All devices approved").font(.system(size: 11.5)).foregroundColor(Theme.textTertiary)
                    }
                }
            }
            .padding(20)
        }
        .background(Theme.bgBase)
        .onAppear { runChecks() }
    }

    func runChecks() {
        guard let router = deviceStore.router else { checks = []; return }
        checks = SecurityCheckService.evaluateRouter(router)
    }
}
