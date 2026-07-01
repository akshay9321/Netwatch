import Foundation
import Network

// Local hostnames on home networks come from mDNS/Bonjour, not unicast DNS —
// your Mac's DNS server (ISP/1.1.1.1/etc.) has no idea what your devices are
// called; only the devices themselves know, and they broadcast it over mDNS.
// This browses common Bonjour service types via NWBrowser (Apple's modern,
// queue-based Bonjour API) and resolves each responder's name + IP.
final class BonjourDiscoveryService {

    static let serviceTypes = [
        "_device-info._tcp",
        "_airplay._tcp",
        "_raop._tcp",
        "_companion-link._tcp",
        "_http._tcp",
        "_https._tcp",
        "_ssh._tcp",
        "_smb._tcp",
        "_afpovertcp._tcp",
        "_ipp._tcp",
        "_ipps._tcp",
        "_googlecast._tcp",
        "_spotify-connect._tcp",
        "_printer._tcp",
        "_workstation._tcp"
    ]

    private var browsers: [NWBrowser] = []
    private var results: [String: String] = [:]
    private let lock = NSLock()
    private let queue = DispatchQueue(label: "com.akshay.netwatch.bonjour")

    func discover(duration: TimeInterval = 4.0) async -> [String: String] {
        await withCheckedContinuation { continuation in
            queue.async {
                self.startBrowsing()
                self.queue.asyncAfter(deadline: .now() + duration) {
                    self.stopBrowsing()
                    self.queue.asyncAfter(deadline: .now() + 1.0) {
                        self.lock.lock()
                        let snapshot = self.results
                        self.lock.unlock()
                        NSLog("NetWatch[Bonjour]: discovery finished, \(snapshot.count) name(s) resolved: \(snapshot)")
                        continuation.resume(returning: snapshot)
                    }
                }
            }
        }
    }

    private func startBrowsing() {
        NSLog("NetWatch[Bonjour]: starting browse across \(Self.serviceTypes.count) service types")
        for type in Self.serviceTypes {
            let descriptor = NWBrowser.Descriptor.bonjour(type: type, domain: nil)
            let params = NWParameters()
            params.includePeerToPeer = false

            let browser = NWBrowser(for: descriptor, using: params)

            browser.stateUpdateHandler = { state in
                switch state {
                case .failed(let error):
                    NSLog("NetWatch[Bonjour]: browser for \(type) FAILED: \(error)")
                case .ready:
                    NSLog("NetWatch[Bonjour]: browser for \(type) ready")
                case .waiting(let error):
                    NSLog("NetWatch[Bonjour]: browser for \(type) waiting: \(error)")
                default:
                    break
                }
            }

            browser.browseResultsChangedHandler = { [weak self] browseResults, _ in
                NSLog("NetWatch[Bonjour]: \(type) reported \(browseResults.count) result(s)")
                for result in browseResults {
                    self?.resolve(result: result, type: type)
                }
            }

            browser.start(queue: queue)
            browsers.append(browser)
        }
    }

    private func stopBrowsing() {
        browsers.forEach { $0.cancel() }
        browsers.removeAll()
    }

    private func resolve(result: NWBrowser.Result, type: String) {
        guard case let .service(name, _, _, _) = result.endpoint else { return }

        let connection = NWConnection(to: result.endpoint, using: .tcp)
        connection.stateUpdateHandler = { [weak self] state in
            if case .ready = state {
                if let remote = connection.currentPath?.remoteEndpoint,
                   case let .hostPort(host, _) = remote,
                   let ip = Self.stringFromHost(host) {
                    NSLog("NetWatch[Bonjour]: resolved \(name) (\(type)) -> \(ip)")
                    self?.addResult(ip: ip, name: name)
                } else {
                    NSLog("NetWatch[Bonjour]: connected to \(name) but couldn't extract IP")
                }
                connection.cancel()
            } else if case .failed(let error) = state {
                NSLog("NetWatch[Bonjour]: resolve connection to \(name) failed: \(error)")
                connection.cancel()
            }
        }
        connection.start(queue: queue)

        // Safety timeout so a hung connection attempt can't leak forever.
        queue.asyncAfter(deadline: .now() + 2.0) {
            connection.cancel()
        }
    }

    private static func stringFromHost(_ host: NWEndpoint.Host) -> String? {
        switch host {
        case .ipv4(let addr): return "\(addr)"
        case .ipv6(let addr): return "\(addr)"
        case .name(let n, _): return n
        @unknown default: return nil
        }
    }

    private func addResult(ip: String, name: String) {
        lock.lock()
        if results[ip] == nil { results[ip] = name }
        lock.unlock()
    }
}
