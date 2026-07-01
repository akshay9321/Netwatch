import SwiftUI

struct WidgetCard<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Theme.textSecondary)
            content
        }
        .padding(16)
        .background(Theme.bgElevated)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 1))
        .cornerRadius(12)
    }
}

struct StatusDot: View {
    var online: Bool
    var body: some View {
        Circle().fill(online ? Theme.online : Theme.textTertiary).frame(width: 7, height: 7)
    }
}

struct Pill: View {
    var text: String
    var online: Bool
    var body: some View {
        Text(text)
            .font(.system(size: 9.5, weight: .bold, design: .monospaced))
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(online ? Theme.online.opacity(0.15) : Color.white.opacity(0.05))
            .foregroundColor(online ? Theme.online : Theme.textTertiary)
            .cornerRadius(20)
    }
}

struct GaugeView: View {
    var value: Double
    var color: Color
    var label: String
    var body: some View {
        ZStack {
            Circle().stroke(Theme.border, lineWidth: 7)
            Circle()
                .trim(from: 0, to: max(0, min(1, value)))
                .stroke(color, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text(label)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(Theme.textPrimary)
        }
    }
}

struct SectionLabel: View {
    var text: String
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 9.5, weight: .bold))
            .foregroundColor(Theme.textTertiary)
            .padding(.bottom, 4)
    }
}

struct DeviceIconBadge: View {
    var iconName: String
    var size: CGFloat = 26
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28).fill(Theme.accentTeal.opacity(0.14))
            Image(systemName: iconName)
                .font(.system(size: size * 0.5))
                .foregroundColor(Theme.accentTeal)
        }
        .frame(width: size, height: size)
    }
}

struct NetworkRadarView: View {
    @State private var angle: Double = 0
    var body: some View {
        ZStack {
            ForEach([16, 30, 43], id: \.self) { r in
                Circle().stroke(Theme.border, lineWidth: 1)
                    .frame(width: CGFloat(r) * 2, height: CGFloat(r) * 2)
            }
            Circle()
                .trim(from: 0, to: 0.22)
                .stroke(
                    AngularGradient(gradient: Gradient(colors: [Theme.accentTeal.opacity(0.55), Theme.accentTeal.opacity(0)]), center: .center),
                    style: StrokeStyle(lineWidth: 86, lineCap: .butt)
                )
                .frame(width: 86, height: 86)
                .rotationEffect(.degrees(angle))
                .clipShape(Circle().size(width: 86, height: 86))
            Circle().fill(Theme.accentTeal).frame(width: 5, height: 5)
        }
        .frame(width: 92, height: 92)
        .onAppear {
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                angle = 360
            }
        }
    }
}
