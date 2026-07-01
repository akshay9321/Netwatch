import Foundation

enum DNSService {
    static func lookup(_ query: String, completion: @escaping (String) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/host")
            task.arguments = [query]
            let pipe = Pipe()
            task.standardOutput = pipe
            task.standardError = pipe
            do {
                try task.run()
                task.waitUntilExit()
            } catch {
                DispatchQueue.main.async { completion("host: unable to start (\(error.localizedDescription))") }
                return
            }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            DispatchQueue.main.async { completion(output) }
        }
    }
}
