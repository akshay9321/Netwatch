import Foundation

enum TracerouteService {
    static func run(host: String, onLine: @escaping (String) -> Void, completion: @escaping () -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/sbin/traceroute")
            task.arguments = ["-w", "1", "-m", "15", host]
            let pipe = Pipe()
            task.standardOutput = pipe

            pipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                guard !data.isEmpty, let str = String(data: data, encoding: .utf8) else { return }
                DispatchQueue.main.async { onLine(str) }
            }
            do {
                try task.run()
                task.waitUntilExit()
            } catch {
                DispatchQueue.main.async { onLine("traceroute: unable to start (\(error.localizedDescription))\n") }
            }
            pipe.fileHandleForReading.readabilityHandler = nil
            DispatchQueue.main.async { completion() }
        }
    }
}
