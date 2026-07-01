import SwiftUI

struct TimelineView: View {
    @EnvironmentObject var eventLog: EventLogStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(eventLog.events) { event in
                    HStack(alignment: .top, spacing: 12) {
                        Circle().fill(color(for: event.kind)).frame(width: 8, height: 8).padding(.top, 5)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(event.title).font(.system(size: 12.3, weight: .semibold))
                            Text(event.timestamp.formatted(date: .abbreviated, time: .shortened))
                                .font(.system(size: 10.5, design: .monospaced)).foregroundColor(Theme.textTertiary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 10)
                    .overlay(Rectangle().frame(height: 1).foregroundColor(Theme.borderSoft), alignment: .bottom)
                }
                if eventLog.events.isEmpty {
                    Text("No events yet — run a scan to start building history.")
                        .foregroundColor(Theme.textTertiary)
                        .padding(20)
                }
            }
            .padding(20)
        }
        .background(Theme.bgBase)
    }

    func color(for kind: EventKind) -> Color {
        switch kind {
        case .joined: return Theme.online
        case .left: return Theme.textTertiary
        case .warning: return Theme.warn
        case .test: return Theme.accentBlue
        case .security: return Theme.offline
        }
    }
}
