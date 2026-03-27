import AVFoundation
import Combine

enum WhiteNoiseType: String, CaseIterable, Identifiable {
    case rain = "Rain"
    case ocean = "Ocean"
    case forest = "Forest"
    case fan = "Fan"
    case pureTone = "White Noise"

    var id: String { rawValue }

    var fileName: String {
        switch self {
        case .rain: return "rain"
        case .ocean: return "ocean"
        case .forest: return "forest"
        case .fan: return "fan"
        case .pureTone: return "whitenoise"
        }
    }

    var systemSoundDescription: String {
        switch self {
        case .rain: return "Rain sounds"
        case .ocean: return "Ocean waves"
        case .forest: return "Forest ambience"
        case .fan: return "Fan noise"
        case .pureTone: return "Pure white noise"
        }
    }
}

@Observable
class AudioManager {
    var isPlaying = false
    var sleepDetected = false
    var sleepTime: Date?

    private var audioPlayer: AVAudioPlayer?
    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var onSleepDetected: (() -> Void)?

    func startWhiteNoise(type: WhiteNoiseType, onSleep: @escaping () -> Void) {
        onSleepDetected = onSleep
        sleepDetected = false
        sleepTime = nil

        configureAudioSession()

        // Try file-based playback first, fall back to procedural generation
        if let url = Bundle.main.url(forResource: type.fileName, withExtension: "mp3") {
            playAudioFile(url: url)
        } else {
            generateAndPlayWhiteNoise(type: type)
        }

        isPlaying = true
    }

    func stop() {
        audioEngine?.stop()
        playerNode?.stop()
        audioEngine = nil
        playerNode = nil
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false

        try? AVAudioSession.sharedInstance().setActive(false)

        NotificationCenter.default.removeObserver(
            self,
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
    }

    // MARK: - File-Based Playback

    private func playAudioFile(url: URL) {
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1 // Loop indefinitely
            player.prepareToPlay()
            player.play()
            self.audioPlayer = player
        } catch {
            print("Failed to play audio file: \(error)")
        }
    }

    // MARK: - Audio Session

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
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
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        if type == .began && isPlaying {
            isPlaying = false
            sleepDetected = true
            sleepTime = Date()
            onSleepDetected?()
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
            player.play()

            self.audioEngine = engine
            self.playerNode = player
        } catch {
            print("Failed to start audio engine: \(error)")
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
            for i in 0..<Int(frameCount) {
                data[i] = Float.random(in: -0.3...0.3)
            }
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
                let envelope = 0.15 + 0.15 * wave
                data[i] = noise * envelope
            }
        case .forest:
            var prev: Float = 0
            for i in 0..<Int(frameCount) {
                let noise = Float.random(in: -0.2...0.2)
                prev = prev * 0.85 + noise * 0.15
                let chirp: Float = Float.random(in: 0...1) > 0.999
                    ? sin(Float(i) * 0.15) * 0.1
                    : 0
                data[i] = prev + chirp
            }
        case .fan:
            var value: Float = 0
            for i in 0..<Int(frameCount) {
                value += Float.random(in: -0.05...0.05)
                value = max(-0.5, min(0.5, value))
                data[i] = value * 0.5
            }
        }

        return buffer
    }
}
