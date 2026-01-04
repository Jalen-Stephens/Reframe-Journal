import SwiftUI

struct DateTimeView: View {
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var appState: AppState
    @Environment(\.notesPalette) private var notesPalette

    @State private var selectedDate: Date = Date()
    @State private var showDatePicker = false
    @State private var showTimePicker = false

    var body: some View {
        StepContentContainer(title: "Date & Time", step: 1, total: 6) {
            Text("When you noticed your mood change. If unsure, leave it as now.")
                .font(.system(size: 13))
                .foregroundColor(notesPalette.textSecondary)

            VStack(spacing: 12) {
                HStack {
                    Text("Selected")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(notesPalette.textSecondary)
                    Spacer()
                    Button("Reset to now") {
                        selectedDate = Date()
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(notesPalette.accent)
                }

                Button {
                    showDatePicker = true
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Date")
                                .font(.system(size: 12))
                                .foregroundColor(notesPalette.textSecondary)
                            Text(selectedDate.formatted(date: .abbreviated, time: .omitted))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(notesPalette.textPrimary)
                        }
                        Spacer()
                        Text(">")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(notesPalette.textSecondary)
                    }
                    .padding(12)
                    .pillSurface(cornerRadius: 12)
                }
                .buttonStyle(.plain)

                Button {
                    showTimePicker = true
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Time")
                                .font(.system(size: 12))
                                .foregroundColor(notesPalette.textSecondary)
                            Text(selectedDate.formatted(date: .omitted, time: .shortened))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(notesPalette.textPrimary)
                        }
                        Spacer()
                        Text(">")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(notesPalette.textSecondary)
                    }
                    .padding(12)
                    .pillSurface(cornerRadius: 12)
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .cardSurface(cornerRadius: 14)
        }
        .background(notesPalette.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom) {
            StepBottomNavBar(
                onBack: { router.pop() },
                onNext: {
                    Task { @MainActor in
                        var draft = appState.wizard.draft
                        draft.createdAt = DateUtils.isoString(from: selectedDate)
                        await appState.wizard.persistDraft(draft)
                        router.push(.wizardStep2)
                    }
                }
            )
        }
        .onAppear {
            if let storedDate = DateUtils.parseIso(appState.wizard.draft.createdAt) {
                selectedDate = storedDate
            } else {
                selectedDate = Date()
            }
        }
        .sheet(isPresented: $showDatePicker) {
            VStack(spacing: 16) {
                Text("Select date")
                    .font(.system(size: 16, weight: .semibold))
                DatePicker("", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                PrimaryButton(label: "Done") {
                    showDatePicker = false
                }
            }
            .padding(16)
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showTimePicker) {
            VStack(spacing: 16) {
                Text("Select time")
                    .font(.system(size: 16, weight: .semibold))
                DatePicker("", selection: $selectedDate, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                PrimaryButton(label: "Done") {
                    showTimePicker = false
                }
            }
            .padding(16)
            .presentationDetents([.medium])
        }
    }
}
