// File: Views/HomeView.swift
// Redesigned home screen with calendar strip, streak indicator, and bottom tab bar

import SwiftUI
import SwiftData

struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var router: AppRouter
    @Environment(\.notesPalette) private var notesPalette
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var entitlementsManager: EntitlementsManager
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - SwiftData Query
    @Query(
        filter: #Predicate<JournalEntry> { !$0.isDraft },
        sort: \JournalEntry.createdAt,
        order: .reverse
    )
    private var allEntries: [JournalEntry]
    
    // MARK: - State
    @StateObject private var viewModel = HomeViewModel()
    @State private var selectedTab: MainTab = .home
    @State private var showDailyLimitAlert = false
    @State private var showPaywall = false
    
    var body: some View {
        ZStack {
            // Background
            notesPalette.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Main content based on selected tab
                switch selectedTab {
                case .home:
                    homeContent
                case .entries:
                    homeContent // Will navigate
                case .insights:
                    insightsPlaceholder
                case .settings:
                    homeContent // Will navigate
                case .newEntry:
                    homeContent // Fallback, button triggers action
                }
            }
            .safeAreaInset(edge: .bottom) {
                MainTabBar(selectedTab: $selectedTab) {
                    startNewThoughtRecord()
                }
            }
        }
        .onAppear {
            viewModel.updateStreak(from: allEntries)
        }
        .onChange(of: allEntries) { _, newEntries in
            viewModel.updateStreak(from: newEntries)
        }
        .onChange(of: selectedTab) { _, newTab in
            handleTabChange(newTab)
        }
        .alert("Daily limit reached", isPresented: $showDailyLimitAlert) {
            Button("OK", role: .cancel) {}
            Button("Upgrade") {
                showPaywall = true
            }
        } message: {
            Text("You've used your 3 free thoughts for today.\nCome back tomorrow, or upgrade for unlimited thoughts.")
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
    
    // MARK: - Home Content
    
    private var homeContent: some View {
        VStack(spacing: 0) {
            // Top header
            headerSection
            
            // Calendar strip
            CalendarStripView(
                weekDays: viewModel.weekDays(entriesWithDates: viewModel.datesWithEntries(from: allEntries)),
                onSelectDate: { date in
                    viewModel.selectDate(date)
                }
            )
            
            // Scrollable content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Day label
                    Text(viewModel.selectedDayLabel)
                        .font(.system(size: 12, weight: .semibold))
                        .tracking(2)
                        .foregroundStyle(notesPalette.textTertiary)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    
                    // Primary CTA card
                    primaryActionCard
                        .padding(.horizontal, 16)
                    
                    // Entries for selected day
                    entriesSection
                        .padding(.horizontal, 16)
                    
                    // Spacer for bottom padding
                    Spacer(minLength: 100)
                }
            }
            .scrollIndicators(.hidden)
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            // Top row: streak + settings
            HStack(alignment: .center) {
                // Streak indicator
                streakIndicator
                
                Spacer()
                
                // Pro upgrade button (for non-pro users)
                if !entitlementsManager.isPro {
                    upgradeButton
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            
            // Greeting
            HStack {
                Text(viewModel.greeting)
                    .font(.system(size: 28, weight: .bold, design: .default))
                    .foregroundStyle(notesPalette.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 4)
        }
    }
    
    // MARK: - Streak Indicator
    
    private var streakIndicator: some View {
        HStack(spacing: 6) {
            Image(systemName: "flame.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(streakColor)
            
            Text("\(viewModel.streak)")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(notesPalette.textPrimary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(viewModel.streak) day streak")
    }
    
    private var streakColor: Color {
        if viewModel.streak > 0 {
            return Color.orange
        }
        return notesPalette.textTertiary
    }
    
    // MARK: - Upgrade Button
    
    private var upgradeButton: some View {
        Button {
            showPaywall = true
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .semibold))
                Text("Pro")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(upgradeGradient)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
    
    private var upgradeGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.35, green: 0.55, blue: 0.85),
                Color(red: 0.25, green: 0.45, blue: 0.75)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Primary Action Card
    
    private var primaryActionCard: some View {
        Button {
            startNewThoughtRecord()
        } label: {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Reframe a thought")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(cardTextPrimary)
                    
                    Text("Work through a difficult moment")
                        .font(.system(size: 14))
                        .foregroundStyle(cardTextSecondary)
                }
                
                Spacer()
                
                // Icon circle
                ZStack {
                    Circle()
                        .fill(cardIconBackground)
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(cardIconForeground)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Reframe a thought. Work through a difficult moment.")
    }
    
    // MARK: - Card Colors
    
    private var cardBackground: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04)
    }
    
    private var cardTextPrimary: Color {
        notesPalette.textPrimary
    }
    
    private var cardTextSecondary: Color {
        notesPalette.textSecondary
    }
    
    private var cardIconBackground: Color {
        colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.06)
    }
    
    private var cardIconForeground: Color {
        notesPalette.textSecondary
    }
    
    // MARK: - Entries Section
    
    @ViewBuilder
    private var entriesSection: some View {
        let filteredEntries = viewModel.entriesForSelectedDate(from: allEntries)
        
        if filteredEntries.isEmpty {
            emptyStateView
        } else {
            VStack(spacing: 12) {
                // Section header
                HStack {
                    Text("Entries")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(notesPalette.textSecondary)
                    Spacer()
                    
                    if viewModel.isSelectedToday && allEntries.count > filteredEntries.count {
                        Button {
                            router.push(.allEntries)
                        } label: {
                            Text("View all")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(notesPalette.textTertiary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 4)
                
                // Entry list (max 3)
                ForEach(Array(filteredEntries.prefix(3))) { entry in
                    let record = entry.toThoughtRecord()
                    EntryListItemView(entry: record) {
                        router.push(.thoughtEntry(id: entry.recordId))
                    }
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            if viewModel.isSelectedToday {
                Image("NuggieStandingDogBed")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 180)
                    .padding(.top, 24)
                
                Text("No entries yet today")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(notesPalette.textSecondary)
                
                Text("Start a thought record to begin your journey.")
                    .font(.system(size: 13))
                    .foregroundStyle(notesPalette.textTertiary)
                    .multilineTextAlignment(.center)
            } else {
                Text("No entries for this day")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(notesPalette.textSecondary)
                    .padding(.top, 32)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
    
    // MARK: - Placeholder Views for Other Tabs
    
    private var insightsPlaceholder: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(notesPalette.textTertiary)
            
            Text("Insights coming soon")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(notesPalette.textPrimary)
            
            Text("Track your progress and discover patterns in your thinking over time.")
                .font(.system(size: 14))
                .foregroundStyle(notesPalette.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Tab Navigation
    
    private func handleTabChange(_ tab: MainTab) {
        switch tab {
        case .entries:
            router.push(.allEntries)
            // Reset to home after navigating
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                selectedTab = .home
            }
        case .settings:
            router.push(.settings)
            // Reset to home after navigating
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                selectedTab = .home
            }
        default:
            break
        }
    }
    
    // MARK: - Actions
    
    private func startNewThoughtRecord() {
        if appState.thoughtUsage.canCreateThought() {
            router.push(.thoughtEntry(id: nil))
        } else {
            showDailyLimitAlert = true
        }
    }
}

// MARK: - Preview

#Preview("Home - Light") {
    HomeView()
        .environmentObject(AppState(modelContext: try! ModelContainerConfig.makeContainer().mainContext))
        .environmentObject(AppRouter())
        .environmentObject(EntitlementsManager())
        .notesTheme()
        .preferredColorScheme(.light)
}

#Preview("Home - Dark") {
    HomeView()
        .environmentObject(AppState(modelContext: try! ModelContainerConfig.makeContainer().mainContext))
        .environmentObject(AppRouter())
        .environmentObject(EntitlementsManager())
        .notesTheme()
        .preferredColorScheme(.dark)
}
