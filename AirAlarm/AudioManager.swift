import AVFoundation
import Combine
import os

enum WhiteNoiseType: String, CaseIterable, Identifiable {
    case rain = "Rain"
    case ocean = "Ocean"
    case fire = "Fire"
    case forest = "Forest"
    case fan = "Fan"
    case pureTone = "White Noise"
    case airplane = "Airplane"

    var id: String { rawValue }

    var localizationKey: String {
        switch self {
        case .rain: return "sound_rain"
        case .ocean: return "sound_ocean"
        case .fire: return "sound_fire"
        case .forest: return "sound_forest"
        case .fan: return "sound_fan"
        case .pureTone: return "sound_whitenoise"
        case .airplane: return "sound_airplane"
        }
    }

    var fileName: String {
        switch self {
        case .rain: return "rain"
        case .ocean: return "ocean"
        case .forest: return "forest"
        case .fan: return "fan"
        case .pureTone: return "whitenoise"
        case .airplane: return "airplane"
        case .fire: return "fire"
        }
    }
}

@Observable
class AudioManager {
    private static let logger = Logger(subsystem: "com.zhangshifeng.airalarm", category: "Audio")

    var isPlaying = false
    var sleepDetected = false
    var sleepTime: Date?
    var volume: Float = 0.7
    var isConfirmingSleep = false

    private var audioPlayer: AVAudioPlayer?
    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var silentPlayer: AVAudioPlayer?
    private var onSleepDetected: (() -> Void)?
    private var confirmationTimer: Timer?
    private var playbackMonitor: Timer?
    private var interruptionStartTime: Date?

    func startWhiteNoise(type: WhiteNoiseType, onSleep: @escaping () -> Void) {
        onSleepDetected = onSleep
        sleepDetected = false
        sleepTime = nil
        isConfirmingSleep = false
        confirmationTimer?.invalidate()

        configureAudioSession()

        if let url = Bundle.main.url(forResource: type.fileName, withExtension: "mp3") {
            playAudioFile(url: url)
        } else {
            generateAndPlayWhiteNoise(type: type)
        }

        isPlaying = true
        startPlaybackMonitor()
    }

    func stop() {
        playbackMonitor?.invalidate()
        playbackMonitor = nil
        confirmationTimer?.invalidate()
        confirmationTimer = nil
        isConfirmingSleep = false
        audioEngine?.stop()
        playerNode?.stop()
        audioEngine = nil
        playerNode = nil
        audioPlayer?.stop()
        audioPlayer = nil
        silentPlayer?.stop()
        silentPlayer = nil
        isPlaying = false

        try? AVAudioSession.sharedInstance().setActive(false)
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.interruptionNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.routeChangeNotification, object: nil)
    }

    /// Start silent audio to keep the app alive in the background after sleep detection
    func startSilentBackgroundAudio() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers, .defaultToSpeaker])
            try session.setActive(true)
        } catch {
            Self.logger.error("Failed to configure silent audio session: \(error)")
        }

        // Generate a short silent WAV in memory
        let sampleRate: Double = 44100
        let duration: Double = 1.0
        let frameCount = Int(sampleRate * duration)
        let dataSize = frameCount * 2 // 16-bit mono
        let headerSize = 44
        var wav = Data(count: headerSize + dataSize)

        // WAV header
        wav.withUnsafeMutableBytes { buf in
            let p = buf.bindMemory(to: UInt8.self).baseAddress!
            // "RIFF"
            p[0] = 0x52; p[1] = 0x49; p[2] = 0x46; p[3] = 0x46
            let fileSize = UInt32(headerSize + dataSize - 8)
            p[4] = UInt8(fileSize & 0xFF); p[5] = UInt8((fileSize >> 8) & 0xFF)
            p[6] = UInt8((fileSize >> 16) & 0xFF); p[7] = UInt8((fileSize >> 24) & 0xFF)
            // "WAVE"
            p[8] = 0x57; p[9] = 0x41; p[10] = 0x56; p[11] = 0x45
            // "fmt "
            p[12] = 0x66; p[13] = 0x6D; p[14] = 0x74; p[15] = 0x20
            p[16] = 16; p[17] = 0; p[18] = 0; p[19] = 0 // chunk size
            p[20] = 1; p[21] = 0 // PCM
            p[22] = 1; p[23] = 0 // mono
            let sr = UInt32(sampleRate)
            p[24] = UInt8(sr & 0xFF); p[25] = UInt8((sr >> 8) & 0xFF)
            p[26] = UInt8((sr >> 16) & 0xFF); p[27] = UInt8((sr >> 24) & 0xFF)
            let byteRate = UInt32(sampleRate * 2)
            p[28] = UInt8(byteRate & 0xFF); p[29] = UInt8((byteRate >> 8) & 0xFF)
            p[30] = UInt8((byteRate >> 16) & 0xFF); p[31] = UInt8((byteRate >> 24) & 0xFF)
            p[32] = 2; p[33] = 0 // block align
            p[34] = 16; p[35] = 0 // bits per sample
            // "data"
            p[36] = 0x64; p[37] = 0x61; p[38] = 0x74; p[39] = 0x61
            let ds = UInt32(dataSize)
            p[40] = UInt8(ds & 0xFF); p[41] = UInt8((ds >> 8) & 0xFF)
            p[42] = UInt8((ds >> 16) & 0xFF); p[43] = UInt8((ds >> 24) & 0xFF)
            // Audio data is already zeros (silence)
        }

        do {
            let player = try AVAudioPlayer(data: wav)
            player.numberOfLoops = -1
            player.volume = 0.01
            player.prepareToPlay()
            player.play()
            self.silentPlayer = player
            Self.logger.info("Silent background audio started for keep-alive")
        } catch {
            Self.logger.error("Failed to start silent audio: \(error)")
        }
    }

    func setVolume(_ value: Float) {
        volume = value
        audioPlayer?.volume = value
        if let node = playerNode {
            node.volume = value
        }
    }

    // MARK: - File-Based Playback

    private func playAudioFile(url: URL) {
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.volume = volume
            player.prepareToPlay()
            player.play()
            self.audioPlayer = player
        } catch {
            Self.logger.error("Failed to play audio file: \(error)")
        }
    }

    // MARK: - Audio Session

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
        } catch {
            Self.logger.error("Failed to configure audio session: \(error)")
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: session
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: session
        )
    }

    /// Periodically check if audio is still playing — catches AirPods sleep detection
    /// and any other mechanism that stops playback without sending notifications
    private func startPlaybackMonitor() {
        playbackMonitor?.invalidate()
        playbackMonitor = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            guard let self, self.isPlaying, !self.isConfirmingSleep else { return }

            let playerStopped = self.audioPlayer != nil && !self.audioPlayer!.isPlaying
            let engineStopped = self.playerNode != nil && !self.playerNode!.isPlaying

            if playerStopped || engineStopped {
                Self.logger.info("Playback monitor: audio stopped unexpectedly, starting sleep confirmation")
                DispatchQueue.main.async {
                    self.beginSleepConfirmation()
                }
            }
        }
    }

    private func beginSleepConfirmation() {
        guard isPlaying, !isConfirmingSleep else { return }
        playbackMonitor?.invalidate()
        playbackMonitor = nil
        interruptionStartTime = Date()
        isConfirmingSleep = true
        confirmationTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: false) { [weak self] _ in
            guard let self else { return }
            self.isPlaying = false
            self.sleepDetected = true
            self.sleepTime = self.interruptionStartTime
            self.isConfirmingSleep = false
            self.onSleepDetected?()
        }
    }

    private func cancelSleepConfirmation(resumePlayback: Bool) {
        guard isConfirmingSleep else { return }
        confirmationTimer?.invalidate()
        confirmationTimer = nil
        isConfirmingSleep = false
        interruptionStartTime = nil
        if resumePlayback {
            audioPlayer?.play()
            playerNode?.play()
        }
        startPlaybackMonitor()
    }

    @objc private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        if type == .began && isPlaying {
            DispatchQueue.main.async { [weak self] in
                self?.beginSleepConfirmation()
            }
        } else if type == .ended {
            DispatchQueue.main.async { [weak self] in
                let options = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
                let shouldResume = AVAudioSession.InterruptionOptions(rawValue: options).contains(.shouldResume)
                self?.cancelSleepConfirmation(resumePlayback: shouldResume)
            }
        }
    }

    @objc private func handleRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else { return }

        if reason == .oldDeviceUnavailable && isPlaying && !isConfirmingSleep {
            Self.logger.info("Audio route changed: headphones removed, starting sleep confirmation")
            audioPlayer?.pause()
            playerNode?.pause()
            DispatchQueue.main.async { [weak self] in
                self?.beginSleepConfirmation()
            }
        }
    }

    // MARK: - Procedural Fallback

    private func generateAndPlayWhiteNoise(type: WhiteNoiseType) {
        let engine = AVAudioEngine()
        let player = AVAudioPlayerNode()
        engine.attach(player)

        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        engine.connect(player, to: engine.mainMixerNode, format: format)

        let buffer = generateNoiseBuffer(type: type, format: format)

        do {
            try engine.start()
            player.scheduleBuffer(buffer, at: nil, options: .loops)
            player.volume = volume
            player.play()
            self.audioEngine = engine
            self.playerNode = player
        } catch {
            Self.logger.error("Failed to start audio engine: \(error)")
        }
    }

    private func generateNoiseBuffer(type: WhiteNoiseType, format: AVAudioFormat) -> AVAudioPCMBuffer {
        let sampleRate = format.sampleRate
        let frameCount = AVAudioFrameCount(sampleRate * 2)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]

        switch type {
        case .pureTone:
            for i in 0..<Int(frameCount) { data[i] = Float.random(in: -0.3...0.3) }
        case .rain:
            var prev: Float = 0
            for i in 0..<Int(frameCount) {
                let noise = Float.random(in: -0.3...0.3)
                prev = prev * 0.7 + noise * 0.3
                let drop: Float = Float.random(in: 0...1) > 0.995 ? Float.random(in: -0.4...0.4) : 0
                data[i] = prev + drop * 0.3
            }
        case .ocean:
            for i in 0..<Int(frameCount) {
                let noise = Float.random(in: -0.3...0.3)
                let wave = sin(Float(i) / Float(sampleRate) * 0.3 * .pi)
                data[i] = noise * (0.15 + 0.15 * wave)
            }
        case .forest:
            var prev: Float = 0
            for i in 0..<Int(frameCount) {
                let noise = Float.random(in: -0.2...0.2)
                prev = prev * 0.85 + noise * 0.15
                let chirp: Float = Float.random(in: 0...1) > 0.999 ? sin(Float(i) * 0.15) * 0.1 : 0
                data[i] = prev + chirp
            }
        case .fan:
            var value: Float = 0
            for i in 0..<Int(frameCount) {
                value += Float.random(in: -0.05...0.05)
                value = max(-0.5, min(0.5, value))
                data[i] = value * 0.5
            }
        case .airplane:
            var prev: Float = 0
            for i in 0..<Int(frameCount) {
                let noise = Float.random(in: -0.25...0.25)
                prev = prev * 0.9 + noise * 0.1
                let hum = sin(Float(i) / Float(sampleRate) * 120 * .pi) * 0.05
                data[i] = prev + hum
            }
        case .fire:
            var prev: Float = 0
            for i in 0..<Int(frameCount) {
                let noise = Float.random(in: -0.3...0.3)
                prev = prev * 0.6 + noise * 0.4
                let crackle: Float = Float.random(in: 0...1) > 0.99 ? Float.random(in: -0.5...0.5) : 0
                data[i] = prev * 0.7 + crackle * 0.3
            }
        }
        return buffer
    }
}
