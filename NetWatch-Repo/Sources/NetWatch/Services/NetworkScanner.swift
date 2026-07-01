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
            if let output = shell("/sbin/ifconfig", [ifname]), let ip = output.firstIPv4() {
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

        let hosts = Array(1...254)
        for batch in stride(from: 0, to: hosts.count, by: 32) {
            let chunk = hosts[batch..<min(batch + 32, hosts.count)]
            await withTaskGroup(of: Void.self) { group in
                for host in chunk {
                    group.addTask {
                        _ = shell("/sbin/ping", ["-c", "1", "-W", "150", "\(iface.subnetPrefix).\(host)"])
                    }
                }
            }
        }

        progress?("Reading ARP table…")
        guard let arpOutput = shell("/usr/sbin/arp", ["-a"]) else { return [] }

        var devices: [Device] = []
        for line in arpOutput.split(separator: "\n") {
            let lineStr = String(line)
            guard let ip = extractIP(from: lineStr), let mac = extractMAC(from: lineStr) else { continue }
            guard mac != "ff:ff:ff:ff:ff:ff", mac.count >= 11 else { continue }

            progress?("Identifying \(ip)…")
            let vendor = OUILookup.vendor(forMAC: mac)
            let hostname = reverseDNS(ip: ip)
            let openPorts = await quickPortScan(host: ip)
            let isRouter = ip.hasSuffix(".1") || ip.hasSuffix(".254")
            let type = classify(vendor: vendor, hostname: hostname, isRouter: isRouter, openPorts: openPorts)

            devices.append(Device(
                id: mac.uppercased(), ip: ip, mac: mac.uppercased(), hostname: hostname, vendor: vendor,
                deviceType: type, isOnline: true, isRouter: isRouter,
                firstSeen: Date(), lastSeen: Date(), openPorts: openPorts
            ))
        }
        return devices
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
        guard let output = shell("/usr/bin/host", [ip]) else { return nil }
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

    @discardableResult
    static func shell(_ path: String, _ args: [String]) -> String? {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: path)
        task.arguments = args
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()
        do { try task.run() } catch { return nil }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        task.waitUntilExit()
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
