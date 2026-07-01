import Foundation
import Network

enum WakeOnLANService {
    static func wake(mac: String) {
        let cleaned = mac.uppercased().replacingOccurrences(of: ":", with: "").replacingOccurrences(of: "-", with: "")
        guard cleaned.count == 12, let macBytes = cleaned.hexBytes() else { return }

        var packet = Data(repeating: 0xFF, count: 6)
        for _ in 0..<16 { packet.append(contentsOf: macBytes) }

        let connection = NWConnection(host: "255.255.255.255", port: 9, using: .udp)
        connection.stateUpdateHandler = { state in
            if state == .ready {
                connection.send(content: packet, completion: .contentProcessed({ _ in connection.cancel() }))
            }
        }
        connection.start(queue: .global())
    }
}

private extension String {
    func hexBytes() -> [UInt8]? {
        var bytes = [UInt8]()
        var idx = startIndex
        while idx < endIndex {
            let next = index(idx, offsetBy: 2)
            guard let byte = UInt8(self[idx..<next], radix: 16) else { return nil }
            bytes.append(byte)
            idx = next
        }
        return bytes
    }
}
