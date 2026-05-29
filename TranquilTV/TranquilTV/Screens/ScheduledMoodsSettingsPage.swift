import SwiftUI

struct ScheduledMoodsSettingsPage: View {
    @ObservedObject private var settings = SettingsService.shared
    @Environment(\.dismiss) private var dismiss

    private var theme: AppTheme { settings.currentTheme }

    var body: some View {
        ZStack {
            LinearGradient(colors: theme.gradientColors, startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    FocusableCircleButton(icon: "chevron.left", size: 56) { dismiss() }
                    Spacer()
                    Text("Scheduled Moods")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Color.clear.frame(width: 56)
                }
                .padding(.horizontal, TranquilTheme.standardPadding)
                .padding(.vertical, 24)

                ToggleSettingsCard(
                    icon: "calendar.badge.clock",
                    title: "Enable Scheduled Moods",
                    subtitle: "Automatically play scenes based on time of day",
                    isOn: $settings.scheduledMoodsEnabled
                )
                .padding(.horizontal, TranquilTheme.standardPadding)
                .padding(.bottom, 24)

                if settings.scheduledMoodsEnabled {
                    ScrollView {
                        VStack(spacing: 16) {
                            Text("Time Blocks")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.white.opacity(0.7))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, TranquilTheme.standardPadding)

                            ForEach($settings.scheduledMoodBlocks) { $block in
                                MoodBlockCard(block: $block)
                                    .padding(.horizontal, TranquilTheme.standardPadding)
                            }
                        }
                        .padding(.bottom, 60)
                    }
                } else {
                    Spacer()
                    Text("Enable Scheduled Moods to configure time-based scene automation.")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, TranquilTheme.standardPadding)
                    Spacer()
                }
            }
        }
        .onAppear {
            AnalyticsService.logScreenView("scheduled_moods_settings_screen")
        }
    }
}

struct MoodBlockCard: View {
    @Binding var block: ScheduledMoodBlockData
    @ObservedObject private var settings = SettingsService.shared
    private var theme: AppTheme { settings.currentTheme }

    @State private var expanded = false

    var body: some View {
        VStack(spacing: 0) {
            TranquilFocusButton(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    expanded.toggle()
                }
            }) { isFocused in
                HStack(spacing: 20) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(theme.accentColor.opacity(0.2))
                            .frame(width: 56, height: 56)
                        Image(systemName: "clock.fill")
                            .font(.system(size: 22))
                            .foregroundColor(theme.accentColor)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(block.id.capitalized)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                        Text(block.timeRangeLabel)
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.6))
                    }

                    Spacer()

                    HStack(spacing: 6) {
                        Image(systemName: block.moodCategory.icon)
                            .font(.system(size: 16))
                            .foregroundColor(theme.accentColor)
                        Text(block.moodCategory.rawValue)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(theme.accentColor.opacity(0.15))
                    .clipShape(Capsule())

                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }
            .buttonStyle(.plain)

            if expanded {
                Divider()
                    .background(Color.white.opacity(0.1))
                    .padding(.horizontal, 20)

                VStack(spacing: 8) {
                    Text("Select Mood")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.top, 16)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(ScheduledMoodCategory.allCases, id: \.rawValue) { mood in
                                MoodCategoryChip(
                                    mood: mood,
                                    isSelected: block.moodCategory == mood,
                                    theme: theme
                                ) {
                                    block.moodCategory = mood
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.bottom, 20)
                }
            }
        }
    }
}

struct MoodCategoryChip: View {
    let mood: ScheduledMoodCategory
    let isSelected: Bool
    let theme: AppTheme
    let onSelect: () -> Void

    var body: some View {
        TranquilFocusButton(action: onSelect) { isFocused in
            VStack(spacing: 6) {
                Image(systemName: mood.icon)
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? theme.accentColor : .white.opacity(0.6))
                Text(mood.rawValue)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 120, height: 80)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? theme.accentColor.opacity(0.2) : Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? theme.accentColor : Color.clear, lineWidth: 2)
            )
            .scaleEffect(isFocused ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isFocused)
        }
        .buttonStyle(.plain)
    }
}

#Preview { ScheduledMoodsSettingsPage() }
