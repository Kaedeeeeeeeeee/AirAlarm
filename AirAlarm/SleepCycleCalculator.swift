import Foundation

struct SleepCycleCalculator {
    static let cycleDuration: TimeInterval = 90 * 60 // 90 minutes in seconds

    static func optimalWakeTime(
        sleepTime: Date,
        earliestWake: Date,
        latestWake: Date
    ) -> (wakeTime: Date, cycles: Int)? {
        // Calculate all possible wake times based on 90-min cycles
        var candidates: [(wakeTime: Date, cycles: Int)] = []

        for cycleCount in 1...8 { // Max 8 cycles = 12 hours
            let wakeTime = sleepTime.addingTimeInterval(cycleDuration * Double(cycleCount))

            if wakeTime >= earliestWake && wakeTime <= latestWake {
                candidates.append((wakeTime, cycleCount))
            }
        }

        // Prefer the wake time closest to the latest allowed time (more sleep)
        return candidates.last
    }

    static func allCycleTimes(from sleepTime: Date, count: Int = 8) -> [(date: Date, cycles: Int)] {
        (1...count).map { cycle in
            (sleepTime.addingTimeInterval(cycleDuration * Double(cycle)), cycle)
        }
    }

    static func formatDuration(cycles: Int) -> String {
        let totalMinutes = cycles * 90
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if minutes == 0 {
            return "\(hours) hours"
        }
        return "\(hours)h \(minutes)m"
    }
}
