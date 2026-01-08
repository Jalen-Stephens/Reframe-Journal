import SwiftUI

// MARK: - Terms Privacy View

/// A dedicated Terms & Privacy page that matches the "How We Feel" style reference.
/// Supports two presentation modes:
/// - Modal (full screen cover): Shows X close button in top-right when `showCloseButton` is true
/// - Pushed (NavigationStack): Uses default back navigation
struct TermsPrivacyView: View {
    @Environment(\.dismiss) private var dismiss
    
    /// Controls whether the Accept button is shown and required
    let requiresAcceptance: Bool
    
    /// Whether to show the X close button (for modal presentation)
    let showCloseButton: Bool
    
    /// Persisted acceptance state
    @AppStorage("hasAcceptedTermsPrivacy") private var hasAcceptedTermsPrivacy = false
    
    // MARK: - Init
    
    /// - Parameters:
    ///   - requiresAcceptance: If true, shows the Accept button and requires interaction.
    ///     Pass true for onboarding/first-launch, false when viewing from Settings.
    ///   - showCloseButton: If true, shows an X button in the top-right corner.
    ///     Use this when presenting modally without acceptance requirement.
    init(requiresAcceptance: Bool = false, showCloseButton: Bool = false) {
        self.requiresAcceptance = requiresAcceptance
        self.showCloseButton = showCloseButton
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Pure black background
            Color.black.ignoresSafeArea()
            
            // Scrollable content
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // Back button
                    backButton
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                    
                    // Brand mark
                    brandMark
                        .padding(.leading, -8)
                        .padding(.bottom, 8)
                    
                    // Main headline
                    Text("Terms & Privacy")
                        .font(.system(size: 36, weight: .bold, design: .serif))
                        .foregroundStyle(.white)
                        .padding(.bottom, 36)
                    
                    // Section 1: Your data is yours
                    sectionHeader("Your data is yours")
                    sectionBody("""
Your journal entries are stored locally on your device—they never leave unless you choose to use AI features. We do not sell or share your journal data with anyone.

If iCloud sync is enabled in the future, your data will be encrypted and tied to your personal iCloud account, which only you control.

For app improvement purposes, we may collect anonymous, non-identifying usage analytics (like which features are used most). This data cannot be traced back to you or your journal content.
""")
                    
                    // Section 2: AI features and privacy
                    sectionHeader("AI features and privacy")
                    sectionBody("""
When you request an AI reframe, the text of your thought is sent to our AI provider to generate a helpful response. We minimize what's sent and do not store your journal content on our servers beyond what's needed to process the request.

For your privacy, we encourage you not to include highly sensitive personal identifiers (like full names, addresses, or account numbers) in your entries. The AI works best with the essence of your thoughts, not personal details.
""")
                    
                    // Section 3: This app isn't therapy
                    sectionHeader("This app isn't therapy")
                    sectionBody("""
The guidance and reframes in this app are intended for general self-reflection purposes only. Please don't rely on this information the way you would advice from a licensed mental health professional—it's not a substitute for therapy or medical care tailored to your individual situation.

If you're experiencing a mental health emergency, please reach out to local emergency services or a crisis helpline in your area.
""")
                    
                    // Section 4: Terms
                    sectionHeader("Terms")
                    sectionBody("""
By using Reframe Journal, you agree to our Terms of Service and Privacy Policy. You can review these documents at any time from the Settings screen.
""")
                    
                    // Footer links
                    termsFooterLinks
                        .padding(.top, 24)
                    
                    // Bottom spacing for the Accept button
                    if requiresAcceptance {
                        Spacer()
                            .frame(height: 120)
                    } else {
                        Spacer()
                            .frame(height: 60)
                    }
                }
                .padding(.horizontal, 24)
            }
            
            // Pinned Accept button (only when required)
            if requiresAcceptance {
                acceptButtonArea
            }
            
            // Modal close button (top-right X)
            if showCloseButton && !requiresAcceptance {
                closeButton
            }
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Brand Mark
    
    /// App mascot brand mark - aligned to leading edge above the "T" in Terms
    private var brandMark: some View {
        Image("FacePrivacy")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 160, height: 160)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Section Components
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 22, weight: .bold))
            .foregroundStyle(.white)
            .padding(.bottom, 16)
            .padding(.top, 8)
    }
    
    private func sectionBody(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 17, weight: .regular))
            .foregroundStyle(Color(white: 0.6))
            .lineSpacing(6)
            .padding(.bottom, 28)
    }
    
    // MARK: - Terms Footer Links
    
    private var termsFooterLinks: some View {
        HStack(spacing: 4) {
            Text("By continuing you agree to our")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(Color(white: 0.5))
            
            Button(action: {
                // TODO: Navigate to full Terms of Service
            }) {
                Text("Terms of Service")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(.white)
                    .underline()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Accept Button Area
    
    /// The accept button is pinned to the bottom of the screen using a ZStack.
    /// A gradient overlay creates a fade effect so scrolling content appears to go "under" the button.
    /// The button container uses safeAreaInset behavior by adding bottom padding that respects the safe area.
    private var acceptButtonArea: some View {
        VStack(spacing: 0) {
            // Gradient fade overlay - creates smooth transition from content to button
            LinearGradient(
                colors: [
                    Color.black.opacity(0),
                    Color.black.opacity(0.9),
                    Color.black
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 40)
            
            // Button container with safe area padding for home indicator
            VStack(spacing: 16) {
                Button(action: acceptTerms) {
                    Text("I Accept")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.white)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 24)
            }
            .padding(.bottom, 16)
            .background(
                Color.black
                    .ignoresSafeArea(edges: .bottom)
            )
        }
    }
    
    // MARK: - Back Button
    
    private var backButton: some View {
        Button(action: { dismiss() }) {
            HStack(spacing: 6) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                Text("Back")
                    .font(.system(size: 17, weight: .regular))
            }
            .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Close Button
    
    private var closeButton: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color(white: 0.6))
                        .frame(width: 32, height: 32)
                        .background(Color(white: 0.15))
                        .clipShape(Circle())
                }
                .padding(.trailing, 20)
                .padding(.top, 16)
            }
            Spacer()
        }
    }
    
    // MARK: - Actions
    
    private func acceptTerms() {
        hasAcceptedTermsPrivacy = true
        dismiss()
    }
}

// MARK: - Preview

#Preview("Terms & Privacy - Acceptance Required") {
    TermsPrivacyView(requiresAcceptance: true)
}

#Preview("Terms & Privacy - View Only") {
    TermsPrivacyView(requiresAcceptance: false)
}
