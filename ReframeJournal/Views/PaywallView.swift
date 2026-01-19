// File: Views/PaywallView.swift
// A calm, trustworthy upgrade screen for Reframe Journal Pro
// Inspired by MyFitnessPal's layout but tailored to the app's tone

import StoreKit
import SwiftUI

struct PaywallView: View {
    @EnvironmentObject private var entitlements: EntitlementsManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.notesPalette) private var notesPalette
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var errorMessage: String?
    @State private var didLoad: Bool = false
    @State private var nuggieOnYearly: Bool = true
    @State private var nuggieOpacity: Double = 1.0

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // MARK: - Background
            notesPalette.background
                .ignoresSafeArea()
            
            // MARK: - Main Content
            VStack(alignment: .leading, spacing: 0) {
                // Spacer for top area
                Color.clear
                    .frame(height: 44)
                
                // MARK: - Hero Section
                heroSection
                    .padding(.horizontal, 24)
                
                // MARK: - Benefits List
                benefitsSection
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                
                // MARK: - Plan Selector with Nuggie
                planSelectorWithNuggie
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                
                // MARK: - Reassurance Text
                reassuranceText
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                
                // MARK: - Error Message
                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .padding(.horizontal, 24)
                        .padding(.top, 4)
                }
                
                Spacer()
            }
            
            // MARK: - Close Button
            closeButton
        }
        .safeAreaInset(edge: .bottom) {
            ctaSection
        }
        .task {
            guard !didLoad else { return }
            didLoad = true
            _ = await entitlements.loadProducts()
        }
        .onAppear {
            AnalyticsService.shared.trackEvent("upgrade_viewed")
        }
    }
    
    // MARK: - Hero Section
    
    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Build a calmer mind,\none thought at a time.")
                .font(.system(size: 28, weight: .bold, design: .default))
                .foregroundStyle(notesPalette.textPrimary)
                .lineSpacing(2)
            
            Text("Upgrade to Pro for unlimited thought records and AI-powered reframes.")
                .font(.body)
                .foregroundStyle(notesPalette.textSecondary)
                .lineSpacing(3)
        }
    }
    
    // MARK: - Benefits Section
    
    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            BenefitRow(
                icon: "infinity",
                title: "Unlimited thought records",
                description: "Journal as often as you need, without limits."
            )
            
            BenefitRow(
                icon: "sparkles",
                title: "Unlimited AI reframes",
                description: "Get gentle AI support to reframe difficult thoughts."
            )
            
            BenefitRow(
                icon: "hand.raised.slash",
                title: "No ads or interruptions",
                description: "A calm, distraction-free space for reflection."
            )
            
            BenefitRow(
                icon: "star",
                title: "Early access to new features",
                description: "Be the first to try new tools as we grow."
            )
        }
    }
    
    // MARK: - Plan Selector with Nuggie
    
    private var planSelectorWithNuggie: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Choose your plan")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(notesPalette.textSecondary)
                .padding(.bottom, 8)
            
            // Nuggie + Plan cards layout
            VStack(spacing: -65) {
                // Nuggie above the cards - overlaps with cards below
                Image("NuggiePeaking")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 115)
                    .frame(maxWidth: .infinity, alignment: nuggieOnYearly ? .leading : .trailing)
                    .padding(.horizontal, 32)
                    .offset(y: nuggieOnYearly ? -6 : 0) // Raise slightly on yearly
                    .opacity(nuggieOpacity)
                    .accessibilityHidden(true)
                
                // Plan cards below Nuggie
                HStack(spacing: 12) {
                    // Yearly Plan Card
                    PlanCard(
                        plan: .yearly,
                        product: entitlements.yearlyProduct,
                        isSelected: entitlements.selectedPlan == .yearly,
                        savingsPercentage: entitlements.yearlySavingsPercentage,
                        monthlyEquivalent: entitlements.yearlyMonthlyEquivalent
                    ) {
                        selectPlan(.yearly)
                    }
                    
                    // Monthly Plan Card
                    PlanCard(
                        plan: .monthly,
                        product: entitlements.monthlyProduct,
                        isSelected: entitlements.selectedPlan == .monthly,
                        savingsPercentage: nil,
                        monthlyEquivalent: nil
                    ) {
                        selectPlan(.monthly)
                    }
                }
            }
        }
    }
    
    // MARK: - Plan Selection with Nuggie Animation
    
    private func selectPlan(_ plan: SubscriptionPlan) {
        // Don't animate if same plan selected
        guard plan != entitlements.selectedPlan else { return }
        
        // Phase 1: Fade out Nuggie
        withAnimation(.easeOut(duration: 0.3)) {
            nuggieOpacity = 0
        }
        
        // Phase 2: Move position while invisible and select new plan
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            nuggieOnYearly = (plan == .yearly)
            entitlements.selectPlan(plan)
            
            // Phase 3: Fade back in at new position
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeIn(duration: 0.35)) {
                    nuggieOpacity = 1
                }
            }
        }
    }
    
    // MARK: - Reassurance Text
    
    private var reassuranceText: some View {
        Text("Cancel anytime. No commitment required.")
            .font(.footnote)
            .foregroundStyle(notesPalette.textTertiary)
            .frame(maxWidth: .infinity)
    }
    
    // MARK: - CTA Section
    
    private var ctaSection: some View {
        VStack(spacing: 12) {
            // Primary CTA Button
                    Button {
                        Task {
                            await purchase()
                        }
                    } label: {
                HStack(spacing: 8) {
                    if entitlements.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                    Text(ctaButtonText)
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(ctaButtonGradient)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .disabled(entitlements.selectedProduct == nil || entitlements.isLoading)
            .opacity((entitlements.selectedProduct == nil || entitlements.isLoading) ? 0.6 : 1)
            
            // Restore Purchases Link
            Button {
                        Task {
                            await entitlements.restore()
                            if entitlements.isPro {
                                dismiss()
                            }
                        }
            } label: {
                Text("Restore purchases")
                    .font(.footnote)
                    .foregroundStyle(notesPalette.textSecondary)
            }
            .disabled(entitlements.isLoading)
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(
            notesPalette.background
                .shadow(color: notesPalette.glassShadow.opacity(0.5), radius: 20, x: 0, y: -10)
                .ignoresSafeArea(edges: .bottom)
        )
    }
    
    private var ctaButtonText: String {
        guard let product = entitlements.selectedProduct else {
            return "Continue"
        }
        
        // Check if there's a free trial (StoreKit 2 handles this)
        if let subscription = product.subscription,
           let introOffer = subscription.introductoryOffer,
           introOffer.paymentMode == .freeTrial {
            let duration = introOffer.period.value
            let unit = introOffer.period.unit
            let unitString: String
            switch unit {
            case .day: unitString = duration == 1 ? "Day" : "Days"
            case .week: unitString = duration == 1 ? "Week" : "Weeks"
            case .month: unitString = duration == 1 ? "Month" : "Months"
            case .year: unitString = duration == 1 ? "Year" : "Years"
            @unknown default: unitString = "Days"
            }
            return "Start \(duration)-\(unitString) Free Trial"
        }
        
        return "Continue"
    }
    
    private var ctaButtonGradient: LinearGradient {
        // Calm, trustworthy blue gradient
        LinearGradient(
            colors: [
                Color(red: 0.35, green: 0.55, blue: 0.85),
                Color(red: 0.25, green: 0.45, blue: 0.75)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Close Button
    
    private var closeButton: some View {
        Button {
                        dismiss()
                    } label: {
            ZStack {
                Circle()
                    .fill(colorScheme == .dark ? Color.white.opacity(0.15) : Color.black.opacity(0.08))
                    .frame(width: 32, height: 32)
                
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(notesPalette.textSecondary)
            }
        }
        .padding(.top, 16)
        .padding(.trailing, 20)
        .accessibilityLabel("Close")
    }
    
    // MARK: - Actions

    private func purchase() async {
        errorMessage = nil
        AnalyticsService.shared.trackEvent("upgrade_clicked", properties: [
            "plan": entitlements.selectedPlan.rawValue
        ])
        do {
            try await entitlements.purchase()
            if entitlements.isPro {
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Benefit Row Component

private struct BenefitRow: View {
    @Environment(\.notesPalette) private var notesPalette
    
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Icon container
            ZStack {
                Circle()
                    .fill(benefitIconBackground)
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(benefitIconColor)
            }
            
            // Text content
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(notesPalette.textPrimary)
                
                Text(description)
                    .font(.footnote)
                    .foregroundStyle(notesPalette.textSecondary)
                    .lineSpacing(1)
            }
        }
    }
    
    private var benefitIconBackground: Color {
        Color(red: 0.35, green: 0.55, blue: 0.85).opacity(0.12)
    }
    
    private var benefitIconColor: Color {
        Color(red: 0.35, green: 0.55, blue: 0.85)
    }
}

// MARK: - Plan Card Component

private struct PlanCard: View {
    @Environment(\.notesPalette) private var notesPalette
    @Environment(\.colorScheme) private var colorScheme
    
    let plan: SubscriptionPlan
    let product: Product?
    let isSelected: Bool
    let savingsPercentage: Int?
    let monthlyEquivalent: Decimal?
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            cardContent
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(plan.displayName) plan, \(displayPrice)")
        .accessibilityHint(isSelected ? "Selected" : "Double tap to select")
    }
    
    // MARK: - Card Content
    
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            savingsBadge
            planNameRow
            priceRow
            monthlyEquivalentText
            billingDescriptionText
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(cardBorder)
    }
    
    // MARK: - Savings Badge
    
    @ViewBuilder
    private var savingsBadge: some View {
        if displaySavings > 0 {
            Text("\(displaySavings)% SAVINGS")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(savingsBadgeColor)
                .clipShape(Capsule())
                .padding(.bottom, 8)
        } else {
            Color.clear
                .frame(height: 22)
                .padding(.bottom, 8)
        }
    }
    
    // MARK: - Plan Name Row
    
    private var planNameRow: some View {
        HStack {
            Text(plan.displayName.uppercased())
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(notesPalette.textPrimary)
            
            Spacer()
            
            selectionIndicator
        }
    }
    
    // MARK: - Selection Indicator
    
    private var selectionIndicator: some View {
        ZStack {
            Circle()
                .stroke(selectionBorderColor, lineWidth: 2)
                .frame(width: 22, height: 22)
            
            if isSelected {
                Circle()
                    .fill(selectedAccentColor)
                    .frame(width: 14, height: 14)
            }
        }
    }
    
    // MARK: - Price Row
    
    private var priceRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text(displayPrice)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(priceColor)
            
            Text("/\(periodAbbreviation)")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(notesPalette.textSecondary)
        }
        .padding(.top, 6)
    }
    
    // MARK: - Monthly Equivalent
    
    @ViewBuilder
    private var monthlyEquivalentText: some View {
        if plan == .yearly {
            Text(monthlyEquivalentDisplayText)
                .font(.system(size: 11))
                .foregroundStyle(notesPalette.textTertiary)
                .padding(.top, 2)
        }
    }
    
    // MARK: - Billing Description
    
    private var billingDescriptionText: some View {
        Text(billingDescription)
            .font(.system(size: 11))
            .foregroundStyle(notesPalette.textTertiary)
            .padding(.top, 8)
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    // MARK: - Card Border
    
    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .stroke(borderColor, lineWidth: isSelected ? 2 : 1)
    }
    
    // MARK: - Computed Properties
    
    private var displayPrice: String {
        if let productPrice = product?.displayPrice {
            return productPrice
        }
        return plan == .monthly ? "$4.99" : "$29.99"
    }
    
    private var displaySavings: Int {
        if let savings = savingsPercentage {
            return savings
        }
        return plan == .yearly ? 50 : 0
    }
    
    private var monthlyEquivalentDisplayText: String {
        if let equivalent = monthlyEquivalent {
            return formatMonthlyEquivalent(equivalent) + "/mo"
        }
        return "$2.50/mo"
    }
    
    private var periodAbbreviation: String {
        plan == .monthly ? "mo" : "yr"
    }
    
    private var billingDescription: String {
        plan == .monthly ? "Billed monthly" : "Billed yearly"
    }
    
    private var cardBackground: Color {
        if isSelected {
            return colorScheme == .dark ? Color.white.opacity(0.08) : Color.white
        }
        return colorScheme == .dark ? Color.white.opacity(0.04) : notesPalette.surface.opacity(0.8)
    }
    
    private var selectedAccentColor: Color {
        Color(red: 0.2, green: 0.65, blue: 0.45)
    }
    
    private var savingsBadgeColor: Color {
        Color(red: 0.2, green: 0.65, blue: 0.45)
    }
    
    private var priceColor: Color {
        isSelected ? selectedAccentColor : notesPalette.textPrimary
    }
    
    private var selectionBorderColor: Color {
        isSelected ? selectedAccentColor : notesPalette.textTertiary.opacity(0.5)
    }
    
    private var borderColor: Color {
        isSelected ? selectedAccentColor : notesPalette.glassBorder
    }
    
    private func formatMonthlyEquivalent(_ price: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: price as NSDecimalNumber) ?? ""
    }
}

// MARK: - Preview

#Preview {
    PaywallView()
        .environmentObject(EntitlementsManager())
        .notesTheme()
}
