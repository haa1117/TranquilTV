import SwiftUI

// MARK: - Button style (no system white parallax plate)

struct TranquilTVButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

extension View {
    /// Plain tvOS button: participates in focus engine, no system white bubble.
    func tranquilTVButton() -> some View {
        buttonStyle(TranquilTVButtonStyle())
            .focusEffectDisabled()
    }
}

// MARK: - Home card focus (matches Android _SceneCard: 1.05 scale + accent border + glow)

struct CardFocusChrome: ViewModifier {
    let isFocused: Bool
    let cornerRadius: CGFloat
    let accentColor: Color

    func body(content: Content) -> some View {
        content
            .scaleEffect(isFocused ? TranquilTheme.cardScaleFocused : 1.0, anchor: .center)
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        isFocused ? accentColor.opacity(0.9) : Color.clear,
                        lineWidth: isFocused ? TranquilTheme.focusBorderWidth : 0
                    )
            }
            .shadow(
                color: isFocused ? accentColor.opacity(0.35) : Color.black.opacity(0.4),
                radius: isFocused ? 12 : 10,
                y: isFocused ? 8 : 8
            )
            .animation(.easeInOut(duration: 0.2), value: isFocused)
            .zIndex(isFocused ? 1 : 0)
    }
}

extension View {
    func cardFocusChrome(isFocused: Bool, cornerRadius: CGFloat, accentColor: Color) -> some View {
        modifier(CardFocusChrome(isFocused: isFocused, cornerRadius: cornerRadius, accentColor: accentColor))
    }
}

struct DefaultFocusModifier: ViewModifier {
    let isPreferred: Bool
    let namespace: Namespace.ID?

    func body(content: Content) -> some View {
        if isPreferred, let namespace {
            content.prefersDefaultFocus(true, in: namespace)
        } else {
            content
        }
    }
}

// MARK: - Settings / secondary screens

struct TranquilFocusButton<Label: View>: View {
    let action: () -> Void
    var prefersDefaultFocus: Bool = false
    var focusNamespace: Namespace.ID? = nil
    @ViewBuilder var label: (_ isFocused: Bool) -> Label

    var body: some View {
        Button(action: action) {
            FocusButtonLabel(label: label)
        }
        .tranquilTVButton()
        .modifier(DefaultFocusModifier(isPreferred: prefersDefaultFocus, namespace: focusNamespace))
    }
}

private struct FocusButtonLabel<Label: View>: View {
    @ViewBuilder var label: (_ isFocused: Bool) -> Label
    @Environment(\.isFocused) private var isFocused

    var body: some View {
        label(isFocused)
    }
}

extension TranquilFocusButton {
    init(
        action: @escaping () -> Void,
        prefersDefaultFocus: Bool = false,
        focusNamespace: Namespace.ID? = nil,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.action = action
        self.prefersDefaultFocus = prefersDefaultFocus
        self.focusNamespace = focusNamespace
        self.label = { _ in label() }
    }
}

struct FocusableCircleButton: View {
    let icon: String
    var size: CGFloat = 60
    var isPrimary: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            CircleButtonLabel(icon: icon, size: size, isPrimary: isPrimary)
        }
        .tranquilTVButton()
    }
}

private struct CircleButtonLabel: View {
    let icon: String
    var size: CGFloat
    var isPrimary: Bool

    @Environment(\.isFocused) private var isFocused
    @ObservedObject private var settings = SettingsService.shared
    private var theme: AppTheme { settings.currentTheme }

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: size * 0.45, weight: isPrimary ? .bold : .regular))
            .foregroundColor(.white)
            .frame(width: size, height: size)
            .background(Circle().fill(isFocused ? theme.accentColor : Color.white.opacity(0.2)))
            .overlay(
                Circle()
                    .stroke(isFocused ? theme.accentColor : Color.white.opacity(0.3),
                            lineWidth: isFocused ? 2.5 : 1)
            )
            .shadow(color: isFocused ? theme.accentColor.opacity(0.5) : .clear, radius: 12)
            .scaleEffect(isFocused ? 1.08 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

struct TVFocusModifier: ViewModifier {
    let isFocused: Bool
    @ObservedObject private var settings = SettingsService.shared

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isFocused ? settings.currentTheme.accentColor.opacity(0.9) : .clear,
                            lineWidth: TranquilTheme.focusBorderWidth)
            )
            .scaleEffect(isFocused ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

extension View {
    func tvFocusStyle(isFocused: Bool) -> some View {
        modifier(TVFocusModifier(isFocused: isFocused))
    }

    /// Uses `@Environment(\.isFocused)` — for plain `Button` focus chrome.
    func tvFocusStyle() -> some View {
        modifier(AutoTVFocusModifier())
    }
}

private struct AutoTVFocusModifier: ViewModifier {
    @Environment(\.isFocused) private var isFocused

    func body(content: Content) -> some View {
        content.tvFocusStyle(isFocused: isFocused)
    }
}
