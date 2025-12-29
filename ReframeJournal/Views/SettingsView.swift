import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Appearance")
                .font(.system(size: 14))
                .foregroundColor(themeManager.theme.textSecondary)

            VStack(spacing: 0) {
                ForEach(Array(ThemePreference.allCases.enumerated()), id: \.element) { index, option in
                    Button {
                        themeManager.themePreference = option
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(option.label)
                                    .font(.system(size: 15))
                                    .foregroundColor(themeManager.theme.textPrimary)
                                if let helper = option.helper {
                                    Text(helper)
                                        .font(.system(size: 12))
                                        .foregroundColor(themeManager.theme.textSecondary)
                                }
                            }
                            Spacer()
                            ZStack {
                                Circle()
                                    .stroke(themeManager.theme.border, lineWidth: 2)
                                    .frame(width: 22, height: 22)
                                if themeManager.themePreference == option {
                                    Circle()
                                        .fill(themeManager.theme.accent)
                                        .frame(width: 10, height: 10)
                                }
                            }
                        }
                        .padding(.vertical, 14)
                        .padding(.horizontal, 16)
                        .background(themeManager.theme.card)
                    }
                    .buttonStyle(.plain)

                    if index < ThemePreference.allCases.count - 1 {
                        Divider()
                            .background(themeManager.theme.muted)
                    }
                }
            }
            .background(themeManager.theme.card)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(themeManager.theme.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Spacer()
        }
        .padding(16)
        .background(themeManager.theme.background.ignoresSafeArea())
        .navigationTitle("Settings")
    }
}
