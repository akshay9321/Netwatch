import SwiftUI

struct DevicesView: View {
    @EnvironmentObject var deviceStore: DeviceStore
    @State private var selected: Device?
    @State private var search: String = ""

    var filtered: [Device] {
        guard !search.isEmpty else { return deviceStore.devices }
        return deviceStore.devices.filter {
            $0.displayName.localizedCaseInsensitiveContains(search) || $0.ip.contains(search)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Devices").font(.system(size: 15, weight: .bold))
                Text("\(deviceStore.devices.count) devices · \(deviceStore.devices.filter{$0.isOnline}.count) online")
                    .font(.system(size: 11.5, design: .monospaced)).foregroundColor(Theme.textSecondary)
                Spacer()
                TextField("Search devices…", text: $search)
                    .textFieldStyle(.plain)
                    .padding(6).frame(width: 180)
                    .background(Theme.bgElevated).cornerRadius(7)
            }
            .padding(.horizontal, 20).frame(height: 52)
            .background(Theme.bgBase)
            Divider()

            HStack(spacing: 26) {
                NetworkRadarView()
                HStack(spacing: 30) {
                    statBlock("\(deviceStore.devices.filter{$0.isOnline}.count)", "Online", Theme.online)
                    statBlock("\(deviceStore.devices.filter{!$0.isOnline}.count)", "Offline", Theme.textTertiary)
                    statBlock("\(deviceStore.devices.filter{!$0.isApproved}.count)", "Unapproved", Theme.accentAmber)
                }
                Spacer()
            }
            .padding(.horizontal, 20).padding(.vertical, 14)
            .background(Theme.bgElevated.opacity(0.35))
            Divider()

            HSplitView {
                VStack(spacing: 0) {
                    List(filtered) { device in
                        HStack {
                            StatusDot(online: device.isOnline)
                            DeviceIconBadge(iconName: device.iconName)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(device.displayName).font(.system(size: 12.5, weight: .semibold))
                                Text("\(device.deviceType) · \(device.vendor ?? "Unknown vendor")")
                                    .font(.system(size: 10)).foregroundColor(Theme.textTertiary)
                            }
                            Spacer()
                            Text(device.ip).font(.system(size: 11, design: .monospaced)).foregroundColor(Theme.textSecondary)
                            Pill(text: device.isOnline ? "ONLINE" : "OFFLINE", online: device.isOnline)
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                        .onTapGesture { selected = device }
                        .listRowBackground(selected?.id == device.id ? Theme.bgElevated : Color.clear)
                    }
                    .listStyle(.plain)
                }
                .frame(minWidth: 500)

                if let d = selected {
                    DeviceDetailView(device: d)
                        .frame(minWidth: 300, idealWidth: 320)
                } else {
                    VStack {
                        Spacer()
                        Text("Select a device").foregroundColor(Theme.textTertiary)
                        Spacer()
                    }
                    .frame(minWidth: 300, idealWidth: 320)
                }
            }
        }
        .background(Theme.bgBase)
        .onAppear { if selected == nil { selected = deviceStore.devices.first } }
        .onChange(of: deviceStore.devices) { _ in
            if let s = selected, let updated = deviceStore.devices.first(where: { $0.id == s.id }) {
                selected = updated
            }
        }
    }

    func statBlock(_ value: String, _ label: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.system(size: 19, weight: .heavy, design: .monospaced)).foregroundColor(color)
            Text(label).font(.system(size: 10.5)).foregroundColor(Theme.textSecondary)
        }
    }
}
