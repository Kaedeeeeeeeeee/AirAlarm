import AlarmKit
import AppIntents
import SwiftUI
import os

// MARK: - Metadata

struct SleepAlarmMetadata: AlarmMetadata {
    var cycles: Int
    var duration: String
}

// MARK: - Alarm Manager

@Observable
class SleepAlarmManager {
    private static let logger = Logger(subsystem: "com.zhangshifeng.airalarm", category: "Alarm")

    var isAlarmScheduled = false
    var scheduledWakeTime: Date?
    var scheduledCycles: Int = 0
    var isRinging = false
    var snoozeCount: Int = 0

    var localization: LocalizationManager?

    private var currentAlarmID: UUID?
    private var ringingTimer: Timer?

    private var system: AlarmKit.AlarmManager { .shared }

    // MARK: - Authorization

    func requestPermission() async -> Bool {
        do {
            let state = try await system.requestAuthorization()
            return state == .authorized
        } catch {
            Self.logger.error("AlarmKit authorization error: \(error)")
            return false
        }
    }

    // MARK: - Schedule

    func scheduleAlarm(at wakeTime: Date, cycles: Int) {
        let interval = wakeTime.timeIntervalSinceNow
        guard interval > 0 else { return }

        let id = UUID()
        currentAlarmID = id

        // Set state synchronously so callers can rely on it immediately
        isAlarmScheduled = true
        scheduledWakeTime = wakeTime
        scheduledCycles = cycles
        startRingingCheck()

        // AlarmKit scheduling happens async
        Task {
            do {
                let config = buildConfiguration(wakeTime: wakeTime, cycles: cycles)
                _ = try await system.schedule(id: id, configuration: config)
                let duration = SleepCycleCalculator.formatDuration(cycles: cycles)
                Self.logger.info("AlarmKit alarm scheduled for \(wakeTime), \(cycles) cycles (\(duration))")
            } catch {
                Self.logger.error("Failed to schedule alarm: \(error)")
                await MainActor.run {
                    guard self.currentAlarmID == id else { return }
                    self.isAlarmScheduled = false
                    self.scheduledWakeTime = nil
                    self.scheduledCycles = 0
                }
            }
        }
    }

    private func buildConfiguration(wakeTime: Date, cycles: Int) -> AlarmKit.AlarmManager.AlarmConfiguration<SleepAlarmMetadata> {
        let duration = SleepCycleCalculator.formatDuration(cycles: cycles)

        let stopButton = AlarmButton(
            text: "Good Morning",
            textColor: .white,
            systemImageName: "sunrise.fill"
        )

        let snoozeButton = AlarmButton(
            text: "Snooze 5 min",
            textColor: .white,
            systemImageName: "moon.zzz"
        )

        let alert = AlarmPresentation.Alert(
            title: "Time to Wake Up",
            stopButton: stopButton,
            secondaryButton: snoozeButton,
            secondaryButtonBehavior: .custom
        )

        let metadata = SleepAlarmMetadata(cycles: cycles, duration: duration)

        let attributes = AlarmAttributes<SleepAlarmMetadata>(
            presentation: AlarmPresentation(alert: alert),
            metadata: metadata,
            tintColor: .indigo
        )

        return .alarm(
            schedule: .fixed(wakeTime),
            attributes: attributes,
            stopIntent: DismissAlarmIntent(),
            secondaryIntent: SnoozeAlarmIntent()
        )
    }

    // MARK: - Cancel

    func cancelAlarm() {
        ringingTimer?.invalidate()
        ringingTimer = nil

        if let id = currentAlarmID {
            try? system.cancel(id: id)
        }

        isAlarmScheduled = false
        scheduledWakeTime = nil
        scheduledCycles = 0
        snoozeCount = 0
        isRinging = false
        currentAlarmID = nil
    }

    // MARK: - Snooze

    func snooze(minutes: Int = 5) {
        stopRinging()
        snoozeCount += 1
        let snoozeTime = Date().addingTimeInterval(Double(minutes * 60))
        scheduleAlarm(at: snoozeTime, cycles: scheduledCycles)
    }

    // MARK: - Morning Greeting State

    /// Show the morning greeting when the user returns to the app after alarm time.
    /// Called on `willEnterForeground` and `didBecomeActive`.
    func checkAlarmCompleted() {
        guard isAlarmScheduled,
              !isRinging,
              let wake = scheduledWakeTime,
              Date() >= wake else { return }
        isRinging = true // triggers MorningGreetingView
    }

    func startRinging() {
        isRinging = true
    }

    func stopRinging() {
        isRinging = false
        if let id = currentAlarmID {
            try? system.stop(id: id)
        }
    }

    /// Delayed check: waits 30s after alarm time before showing greeting,
    /// giving the user time to interact with the AlarmKit system UI first.
    private func startRingingCheck() {
        ringingTimer?.invalidate()
        ringingTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            guard let self, let wake = self.scheduledWakeTime else {
                timer.invalidate()
                return
            }
            // Wait 30 seconds past alarm time before showing greeting in-app
            let delay: TimeInterval = 30
            if Date() >= wake.addingTimeInterval(delay) && !self.isRinging {
                self.isRinging = true
                timer.invalidate()
            }
        }
    }
}

// MARK: - App Intents

/// Opens the app when the user taps "Good Morning" to dismiss the alarm.
struct DismissAlarmIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Dismiss Alarm"
    static var description: IntentDescription = "Dismiss the alarm and open AirAlarm"
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        .result()
    }
}

struct SnoozeAlarmIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Snooze Alarm"
    static var description: IntentDescription = "Snooze the alarm for 5 minutes"

    func perform() async throws -> some IntentResult {
        .result()
    }
}
