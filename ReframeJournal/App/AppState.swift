import Foundation

@MainActor
final class AppState: ObservableObject {
    let repository: ThoughtRecordRepository
    let wizard: WizardViewModel

    init(repository: ThoughtRecordRepository = ThoughtRecordRepository()) {
        self.repository = repository
        self.wizard = WizardViewModel(repository: repository)
    }
}
