import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @AppStorage("appAppearance") private var appAppearanceRaw: String = AppAppearance.system.rawValue
    @AppStorage("aiReframeEnabled") private var aiReframeEnabled: Bool = false

    private var appAppearance: Binding<AppAppearance> {
        Binding(
            get: { AppAppearance(rawValue: appAppearanceRaw) ?? .system },
            set: { appAppearanceRaw = $0.rawValue }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Appearance")
                .font(.system(size: 14))
                .foregroundColor(themeManager.theme.textSecondary)

            Picker("Appearance", selection: appAppearance) {
                ForEach(AppAppearance.allCases) { option in
                    Text(option.title)
                        .tag(option)
                }
            }
            .pickerStyle(.segmented)
            .padding(12)
            .cardSurface(cornerRadius: 12, shadow: false)

            Text("AI")
                .font(.system(size: 14))
                .foregroundColor(themeManager.theme.textSecondary)

            Toggle("AI Reframe (Send entries to OpenAI)", isOn: $aiReframeEnabled)
                .font(.system(size: 14, weight: .semibold))
                .padding(12)
                .foregroundColor(themeManager.theme.textPrimary)
                .cardSurface(cornerRadius: 12, shadow: false)

            Spacer()
        }
        .padding(16)
        .background(themeManager.theme.background.ignoresSafeArea())
        .navigationTitle("Settings")
    }
}
