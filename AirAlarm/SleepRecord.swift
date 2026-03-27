import SwiftData
import Foundation

@Model
class SleepRecord {
    var sleepTime: Date
    var wakeTime: Date
    var cycles: Int
    var noiseType: String
    var date: Date

    init(sleepTime: Date, wakeTime: Date, cycles: Int, noiseType: String) {
        self.sleepTime = sleepTime
        self.wakeTime = wakeTime
        self.cycles = cycles
        self.noiseType = noiseType
        self.date = Calendar.current.startOfDay(for: wakeTime)
    }

    var duration: TimeInterval {
        wakeTime.timeIntervalSince(sleepTime)
    }

    var durationText: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if minutes == 0 { return "\(hours)h" }
        return "\(hours)h \(minutes)m"
    }
}
