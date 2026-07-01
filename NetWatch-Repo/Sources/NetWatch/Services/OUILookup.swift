import Foundation

// Curated subset of common vendor OUI prefixes (first 3 bytes of MAC).
// NOT the full IEEE registry — expand `table` with more entries as needed.
// Full registry: https://standards-oui.ieee.org/oui/oui.txt
enum OUILookup {
    static func vendor(forMAC mac: String) -> String? {
        let clean = mac.uppercased()
            .replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: "-", with: "")
        guard clean.count >= 6 else { return nil }
        let prefix = String(clean.prefix(6))
        return table[prefix]
    }

    static let table: [String: String] = [
        "3C0754": "Apple", "A48388": "Apple", "3C0637": "Apple", "F0B479": "Apple",
        "D8BB2C": "Apple", "9C207B": "Apple", "F4F1E7": "Apple", "AC87A3": "Apple",
        "001A11": "Google", "3C5AB4": "Google", "F4F5D8": "Google", "94EB2C": "Google",
        "B827EB": "Raspberry Pi Foundation", "DCA632": "Raspberry Pi Foundation", "E45F01": "Raspberry Pi Foundation",
        "A483E7": "Ubiquiti", "24A43C": "Ubiquiti", "784558": "Ubiquiti", "F09FC2": "Ubiquiti",
        "0011D9": "Synology", "001132": "Synology", "0011E1": "Synology",
        "98460A": "Sony", "AC9B0A": "Sony", "FCF152": "Sony",
        "B0CE18": "Ecobee",
        "2CAA8E": "Wyze",
        "18B430": "Nest Labs", "64168D": "Nest Labs",
        "ECFABC": "TP-Link", "50C7BF": "TP-Link", "A42BB0": "TP-Link",
        "A0F3C1": "Netgear", "9CB6D0": "Netgear", "204E71": "Netgear",
        "1CAFF7": "D-Link", "B8A386": "D-Link",
        "3C15FB": "Amazon", "68540F": "Amazon", "F0272D": "Amazon", "A002DC": "Amazon",
        "38F73D": "Samsung", "8425DB": "Samsung", "5C0A5B": "Samsung", "E8508B": "Samsung",
        "18746A": "Xiaomi", "34CE00": "Xiaomi", "F0B429": "Xiaomi",
        "70B3D5": "Espressif (IoT)", "246F28": "Espressif (IoT)", "8CAAB5": "Espressif (IoT)",
        "001C42": "Belkin/Wemo",
        "ECB5FA": "Philips Hue", "001788": "Philips Hue",
        "9C93E4": "Roku", "DC3A5E": "Roku",
        "744401": "LG Electronics", "10683F": "LG Electronics",
        "000C29": "VMware", "080027": "VirtualBox", "005056": "VMware",
        "3465A9": "Intel", "F8FF88": "Intel",
        "D45D64": "Microsoft", "7C1E52": "Microsoft",
        "8462A6": "Cisco", "0026CB": "Cisco",
    ]
}
