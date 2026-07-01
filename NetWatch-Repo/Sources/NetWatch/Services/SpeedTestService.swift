import Foundation

struct SpeedTestResult {
    var downloadMbps: Double
    var uploadMbps: Double
    var pingMs: Double
}

// Uses Cloudflare's public speed-test endpoints (speed.cloudflare.com) — the same
// technique used by several open-source speed test tools. No account/key needed,
// but it's an unofficial dependency: if Cloudflare changes the path this will need updating.
enum SpeedTestService {
    static func run(completion: @escaping (SpeedTestResult?) -> Void) {
        measurePing { ping in
            measureDownload { down in
                measureUpload { up in
                    guard let down, let up, let ping else { completion(nil); return }
                    completion(SpeedTestResult(downloadMbps: down, uploadMbps: up, pingMs: ping))
                }
            }
        }
    }

    private static func measurePing(completion: @escaping (Double?) -> Void) {
        guard let url = URL(string: "https://speed.cloudflare.com/__down?bytes=0") else { completion(nil); return }
        let start = Date()
        URLSession.shared.dataTask(with: url) { _, _, error in
            let elapsed = Date().timeIntervalSince(start) * 1000
            DispatchQueue.main.async { completion(error == nil ? elapsed : nil) }
        }.resume()
    }

    private static func measureDownload(bytes: Int = 25_000_000, completion: @escaping (Double?) -> Void) {
        guard let url = URL(string: "https://speed.cloudflare.com/__down?bytes=\(bytes)") else { completion(nil); return }
        let start = Date()
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data, error == nil else { DispatchQueue.main.async { completion(nil) }; return }
            let elapsed = Date().timeIntervalSince(start)
            let mbps = (Double(data.count) * 8.0 / 1_000_000.0) / max(elapsed, 0.001)
            DispatchQueue.main.async { completion(mbps) }
        }.resume()
    }

    private static func measureUpload(bytes: Int = 8_000_000, completion: @escaping (Double?) -> Void) {
        guard let url = URL(string: "https://speed.cloudflare.com/__up") else { completion(nil); return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = Data(count: bytes)
        let start = Date()
        URLSession.shared.dataTask(with: request) { _, _, error in
            let elapsed = Date().timeIntervalSince(start)
            let mbps = error == nil ? (Double(bytes) * 8.0 / 1_000_000.0) / max(elapsed, 0.001) : nil
            DispatchQueue.main.async { completion(mbps) }
        }.resume()
    }
}
