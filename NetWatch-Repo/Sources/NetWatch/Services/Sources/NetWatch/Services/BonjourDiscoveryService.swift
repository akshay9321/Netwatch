import Foundation

// Local hostnames on home networks come from mDNS/Bonjour, not unicast DNS —
// your Mac's DNS server (ISP/1.1.1.1/etc.) has no idea what your devices are
// called; only the devices themselves know, and they broadcast it over mDNS.
// This browses common Bonjour service types and resolves each responder's
// name + IP, building an ip -> friendly-name map to enrich the ARP scan with.
final class BonjourDiscoveryService: NSObject {

    static let serviceTypes = [
        "_device-info._tcp.",
        "_airplay._tcp.",
        "_raop._tcp.",
        "_companion-link._tcp.",
        "_http._tcp.",
        "_https._tcp.",
        "_ssh._tcp.",
        "_smb._tcp.",
        "_afpovertcp._tcp.",
        "_ipp._tcp.",
        "_ipps._tcp.",
        "_googlecast._tcp.",
        "_spotify-connect._tcp.",
        "_printer._tcp.",
        "_workstation._tcp.",
        "_sleep-proxy._udp."
    ]

    private var browsers: [NetServiceBrowser] = []
    private var resolvingServices: [NetService] = []
    private var results: [String: String] = [:]
    private let lock = NSLock()

    func discover(duration: TimeInterval = 4.0) async -> [String: String] {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                self.startBrowsing()
                DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                    self.stopBrowsing()
                    // brief grace period for any resolves still in flight
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        self.lock.lock()
                        let snapshot = self.results
                        self.lock.unlock()
                        continuation.resume(returning: snapshot)
                    }
                }
            }
        }
    }

    private func startBrowsing() {
        for type in Self.serviceTypes {
            let browser = NetServiceBrowser()
            browser.delegate = self
            browser.schedule(in: .main, forMode: .common)
            browser.searchForServices(ofType: type, inDomain: "local.")
            browsers.append(browser)
        }
    }

    private func stopBrowsing() {
        browsers.forEach { $0.stop() }
        browsers.removeAll()
    }

    private func addResult(ip: String, name: String) {
        lock.lock()
        if results[ip] == nil {
            results[ip] = name
        }
        lock.unlock()
    }
}

extension BonjourDiscoveryService: NetServiceBrowserDelegate {
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        service.delegate = self
        service.schedule(in: .main, forMode: .common)
        resolvingServices.append(service)
        service.resolve(withTimeout: 3.0)
    }
}

extension BonjourDiscoveryService: NetServiceDelegate {
    func netServiceDidResolveAddress(_ sender: NetService) {
        guard let addresses = sender.addresses else { return }
        let name = sender.name
        for data in addresses {
            if let ip = Self.ipv4String(from: data) {
                addResult(ip: ip, name: name)
            }
        }
    }

    private static func ipv4String(from data: Data) -> String? {
        data.withUnsafeBytes { (rawPtr: UnsafeRawBufferPointer) -> String? in
            guard let base = rawPtr.baseAddress else { return nil }
            let family = base.assumingMemoryBound(to: sockaddr.self).pointee.sa_family
            guard family == sa_family_t(AF_INET) else { return nil }
            var sinAddr = base.assumingMemoryBound(to: sockaddr_in.self).pointee.sin_addr
            var buffer = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
            inet_ntop(AF_INET, &sinAddr, &buffer, socklen_t(INET_ADDRSTRLEN))
            return String(cString: buffer)
        }
    }
}
