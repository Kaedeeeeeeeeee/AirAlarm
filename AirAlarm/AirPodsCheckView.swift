import SwiftUI
import AVFoundation

struct AirPodsCheckView: View {
    let onContinue: () -> Void

    @Environment(LocalizationManager.self) private var loc
    @State private var isConnected = false
    @State private var pollTimer: Timer?

    private let supportedModels = [
        "AirPods Pro 2",
        "AirPods Pro 3",
        "AirPods 4"
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle()
                    .fill(isConnected ? .green.opacity(0.15) : .red.opacity(0.15))
                    .frame(width: 120, height: 120)

                Image(systemName: "airpodspro")
                    .font(.system(size: 48))
                    .foregroundStyle(isConnected ? .green : .red.opacity(0.7))
                    .symbolEffect(.pulse, isActive: !isConnected)
            }
            .padding(.bottom, 24)
            .accessibilityLabel(isConnected ? loc.t("airpods_connected") : loc.t("put_airpods"))

            Text(isConnected ? loc.t("airpods_connected") : loc.t("put_airpods"))
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.bottom, 8)

            Text(isConnected
                 ? loc.t("airpods_subtitle_connected")
                 : loc.t("airpods_subtitle"))
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.bottom, 32)

            VStack(alignment: .leading, spacing: 10) {
                Text(loc.t("supported_models"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.4))

                ForEach(supportedModels, id: \.self) { model in
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.3))
                        Text(model)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(.regular, in: .rect(cornerRadius: 16))
            .padding(.horizontal, 32)

            Spacer()

            Button(action: onContinue) {
                HStack(spacing: 10) {
                    Text(isConnected ? loc.t("next") : loc.t("skip"))
                        .font(.headline)
                    Image(systemName: "arrow.right")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(isConnected ? .white : .white.opacity(0.5))
                .padding(.horizontal, 48)
                .padding(.vertical, 16)
            }
            .glassEffect(isConnected ? .regular : .clear, in: .capsule)
            .padding(.bottom, 60)
        }
        .onAppear {
            checkAirPods()
            pollTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
                checkAirPods()
            }
        }
        .onDisappear {
            pollTimer?.invalidate()
            pollTimer = nil
        }
        .onReceive(
            NotificationCenter.default.publisher(for: AVAudioSession.routeChangeNotification)
        ) { _ in
            checkAirPods()
        }
    }

    private func checkAirPods() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, options: [.allowBluetooth, .allowBluetoothA2DP])
        try? session.setActive(true)

        let outputs = session.currentRoute.outputs
        let connected = outputs.contains {
            $0.portType == .bluetoothA2DP || $0.portType == .bluetoothHFP
        }
        if connected != isConnected {
            withAnimation(.easeInOut(duration: 0.4)) {
                isConnected = connected
            }
        }
    }
}

#Preview {
    ZStack {
        BreathingBackground()
        AirPodsCheckView(onContinue: {})
    }
    .preferredColorScheme(.dark)
}
