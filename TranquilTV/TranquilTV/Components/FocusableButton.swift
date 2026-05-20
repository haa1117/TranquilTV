import SwiftUI

struct FocusableCircleButton: View {
    let icon: String
    var size: CGFloat = 60
    var isPrimary: Bool = false
    let action: () -> Void

    @Environment(\.isFocused) private var isFocused
    @ObservedObject private var settings = SettingsService.shared
    private var theme: AppTheme { settings.currentTheme }

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.45, weight: isPrimary ? .bold : .regular))
                .foregroundColor(.white)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(isFocused ? theme.accentColor : Color.white.opacity(0.2))
                )
                .overlay(
                    Circle()
                        .stroke(isFocused ? theme.accentColor : Color.white.opacity(0.3),
                                lineWidth: isFocused ? 2.5 : 1)
                )
                .shadow(color: isFocused ? theme.accentColor.opacity(0.6) : .clear, radius: 12)
                .scaleEffect(isFocused ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.15), value: isFocused)
        }
        .buttonStyle(.plain)
    }
}

struct TVFocusModifier: ViewModifier {
    @ObservedObject private var settings = SettingsService.shared
    @Environment(\.isFocused) private var isFocused

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isFocused ? settings.currentTheme.accentColor : .clear,
                            lineWidth: TranquilTheme.focusBorderWidth)
            )
            .scaleEffect(isFocused ? 1.04 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isFocused)
    }
}

extension View {
    func tvFocusStyle() -> some View {
        modifier(TVFocusModifier())
    }
}
