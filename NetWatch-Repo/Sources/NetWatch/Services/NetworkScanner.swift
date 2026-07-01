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

        progress?("Identifying \(entries.count) devices…")

        // Enrich every device concurrently (hostname + port scan), each with its own
        // hard timeout, so one unresponsive device can never stall the whole scan.
        var devices: [Device] = []
        await withTaskGroup(of: Device.self) { group in
            for entry in entries {
                group.addTask {
                    await buildDevice(ip: entry.ip, mac: entry.mac)
                }
            }
            for await device in group {
                devices.append(device)
            }
        }
        return devices
    }

    private static func buildDevice(ip: String, mac: String) async -> Device {
        let vendor = OUILookup.vendor(forMAC: mac)
        let hostname = reverseDNS(ip: ip)
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
        if v.contains("apple") &&
