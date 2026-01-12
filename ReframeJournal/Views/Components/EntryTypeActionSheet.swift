// File: Views/Components/EntryTypeActionSheet.swift
// Action sheet for selecting entry type

import SwiftUI

struct EntryTypeActionSheet: View {
    @Environment(\.notesPalette) private var notesPalette
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    let onThoughtEntry: () -> Void
    let onUrgeEntry: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                entryOption(
                    title: "Thought Entry",
                    subtitle: "Reframe difficult thoughts",
                    icon: "brain.head.profile",
                    action: {
                        onThoughtEntry()
                        dismiss()
                    }
                )
                
                entryOption(
                    title: "Urge Entry",
                    subtitle: "Resist urges with mindfulness",
                    icon: "waveform.path",
                    action: {
                        onUrgeEntry()
                        dismiss()
                    }
                )
            }
            .padding(20)
            .background(notesPalette.background)
            .navigationTitle("New Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func entryOption(
        title: String,
        subtitle: String,
        icon: String,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            action()
        } label: {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(optionIconBackground)
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(notesPalette.textPrimary)
                }
                
                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(notesPalette.textPrimary)
                    
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundStyle(notesPalette.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(notesPalette.textTertiary)
            }
            .padding(16)
            .background(optionBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
    
    private var optionBackground: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04)
    }
    
    private var optionIconBackground: Color {
        colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.06)
    }
}
