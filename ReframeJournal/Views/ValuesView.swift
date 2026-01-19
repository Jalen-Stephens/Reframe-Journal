// File: Views/ValuesView.swift
// Personal Values worksheet view - shows category buttons that navigate to detail forms

import SwiftUI
import SwiftData

struct ValuesView: View {
    @Environment(\.notesPalette) private var notesPalette
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var router: AppRouter
    
    @Query private var valuesQuery: [PersonalValues]
    
    private var personalValues: PersonalValues? {
        valuesQuery.first
    }
    
    var body: some View {
        ZStack {
            notesPalette.background.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    headerSection
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                    
                    // Category buttons
                    VStack(spacing: 12) {
                        ForEach(ValuesCategory.allCases) { category in
                            categoryButton(for: category)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Bottom padding
                    Color.clear.frame(height: 100)
                }
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Personal Values")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(notesPalette.textPrimary)
            
            Text("A Values Clarification exercise to help you explore and clarify the things you hold meaningful and important on a personal level.")
                .font(.system(size: 15))
                .foregroundStyle(notesPalette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    // MARK: - Category Button
    
    private func categoryButton(for category: ValuesCategory) -> some View {
        let value = personalValues.flatMap { category.getValue(from: $0) }
        let hasValue = value != nil && !value!.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        
        return Button {
            router.push(.valuesCategoryDetail(category: category))
        } label: {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(notesPalette.accent.opacity(0.1))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: category.icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(notesPalette.accent)
                }
                
                // Title and preview
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(notesPalette.textPrimary)
                        .multilineTextAlignment(.leading)
                    
                    if hasValue, let value = value {
                        Text(value)
                            .font(.system(size: 14))
                            .foregroundStyle(notesPalette.textSecondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    } else {
                        Text("Tap to add your values")
                            .font(.system(size: 14))
                            .foregroundStyle(notesPalette.textTertiary)
                            .italic()
                    }
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(notesPalette.textTertiary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(hasValue ? notesPalette.accent.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Card Colors
    
    private var cardBackground: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04)
    }
}

// MARK: - Preview

#Preview("Values View - Light") {
    ValuesView()
        .modelContainer(try! ModelContainerConfig.makePreviewContainer())
        .environmentObject(AppRouter())
        .notesTheme()
        .preferredColorScheme(.light)
}

#Preview("Values View - Dark") {
    ValuesView()
        .modelContainer(try! ModelContainerConfig.makePreviewContainer())
        .environmentObject(AppRouter())
        .notesTheme()
        .preferredColorScheme(.dark)
}
