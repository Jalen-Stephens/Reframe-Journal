// File: Views/MainTabView.swift
// Main tab view that manages all tab bar pages with persistent tab bar

import SwiftUI
import SwiftData
import Foundation

struct MainTabView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var router: AppRouter
    @Environment(\.notesPalette) private var notesPalette
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var entitlementsManager: EntitlementsManager
    @Environment(\.modelContext) private var modelContext
    
    @State private var selectedTab: MainTab = .home
    @State private var showDailyLimitAlert = false
    @State private var showPaywall = false
    @State private var showEntryTypeSheet = false
    
    var body: some View {
        ZStack {
            // Background
            notesPalette.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Main content based on selected tab
                Group {
                    switch selectedTab {
                    case .home:
                        HomeContentView(selectedTab: $selectedTab)
                    case .entries:
                        AllEntriesView()
                    case .values:
                        ValuesView()
                    case .settings:
                        SettingsView()
                    case .newEntry:
                        HomeContentView(selectedTab: $selectedTab) // Fallback, button triggers action
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                MainTabBar(selectedTab: $selectedTab) {
                    showEntryTypeSheet = true
                }
            }
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
        .sheet(isPresented: $showEntryTypeSheet) {
            EntryTypeActionSheet(
                onThoughtEntry: {
                    startNewThoughtRecord()
                },
                onUrgeEntry: {
                    startNewUrgeEntry()
                }
            )
            .presentationDetents([.medium])
        }
    }
    
    // MARK: - Actions
    
    private func startNewThoughtRecord() {
        if appState.thoughtUsage.canCreateThought() {
            AnalyticsService.shared.trackEvent("thought_started")
            router.push(.thoughtEntry(id: nil))
        } else {
            showDailyLimitAlert = true
        }
    }
    
    private func startNewUrgeEntry() {
        if appState.thoughtUsage.canCreateThought() {
            AnalyticsService.shared.trackEvent("urge_started")
            router.push(.urgeEntry(id: nil))
        } else {
            showDailyLimitAlert = true
        }
    }
}

// MARK: - Home Content View

private struct HomeContentView: View {
    @Binding var selectedTab: MainTab
    
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var router: AppRouter
    @Environment(\.notesPalette) private var notesPalette
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var entitlementsManager: EntitlementsManager
    @Environment(\.modelContext) private var modelContext
    
    @Query(
        filter: #Predicate<JournalEntry> { !$0.isDraft },
        sort: \JournalEntry.createdAt,
        order: .reverse
    )
    private var allEntries: [JournalEntry]
    
    @StateObject private var viewModel = HomeViewModel()
    @State private var showDailyLimitAlert = false
    @State private var showPaywall = false
    
    var body: some View {
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
            
            // Non-scrollable content
            VStack(alignment: .leading, spacing: 12) {
                // Day label
                Text(viewModel.selectedDayLabel)
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(2)
                    .foregroundStyle(notesPalette.textTertiary)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                
                // Primary CTA card
                primaryActionCard
                    .padding(.horizontal, 16)
                
                // Entries for selected day
                entriesSection
                    .padding(.horizontal, 16)
                
                // Spacer to push content up
                Spacer(minLength: 0)
            }
        }
        .onAppear {
            viewModel.updateStreak(from: allEntries)
        }
        .onChange(of: allEntries) { _, newEntries in
            viewModel.updateStreak(from: newEntries)
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
            .padding(.bottom, 2)
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
            .padding(16)
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
            VStack(spacing: 0) {
                // Section header
                HStack {
                    Text("Entries")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(notesPalette.textSecondary)
                    Spacer()
                    
                    if viewModel.isSelectedToday && (filteredEntries.count > 3 || allEntries.count > filteredEntries.count) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                selectedTab = .entries
                            }
                        } label: {
                            Text("View all")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(notesPalette.textTertiary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 8)
                
                // Entry list (max 3 entries) with swipe actions
                List {
                    ForEach(Array(filteredEntries.prefix(3))) { entry in
                        EntryListItemView(entry: entry) {
                            switch entry.entryType {
                            case .thought:
                                router.push(.thoughtEntry(id: entry.recordId))
                            case .urge:
                                router.push(.urgeEntry(id: entry.recordId))
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button {
                                switch entry.entryType {
                                case .thought:
                                    router.push(.thoughtEntry(id: entry.recordId))
                                case .urge:
                                    router.push(.urgeEntry(id: entry.recordId))
                                }
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(notesPalette.accent)

                            Button(role: .destructive) {
                                deleteEntry(entry)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .listRowInsets(rowInsets)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .scrollDisabled(true)
                .frame(height: calculateListHeight(for: filteredEntries))
                
                // Nuggie image based on time of day (lowered slightly when 3 entries)
                nuggieImage
                    .padding(.top, filteredEntries.count >= 3 ? 0 : 4)
            }
        }
    }
    
    // MARK: - Helpers
    
    private var rowInsets: EdgeInsets {
        EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
    }
    
    private func calculateListHeight(for entries: [JournalEntry]) -> CGFloat {
        // Approximate height: ~80 per entry
        let entryHeight: CGFloat = 80
        let maxEntries = min(entries.count, 3)
        return CGFloat(maxEntries) * entryHeight
    }
    
    private func deleteEntry(_ entry: JournalEntry) {
        modelContext.delete(entry)
        try? modelContext.save()
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
    
    // MARK: - Nuggie Image
    
    private var nuggieImage: some View {
        Image(viewModel.isNightTime ? "NuggieDogBedJournal" : "NuggieStandingDogBed")
            .resizable()
            .scaledToFit()
            .frame(maxWidth: 220, maxHeight: 220)
            .frame(maxWidth: .infinity)
            .accessibilityLabel(viewModel.isNightTime 
                ? "Nuggie sleeping in a dog bed" 
                : "Nuggie standing by a dog bed")
    }
    
    // MARK: - Actions
    
    private func startNewThoughtRecord() {
        if appState.thoughtUsage.canCreateThought() {
            AnalyticsService.shared.trackEvent("thought_started")
            router.push(.thoughtEntry(id: nil))
        } else {
            showDailyLimitAlert = true
        }
    }
}

