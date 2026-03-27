import WidgetKit
import SwiftUI

// MARK: - Shared Data Keys

enum WidgetDataKeys {
    static let suiteName = "group.com.zhangshifeng.airalarm"
    static let lastSleepDuration = "lastSleepDuration"
    static let lastSleepCycles = "lastSleepCycles"
    static let lastSleepDate = "lastSleepDate"
}

// MARK: - Widget Localization

enum WidgetL10n {
    private static var lang: String {
        UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
    }

    private static let strings: [String: [String: String]] = [
        "cycles": ["en": "cycles", "zh": "个周期", "ja": "サイクル"],
        "no_data": ["en": "No sleep data yet", "zh": "暂无睡眠数据", "ja": "睡眠データなし"],
        "slept": ["en": "Slept", "zh": "睡了", "ja": "睡眠"],
        "sleep_summary": ["en": "Sleep Summary", "zh": "睡眠摘要", "ja": "睡眠サマリー"],
        "description": ["en": "Shows your last sleep session", "zh": "显示你最近的睡眠记录", "ja": "最新の睡眠セッションを表示"],
    ]

    static func t(_ key: String) -> String {
        strings[key]?[lang] ?? strings[key]?["en"] ?? key
    }
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

                Text("\(cycles) \(WidgetL10n.t("cycles"))")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))

                if let date = entry.sleepDate {
                    Text(date, style: .date)
                        .font(.system(size: 9))
                        .foregroundStyle(.white.opacity(0.3))
                }
            } else {
                Spacer()
                Text(WidgetL10n.t("no_data"))
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
                Text("\(WidgetL10n.t("slept")) \(duration) · \(cycles) \(WidgetL10n.t("cycles"))")
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
        .configurationDisplayName(WidgetL10n.t("sleep_summary"))
        .description(WidgetL10n.t("description"))
        .supportedFamilies([.systemSmall, .accessoryRectangular])
    }
}
