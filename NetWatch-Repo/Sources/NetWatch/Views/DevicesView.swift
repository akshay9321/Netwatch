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
        HSplitView {
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

                List(filtered) { device in
                    HStack {
                        StatusDot(online: device.isOnline)
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
        .background(Theme.bgBase)
        .onAppear { if selected == nil { selected = deviceStore.devices.first } }
        .onChange(of: deviceStore.devices) { _ in
            if let s = selected, let updated = deviceStore.devices.first(where: { $0.id == s.id }) {
                selected = updated
            }
        }
    }
}
