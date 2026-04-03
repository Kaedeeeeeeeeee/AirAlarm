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

        let config = AlarmKit.AlarmManager.AlarmConfiguration.alarm(
            schedule: .fixed(wakeTime),
            attributes: attributes,
            secondaryIntent: SnoozeAlarmIntent()
        )

        Task {
            do {
                _ = try await system.schedule(id: id, configuration: config)
                await MainActor.run {
                    self.isAlarmScheduled = true
                    self.scheduledWakeTime = wakeTime
                    self.scheduledCycles = cycles
                    self.startRingingCheck()
                }
                Self.logger.info("AlarmKit alarm scheduled for \(wakeTime), \(cycles) cycles (\(duration))")
            } catch {
                Self.logger.error("Failed to schedule alarm: \(error)")
            }
        }
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

    // MARK: - Ringing State (for in-app UI)

    func startRinging() {
        isRinging = true
    }

    func stopRinging() {
        ringingTimer?.invalidate()
        ringingTimer = nil
        isRinging = false

        if let id = currentAlarmID {
            try? system.stop(id: id)
        }
    }

    /// Poll to detect when alarm time arrives while app is in foreground
    private func startRingingCheck() {
        ringingTimer?.invalidate()
        ringingTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            guard let self, let wake = self.scheduledWakeTime else {
                timer.invalidate()
                return
            }
            if Date() >= wake && !self.isRinging {
                self.isRinging = true
                timer.invalidate()
            }
        }
    }
}

// MARK: - App Intents

struct SnoozeAlarmIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Snooze Alarm"
    static var description: IntentDescription = "Snooze the alarm for 5 minutes"

    func perform() async throws -> some IntentResult {
        .result()
    }
}
