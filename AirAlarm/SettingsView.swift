import SwiftUI

struct SettingsView: View {
    @Environment(LocalizationManager.self) private var loc
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var loc = loc

        NavigationStack {
            List {
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
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
