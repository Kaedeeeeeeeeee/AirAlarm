import SwiftUI

struct WelcomeView: View {
    let onContinue: () -> Void

    @Environment(LocalizationManager.self) private var loc
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Image(systemName: "moon.stars.fill")
                .font(.system(size: 72))
                .foregroundStyle(.white.opacity(0.8))
                .symbolEffect(.pulse, isActive: appeared)
                .padding(.bottom, 24)

            Text(loc.t("ready_sleep"))
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.bottom, 12)

            Text(loc.t("ready_subtitle"))
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 40)

            Spacer()

            Button(action: onContinue) {
                HStack(spacing: 10) {
                    Text(loc.t("lets_go"))
                        .font(.headline)
                    Image(systemName: "arrow.right")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 48)
                .padding(.vertical, 16)
            }
            .glass(.regular, in: .capsule)
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
