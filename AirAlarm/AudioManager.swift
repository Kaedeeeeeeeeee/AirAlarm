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
    private var onSleepDetected: (() -> Void)?
    private var confirmationTimer: Timer?
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
    }

    func stop() {
        confirmationTimer?.invalidate()
        confirmationTimer = nil
        isConfirmingSleep = false
        audioEngine?.stop()
        playerNode?.stop()
        audioEngine = nil
        playerNode = nil
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false

        try? AVAudioSession.sharedInstance().setActive(false)
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.interruptionNotification, object: nil)
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
    }

    @objc private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        if type == .began && isPlaying {
            // Start 30-second confirmation window
            interruptionStartTime = Date()
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.isConfirmingSleep = true
                self.confirmationTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: false) { [weak self] _ in
                    guard let self else { return }
                    // 30s passed without resume → confirmed sleep
                    self.isPlaying = false
                    self.sleepDetected = true
                    self.sleepTime = self.interruptionStartTime
                    self.isConfirmingSleep = false
                    self.onSleepDetected?()
                }
            }
        } else if type == .ended {
            // Audio resumed — false trigger
            DispatchQueue.main.async { [weak self] in
                guard let self, self.isConfirmingSleep else { return }
                self.confirmationTimer?.invalidate()
                self.confirmationTimer = nil
                self.isConfirmingSleep = false
                self.interruptionStartTime = nil

                let options = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
                if AVAudioSession.InterruptionOptions(rawValue: options).contains(.shouldResume) {
                    self.audioPlayer?.play()
                    self.playerNode?.play()
                }
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
