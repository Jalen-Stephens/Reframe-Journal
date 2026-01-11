// File: Views/ValuesProfileView.swift
// Main values profile screen showing all 10 categories

import SwiftUI

struct ValuesProfileView: View {
    @Environment(\.notesPalette) private var notesPalette
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var router: AppRouter
    @StateObject private var service: ValuesProfileService
    
    init() {
        // Initialize with a temporary context, will be updated in onAppear
        let tempContainer = try! ModelContainerConfig.makeContainer()
        _service = StateObject(wrappedValue: ValuesProfileService(modelContext: tempContainer.mainContext))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                headerSection
                
                if service.isLoaded {
                    categoriesList
                } else {
                    loadingView
                }
            }
            .padding(.horizontal, 20)
        }
        .background(notesPalette.background.ignoresSafeArea())
        .navigationTitle("My Values")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            // Update service with the actual modelContext from environment
            service.updateModelContext(modelContext)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    router.pop()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Settings")
                            .font(.system(size: 17))
                    }
                    .foregroundStyle(notesPalette.textPrimary)
                }
            }
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your values guide how you want to show up in life. Reflecting on them helps create more meaningful reframes.")
                .font(.system(size: 14))
                .foregroundStyle(notesPalette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            
            if service.profile.hasContent {
                progressIndicator
            }
        }
        .padding(.vertical, 16)
    }
    
    private var progressIndicator: some View {
        HStack(spacing: 8) {
            let filled = service.profile.entries.values.filter { $0.hasContent }.count
            let total = ValuesCategory.allCases.count
            
            ProgressView(value: Double(filled), total: Double(total))
                .tint(notesPalette.textSecondary)
            
            Text("\(filled)/\(total) explored")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(notesPalette.textTertiary)
        }
    }
    
    // MARK: - Categories List
    
    private var categoriesList: some View {
        VStack(spacing: 0) {
            ForEach(ValuesCategory.allCases) { category in
                let entry = service.entry(for: category)
                
                NavigationLink(value: Route.valuesCategoryDetail(category: category)) {
                    CategoryRowView(
                        category: category,
                        entry: entry
                    )
                }
                .buttonStyle(.plain)
                
                if category != ValuesCategory.allCases.last {
                    Divider()
                        .background(notesPalette.separator.opacity(0.5))
                        .padding(.leading, 48)
                }
            }
        }
    }
    
    // MARK: - Loading
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(notesPalette.textSecondary)
            Text("Loading your values...")
                .font(.system(size: 14))
                .foregroundStyle(notesPalette.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
}

// MARK: - Category Row

private struct CategoryRowView: View {
    @Environment(\.notesPalette) private var notesPalette
    
    let category: ValuesCategory
    let entry: ValuesCategoryEntry
    
    var body: some View {
        HStack(spacing: 14) {
            // Icon
            Image(systemName: category.iconName)
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(entry.hasContent ? notesPalette.textSecondary : notesPalette.textTertiary)
                .frame(width: 24, alignment: .center)
            
            // Title and summary
            VStack(alignment: .leading, spacing: 3) {
                Text(category.title)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(notesPalette.textPrimary)
                
                if let summary = entry.summaryText {
                    Text(summary)
                        .font(.system(size: 13))
                        .foregroundStyle(notesPalette.textTertiary)
                        .lineLimit(1)
                } else {
                    Text("Tap to explore")
                        .font(.system(size: 13))
                        .foregroundStyle(notesPalette.textTertiary.opacity(0.7))
                }
            }
            
            Spacer()
            
            // Importance indicator (if set)
            if let importance = entry.importance, importance > 0 {
                HStack(spacing: 2) {
                    ForEach(0..<importance, id: \.self) { _ in
                        Circle()
                            .fill(notesPalette.textTertiary)
                            .frame(width: 4, height: 4)
                    }
                }
            }
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(notesPalette.textTertiary)
        }
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}

// MARK: - Preview

#Preview("Values Profile - Light") {
    NavigationStack {
        ValuesProfileView()
            .environmentObject(AppRouter())
            .modelContainer(try! ModelContainerConfig.makePreviewContainer())
            .notesTheme()
            .preferredColorScheme(.light)
    }
}

#Preview("Values Profile - Dark") {
    NavigationStack {
        ValuesProfileView()
            .environmentObject(AppRouter())
            .modelContainer(try! ModelContainerConfig.makePreviewContainer())
            .notesTheme()
            .preferredColorScheme(.dark)
    }
}
