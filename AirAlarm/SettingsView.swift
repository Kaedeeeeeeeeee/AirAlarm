import SwiftUI

struct SettingsView: View {
    @Environment(LocalizationManager.self) private var loc
    @Environment(\.dismiss) private var dismiss

    @AppStorage("bedtimeReminderEnabled") private var reminderEnabled = false
    @AppStorage("bedtimeReminderHour") private var reminderHour = 22
    @AppStorage("bedtimeReminderMinute") private var reminderMinute = 30

    @State private var reminderTime = Calendar.current.date(
        bySettingHour: 22, minute: 30, second: 0, of: Date()
    ) ?? Date()

    var body: some View {
        @Bindable var loc = loc

        NavigationStack {
            List {
                // Bedtime Reminder
                Section {
                    Toggle(loc.t("bedtime_reminder"), isOn: $reminderEnabled)
                        .accessibilityIdentifier("bedtimeToggle")
                        .onChange(of: reminderEnabled) { _, enabled in
                            if enabled {
                                BedtimeReminderManager.schedule(hour: reminderHour, minute: reminderMinute, localization: loc)
                            } else {
                                BedtimeReminderManager.cancel()
                            }
                        }

                    if reminderEnabled {
                        DatePicker(loc.t("reminder_time"), selection: $reminderTime, displayedComponents: .hourAndMinute)
                            .onChange(of: reminderTime) { _, newTime in
                                let cal = Calendar.current
                                reminderHour = cal.component(.hour, from: newTime)
                                reminderMinute = cal.component(.minute, from: newTime)
                                BedtimeReminderManager.schedule(hour: reminderHour, minute: reminderMinute, localization: loc)
                            }
                    }
                } header: {
                    Text(loc.t("bedtime_reminder"))
                }
                .listRowBackground(Color.white.opacity(0.05))

                // Language
                Section {
                    Picker(loc.t("language"), selection: $loc.current) {
                        ForEach(LocalizationManager.Language.allCases) { lang in
                            Text(lang.displayName).tag(lang)
                        }
                    }
                } header: {
                    Text(loc.t("language"))
                }
                .listRowBackground(Color.white.opacity(0.05))

                // History
                Section {
                    NavigationLink(loc.t("history")) {
                        HistoryView()
                    }
                    .accessibilityIdentifier("historyLink")
                }
                .listRowBackground(Color.white.opacity(0.05))

                // About
                Section {
                    HStack {
                        Text("AirAlarm")
                            .foregroundStyle(.white)
                        Spacer()
                        Text("1.0")
                            .foregroundStyle(.white.opacity(0.4))
                    }
                } header: {
                    Text(loc.t("about"))
                }
                .listRowBackground(Color.white.opacity(0.05))
            }
            .scrollContentBackground(.hidden)
            .background(Color(red: 0.04, green: 0.04, blue: 0.12))
            .navigationTitle(loc.t("settings"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .accessibilityIdentifier("settingsClose")
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            reminderTime = Calendar.current.date(
                bySettingHour: reminderHour, minute: reminderMinute, second: 0, of: Date()
            ) ?? Date()
        }
    }
}
