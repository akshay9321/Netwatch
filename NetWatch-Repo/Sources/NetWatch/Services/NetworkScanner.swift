import Foundation
import Network

// Real local-network discovery: no server, no localhost — runs directly in-process.
// Technique: ping-sweep the /24 to populate the OS ARP cache, then read `arp -a`,
// same approach Fing and most LAN scanners use since raw ARP needs root privileges.
enum NetworkScanner {

    struct Interface {
        let ip: String
        let subnetPrefix: String // e.g. "192.168.1"
    }

    static func localInterface() -> Interface? {
        for ifname in ["en0", "en1", "en2"] {
            if let output = shell("/sbin/ifconfig", [ifname], timeoutSeconds: 2.0), let ip = output.firstIPv4() {
                let parts = ip.split(separator: ".")
                if parts.count == 4 {
                    let prefix = parts.prefix(3).joined(separator: ".")
                    return Interface(ip: ip, subnetPrefix: prefix)
                }
            }
        }
        return nil
    }

    static func scan(progress: (@Sendable (String) -> Void)? = nil) async -> [Device] {
        guard let iface = localInterface() else { return [] }
        progress?("Sweeping \(iface.subnetPrefix).0/24…")

        // Runs concurrently with the ping sweep below — Bonjour browsing takes
        // a few seconds regardless, so overlapping it with the sweep costs nothing.
        async let bonjourTask = BonjourDiscoveryService().discover(duration: 4.0)

        let hosts = Array(1...254)
        for batch in stride(from: 0, to: hosts.count, by: 32) {
            let chunk = hosts[batch..<min(batch + 32, hosts.count)]
            await withTaskGroup(of: Void.self) { group in
                for host in chunk {
                    group.addTask {
                        _ = shell("/sbin/ping", ["-c", "1", "-W", "150", "\(iface.subnetPrefix).\(host)"], timeoutSeconds: 1.0)
                    }
                }
            }
        }

        progress?("Reading ARP table…")
        guard let arpOutput = shell("/usr/sbin/arp", ["-a"], timeoutSeconds: 3.0) else { return [] }

        var entries: [(ip: String, mac: String)] = []
        for line in arpOutput.split(separator: "\n") {
            let lineStr = String(line)
            guard let ip = extractIP(from: lineStr), let mac = extractMAC(from: lineStr) else { continue }
            guard mac != "ff:ff:ff:ff:ff:ff", mac.count >= 11 else { continue }
            entries.append((ip, mac))
        }

        progress?("Resolving device names…")
        let bonjourNames = await bonjourTask

        progress?("Identifying \(entries.count) devices…")

        // Enrich every device concurrently (hostname + port scan), each with its own
        // hard timeout, so one unresponsive device can never stall the whole scan.
        var devices: [Device] = []
        await withTaskGroup(of: Device.self) { group in
            for entry in entries {
                group.addTask {
                    await buildDevice(ip: entry.ip, mac: entry.mac, bonjourNames: bonjourNames)
                }
            }
            for await device in group {
                devices.append(device)
            }
        }
        return devices
    }

    private static func buildDevice(ip: String, mac: String, bonjourNames: [String: String]) async -> Device {
        let vendor = OUILookup.vendor(forMAC: mac)
        // Bonjour name first (actually works on home LANs) — unicast reverse DNS as a fallback.
        let hostname = bonjourNames[ip] ?? reverseDNS(ip: ip)
        let openPorts = await quickPortScan(host: ip)
        let isRouter = ip.hasSuffix(".1") || ip.hasSuffix(".254")
        let type = classify(vendor: vendor, hostname: hostname, isRouter: isRouter, openPorts: openPorts)
        return Device(
            id: mac.uppercased(), ip: ip, mac: mac.uppercased(), hostname: hostname, vendor: vendor,
            deviceType: type, isOnline: true, isRouter: isRouter,
            firstSeen: Date(), lastSeen: Date(), openPorts: openPorts
        )
    }

    private static func classify(vendor: String?, hostname: String?, isRouter: Bool, openPorts: [Int]) -> String {
        if isRouter { return "Router" }
        let v = (vendor ?? "").lowercased()
        let h = (hostname ?? "").lowercased()
        if v.contains("apple") && h.contains("iphone") { return "Mobile" }
        if v.contains("apple") && (h.contains("macbook") || h.contains("imac")) { return "Laptop" }
        if v.contains("synology") { return "Storage" }
        if v.contains("sony") || h.contains("playstation") { return "Gaming" }
        if v.contains("wyze") || v.contains("hue") || v.contains("nest") || v.contains("ecobee") || v.contains("espressif") || v.contains("wemo") { return "IoT" }
        if v.contains("roku") || v.contains("lg electronics") { return "TV" }
        if openPorts.contains(554) { return "Camera" }
        return "Unknown"
    }

    static func quickPortScan(host: String, ports: [Int] = [22, 80, 443, 554, 8080, 9100]) async -> [Int] {
        var open: [Int] = []
        await withTaskGroup(of: (Int, Bool).self) { group in
            for port in ports {
                group.addTask { (port, await checkPort(host: host, port: port)) }
            }
            for await (port, isOpen) in group where isOpen {
                open.append(port)
            }
        }
        return open.sorted()
    }

    static func checkPort(host: String, port: Int, timeout: TimeInterval = 0.6) async -> Bool {
        await withCheckedContinuation { continuation in
            guard let nwPort = NWEndpoint.Port(rawValue: UInt16(port)) else {
                continuation.resume(returning: false); return
            }
            let conn = NWConnection(host: NWEndpoint.Host(host), port: nwPort, using: .tcp)
            var didResume = false
            let resumeOnce: (Bool) -> Void = { result in
                if !didResume {
                    didResume = true
                    conn.cancel()
                    continuation.resume(returning: result)
                }
            }
            conn.stateUpdateHandler = { state in
                switch state {
                case .ready: resumeOnce(true)
                case .failed, .cancelled: resumeOnce(false)
                default: break
                }
            }
            conn.start(queue: .global())
            DispatchQueue.global().asyncAfter(deadline: .now() + timeout) { resumeOnce(false) }
        }
    }

    private static func reverseDNS(ip: String) -> String? {
        guard let output = shell("/usr/bin/host", [ip], timeoutSeconds: 1.5) else { return nil }
        if output.contains("not found") || output.contains("NXDOMAIN") { return nil }
        if let range = output.range(of: "domain name pointer ") {
            var name = String(output[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            if name.hasSuffix(".") { name.removeLast() }
            return name.isEmpty ? nil : name
        }
        return nil
    }

    private static func extractIP(from line: String) -> String? {
        guard let open = line.firstIndex(of: "("), let close = line.firstIndex(of: ")") else { return nil }
        return String(line[line.index(after: open)..<close])
    }

    private static func extractMAC(from line: String) -> String? {
        let comps = line.split(separator: " ")
        guard let atIndex = comps.firstIndex(of: "at"), atIndex + 1 < comps.count else { return nil }
        return String(comps[atIndex + 1])
    }

    /// Runs a command with a hard wall-clock timeout — if the process hasn't
    /// exited by then, it's force-terminated and this returns nil. Prevents
    /// any single unresponsive lookup (e.g. reverse DNS) from stalling a scan.
    @discardableResult
    static func shell(_ path: String, _ args: [String], timeoutSeconds: Double = 3.0) -> String? {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: path)
        task.arguments = args
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()

        do { try task.run() } catch { return nil }

        let semaphore = DispatchSemaphore(value: 0)
        DispatchQueue.global().async {
            task.waitUntilExit()
            semaphore.signal()
        }

        let result = semaphore.wait(timeout: .now() + timeoutSeconds)
        if result == .timedOut {
            task.terminate()
            return nil
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)
    }
}

private extension String {
    func firstIPv4() -> String? {
        guard let range = range(of: "inet ") else { return nil }
        let rest = self[range.upperBound...]
        return String(rest.split(separator: " ").first ?? "")
    }
}
