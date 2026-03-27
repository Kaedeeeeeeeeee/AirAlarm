import SwiftUI

struct AlarmRingingView: View {
    let cycles: Int
    let onDismiss: () -> Void

    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Current time
            Text(Date(), style: .time)
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.bottom, 8)

            // Sleep summary
            Text("You slept \(SleepCycleCalculator.formatDuration(cycles: cycles))")
                .font(.title3.weight(.medium))
                .foregroundStyle(.white.opacity(0.5))

            Spacer()

            // Big dismiss button
            Button(action: onDismiss) {
                VStack(spacing: 16) {
                    Image(systemName: "sunrise.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(.yellow)

                    Text("Good Morning")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 48)
                .glassEffect(.regular, in: .rect(cornerRadius: 28))
            }
            .scaleEffect(pulseScale)
            .padding(.horizontal, 32)

            Spacer()

            Text("Tap to dismiss")
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
        AlarmRingingView(cycles: 4, onDismiss: {})
    }
    .preferredColorScheme(.dark)
}
