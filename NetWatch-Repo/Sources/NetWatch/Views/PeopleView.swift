import SwiftUI

struct PeopleView: View {
    @EnvironmentObject var peopleStore: PeopleStore
    @EnvironmentObject var deviceStore: DeviceStore
    @State private var newName = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    TextField("Add a person…", text: $newName)
                        .textFieldStyle(.roundedBorder).frame(width: 220)
                    Button("Add") {
                        guard !newName.isEmpty else { return }
                        peopleStore.add(name: newName)
                        newName = ""
                    }
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(peopleStore.people) { person in
                        WidgetCard(title: person.name) {
                            let home = peopleStore.isHome(person, devices: deviceStore.devices)
                            Text(home ? "● Home" : "○ Away")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(home ? Theme.online : Theme.textTertiary)
                            ForEach(person.deviceMACs, id: \.self) { mac in
                                if let d = deviceStore.devices.first(where: { $0.id == mac }) {
                                    Text(d.displayName).font(.system(size: 11)).foregroundColor(Theme.textSecondary)
                                }
                            }
                            Menu("Assign device") {
                                ForEach(deviceStore.devices) { d in
                                    Button(d.displayName) { peopleStore.assign(deviceMAC: d.id, to: person.id) }
                                }
                            }
                            .font(.system(size: 10.5))
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(Theme.bgBase)
    }
}
