import Combine
import Foundation

@MainActor
final class AppState: ObservableObject {
    let repository: ThoughtRecordRepository
    let wizard: WizardViewModel
    let thoughtUsage: ThoughtUsageService
    private var cancellables: Set<AnyCancellable> = []

    init(repository: ThoughtRecordRepository = ThoughtRecordRepository()) {
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
