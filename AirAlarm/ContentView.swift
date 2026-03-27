import SwiftUI

enum AppState {
    case idle
    case playingNoise
    case sleepDetected
    case alarmSet
}

struct ContentView: View {
    @State private var audioManager = AudioManager()
    @State private var alarmManager = AlarmManager()

    @State private var selectedNoise: WhiteNoiseType = .rain
    @State private var wakeWindowStart = Calendar.current.date(
        bySettingHour: 6, minute: 30, second: 0, of: Date()
    ) ?? Date()

    @State private var appState: AppState = .idle
    @State private var hasNotificationPermission = false

    @AppStorage("lastNoiseType") private var lastNoiseRawValue: String = WhiteNoiseType.rain.rawValue
    @AppStorage("wakeWindowStartHour") private var storedHour: Int = 6
    @AppStorage("wakeWindowStartMinute") private var storedMinute: Int = 30

    // Fixed 90-minute window
    private var wakeWindowEnd: Date {
        wakeWindowStart.addingTimeInterval(90 * 60)
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                VStack(spacing: 0) {
                    Spacer()

                    // Wake window info
                    wakeWindowHeader
                        .padding(.bottom, 16)

                    // Clock dial
                    ClockDialView(
                        wakeWindowStart: $wakeWindowStart,
                        appState: appState,
                        sleepTime: audioManager.sleepTime,
                        wakeTime: alarmManager.scheduledWakeTime,
                        scheduledCycles: alarmManager.scheduledCycles,
                        onTapCenter: { handleAction() }
                    )
                    .frame(width: 350, height: 350)

                    // Alarm info (when alarm set)
                    if appState == .alarmSet {
                        alarmInfoPill
                            .transition(.scale.combined(with: .opacity))
                            .padding(.top, 16)
                    }

                    // Playing status
                    if appState == .playingNoise {
                        playingStatus
                            .transition(.scale.combined(with: .opacity))
                            .padding(.top, 16)
                    }

                    // Dismiss alarm button (when ringing)
                    if alarmManager.isRinging {
                        dismissAlarmButton
                            .transition(.scale.combined(with: .opacity))
                            .padding(.top, 24)
                    }

                    Spacer()

                    // Noise picker
                    noisePickerView
                        .padding(.bottom, 16)
                }
                .padding(.horizontal, 20)
            }
        }
        .task {
            hasNotificationPermission = await alarmManager.requestPermission()
            restoreSettings()
        }
        .onChange(of: selectedNoise) { _, new in lastNoiseRawValue = new.rawValue }
        .onChange(of: wakeWindowStart) { _, new in
            let cal = Calendar.current
            storedHour = cal.component(.hour, from: new)
            storedMinute = cal.component(.minute, from: new)
        }
    }

    // MARK: - Wake Window Header

    private var wakeWindowHeader: some View {
        VStack(spacing: 6) {
            Text("Wake Window")
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

            Text("Drag the arc to adjust · 90 min cycle")
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.25))
        }
    }

    // MARK: - Playing Status

    private var playingStatus: some View {
        HStack(spacing: 8) {
            Image(systemName: "waveform")
                .symbolEffect(.pulse)
            Text("Playing \(selectedNoise.rawValue)...")
        }
        .font(.subheadline.weight(.medium))
        .foregroundStyle(.white.opacity(0.6))
    }

    // MARK: - Dismiss Alarm

    private var dismissAlarmButton: some View {
        Button {
            withAnimation(.spring(duration: 0.4)) {
                alarmManager.stopRinging()
                alarmManager.cancelAlarm()
                appState = .idle
            }
        } label: {
            VStack(spacing: 8) {
                Image(systemName: "sunrise.fill")
                    .font(.system(size: 32))
                Text("Good Morning")
                    .font(.headline)
                Text("Tap to dismiss")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 40)
            .padding(.vertical, 20)
        }
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }

    // MARK: - Alarm Info Pill

    private var alarmInfoPill: some View {
        VStack(spacing: 4) {
            if let wakeTime = alarmManager.scheduledWakeTime {
                Text(wakeTime, style: .time)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("\(alarmManager.scheduledCycles) cycles — \(SleepCycleCalculator.formatDuration(cycles: alarmManager.scheduledCycles))")
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
                            Text(noise.rawValue).font(.caption2.weight(.medium))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .foregroundStyle(selectedNoise == noise ? .white : .white.opacity(0.5))
                    }
                    .glassEffect(selectedNoise == noise ? .regular : .clear, in: .capsule)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Helpers

    private func noiseIcon(_ noise: WhiteNoiseType) -> String {
        switch noise {
        case .rain: return "cloud.rain"
        case .ocean: return "water.waves"
        case .forest: return "leaf"
        case .fan: return "fan"
        case .pureTone: return "waveform.path"
        }
    }

    private func formatTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: date)
    }

    // MARK: - Settings

    private func restoreSettings() {
        if let noise = WhiteNoiseType(rawValue: lastNoiseRawValue) { selectedNoise = noise }
        if let d = Calendar.current.date(bySettingHour: storedHour, minute: storedMinute, second: 0, of: Date()) {
            wakeWindowStart = d
        }
    }

    // MARK: - Business Logic

    private func handleAction() {
        switch appState {
        case .idle: startSleep()
        case .playingNoise: stopEverything()
        case .sleepDetected: break
        case .alarmSet:
            withAnimation(.spring(duration: 0.4)) {
                alarmManager.cancelAlarm()
                appState = .idle
            }
        }
    }

    private func startSleep() {
        audioManager.startWhiteNoise(type: selectedNoise) { onSleepDetected() }
        withAnimation(.spring(duration: 0.4)) { appState = .playingNoise }
    }

    private func stopEverything() {
        audioManager.stop()
        alarmManager.cancelAlarm()
        appState = .idle
    }

    private func onSleepDetected() {
        appState = .sleepDetected
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
    ContentView()
}
