import AppIntents
import UIKit

struct StartSleepIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Sleep Session"
    static var description: IntentDescription = "Opens AirAlarm and starts playing white noise for sleep"
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        // Signal the app to start sleep via URL scheme
        await MainActor.run {
            if let url = URL(string: "airalarm://start") {
                UIApplication.shared.open(url)
            }
        }
        return .result()
    }
}

struct AirAlarmShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartSleepIntent(),
            phrases: [
                "Start sleeping with \(.applicationName)",
                "Start \(.applicationName)",
                "Sleep with \(.applicationName)"
            ],
            shortTitle: "Start Sleep",
            systemImageName: "moon.zzz.fill"
        )
    }
}
