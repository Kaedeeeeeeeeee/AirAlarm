import UserNotifications
import AVFoundation

@Observable
class AlarmManager {
    var isAlarmScheduled = false
    var scheduledWakeTime: Date?
    var scheduledCycles: Int = 0
    var isRinging = false
    var snoozeCount: Int = 0

    private var alarmPlayer: AVAudioPlayer?
    private var alarmTimer: Timer?
    private var volumeTimer: Timer?

    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .criticalAlert])
        } catch {
            print("Notification permission error: \(error)")
            return false
        }
    }

    func scheduleAlarm(at wakeTime: Date, cycles: Int) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        let content = UNMutableNotificationContent()
        content.title = "Time to Wake Up"
        content.body = "You've completed \(cycles) sleep cycles (\(SleepCycleCalculator.formatDuration(cycles: cycles))). This is your optimal wake time!"
        content.sound = UNNotificationSound.defaultCritical
        content.interruptionLevel = .timeSensitive

        let interval = wakeTime.timeIntervalSinceNow
        guard interval > 0 else { return }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: "air-alarm-wake", content: content, trigger: trigger)
        center.add(request)

        alarmTimer?.invalidate()
        alarmTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            self?.startRinging()
        }

        // Schedule background task as backup
        BackgroundTaskManager.scheduleAlarmCheck(at: wakeTime)

        isAlarmScheduled = true
        scheduledWakeTime = wakeTime
        scheduledCycles = cycles
    }

    func cancelAlarm() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        alarmTimer?.invalidate()
        alarmTimer = nil
        stopRinging()
        isAlarmScheduled = false
        scheduledWakeTime = nil
        scheduledCycles = 0
        snoozeCount = 0
    }

    // MARK: - Snooze

    func snooze(minutes: Int = 5) {
        stopRinging()
        snoozeCount += 1
        let snoozeTime = Date().addingTimeInterval(Double(minutes * 60))
        scheduleAlarm(at: snoozeTime, cycles: scheduledCycles)
    }

    // MARK: - Ringing

    func startRinging() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
        } catch {
            print("Failed to configure alarm audio session: \(error)")
        }

        guard let url = Bundle.main.url(forResource: "alarm", withExtension: "mp3") else { return }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.volume = 0.0
            player.prepareToPlay()
            player.play()
            self.alarmPlayer = player
            self.isRinging = true
            startVolumeRamp()
        } catch {
            print("Failed to play alarm: \(error)")
        }
    }

    func stopRinging() {
        volumeTimer?.invalidate()
        volumeTimer = nil
        alarmPlayer?.stop()
        alarmPlayer = nil
        isRinging = false
    }

    private func startVolumeRamp() {
        let rampDuration: Float = 15.0
        let stepInterval: TimeInterval = 0.2
        let steps = Int(rampDuration / Float(stepInterval))
        var currentStep = 0

        volumeTimer = Timer.scheduledTimer(withTimeInterval: stepInterval, repeats: true) { [weak self] timer in
            guard let self, let player = self.alarmPlayer else {
                timer.invalidate()
                return
            }
            currentStep += 1
            let progress = Float(currentStep) / Float(steps)
            player.volume = progress * progress
            if currentStep >= steps {
                player.volume = 1.0
                timer.invalidate()
            }
        }
    }
}
