import Foundation

enum PingService {
    static func ping(host: String, count: Int = 4, onLine: @escaping (String) -> Void, completion: @escaping (String) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/sbin/ping")
            task.arguments = ["-c", "\(count)", host]
            let pipe = Pipe()
            task.standardOutput = pipe
            var fullOutput = ""

            pipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                guard !data.isEmpty, let str = String(data: data, encoding: .utf8) else { return }
                fullOutput += str
                DispatchQueue.main.async { onLine(str) }
            }
            do {
                try task.run()
                task.waitUntilExit()
            } catch {
                DispatchQueue.main.async { onLine("ping: unable to start (\(error.localizedDescription))\n") }
            }
            pipe.fileHandleForReading.readabilityHandler = nil
            DispatchQueue.main.async { completion(fullOutput) }
        }
    }
}
