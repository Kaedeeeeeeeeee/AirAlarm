import SwiftUI
import UIKit

struct ClockDialView: View {
    @Binding var wakeWindowStart: Date
    let appState: AppState
    let sleepTime: Date?
    let wakeTime: Date?
    let scheduledCycles: Int
    let onTapCenter: () -> Void

    // Fixed 90-minute window
    private let windowDuration: TimeInterval = 90 * 60

    // Drag state
    @State private var isDragging = false
    @State private var dragStartOffset: Double = 0
    @State private var dragStartAngle: Double = 0

    // Breathing animation
    @State private var breathScale: CGFloat = 1.0

    // Haptic
    @State private var lastSnappedMinute: Int = -1

    // MARK: - Layout Constants

    private let trackLineWidth: CGFloat = 40
    private let arcLineWidth: CGFloat = 40
    private let handleSize: CGFloat = 38
    private let hourLabelInset: CGFloat = 24

    // Computed end time
    private var wakeWindowEnd: Date {
        wakeWindowStart.addingTimeInterval(windowDuration)
    }

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let trackRadius = (size - trackLineWidth) / 2 - hourLabelInset

            ZStack {
                backgroundTrack(center: center, radius: trackRadius)
                wakeWindowArc(center: center, radius: trackRadius)

                if let sleepTime, appState == .alarmSet {
                    cycleDots(center: center, radius: trackRadius, sleepTime: sleepTime)
                }

                hourLabels(center: center, radius: trackRadius + trackLineWidth / 2 + 16)
                centerContent(center: center, radius: trackRadius * 0.45)

                if appState == .idle || appState == .playingNoise {
                    arcTimeLabels(center: center, radius: trackRadius)
                }

                if appState == .alarmSet {
                    sleepWakeMarkers(center: center, radius: trackRadius)
                }
            }
            .contentShape(Circle())
            .gesture(arcDragGesture(center: center, radius: trackRadius))
            .scaleEffect(breathScale)
            .onChange(of: appState) { _, newState in
                withAnimation(
                    newState == .playingNoise
                        ? .easeInOut(duration: 4).repeatForever(autoreverses: true)
                        : .easeInOut(duration: 0.5)
                ) {
                    breathScale = newState == .playingNoise ? 1.03 : 1.0
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    // MARK: - Background Track

    private func backgroundTrack(center: CGPoint, radius: CGFloat) -> some View {
        Circle()
            .stroke(.white.opacity(0.08), lineWidth: trackLineWidth)
            .frame(width: radius * 2, height: radius * 2)
            .position(center)
    }

    // MARK: - Wake Window Arc (fixed 90-min)

    private func wakeWindowArc(center: CGPoint, radius: CGFloat) -> some View {
        let startAngle = angle(for: wakeWindowStart)
        let endAngle = angle(for: wakeWindowEnd)

        return ZStack {
            // Outer glow
            Path { p in
                p.addArc(center: center, radius: radius,
                         startAngle: .radians(startAngle), endAngle: .radians(endAngle), clockwise: false)
            }
            .stroke(.white.opacity(0.06), style: StrokeStyle(lineWidth: arcLineWidth + 12, lineCap: .round))
            .blur(radius: 6)

            // Main arc
            Path { p in
                p.addArc(center: center, radius: radius,
                         startAngle: .radians(startAngle), endAngle: .radians(endAngle), clockwise: false)
            }
            .stroke(.white.opacity(0.22), style: StrokeStyle(lineWidth: arcLineWidth, lineCap: .round))

            // Inner highlight
            Path { p in
                p.addArc(center: center, radius: radius,
                         startAngle: .radians(startAngle), endAngle: .radians(endAngle), clockwise: false)
            }
            .stroke(.white.opacity(0.12), style: StrokeStyle(lineWidth: arcLineWidth - 12, lineCap: .round))
        }
    }

    // MARK: - Arc Time Labels

    private func arcTimeLabels(center: CGPoint, radius: CGFloat) -> some View {
        let startAngle = angle(for: wakeWindowStart)
        let endAngle = angle(for: wakeWindowEnd)
        let innerR = radius - trackLineWidth / 2 - 24

        return ZStack {
            // Start time label
            Text(formatShortTime(wakeWindowStart))
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))
                .position(point(at: startAngle, radius: innerR, center: center))

            // End time label
            Text(formatShortTime(wakeWindowEnd))
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))
                .position(point(at: endAngle, radius: innerR, center: center))
        }
    }

    // MARK: - Cycle Dots

    private func cycleDots(center: CGPoint, radius: CGFloat, sleepTime: Date) -> some View {
        let cycles = SleepCycleCalculator.allCycleTimes(from: sleepTime)
        let startAngle = angle(for: wakeWindowStart)
        let endAngle = angle(for: wakeWindowEnd)

        return ZStack {
            ForEach(cycles, id: \.cycles) { cycle in
                let cycleAngle = angle(for: cycle.date)
                if isAngleBetween(cycleAngle, start: startAngle, end: endAngle) {
                    let pos = point(at: cycleAngle, radius: radius, center: center)
                    Circle()
                        .fill(.white.opacity(0.9))
                        .frame(width: 8, height: 8)
                        .shadow(color: .white.opacity(0.5), radius: 4)
                        .position(pos)
                }
            }
        }
    }

    // MARK: - Sleep & Wake Markers

    private func sleepWakeMarkers(center: CGPoint, radius: CGFloat) -> some View {
        ZStack {
            if let sleepTime {
                let pos = point(at: angle(for: sleepTime), radius: radius, center: center)
                ZStack {
                    Circle().fill(.indigo).frame(width: handleSize, height: handleSize)
                    Image(systemName: "moon.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .position(pos)
            }
            if let wakeTime {
                let pos = point(at: angle(for: wakeTime), radius: radius, center: center)
                ZStack {
                    Circle().fill(.orange).frame(width: handleSize, height: handleSize)
                    Image(systemName: "bell.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .position(pos)
            }
        }
    }

    // MARK: - Hour Labels

    private func hourLabels(center: CGPoint, radius: CGFloat) -> some View {
        ZStack {
            ForEach(0..<12, id: \.self) { i in
                let a = Double(i) * .pi / 6 - .pi / 2
                let pos = point(at: a, radius: radius, center: center)
                let hour = i == 0 ? 12 : i
                Text("\(hour)")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.4))
                    .position(pos)
            }
        }
    }

    // MARK: - Center Content

    private func centerContent(center: CGPoint, radius: CGFloat) -> some View {
        Button(action: onTapCenter) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: radius * 2, height: radius * 2)

                switch appState {
                case .idle:
                    VStack(spacing: 8) {
                        Image(systemName: "play.fill").font(.system(size: 32))
                        Text("Start").font(.system(size: 14, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(.white)

                case .playingNoise:
                    waveformAnimation

                case .sleepDetected:
                    VStack(spacing: 6) {
                        Image(systemName: "bed.double.fill").font(.system(size: 24))
                        Text("Detecting...").font(.system(size: 11, weight: .medium, design: .rounded))
                    }
                    .foregroundStyle(.purple)

                case .alarmSet:
                    VStack(spacing: 4) {
                        if let wakeTime {
                            Text(wakeTime, style: .time)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                            Text("\(scheduledCycles) cycles")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                    .foregroundStyle(.white)
                }
            }
        }
        .buttonStyle(.plain)
        .position(center)
    }

    private var waveformAnimation: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            HStack(spacing: 5) {
                ForEach(0..<5, id: \.self) { i in
                    let phase = time * 2.5 + Double(i) * 0.6
                    let height = 14.0 + 18.0 * abs(sin(phase))
                    Capsule().fill(.white.opacity(0.8)).frame(width: 5, height: height)
                }
            }
        }
    }

    // MARK: - Drag Gesture (single arc drag)

    private func arcDragGesture(center: CGPoint, radius: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard appState == .idle else { return }

                let dx = value.location.x - center.x
                let dy = value.location.y - center.y
                let currentAngle = atan2(dy, dx)

                if !isDragging {
                    let startDx = value.startLocation.x - center.x
                    let startDy = value.startLocation.y - center.y
                    let dist = hypot(startDx, startDy)

                    let innerBound = radius - trackLineWidth
                    let outerBound = radius + trackLineWidth
                    guard dist > innerBound && dist < outerBound else { return }

                    let tapAngle = atan2(startDy, startDx)
                    let startA = angle(for: wakeWindowStart)
                    let endA = angle(for: wakeWindowEnd)

                    guard isAngleBetween(tapAngle, start: startA, end: endA) else { return }

                    isDragging = true
                    dragStartOffset = tapAngle
                    dragStartAngle = startA
                    triggerHaptic()
                }

                let delta = currentAngle - dragStartOffset
                let newStartAngle = dragStartAngle + delta
                let newDate = snapToDate(from: newStartAngle)

                if newDate != wakeWindowStart {
                    withAnimation(.interactiveSpring) {
                        wakeWindowStart = newDate
                    }
                    hapticOnSnap(newDate)
                }
            }
            .onEnded { _ in
                isDragging = false
            }
    }

    // MARK: - Haptic

    private func hapticOnSnap(_ date: Date) {
        let cal = Calendar.current
        let total = cal.component(.hour, from: date) * 60 + cal.component(.minute, from: date)
        if total != lastSnappedMinute {
            lastSnappedMinute = total
            triggerHaptic()
        }
    }

    private func triggerHaptic() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    // MARK: - Angle/Time Conversion

    private func angle(for date: Date) -> Double {
        let cal = Calendar.current
        let hour = cal.component(.hour, from: date) % 12
        let minute = cal.component(.minute, from: date)
        let fraction = Double(hour * 60 + minute) / 720.0
        return fraction * 2 * .pi - .pi / 2
    }

    private func snapToDate(from angle: Double) -> Date {
        var n = angle + .pi / 2
        if n < 0 { n += 2 * .pi }
        while n >= 2 * .pi { n -= 2 * .pi }
        let totalMinutes = Int(n / (2 * .pi) * 720)
        let snapped = (totalMinutes / 5) * 5
        let hour = (snapped / 60) % 12
        let minute = snapped % 60
        return Calendar.current.date(
            bySettingHour: hour, minute: minute, second: 0, of: Date()
        ) ?? Date()
    }

    private func point(at angle: Double, radius: CGFloat, center: CGPoint) -> CGPoint {
        CGPoint(x: center.x + radius * CGFloat(cos(angle)),
                y: center.y + radius * CGFloat(sin(angle)))
    }

    private func isAngleBetween(_ angle: Double, start: Double, end: Double) -> Bool {
        var a = angle - start
        var span = end - start
        if span < 0 { span += 2 * .pi }
        if a < 0 { a += 2 * .pi }
        return a <= span
    }

    private func formatShortTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "H:mm"
        return f.string(from: date)
    }
}
