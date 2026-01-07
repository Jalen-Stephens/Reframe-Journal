// File: App/AppState.swift
// Central app state container - updated for SwiftData

import Combine
import Foundation
import SwiftData

@MainActor
final class AppState: ObservableObject {
    let repository: ThoughtRecordRepository
    let wizard: WizardViewModel
    let thoughtUsage: ThoughtUsageService
    private var cancellables: Set<AnyCancellable> = []

    init(modelContext: ModelContext) {
        let repository = ThoughtRecordRepository(modelContext: modelContext)
        self.repository = repository
        self.wizard = WizardViewModel(repository: repository)
        self.thoughtUsage = ThoughtUsageService()
        wizard.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
}
