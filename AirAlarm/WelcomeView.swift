import SwiftUI

struct WelcomeView: View {
    let onContinue: () -> Void

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Image(systemName: "moon.stars.fill")
                .font(.system(size: 72))
                .foregroundStyle(.white.opacity(0.8))
                .symbolEffect(.breathe, isActive: appeared)
                .padding(.bottom, 24)

            Text("Ready to Sleep?")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.bottom, 12)

            Text("AirAlarm will play soothing sounds\nand wake you at the perfect moment\nin your sleep cycle.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 40)

            Spacer()

            Button(action: onContinue) {
                HStack(spacing: 10) {
                    Text("Let's Go")
                        .font(.headline)
                    Image(systemName: "arrow.right")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 48)
                .padding(.vertical, 16)
            }
            .glassEffect(.regular, in: .capsule)
            .padding(.bottom, 60)
        }
        .onAppear { appeared = true }
    }
}

#Preview {
    ZStack {
        BreathingBackground()
        WelcomeView(onContinue: {})
    }
    .preferredColorScheme(.dark)
}
