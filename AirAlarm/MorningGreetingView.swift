import SwiftUI

// MARK: - Morning Greeting View

struct MorningGreetingView: View {
    let cycles: Int
    let onDismiss: () -> Void
    @Environment(LocalizationManager.self) private var loc

    @State private var sunRisen = false
    @State private var glowPulse = false
    @State private var backgroundWarm = false
    @State private var quoteIndex = Int.random(in: 1...8)
    @State private var dismissed = false

    var body: some View {
        ZStack {
            // Animated gradient background: night → dawn
            sunriseBackground

            // Light rays from sun
            sunRays
                .opacity(sunRisen ? 0.25 : 0)

            // Floating particles
            ParticleField()
                .opacity(sunRisen ? 1 : 0)

            // Sun with glow
            sunWithGlow
                .offset(y: sunRisen ? 40 : 200)
                .opacity(sunRisen ? 1 : 0)

            // Content overlay
            VStack(spacing: 0) {
                Spacer()

                // Current time
                Text(Date(), style: .time)
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .opacity(sunRisen ? 1 : 0)

                // Sleep duration
                Text("\(loc.t("you_slept")) \(SleepCycleCalculator.formatDuration(cycles: cycles))")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.top, 8)
                    .opacity(sunRisen ? 1 : 0)

                Spacer()

                // Random warm quote
                Text(loc.t("morning_quote_\(quoteIndex)"))
                    .font(.body.italic())
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .opacity(sunRisen ? 1 : 0)

                Spacer()

                // Tap hint
                Text(loc.t("tap_new_day"))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.3))
                    .padding(.bottom, 50)
                    .opacity(sunRisen ? 1 : 0)
            }
        }
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .onTapGesture {
            guard !dismissed else { return }
            dismissed = true
            onDismiss()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 2.0)) {
                sunRisen = true
                backgroundWarm = true
            }
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true).delay(1.5)) {
                glowPulse = true
            }
        }
    }

    // MARK: - Sunrise Background

    private var sunriseBackground: some View {
        LinearGradient(
            colors: backgroundWarm
                ? [Color(red: 0.45, green: 0.70, blue: 0.92),  // light blue sky
                   Color(red: 0.55, green: 0.78, blue: 0.95),  // soft sky
                   Color(red: 0.85, green: 0.65, blue: 0.40),  // warm horizon
                   Color(red: 0.95, green: 0.55, blue: 0.20)]  // golden bottom
                : [Color(red: 0.03, green: 0.03, blue: 0.10),
                   Color(red: 0.04, green: 0.04, blue: 0.14),
                   Color(red: 0.05, green: 0.05, blue: 0.16),
                   Color(red: 0.06, green: 0.06, blue: 0.18)],
            startPoint: .top,
            endPoint: .bottom
        )
        .animation(.easeOut(duration: 3.0), value: backgroundWarm)
    }

    // MARK: - Sun with Glow

    private var sunWithGlow: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.orange.opacity(0.3),
                            Color.yellow.opacity(0.1),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 30,
                        endRadius: 180
                    )
                )
                .frame(width: 360, height: 360)
                .scaleEffect(glowPulse ? 1.3 : 1.0)

            // Inner glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.6),
                            Color.yellow.opacity(0.4),
                            Color.orange.opacity(0.1),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)
                .scaleEffect(glowPulse ? 1.15 : 1.0)

            // Sun core
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white, Color(red: 1.0, green: 0.85, blue: 0.4)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 30
                    )
                )
                .frame(width: 50, height: 50)
        }
    }

    // MARK: - Sun Rays

    private var sunRays: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2 + 40)
            ZStack {
                ForEach(0..<12, id: \.self) { i in
                    let angle = Double(i) * 30 - 90
                    let radians = angle * .pi / 180
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.yellow.opacity(0.4), Color.clear],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(width: 2, height: geo.size.height * 0.4)
                        .rotationEffect(.degrees(angle))
                        .position(x: center.x + CGFloat(cos(radians)) * 60,
                                  y: center.y + CGFloat(sin(radians)) * 60)
                }
            }
        }
    }
}

// MARK: - Particle Field

private struct ParticleField: View {
    private let particleCount = 25

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                for i in 0..<particleCount {
                    let seed = Double(i) * 137.508 // golden angle
                    let speed = 0.3 + (seed.truncatingRemainder(dividingBy: 1.0)) * 0.4
                    let x = (sin(seed * 3.14 + time * 0.2) * 0.4 + 0.5) * size.width
                        + sin(time * speed + seed) * 20
                    let rawY = (time * speed * 15 + seed * 50)
                        .truncatingRemainder(dividingBy: size.height)
                    let y = size.height - rawY
                    let alpha = 0.2 + sin(time * 2 + seed) * 0.15
                    let radius = 1.5 + sin(seed) * 1.0

                    let rect = CGRect(
                        x: x - radius,
                        y: y - radius,
                        width: radius * 2,
                        height: radius * 2
                    )
                    context.fill(
                        Circle().path(in: rect),
                        with: .color(.white.opacity(alpha))
                    )
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    MorningGreetingView(cycles: 5, onDismiss: {})
        .environment(LocalizationManager())
}
