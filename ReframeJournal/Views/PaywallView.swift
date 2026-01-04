// File: Views/PaywallView.swift
import StoreKit
import SwiftUI

struct PaywallView: View {
    @EnvironmentObject private var entitlements: EntitlementsManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.notesPalette) private var notesPalette
    @Environment(\.colorScheme) private var colorScheme
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var didLoad: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Go Pro")
                        .font(.largeTitle.bold())

                    VStack(alignment: .leading, spacing: 12) {
                        Label("Unlimited thoughts", systemImage: "infinity")
                        Label("No ads", systemImage: "nosign")
                        Label("Higher AI usage limits", systemImage: "sparkles")
                    }
                    .font(.headline)

                    if let product = entitlements.proProduct {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(product.displayName)
                                .font(.title3.bold())
                            Text(product.displayPrice + " / month")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        ProgressView("Loading product...")
                    }

                    Button {
                        Task {
                            await purchase()
                        }
                    } label: {
                        Text("Subscribe for $0.99/month")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(entitlements.proProduct == nil || isLoading)

                    Button("Restore Purchases") {
                        Task {
                            await entitlements.restore()
                            if entitlements.isPro {
                                dismiss()
                            }
                        }
                    }
                    .disabled(isLoading)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
                .padding(24)
            }
            .scrollContentBackground(.hidden)
            .background(notesPalette.background)
            .navigationTitle("Upgrade")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbarBackground(notesPalette.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(colorScheme, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    GlassPillButton {
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(notesPalette.textSecondary)
                    }
                }
            }
            .task {
                guard !didLoad else { return }
                didLoad = true
                _ = await entitlements.loadProducts()
            }
        }
    }

    private func purchase() async {
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil
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
