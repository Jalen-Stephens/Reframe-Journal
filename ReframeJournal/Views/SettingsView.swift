import SwiftUI

struct SettingsView: View {
    @Environment(\.notesPalette) private var notesPalette
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appAppearance") private var appAppearanceRaw: String = AppAppearance.system.rawValue
    @AppStorage("aiReframeEnabled") private var aiReframeEnabled: Bool = false
    @AppStorage("devDisableThoughtLimit") private var devDisableThoughtLimit: Bool = false

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
                .foregroundColor(notesPalette.textSecondary)

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
                .foregroundColor(notesPalette.textSecondary)

            Toggle("AI Reframe (Send entries to OpenAI)", isOn: $aiReframeEnabled)
                .font(.system(size: 14, weight: .semibold))
                .padding(12)
                .foregroundColor(notesPalette.textPrimary)
                .cardSurface(cornerRadius: 12, shadow: false)

            Text("Developer")
                .font(.system(size: 14))
                .foregroundColor(notesPalette.textSecondary)

            Toggle("Disable thought limit", isOn: $devDisableThoughtLimit)
                .font(.system(size: 14, weight: .semibold))
                .padding(12)
                .foregroundColor(notesPalette.textPrimary)
                .cardSurface(cornerRadius: 12, shadow: false)

            Spacer()
        }
        .padding(16)
        .background(notesPalette.background.ignoresSafeArea())
        .navigationTitle("Settings")
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                GlassIconButton(icon: .chevronLeft, size: AppTheme.iconSizeMedium, accessibilityLabel: "Back") {
                    dismiss()
                }
            }
        }
    }
}
