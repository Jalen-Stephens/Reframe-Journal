import SwiftUI

struct DateTimeView: View {
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var themeManager: ThemeManager

    @State private var selectedDate: Date = Date()
    @State private var showDatePicker = false
    @State private var showTimePicker = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                WizardProgressView(step: 1, total: 6)
                Text("Date & Time")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeManager.theme.textPrimary)
                Text("When you noticed your mood change. If unsure, leave it as now.")
                    .font(.system(size: 13))
                    .foregroundColor(themeManager.theme.textSecondary)

                VStack(spacing: 12) {
                    HStack {
                        Text("Selected")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(themeManager.theme.textSecondary)
                        Spacer()
                        Button("Reset to now") {
                            selectedDate = Date()
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(themeManager.theme.accent)
                    }

                    Button {
                        showDatePicker = true
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Date")
                                    .font(.system(size: 12))
                                    .foregroundColor(themeManager.theme.textSecondary)
                                Text(selectedDate.formatted(date: .abbreviated, time: .omitted))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(themeManager.theme.textPrimary)
                            }
                            Spacer()
                            Text(">")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(themeManager.theme.textSecondary)
                        }
                        .padding(12)
                        .background(themeManager.theme.card)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(themeManager.theme.border, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)

                    Button {
                        showTimePicker = true
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Time")
                                    .font(.system(size: 12))
                                    .foregroundColor(themeManager.theme.textSecondary)
                                Text(selectedDate.formatted(date: .omitted, time: .shortened))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(themeManager.theme.textPrimary)
                            }
                            Spacer()
                            Text(">")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(themeManager.theme.textSecondary)
                        }
                        .padding(12)
                        .background(themeManager.theme.card)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(themeManager.theme.border, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(12)
                .background(themeManager.theme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(themeManager.theme.border, lineWidth: 1)
                )
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(themeManager.theme.background.ignoresSafeArea())
        .ignoresSafeArea(.container, edges: .vertical)
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(label: "Next") {
                Task {
                    var draft = appState.wizard.draft
                    draft.createdAt = DateUtils.isoString(from: selectedDate)
                    await appState.wizard.persistDraft(draft)
                    router.push(.wizardStep2)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 10)
            .background(.ultraThinMaterial)
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
