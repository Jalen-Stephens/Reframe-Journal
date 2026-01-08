import SwiftUI

// MARK: - Settings View

struct SettingsView: View {
    @Environment(\.notesPalette) private var notesPalette
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    
    // MARK: - State
    
    @AppStorage("appAppearance") private var appAppearanceRaw: String = AppAppearance.system.rawValue
    @State private var showAppearancePicker = false
    
    private var currentAppearance: AppAppearance {
        AppAppearance(rawValue: appAppearanceRaw) ?? .system
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                
                // MARK: - Account Section
                
                SettingsSectionHeader(title: "Account")
                
                SettingsRow(
                    icon: "bell",
                    title: "Notifications",
                    action: { /* TODO: Navigate to notifications settings */ }
                )
                
                SettingsDivider()
                
                SettingsRow(
                    icon: "person.circle",
                    title: "Manage account",
                    action: { /* TODO: Navigate to account management */ }
                )
                
                SettingsDivider()
                
                SettingsRow(
                    icon: "creditcard",
                    title: "Manage subscription",
                    action: { /* TODO: Navigate to subscription management */ }
                )
                
                SettingsDivider()
                
                SettingsRowWithValue(
                    icon: "circle.lefthalf.filled",
                    title: "Appearance",
                    value: currentAppearance.title,
                    action: { showAppearancePicker = true }
                )
                
                // MARK: - Support Section
                
                SettingsSectionHeader(title: "Support")
                
                SettingsNavigationRow(
                    icon: "lock.shield",
                    title: "Privacy Policy",
                    destination: .termsPrivacy
                )
                
                SettingsDivider()
                
                SettingsRow(
                    icon: "envelope",
                    title: "Contact us",
                    isExternal: true,
                    action: { openContactEmail() }
                )
                
                SettingsDivider()
                
                SettingsRow(
                    icon: "heart",
                    title: "Write a review",
                    isExternal: true,
                    action: { openAppStoreReview() }
                )
                
                // MARK: - Footer
                
                SettingsFooter()
                
            }
            .padding(.horizontal, 20)
        }
        .background(notesPalette.background.ignoresSafeArea())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showAppearancePicker) {
            AppearancePickerSheet(selection: $appAppearanceRaw)
                .presentationDetents([.height(280)])
                .presentationDragIndicator(.visible)
        }
    }
    
    // MARK: - Actions
    
    private func openContactEmail() {
        if let url = URL(string: "mailto:jalen.stephens2025+reframe@gmail.com") {
            openURL(url)
        }
    }
    
    private func openAppStoreReview() {
        // TODO: Replace with actual App Store ID
        // Format: itms-apps://itunes.apple.com/app/idXXXXXXXXXX?action=write-review
        if let url = URL(string: "itms-apps://itunes.apple.com/app/id000000000?action=write-review") {
            openURL(url)
        }
    }
}

// MARK: - Appearance Picker Sheet

private struct AppearancePickerSheet: View {
    @Environment(\.notesPalette) private var notesPalette
    @Environment(\.dismiss) private var dismiss
    @Binding var selection: String
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ForEach(AppAppearance.allCases) { option in
                    Button {
                        selection = option.rawValue
                        dismiss()
                    } label: {
                        HStack {
                            Text(option.title)
                                .font(.system(size: 17))
                                .foregroundStyle(notesPalette.textPrimary)
                            
                            Spacer()
                            
                            if selection == option.rawValue {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(notesPalette.textPrimary)
                            }
                        }
                        .padding(.vertical, 14)
                        .padding(.horizontal, 20)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    
                    if option != AppAppearance.allCases.last {
                        Rectangle()
                            .fill(notesPalette.separator.opacity(0.5))
                            .frame(height: 0.5)
                            .padding(.leading, 20)
                    }
                }
                
                Spacer()
            }
            .padding(.top, 8)
            .background(notesPalette.background.ignoresSafeArea())
            .navigationTitle("Appearance")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Settings Row

private struct SettingsRow: View {
    @Environment(\.notesPalette) private var notesPalette
    
    let icon: String
    let title: String
    var isExternal: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(notesPalette.textSecondary.opacity(0.8))
                    .frame(width: 24, alignment: .center)
                
                Text(title)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(notesPalette.textPrimary)
                
                Spacer()
                
                if isExternal {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(notesPalette.textTertiary)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(notesPalette.textTertiary)
                }
            }
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Settings Navigation Row

private struct SettingsNavigationRow: View {
    @Environment(\.notesPalette) private var notesPalette
    
    let icon: String
    let title: String
    let destination: Route
    
    var body: some View {
        NavigationLink(value: destination) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(notesPalette.textSecondary.opacity(0.8))
                    .frame(width: 24, alignment: .center)
                
                Text(title)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(notesPalette.textPrimary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(notesPalette.textTertiary)
            }
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Settings Row With Value

private struct SettingsRowWithValue: View {
    @Environment(\.notesPalette) private var notesPalette
    
    let icon: String
    let title: String
    let value: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(notesPalette.textSecondary.opacity(0.8))
                    .frame(width: 24, alignment: .center)
                
                Text(title)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(notesPalette.textPrimary)
                
                Spacer()
                
                Text(value)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(notesPalette.textTertiary)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(notesPalette.textTertiary)
            }
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Settings Section Header

private struct SettingsSectionHeader: View {
    @Environment(\.notesPalette) private var notesPalette
    
    let title: String
    
    var body: some View {
        HStack {
            Text(title.uppercased())
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(notesPalette.textTertiary)
                .tracking(0.5)
            Spacer()
        }
        .padding(.top, 28)
        .padding(.bottom, 8)
    }
}

// MARK: - Settings Divider

private struct SettingsDivider: View {
    @Environment(\.notesPalette) private var notesPalette
    
    var body: some View {
        Rectangle()
            .fill(notesPalette.separator.opacity(0.5))
            .frame(height: 0.5)
            .padding(.leading, 38)
    }
}

// MARK: - Settings Footer

private struct SettingsFooter: View {
    @Environment(\.notesPalette) private var notesPalette
    
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(version) (\(build))"
    }
    
    var body: some View {
        VStack(spacing: 6) {
            Text("Reframe Journal")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(notesPalette.textTertiary)
            
            Text(appVersion)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(notesPalette.textTertiary.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 48)
        .padding(.bottom, 32)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SettingsView()
            .notesTheme()
    }
}
