import SwiftUI

struct AlarmRingingView: View {
    let cycles: Int
    let onDismiss: () -> Void
    let onSnooze: () -> Void
    @Environment(LocalizationManager.self) private var loc

    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Text(Date(), style: .time)
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.bottom, 8)

            Text("\(loc.t("you_slept")) \(SleepCycleCalculator.formatDuration(cycles: cycles))")
                .font(.title3.weight(.medium))
                .foregroundStyle(.white.opacity(0.5))

            Spacer()

            Button(action: onDismiss) {
                VStack(spacing: 16) {
                    Image(systemName: "sunrise.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(.yellow)

                    Text(loc.t("good_morning"))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 48)
                .glassEffect(.regular, in: .rect(cornerRadius: 28))
            }
            .scaleEffect(pulseScale)
            .padding(.horizontal, 32)

            Button(action: onSnooze) {
                HStack(spacing: 8) {
                    Image(systemName: "moon.zzz")
                        .font(.subheadline)
                    Text(loc.t("snooze"))
                        .font(.subheadline.weight(.medium))
                }
                .foregroundStyle(.white.opacity(0.5))
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
            }
            .glassEffect(.clear, in: .capsule)
            .padding(.top, 20)

            Spacer()

            Text(loc.t("tap_dismiss"))
                .font(.caption)
                .foregroundStyle(.white.opacity(0.3))
                .padding(.bottom, 40)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseScale = 1.04
            }
        }
    }
}

#Preview {
    ZStack {
        BreathingBackground()
        AlarmRingingView(cycles: 4, onDismiss: {}, onSnooze: {})
    }
    .environment(LocalizationManager())
    .preferredColorScheme(.dark)
}
