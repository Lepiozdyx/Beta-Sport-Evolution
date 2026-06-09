import SwiftUI
import UIKit

enum AppTheme {
    static let background = Color(red: 0.025, green: 0.065, blue: 0.14)
    static let panel = Color(red: 0.03, green: 0.12, blue: 0.25).opacity(0.92)
    static let field = Color(red: 0.025, green: 0.075, blue: 0.16)
    static let blue = Color(red: 0.0, green: 0.63, blue: 1.0)
    static let cyan = Color(red: 0.15, green: 0.82, blue: 0.96)
    static let mint = Color(red: 0.13, green: 0.9, blue: 0.68)
    static let secondary = Color.white.opacity(0.62)
    static let border = Color.blue.opacity(0.3)
    static let gradient = LinearGradient(colors: [blue, cyan], startPoint: .leading, endPoint: .trailing)
}

struct AppBackground: View {
    var body: some View {
        ZStack {
            AppTheme.background
            Image(.appSportsBackground)
                .resizable()
//            AssetImage(name: "app_sports_background", mode: .cover)
//                .padding(8)
//                .opacity(0.55)
            LinearGradient(colors: [.clear, AppTheme.background.opacity(0.5)], startPoint: .top, endPoint: .bottom)
        }
        .ignoresSafeArea()
    }
}

enum AssetScaleMode { case cover, contain, fill }

struct AssetImage: View {
    let name: String
    var mode: AssetScaleMode = .contain
    var showsMissingLabel = true

    var body: some View {
        Group {
            if let image = UIImage(named: name) {
                Image(uiImage: image)
                    .resizable()
                    .modifier(AssetScaling(mode: mode))
            } else if showsMissingLabel {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppTheme.field)
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [5]))
                        .foregroundStyle(AppTheme.secondary)
                    Text(name)
                        .font(.caption2)
                        .foregroundStyle(AppTheme.secondary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.65)
                        .multilineTextAlignment(.center)
                        .padding(8)
                }
            } else {
                Color.clear
            }
        }
        .clipped()
    }
}

private struct AssetScaling: ViewModifier {
    let mode: AssetScaleMode
    func body(content: Content) -> some View {
        switch mode {
        case .cover: content.scaledToFill()
        case .contain: content.scaledToFit()
        case .fill: content
        }
    }
}

struct Panel<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        content
            .padding(20)
            .background(AppTheme.panel, in: RoundedRectangle(cornerRadius: 24))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(AppTheme.border))
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 54)
            .background(AppTheme.gradient.opacity(configuration.isPressed ? 0.72 : 1), in: RoundedRectangle(cornerRadius: 18))
            .foregroundStyle(.white)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct SegmentedPill<T: Hashable>: View {
    let values: [T]
    @Binding var selection: T
    let title: (T) -> String

    var body: some View {
        HStack(spacing: 4) {
            ForEach(values, id: \.self) { value in
                Button(title(value)) { selection = value }
                    .font(.subheadline.weight(selection == value ? .semibold : .regular))
                    .foregroundStyle(selection == value ? .white : AppTheme.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(selection == value ? AnyShapeStyle(AppTheme.gradient) : AnyShapeStyle(Color.clear), in: Capsule())
            }
        }
        .padding(4)
        .background(AppTheme.field, in: Capsule())
        .overlay(Capsule().stroke(AppTheme.border))
    }
}

struct EmptyStateView: View {
    let symbol: String
    let title: String
    let message: String
    var body: some View {
        ContentUnavailableView(title, systemImage: symbol, description: Text(message))
            .foregroundStyle(.white)
    }
}

extension View {
    func appScreen() -> some View {
        self
            .foregroundStyle(.white)
            .background(AppBackground())
            .tint(AppTheme.blue)
    }
}
