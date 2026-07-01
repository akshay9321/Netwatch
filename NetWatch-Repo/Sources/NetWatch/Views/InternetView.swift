import SwiftUI

struct InternetView: View {
    @State private var result: SpeedTestResult?
    @State private var isRunning = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HStack(spacing: 30) {
                    GaugeView(value: min((result?.downloadMbps ?? 0) / 500, 1), color: Theme.accentTeal,
                              label: result != nil ? "\(Int(result!.downloadMbps))" : "—")
                        .frame(width: 140, height: 140)

                    VStack(alignment: .leading, spacing: 14) {
                        metric("Download", result.map { "\(Int($0.downloadMbps)) Mbps" } ?? "—", Theme.accentTeal)
                        metric("Upload", result.map { "\(Int($0.uploadMbps)) Mbps" } ?? "—", Theme.accentBlue)
                        metric("Ping", result.map { "\(Int($0.pingMs)) ms" } ?? "—", Theme.textPrimary)
                    }
                    Spacer()
                    Button {
                        isRunning = true
                        SpeedTestService.run { r in
                            result = r
                            isRunning = false
                        }
                    } label: {
                        Text(isRunning ? "Testing…" : "▶ Run Speed Test")
                            .font(.system(size: 12.5, weight: .bold))
                            .padding(.horizontal, 20).padding(.vertical, 11)
                            .background(Theme.accentTeal).foregroundColor(.black.opacity(0.85)).cornerRadius(9)
                    }
                    .buttonStyle(.plain)
                    .disabled(isRunning)
                }
                .padding(24)
                .background(Theme.bgElevated)
                .cornerRadius(12)
                .padding(.horizontal, 20)

                Text("ISP city ranking and crowd-sourced outage maps need a shared backend, so this build shows only your own measurements. The reachability check below hits a public DNS resolver directly.")
                    .font(.system(size: 10.5))
                    .foregroundColor(Theme.textTertiary)
                    .padding(.horizontal, 20)

                OutageCheckCard().padding(.horizontal, 20)
                Spacer()
            }
            .padding(.vertical, 20)
        }
        .background(Theme.bgBase)
    }

    func metric(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.system(size: 22, weight: .heavy, design: .monospaced)).foregroundColor(color)
            Text(label).font(.system(size: 10.5)).foregroundColor(Theme.textSecondary)
        }
    }
}

struct OutageCheckCard: View {
    @State private var status: String = "Not checked yet"
    @State private var reachable = true

    var body: some View {
        WidgetCard(title: "Internet Reachability") {
            HStack {
                StatusDot(online: reachable)
                Text(status).font(.system(size: 12))
                Spacer()
                Button("Check") { check() }
            }
        }
        .onAppear { check() }
    }

    func check() {
        status = "Checking…"
        Task {
            let ok = await NetworkScanner.checkPort(host: "1.1.1.1", port: 443, timeout: 2)
            reachable = ok
            status = ok ? "Internet reachable — no outage detected" : "No response from 1.1.1.1 — possible outage"
        }
    }
}
