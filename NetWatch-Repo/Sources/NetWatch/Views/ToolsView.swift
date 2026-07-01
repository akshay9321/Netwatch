import SwiftUI

struct ToolsView: View {
    enum Tool: String, CaseIterable, Identifiable {
        case ping = "Ping"
        case traceroute = "Traceroute"
        case dns = "DNS Lookup"
        case mac = "MAC Lookup"
        case wol = "Wake-on-LAN"
        case ports = "Find Open Ports"
        var id: String { rawValue }
    }

    @State private var selected: Tool = .ping
    @State private var target = "1.1.1.1"
    @State private var output = ""
    @State private var isRunning = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Tools").font(.system(size: 15, weight: .bold))
                Spacer()
            }
            .padding(.horizontal, 20).frame(height: 52)
            Divider()

            HStack(spacing: 0) {
                List(Tool.allCases, selection: Binding(get: { selected }, set: { if let v = $0 { selected = v } })) { tool in
                    Text(tool.rawValue).tag(tool)
                }
                .listStyle(.sidebar)
                .frame(width: 180)

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        TextField(selected == .mac ? "MAC address (e.g. A4:83:E7:...)" : "Target host or IP", text: $target)
                            .textFieldStyle(.roundedBorder)
                        Button(isRunning ? "Running…" : "Run") { run() }
                            .disabled(isRunning)
                    }
                    ScrollView {
                        Text(output.isEmpty ? "Output will appear here…" : output)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(Theme.online)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(10)
                    .background(Color.black.opacity(0.35))
                    .cornerRadius(8)
                }
                .padding(16)
            }
        }
        .background(Theme.bgBase)
    }

    func run() {
        output = ""
        isRunning = true
        switch selected {
        case .ping:
            PingService.ping(host: target, onLine: { output += $0 }, completion: { _ in isRunning = false })
        case .traceroute:
            TracerouteService.run(host: target, onLine: { output += $0 }, completion: { isRunning = false })
        case .dns:
            DNSService.lookup(target) { output = $0; isRunning = false }
        case .mac:
            output = OUILookup.vendor(forMAC: target) ?? "No vendor found for that MAC prefix"
            isRunning = false
        case .wol:
            WakeOnLANService.wake(mac: target)
            output = "Magic packet sent to \(target)"
            isRunning = false
        case .ports:
            Task {
                let open = await NetworkScanner.quickPortScan(host: target, ports: Array(1...1024))
                output = open.isEmpty ? "No open ports found in 1–1024" : "Open ports: \(open.map(String.init).joined(separator: ", "))"
                isRunning = false
            }
        }
    }
}
