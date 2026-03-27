import WidgetKit
import SwiftUI

// MARK: - Shared Data Keys

enum WidgetDataKeys {
    static let suiteName = "group.airalarm"
    static let lastSleepDuration = "lastSleepDuration"
    static let lastSleepCycles = "lastSleepCycles"
    static let lastSleepDate = "lastSleepDate"
}

// MARK: - Timeline Entry

struct SleepEntry: TimelineEntry {
    let date: Date
    let sleepDuration: String?
    let cycles: Int?
    let sleepDate: Date?
}

// MARK: - Timeline Provider

struct SleepTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> SleepEntry {
        SleepEntry(date: .now, sleepDuration: "7h 30m", cycles: 5, sleepDate: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (SleepEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SleepEntry>) -> Void) {
        let entry = currentEntry()
        // Refresh every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func currentEntry() -> SleepEntry {
        let defaults = UserDefaults(suiteName: WidgetDataKeys.suiteName)
        let duration = defaults?.string(forKey: WidgetDataKeys.lastSleepDuration)
        let cycles = defaults?.integer(forKey: WidgetDataKeys.lastSleepCycles)
        let sleepDate = defaults?.object(forKey: WidgetDataKeys.lastSleepDate) as? Date

        return SleepEntry(
            date: .now,
            sleepDuration: duration,
            cycles: cycles == 0 ? nil : cycles,
            sleepDate: sleepDate
        )
    }
}

// MARK: - Small Widget View

struct SmallWidgetView: View {
    let entry: SleepEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "moon.zzz.fill")
                    .font(.caption)
                    .foregroundStyle(.purple)
                Text("AirAlarm")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.6))
            }

            if let duration = entry.sleepDuration, let cycles = entry.cycles {
                Text(duration)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("\(cycles) cycles")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))

                if let date = entry.sleepDate {
                    Text(date, style: .date)
                        .font(.system(size: 9))
                        .foregroundStyle(.white.opacity(0.3))
                }
            } else {
                Spacer()
                Text("No sleep data yet")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(4)
    }
}

// MARK: - Lock Screen Widget View

struct LockScreenWidgetView: View {
    let entry: SleepEntry

    var body: some View {
        if let duration = entry.sleepDuration, let cycles = entry.cycles {
            HStack(spacing: 6) {
                Image(systemName: "moon.zzz.fill")
                    .font(.caption)
                Text("Slept \(duration) · \(cycles) cycles")
                    .font(.caption)
            }
        } else {
            HStack(spacing: 6) {
                Image(systemName: "moon.zzz.fill")
                    .font(.caption)
                Text("AirAlarm")
                    .font(.caption)
            }
        }
    }
}

// MARK: - Widget Definition

struct AirAlarmWidget: Widget {
    let kind = "AirAlarmWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SleepTimelineProvider()) { entry in
            SmallWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Sleep Summary")
        .description("Shows your last sleep session")
        .supportedFamilies([.systemSmall, .accessoryRectangular])
    }
}
