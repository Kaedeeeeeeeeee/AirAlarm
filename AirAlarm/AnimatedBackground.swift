import SwiftUI

struct BreathingBackground: View {
    @State private var glowScale: CGFloat = 1.0
    @State private var glowOpacity: CGFloat = 0.12

    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.04, blue: 0.12)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white.opacity(glowOpacity), .clear],
                        center: .center,
                        startRadius: 20,
                        endRadius: 280
                    )
                )
                .scaleEffect(glowScale)
                .blur(radius: 50)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                glowScale = 1.25
                glowOpacity = 0.22
            }
        }
    }
}

#Preview {
    BreathingBackground()
        .preferredColorScheme(.dark)
}
