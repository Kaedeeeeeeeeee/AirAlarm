import SwiftUI
import SwiftData
import Combine
import UserNotifications

enum AppState {
    case idle
    case playingNoise
    case sleepDetected
    case alarmSet
}

struct ContentView: View {
    @State private var audioManager = AudioManager()
    var alarmManager: AlarmManager
    @Environment(LocalizationManager.self) private var loc
    @Environment(\.modelContext) private var modelContext

    @State private var selectedNoise: WhiteNoiseType = .rain
    @State private var wakeWindowStart = Calendar.current.date(
        bySettingHour: 6, minute: 30, second: 0, of: Date()
    ) ?? Date()

    @State private var appState: AppState = .idle
    @State private var hasNotificationPermission = false
    @State private var showSettings = false

    @AppStorage("lastNoiseType") private var lastNoiseRawValue: String = WhiteNoiseType.rain.rawValue
    @AppStorage("wakeWindowStartHour") private var storedHour: Int = 6
    @AppStorage("wakeWindowStartMinute") private var storedMinute: Int = 30
    @AppStorage("noiseVolume") private var storedVolume: Double = 0.7
    @AppStorage("screenSaverEnabled") private var screenSaverEnabled: Bool = true
    @AppStorage("hasSeenScreenSaverAlert") private var hasSeenScreenSaverAlert = false
    @State private var showScreenSaverAlert = false
    @State private var screenSaverActive = false
    @State private var lastInteractionTime = Date()
    private let screenSaverTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var wakeWindowEnd: Date {
        wakeWindowStart.addingTimeInterval(90 * 60)
    }

    var body: some View {
        ZStack {
            noiseTintOverlay
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 1.5), value: selectedNoise)

            if !screenSaverActive {
                VStack(spacing: 0) {
                    // Top bar: always in layout, hidden via opacity in sleep mode
                    HStack {
                        Button { showSettings = true } label: {
                            Image(systemName: "gearshape")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.4))
                                .padding(10)
                        }
                        .glassEffect(.clear, in: .circle)
                        .accessibilityLabel(loc.t("settings"))
                        .accessibilityIdentifier("settingsButton")

                        Spacer()

                        Button {
                            alarmManager.startRinging()
                        } label: {
                            Image(systemName: "bell.and.waves.left.and.right")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.4))
                                .padding(10)
                        }
                        .glassEffect(.clear, in: .circle)
                        .accessibilityLabel("Test Alarm")
                        .accessibilityIdentifier("testAlarmButton")
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 4)
                    .opacity(isSleepModeActive ? 0 : 1)
                    .allowsHitTesting(!isSleepModeActive)

                    Spacer().frame(maxHeight: 100)

                    wakeWindowHeader
                        .padding(.bottom, 16)

                    ClockDialView(
                        wakeWindowStart: $wakeWindowStart,
                        appState: appState,
                        sleepTime: audioManager.sleepTime,
                        wakeTime: alarmManager.scheduledWakeTime,
                        scheduledCycles: alarmManager.scheduledCycles,
                        onTapCenter: { handleAction() }
                    )
                    .frame(width: 350, height: 350)

                    // Status area — fixed height to prevent clock shift
                    ZStack {
                        if appState == .alarmSet {
                            alarmInfoPill
                                .transition(.scale.combined(with: .opacity))
                        }

                        if appState == .playingNoise {
                            playingStatus
                                .transition(.scale.combined(with: .opacity))
                        }

                        if audioManager.isConfirmingSleep {
                            HStack(spacing: 8) {
                                ProgressView().tint(.white)
                                Text(loc.t("detecting_sleep"))
                            }
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white.opacity(0.6))
                            .accessibilityIdentifier("sleepDetectionIndicator")
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .frame(height: 60)
                    .padding(.top, 16)

                    Spacer()

                    // Bottom controls — fixed height to prevent clock position shift
                    VStack(spacing: 0) {
                        if isSleepModeActive {
                            screenSaverToggle
                                .padding(.horizontal, 24)
                                .padding(.bottom, 16)
                                .transition(.opacity)

                            volumeSlider
                                .padding(.bottom, 12)
                                .transition(.opacity)
                        } else {
                            Spacer()
                            noisePickerView
                                .padding(.bottom, 16)
                                .transition(.opacity.animation(.easeOut(duration: 0.15)))
                        }
                    }
                    .frame(height: 150)
                }
                .padding(.horizontal, 20)
            }

            // Screen saver overlay
            if screenSaverActive {
                Color.black
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            screenSaverActive = false
                        }
                        lastInteractionTime = Date()
                    }
            }
        }
        .animation(.easeInOut(duration: 0.5), value: screenSaverActive)
        .statusBarHidden(screenSaverActive)
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .task {
            hasNotificationPermission = await alarmManager.requestPermission()
            restoreSettings()
        }
        .onChange(of: selectedNoise) { _, new in
            lastNoiseRawValue = new.rawValue
            if appState == .playingNoise {
                audioManager.startWhiteNoise(type: new) { onSleepDetected() }
            }
        }
        .onChange(of: wakeWindowStart) { _, new in
            let cal = Calendar.current
            storedHour = cal.component(.hour, from: new)
            storedMinute = cal.component(.minute, from: new)
        }
        .onChange(of: alarmManager.isRinging) { wasRinging, isRinging in
            if wasRinging && !isRinging {
                saveSleepRecord()
                appState = .idle
                UIApplication.shared.isIdleTimerDisabled = false
                screenSaverActive = false
            }
        }
        .onReceive(screenSaverTimer) { _ in
            guard screenSaverEnabled, !screenSaverActive, isSleepModeActive else { return }
            if Date().timeIntervalSince(lastInteractionTime) >= 30 {
                withAnimation(.easeInOut(duration: 0.5)) {
                    screenSaverActive = true
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            if screenSaverEnabled && isSleepModeActive {
                UIApplication.shared.isIdleTimerDisabled = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            guard isSleepModeActive else { return }
            let content = UNMutableNotificationContent()
            content.title = loc.t("bg_warning_title")
            content.body = loc.t("bg_warning_body")
            content.sound = .default
            content.interruptionLevel = .timeSensitive
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(identifier: "bg-warning", content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
        }
        .alert(loc.t("screensaver_alert_title"), isPresented: $showScreenSaverAlert) {
            Button(loc.t("screensaver_alert_ok")) {
                hasSeenScreenSaverAlert = true
                startSleep()
            }
        } message: {
            Text(loc.t("screensaver_alert_message"))
        }
    }

    // MARK: - Wake Window Header

    private var wakeWindowHeader: some View {
        VStack(spacing: 6) {
            Text(loc.t("wake_window"))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.4))

            HStack(spacing: 16) {
                Text(formatTime(wakeWindowStart))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("—")
                    .font(.system(size: 24, weight: .light))
                    .foregroundStyle(.white.opacity(0.3))
                Text(formatTime(wakeWindowEnd))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            Text(loc.t("drag_hint"))
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.25))
        }
    }

    // MARK: - Screen Saver Toggle

    private var screenSaverToggle: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: $screenSaverEnabled) {
                Text(loc.t("screen_saver"))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .tint(.green)
            .accessibilityIdentifier("screenSaverToggle")

            Text(loc.t("screen_saver_hint"))
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.3))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Volume Slider

    private var volumeSlider: some View {
        HStack(spacing: 12) {
            Image(systemName: "speaker.fill")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.35))
            Slider(value: Binding(
                get: { storedVolume },
                set: {
                    storedVolume = $0
                    audioManager.setVolume(Float($0))
                }
            ), in: 0...1)
            .tint(.white.opacity(0.5))
            .accessibilityLabel(loc.t("volume"))
            .accessibilityIdentifier("volumeSlider")
            Image(systemName: "speaker.wave.3.fill")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.35))
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Playing Status

    private var playingStatus: some View {
        HStack(spacing: 8) {
            Image(systemName: "waveform").symbolEffect(.pulse)
            Text("\(loc.t("playing")) \(loc.t(selectedNoise.localizationKey))...")
        }
        .font(.subheadline.weight(.medium))
        .foregroundStyle(.white.opacity(0.6))
        .accessibilityIdentifier("playingStatus")
    }

    // MARK: - Alarm Info Pill

    private var alarmInfoPill: some View {
        VStack(spacing: 4) {
            if let wakeTime = alarmManager.scheduledWakeTime {
                Text(wakeTime, style: .time)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("\(alarmManager.scheduledCycles) \(loc.t("cycles")) — \(SleepCycleCalculator.formatDuration(cycles: alarmManager.scheduledCycles))")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }

    // MARK: - Noise Picker

    private var noisePickerView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(WhiteNoiseType.allCases) { noise in
                    Button {
                        withAnimation(.spring(duration: 0.3)) { selectedNoise = noise }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: noiseIcon(noise)).font(.caption2)
                            Text(loc.t(noise.localizationKey)).font(.caption2.weight(.medium))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .foregroundStyle(selectedNoise == noise ? .white : .white.opacity(0.5))
                    }
                    .glassEffect(selectedNoise == noise ? .regular : .clear, in: .capsule)
                    .accessibilityLabel(noise.rawValue)
                    .accessibilityAddTraits(selectedNoise == noise ? .isSelected : [])
                    .accessibilityIdentifier("noise_\(noise.rawValue)")
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Noise Tint Overlay

    private var noiseTintOverlay: some View {
        let color: Color = switch selectedNoise {
        case .rain:      Color(red: 0.05, green: 0.08, blue: 0.22)
        case .ocean:     Color(red: 0.02, green: 0.06, blue: 0.26)
        case .forest:    Color(red: 0.03, green: 0.14, blue: 0.08)
        case .fan:       Color(red: 0.07, green: 0.07, blue: 0.10)
        case .pureTone:  Color(red: 0.10, green: 0.05, blue: 0.22)
        case .airplane:  Color(red: 0.06, green: 0.07, blue: 0.18)
        case .fire:      Color(red: 0.22, green: 0.06, blue: 0.02)
        }
        return color.opacity(0.6)
    }

    // MARK: - Helpers

    private func noiseIcon(_ noise: WhiteNoiseType) -> String {
        switch noise {
        case .rain: return "cloud.rain"
        case .ocean: return "water.waves"
        case .forest: return "leaf"
        case .fan: return "fan"
        case .pureTone: return "waveform.path"
        case .airplane: return "airplane"
        case .fire: return "flame"
        }
    }

    private func formatTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: date)
    }

    private func restoreSettings() {
        if let noise = WhiteNoiseType(rawValue: lastNoiseRawValue) { selectedNoise = noise }
        if let d = Calendar.current.date(bySettingHour: storedHour, minute: storedMinute, second: 0, of: Date()) {
            wakeWindowStart = d
        }
        audioManager.setVolume(Float(storedVolume))
    }

    // MARK: - Screen Saver Helpers

    private var isSleepModeActive: Bool {
        appState == .playingNoise || appState == .sleepDetected || appState == .alarmSet
    }

    // MARK: - Business Logic

    private func handleAction() {
        switch appState {
        case .idle:
            if !hasSeenScreenSaverAlert {
                showScreenSaverAlert = true
            } else {
                startSleep()
            }
        case .playingNoise: stopEverything()
        case .sleepDetected: break
        case .alarmSet:
            withAnimation(.spring(duration: 0.4)) {
                alarmManager.cancelAlarm()
                appState = .idle
                UIApplication.shared.isIdleTimerDisabled = false
                screenSaverActive = false
            }
        }
    }

    private func startSleep() {
        audioManager.startWhiteNoise(type: selectedNoise) { onSleepDetected() }
        withAnimation(.spring(duration: 0.4)) { appState = .playingNoise }
        if screenSaverEnabled {
            UIApplication.shared.isIdleTimerDisabled = true
            lastInteractionTime = Date()
        }
    }

    private func stopEverything() {
        audioManager.stop()
        alarmManager.cancelAlarm()
        appState = .idle
        UIApplication.shared.isIdleTimerDisabled = false
        screenSaverActive = false
    }

    private func onSleepDetected() {
        appState = .sleepDetected
        if screenSaverEnabled {
            UIApplication.shared.isIdleTimerDisabled = true
        }
        guard let sleepTime = audioManager.sleepTime else { return }

        let earliest = normalizedWakeTime(wakeWindowStart, after: sleepTime)
        let latest = normalizedWakeTime(wakeWindowEnd, after: sleepTime)

        if let result = SleepCycleCalculator.optimalWakeTime(
            sleepTime: sleepTime, earliestWake: earliest, latestWake: latest
        ) {
            alarmManager.scheduleAlarm(at: result.wakeTime, cycles: result.cycles)
            withAnimation(.spring(duration: 0.4)) { appState = .alarmSet }
        } else {
            let fallbackCycles = Int(latest.timeIntervalSince(sleepTime) / SleepCycleCalculator.cycleDuration)
            alarmManager.scheduleAlarm(at: latest, cycles: max(fallbackCycles, 1))
            withAnimation(.spring(duration: 0.4)) { appState = .alarmSet }
        }
    }

    func saveSleepRecord() {
        guard let sleepTime = audioManager.sleepTime,
              let wakeTime = alarmManager.scheduledWakeTime else { return }
        let record = SleepRecord(
            sleepTime: sleepTime,
            wakeTime: wakeTime,
            cycles: alarmManager.scheduledCycles,
            noiseType: selectedNoise.rawValue
        )
        modelContext.insert(record)
    }

    private func normalizedWakeTime(_ time: Date, after sleepTime: Date) -> Date {
        let cal = Calendar.current
        let comps = cal.dateComponents([.hour, .minute], from: time)
        var candidate = cal.nextDate(after: sleepTime, matching: comps, matchingPolicy: .nextTime) ?? time
        if candidate <= sleepTime {
            candidate = cal.date(byAdding: .day, value: 1, to: candidate) ?? candidate
        }
        return candidate
    }
}

#Preview {
    ContentView(alarmManager: AlarmManager())
        .environment(LocalizationManager())
        .modelContainer(for: SleepRecord.self)
}
