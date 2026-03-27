import SwiftUI

struct OnboardingView: View {
    let onFinish: () -> Void

    @Environment(LocalizationManager.self) private var loc
    @State private var currentPage = 0

    var body: some View {
        ZStack {
            // Background
            BreathingBackground()

            VStack(spacing: 0) {
                // Pages
                TabView(selection: $currentPage) {
                    SleepCyclePage(loc: loc).tag(0)
                    AirPodsPage(loc: loc).tag(1)
                    WakeWindowPage(loc: loc).tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))

                // Button
                Button {
                    if currentPage < 2 {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentPage += 1
                        }
                    } else {
                        onFinish()
                    }
                } label: {
                    Text(currentPage < 2 ? loc.t("next") : loc.t("get_started"))
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .glassEffect(.regular, in: .rect(cornerRadius: 16))
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Page 1: Sleep Cycles

private struct SleepCyclePage: View {
    let loc: LocalizationManager
    @State private var waveProgress: CGFloat = 0
    @State private var showMarker = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Wave animation
            ZStack(alignment: .topLeading) {
                // Wave path
                SleepWavePath()
                    .trim(from: 0, to: waveProgress)
                    .stroke(.white.opacity(0.6), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .frame(width: 300, height: 120)

                // "90 min" labels — centered under each cycle
                if waveProgress > 0.3 {
                    ForEach(0..<4, id: \.self) { i in
                        Text(loc.t("ninety_min"))
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.white.opacity(0.3))
                            .position(x: CGFloat(37.5 + Double(i) * 75), y: 110)
                            .transition(.opacity)
                    }
                }

                // Best wake marker — at 3rd wave peak (top = light sleep = end of cycle)
                // Wave peaks (negative amplitude) are at x positions: cycle * 0.25 of width
                // 3rd peak is at x = (2.75/4) * 300 = 206, y = midY - amplitude = 48 - 42 = 6
                if showMarker {
                    VStack(spacing: 2) {
                        Text(loc.t("best_wake_time"))
                            .font(.system(size: 8, weight: .medium))
                            .foregroundStyle(.yellow.opacity(0.8))
                        Image(systemName: "star.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.yellow)
                    }
                    .position(x: 206, y: 12)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(width: 300, height: 130)
            .onAppear {
                withAnimation(.easeInOut(duration: 2.5)) {
                    waveProgress = 1.0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.spring(duration: 0.5)) {
                        showMarker = true
                    }
                }
            }

            VStack(spacing: 12) {
                Text(loc.t("onboarding_title_1"))
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(loc.t("onboarding_desc_1"))
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
    }
}

// MARK: - Sleep Wave Shape

private struct SleepWavePath: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let midY = h * 0.5
        let amplitude = h * 0.35

        path.move(to: CGPoint(x: 0, y: midY))

        // 4 complete sine wave cycles
        // Positive sin = DOWN (deep sleep), negative sin = UP (light sleep / peak = best wake)
        for x in stride(from: 0, through: w, by: 1) {
            let progress = x / w
            let y = midY + amplitude * sin(progress * 4 * 2 * .pi)
            path.addLine(to: CGPoint(x: x, y: y))
        }

        return path
    }
}

// MARK: - Page 2: AirPods Detection

private struct AirPodsPage: View {
    let loc: LocalizationManager
    @State private var phase = 0

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Animation area
            ZStack {
                // AirPods icon
                Image(systemName: "airpodspro")
                    .font(.system(size: 64))
                    .foregroundStyle(.white.opacity(phase >= 0 ? 0.8 : 0))
                    .scaleEffect(phase >= 0 ? 1 : 0.5)

                // Sound waves
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(.white.opacity(phase == 1 ? 0.3 - Double(i) * 0.1 : 0), lineWidth: 1.5)
                        .frame(width: CGFloat(100 + i * 30), height: CGFloat(100 + i * 30))
                        .scaleEffect(phase == 1 ? 1 : 0.8)
                }

                // Moon (sleep detected)
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.purple.opacity(0.8))
                    .offset(x: 50, y: -40)
                    .scaleEffect(phase >= 3 ? 1 : 0)
                    .opacity(phase >= 3 ? 1 : 0)
            }
            .frame(height: 160)
            .onAppear { runSequence() }

            VStack(spacing: 12) {
                Text(loc.t("onboarding_title_2"))
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(loc.t("onboarding_desc_2"))
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
    }

    private func runSequence() {
        withAnimation(.easeOut(duration: 0.6)) { phase = 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.8)) { phase = 2 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.spring(duration: 0.6)) { phase = 3 }
        }
    }
}

// MARK: - Page 3: Wake Window

private struct WakeWindowPage: View {
    let loc: LocalizationManager
    @State private var arcRotation: Double = 0

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Mini clock preview
            ZStack {
                // Track
                Circle()
                    .stroke(.white.opacity(0.08), lineWidth: 24)
                    .frame(width: 160, height: 160)

                // Arc — fixed position, rotated as a group
                ZStack {
                    // Main arc
                    Path { p in
                        p.addArc(
                            center: CGPoint(x: 80, y: 80),
                            radius: 80,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(-45),
                            clockwise: false
                        )
                    }
                    .stroke(.white.opacity(0.25), style: StrokeStyle(lineWidth: 24, lineCap: .round))

                    // Inner highlight
                    Path { p in
                        p.addArc(
                            center: CGPoint(x: 80, y: 80),
                            radius: 80,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(-45),
                            clockwise: false
                        )
                    }
                    .stroke(.white.opacity(0.12), style: StrokeStyle(lineWidth: 14, lineCap: .round))
                }
                .frame(width: 160, height: 160)
                .rotationEffect(.degrees(arcRotation))

                // "90 min" in center (doesn't rotate)
                Text(loc.t("ninety_min"))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .frame(height: 180)
            .onAppear {
                withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                    arcRotation = 200
                }
            }

            VStack(spacing: 12) {
                Text(loc.t("onboarding_title_3"))
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(loc.t("onboarding_desc_3"))
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
    }
}

#Preview {
    OnboardingView(onFinish: {})
}
