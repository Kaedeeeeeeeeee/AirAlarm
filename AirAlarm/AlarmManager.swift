import UserNotifications
import AVFoundation

@Observable
class AlarmManager {
    var isAlarmScheduled = false
    var scheduledWakeTime: Date?
    var scheduledCycles: Int = 0
    var isRinging = false

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

        // 1. Schedule backup notification (in case app is killed)
        let content = UNMutableNotificationContent()
        content.title = "Time to Wake Up"
        content.body = "You've completed \(cycles) sleep cycles (\(SleepCycleCalculator.formatDuration(cycles: cycles))). This is your optimal wake time!"
        content.sound = UNNotificationSound.defaultCritical
        content.interruptionLevel = .timeSensitive

        let interval = wakeTime.timeIntervalSinceNow
        guard interval > 0 else { return }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(
            identifier: "air-alarm-wake",
            content: content,
            trigger: trigger
        )
        center.add(request)

        // 2. Schedule in-app audio alarm (primary method)
        alarmTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            self?.startRinging()
        }

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
    }

    // MARK: - Ringing

    private func startRinging() {
        // Configure audio session for speaker output (works even if AirPods fell off)
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
        } catch {
            print("Failed to configure alarm audio session: \(error)")
        }

        // Load alarm sound
        guard let url = Bundle.main.url(forResource: "alarm", withExtension: "mp3") else {
            print("alarm.mp3 not found in bundle")
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1 // Loop until dismissed
            player.volume = 0.0 // Start silent
            player.prepareToPlay()
            player.play()
            self.alarmPlayer = player
            self.isRinging = true

            // Gradually increase volume over 15 seconds
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
        // Ramp from 0 to 1 over 15 seconds (update every 0.2s)
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
            // Ease-in curve for natural volume ramp
            player.volume = progress * progress

            if currentStep >= steps {
                player.volume = 1.0
                timer.invalidate()
            }
        }
    }
}
