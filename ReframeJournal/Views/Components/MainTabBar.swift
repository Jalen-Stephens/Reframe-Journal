// File: Views/Components/MainTabBar.swift
// Custom tab bar with centered floating action button for new thought records

import SwiftUI

// MARK: - Tab Item

enum MainTab: CaseIterable, Identifiable {
    case home
    case entries
    case newEntry // Center FAB
    case insights
    case settings
    
    var id: Self { self }
    
    var label: String {
        switch self {
        case .home: return "Home"
        case .entries: return "Entries"
        case .newEntry: return "New"
        case .insights: return "Insights"
        case .settings: return "Settings"
        }
    }
    
    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .entries: return "book.closed.fill"
        case .newEntry: return "plus"
        case .insights: return "chart.line.uptrend.xyaxis"
        case .settings: return "gearshape.fill"
        }
    }
    
    var isCenter: Bool {
        self == .newEntry
    }
}

// MARK: - Tab Bar View

struct MainTabBar: View {
    @Environment(\.notesPalette) private var notesPalette
    @Environment(\.colorScheme) private var colorScheme
    
    @Binding var selectedTab: MainTab
    let onNewEntry: () -> Void
    
    private let tabBarHeight: CGFloat = 56
    private let fabSize: CGFloat = 56
    
    var body: some View {
        GeometryReader { geometry in
            let bottomSafeArea = geometry.safeAreaInsets.bottom
            
            VStack(spacing: 0) {
                Spacer()
                
                ZStack(alignment: .top) {
                    // Background
                    tabBarBackground
                        .frame(height: tabBarHeight + bottomSafeArea)
                    
                    // Tab items
                    HStack(spacing: 0) {
                        ForEach(MainTab.allCases) { tab in
                            if tab.isCenter {
                                // Center FAB
                                centerButton
                            } else {
                                tabItem(for: tab)
                            }
                        }
                    }
                    .frame(height: tabBarHeight)
                    .padding(.bottom, bottomSafeArea)
                }
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .frame(height: tabBarHeight + 34) // Approximate safe area for sizing
    }
    
    // MARK: - Background
    
    private var tabBarBackground: some View {
        Rectangle()
            .fill(notesPalette.surface.opacity(0.95))
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(notesPalette.separator)
                    .frame(height: 0.5)
            }
            .background(.ultraThinMaterial)
    }
    
    // MARK: - Tab Item
    
    private func tabItem(for tab: MainTab) -> some View {
        let isSelected = selectedTab == tab
        
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                    .symbolRenderingMode(.monochrome)
                
                Text(tab.label)
                    .font(.system(size: 10, weight: isSelected ? .medium : .regular))
            }
            .foregroundStyle(isSelected ? notesPalette.textPrimary : notesPalette.textTertiary)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.label)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
    
    // MARK: - Center FAB
    
    private var centerButton: some View {
        Button {
            onNewEntry()
        } label: {
            ZStack {
                Circle()
                    .fill(fabFill)
                    .frame(width: fabSize, height: fabSize)
                    .shadow(color: fabShadow, radius: 8, y: 4)
                
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(fabForeground)
            }
            .offset(y: -12) // Float above tab bar
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .accessibilityLabel("New thought record")
    }
    
    // MARK: - FAB Colors
    
    private var fabFill: Color {
        colorScheme == .dark ? .white : .black
    }
    
    private var fabForeground: Color {
        colorScheme == .dark ? .black : .white
    }
    
    private var fabShadow: Color {
        colorScheme == .dark ? .black.opacity(0.4) : .black.opacity(0.15)
    }
}

// MARK: - Preview

#Preview("Tab Bar - Light") {
    ZStack {
        Color("NotesBackground")
            .ignoresSafeArea()
        
        VStack {
            Spacer()
            MainTabBar(selectedTab: .constant(.home)) {}
        }
    }
    .notesTheme()
    .preferredColorScheme(.light)
}

#Preview("Tab Bar - Dark") {
    ZStack {
        Color("NotesBackground")
            .ignoresSafeArea()
        
        VStack {
            Spacer()
            MainTabBar(selectedTab: .constant(.home)) {}
        }
    }
    .notesTheme()
    .preferredColorScheme(.dark)
}
