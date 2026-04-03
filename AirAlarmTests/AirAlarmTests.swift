import Testing
import Foundation
import SwiftData
@testable import AirAlarm

// MARK: - SleepCycleCalculator Tests

struct SleepCycleCalculatorTests {

    // MARK: - optimalWakeTime

    @Test func optimalWakeTime_multipleCyclesInWindow_returnsLatest() {
        let sleepTime = makeDate(hour: 23, minute: 0)
        // Cycles: 0:30, 2:00, 3:30, 5:00, 6:30, 8:00
        let earliest = makeDate(hour: 5, minute: 0, dayOffset: 1)
        let latest = makeDate(hour: 8, minute: 0, dayOffset: 1)

        let result = SleepCycleCalculator.optimalWakeTime(
            sleepTime: sleepTime, earliestWake: earliest, latestWake: latest
        )

        #expect(result != nil)
        // 5 cycles = 7.5h = 6:30, 6 cycles = 9h = 8:00 — should pick 8:00 (latest)
        #expect(result?.cycles == 6)
        let expected = sleepTime.addingTimeInterval(6 * 90 * 60)
        #expect(result?.wakeTime == expected)
    }

    @Test func optimalWakeTime_singleCycleInWindow() {
        let sleepTime = makeDate(hour: 23, minute: 0)
        // Only cycle 4 (6h = 5:00) falls in window
        let earliest = makeDate(hour: 4, minute: 50, dayOffset: 1)
        let latest = makeDate(hour: 5, minute: 10, dayOffset: 1)

        let result = SleepCycleCalculator.optimalWakeTime(
            sleepTime: sleepTime, earliestWake: earliest, latestWake: latest
        )

        #expect(result != nil)
        #expect(result?.cycles == 4)
    }

    @Test func optimalWakeTime_noCycleInWindow_returnsNil() {
        let sleepTime = makeDate(hour: 23, minute: 0)
        // Window between two cycles: cycle 3 = 3:30, cycle 4 = 5:00
        let earliest = makeDate(hour: 3, minute: 40, dayOffset: 1)
        let latest = makeDate(hour: 4, minute: 50, dayOffset: 1)

        let result = SleepCycleCalculator.optimalWakeTime(
            sleepTime: sleepTime, earliestWake: earliest, latestWake: latest
        )

        #expect(result == nil)
    }

    @Test func optimalWakeTime_cycleExactlyAtWindowEdge() {
        let sleepTime = makeDate(hour: 23, minute: 0)
        // Cycle 4 = 23:00 + 6h = 5:00 next day
        let cycleTime = sleepTime.addingTimeInterval(4 * 90 * 60)
        let earliest = cycleTime // exactly at earliest
        let latest = cycleTime.addingTimeInterval(60) // 1 min after

        let result = SleepCycleCalculator.optimalWakeTime(
            sleepTime: sleepTime, earliestWake: earliest, latestWake: latest
        )

        #expect(result != nil)
        #expect(result?.cycles == 4)
        #expect(result?.wakeTime == cycleTime)
    }

    @Test func optimalWakeTime_cycleExactlyAtLatestEdge() {
        let sleepTime = makeDate(hour: 23, minute: 0)
        let cycleTime = sleepTime.addingTimeInterval(5 * 90 * 60)
        let earliest = cycleTime.addingTimeInterval(-60)
        let latest = cycleTime // exactly at latest

        let result = SleepCycleCalculator.optimalWakeTime(
            sleepTime: sleepTime, earliestWake: earliest, latestWake: latest
        )

        #expect(result != nil)
        #expect(result?.cycles == 5)
    }

    // MARK: - Real-world scenarios

    @Test func optimalWakeTime_sleepAt2350_wake730to900() {
        // Sleep at 23:50, wake window 7:30-9:00
        let sleepTime = makeDate(hour: 23, minute: 50)
        let earliest = makeDate(hour: 7, minute: 30, dayOffset: 1)
        let latest = makeDate(hour: 9, minute: 0, dayOffset: 1)

        let result = SleepCycleCalculator.optimalWakeTime(
            sleepTime: sleepTime, earliestWake: earliest, latestWake: latest
        )

        #expect(result != nil)
        // Cycle 5: 23:50 + 7.5h = 7:20 ❌
        // Cycle 6: 23:50 + 9h = 8:50 ✅
        #expect(result?.cycles == 6)
        let expected = sleepTime.addingTimeInterval(6 * 90 * 60)
        #expect(result?.wakeTime == expected)
    }

    @Test func optimalWakeTime_sleepAt0050_wake730to900() {
        // Sleep at 00:50, wake window 7:30-9:00
        let sleepTime = makeDate(hour: 0, minute: 50)
        let earliest = makeDate(hour: 7, minute: 30)
        let latest = makeDate(hour: 9, minute: 0)

        let result = SleepCycleCalculator.optimalWakeTime(
            sleepTime: sleepTime, earliestWake: earliest, latestWake: latest
        )

        #expect(result != nil)
        // Cycle 4: 00:50 + 6h = 6:50 ❌
        // Cycle 5: 00:50 + 7.5h = 8:20 ✅
        // Cycle 6: 00:50 + 9h = 9:50 ❌
        #expect(result?.cycles == 5)
        let expected = sleepTime.addingTimeInterval(5 * 90 * 60)
        #expect(result?.wakeTime == expected)
    }

    @Test func optimalWakeTime_sleepAt2300_wake700to830() {
        // Sleep at 23:00, wake window 7:00-8:30
        let sleepTime = makeDate(hour: 23, minute: 0)
        let earliest = makeDate(hour: 7, minute: 0, dayOffset: 1)
        let latest = makeDate(hour: 8, minute: 30, dayOffset: 1)

        let result = SleepCycleCalculator.optimalWakeTime(
            sleepTime: sleepTime, earliestWake: earliest, latestWake: latest
        )

        #expect(result != nil)
        // Cycle 5: 23:00 + 7.5h = 6:30 ❌
        // Cycle 6: 23:00 + 9h = 8:00 ✅
        // Cycle 7: 23:00 + 10.5h = 9:30 ❌
        #expect(result?.cycles == 6)
        let expected = sleepTime.addingTimeInterval(6 * 90 * 60)
        #expect(result?.wakeTime == expected)
    }

    @Test func optimalWakeTime_sleepAt0130_wake730to900() {
        // Sleep at 01:30, wake window 7:30-9:00
        let sleepTime = makeDate(hour: 1, minute: 30)
        let earliest = makeDate(hour: 7, minute: 30)
        let latest = makeDate(hour: 9, minute: 0)

        let result = SleepCycleCalculator.optimalWakeTime(
            sleepTime: sleepTime, earliestWake: earliest, latestWake: latest
        )

        #expect(result != nil)
        // Cycle 4: 01:30 + 6h = 7:30 ✅
        // Cycle 5: 01:30 + 7.5h = 9:00 ✅
        #expect(result?.cycles == 5) // should pick latest
        let expected = sleepTime.addingTimeInterval(5 * 90 * 60)
        #expect(result?.wakeTime == expected)
    }

    // MARK: - allCycleTimes

    @Test func allCycleTimes_defaultCount_returns8Cycles() {
        let sleepTime = makeDate(hour: 0, minute: 0)
        let cycles = SleepCycleCalculator.allCycleTimes(from: sleepTime)

        #expect(cycles.count == 8)

        for (index, cycle) in cycles.enumerated() {
            let expectedInterval = Double(index + 1) * 90 * 60
            #expect(cycle.cycles == index + 1)
            #expect(cycle.date.timeIntervalSince(sleepTime) == expectedInterval)
        }
    }

    @Test func allCycleTimes_customCount() {
        let sleepTime = makeDate(hour: 0, minute: 0)
        let cycles = SleepCycleCalculator.allCycleTimes(from: sleepTime, count: 3)

        #expect(cycles.count == 3)
        #expect(cycles[0].cycles == 1)
        #expect(cycles[2].cycles == 3)
    }

    @Test func allCycleTimes_intervalsAre90Minutes() {
        let sleepTime = Date()
        let cycles = SleepCycleCalculator.allCycleTimes(from: sleepTime)

        for i in 1..<cycles.count {
            let interval = cycles[i].date.timeIntervalSince(cycles[i - 1].date)
            #expect(interval == 90 * 60)
        }
    }

    // MARK: - formatDuration

    @Test func formatDuration_wholeHours() {
        // 4 cycles = 360 min = 6 hours
        #expect(SleepCycleCalculator.formatDuration(cycles: 4) == "6 hours")
        // 8 cycles = 720 min = 12 hours
        #expect(SleepCycleCalculator.formatDuration(cycles: 8) == "12 hours")
    }

    @Test func formatDuration_withMinutes() {
        // 1 cycle = 90 min = 1h 30m
        #expect(SleepCycleCalculator.formatDuration(cycles: 1) == "1h 30m")
        // 3 cycles = 270 min = 4h 30m
        #expect(SleepCycleCalculator.formatDuration(cycles: 3) == "4h 30m")
        // 5 cycles = 450 min = 7h 30m
        #expect(SleepCycleCalculator.formatDuration(cycles: 5) == "7h 30m")
    }

    @Test func formatDuration_allCycleCounts() {
        let expected = [
            1: "1h 30m",
            2: "3 hours",
            3: "4h 30m",
            4: "6 hours",
            5: "7h 30m",
            6: "9 hours",
            7: "10h 30m",
            8: "12 hours"
        ]
        for (cycles, text) in expected {
            #expect(SleepCycleCalculator.formatDuration(cycles: cycles) == text)
        }
    }

    // MARK: - cycleDuration constant

    @Test func cycleDuration_is90Minutes() {
        #expect(SleepCycleCalculator.cycleDuration == 5400) // 90 * 60
    }

    // MARK: - Helpers

    private func makeDate(hour: Int, minute: Int, dayOffset: Int = 0) -> Date {
        var cal = Calendar.current
        cal.timeZone = TimeZone.current
        var comps = cal.dateComponents([.year, .month, .day], from: Date())
        comps.hour = hour
        comps.minute = minute
        comps.second = 0
        var date = cal.date(from: comps)!
        if dayOffset != 0 {
            date = cal.date(byAdding: .day, value: dayOffset, to: date)!
        }
        return date
    }
}

// MARK: - WhiteNoiseType Tests

struct WhiteNoiseTypeTests {

    @Test func allCases_containsSevenTypes() {
        #expect(WhiteNoiseType.allCases.count == 7)
    }

    @Test func fileName_mappingsAreCorrect() {
        #expect(WhiteNoiseType.rain.fileName == "rain")
        #expect(WhiteNoiseType.ocean.fileName == "ocean")
        #expect(WhiteNoiseType.forest.fileName == "forest")
        #expect(WhiteNoiseType.fan.fileName == "fan")
        #expect(WhiteNoiseType.pureTone.fileName == "whitenoise")
        #expect(WhiteNoiseType.airplane.fileName == "airplane")
        #expect(WhiteNoiseType.fire.fileName == "fire")
    }

    @Test func rawValue_roundTrip() {
        for noise in WhiteNoiseType.allCases {
            let restored = WhiteNoiseType(rawValue: noise.rawValue)
            #expect(restored == noise)
        }
    }

    @Test func rawValues_areDisplayStrings() {
        #expect(WhiteNoiseType.rain.rawValue == "Rain")
        #expect(WhiteNoiseType.ocean.rawValue == "Ocean")
        #expect(WhiteNoiseType.forest.rawValue == "Forest")
        #expect(WhiteNoiseType.fan.rawValue == "Fan")
        #expect(WhiteNoiseType.pureTone.rawValue == "White Noise")
        #expect(WhiteNoiseType.airplane.rawValue == "Airplane")
        #expect(WhiteNoiseType.fire.rawValue == "Fire")
    }

    @Test func id_matchesRawValue() {
        for noise in WhiteNoiseType.allCases {
            #expect(noise.id == noise.rawValue)
        }
    }
}

// MARK: - SleepAlarmManager Tests

struct SleepAlarmManagerTests {

    @Test func initialState_isCorrect() {
        let manager = SleepAlarmManager()
        #expect(manager.isAlarmScheduled == false)
        #expect(manager.isRinging == false)
        #expect(manager.scheduledWakeTime == nil)
        #expect(manager.scheduledCycles == 0)
        #expect(manager.snoozeCount == 0)
    }

    @Test func cancelAlarm_resetsAllState() {
        let manager = SleepAlarmManager()
        let future = Date().addingTimeInterval(3600)
        manager.scheduleAlarm(at: future, cycles: 5)
        #expect(manager.isAlarmScheduled == true)
        #expect(manager.scheduledCycles == 5)

        manager.cancelAlarm()
        #expect(manager.isAlarmScheduled == false)
        #expect(manager.isRinging == false)
        #expect(manager.scheduledWakeTime == nil)
        #expect(manager.scheduledCycles == 0)
        #expect(manager.snoozeCount == 0)
    }

    @Test func stopRinging_resetsRingingState() {
        let manager = SleepAlarmManager()
        manager.stopRinging()
        #expect(manager.isRinging == false)
    }

    @Test func scheduleAlarm_setsState() {
        let manager = SleepAlarmManager()
        let wakeTime = Date().addingTimeInterval(7200)
        manager.scheduleAlarm(at: wakeTime, cycles: 4)

        #expect(manager.isAlarmScheduled == true)
        #expect(manager.scheduledWakeTime == wakeTime)
        #expect(manager.scheduledCycles == 4)
    }

    @Test func scheduleAlarm_pastTime_doesNotSchedule() {
        let manager = SleepAlarmManager()
        let pastTime = Date().addingTimeInterval(-60)
        manager.scheduleAlarm(at: pastTime, cycles: 3)

        #expect(manager.isAlarmScheduled == false)
    }

    // MARK: - Snooze

    @Test func snooze_incrementsSnoozeCount() {
        let manager = SleepAlarmManager()
        let future = Date().addingTimeInterval(3600)
        manager.scheduleAlarm(at: future, cycles: 4)
        #expect(manager.snoozeCount == 0)

        manager.snooze(minutes: 5)
        #expect(manager.snoozeCount == 1)

        manager.snooze(minutes: 5)
        #expect(manager.snoozeCount == 2)
    }

    @Test func snooze_reschedulesAlarm() {
        let manager = SleepAlarmManager()
        let future = Date().addingTimeInterval(3600)
        manager.scheduleAlarm(at: future, cycles: 4)

        let beforeSnooze = Date()
        manager.snooze(minutes: 5)

        // After snooze, alarm should still be scheduled
        #expect(manager.isAlarmScheduled == true)
        // Cycles should be preserved
        #expect(manager.scheduledCycles == 4)
        // New wake time should be ~5 minutes from now
        if let newWakeTime = manager.scheduledWakeTime {
            let interval = newWakeTime.timeIntervalSince(beforeSnooze)
            #expect(interval > 290) // ~5 min, with small tolerance
            #expect(interval < 310)
        } else {
            Issue.record("scheduledWakeTime should not be nil after snooze")
        }
    }

    @Test func snooze_stopsRinging() {
        let manager = SleepAlarmManager()
        let future = Date().addingTimeInterval(3600)
        manager.scheduleAlarm(at: future, cycles: 4)
        manager.snooze(minutes: 5)
        // stopRinging is called inside snooze, so isRinging should be false
        #expect(manager.isRinging == false)
    }

    @Test func cancelAlarm_resetsSnoozeCount() {
        let manager = SleepAlarmManager()
        let future = Date().addingTimeInterval(3600)
        manager.scheduleAlarm(at: future, cycles: 4)
        manager.snooze(minutes: 5)
        manager.snooze(minutes: 5)
        #expect(manager.snoozeCount == 2)

        manager.cancelAlarm()
        #expect(manager.snoozeCount == 0)
    }

    // MARK: - Ringing lifecycle

    @Test func startRinging_setsIsRinging() {
        let manager = SleepAlarmManager()
        #expect(manager.isRinging == false)
        manager.startRinging()
        #expect(manager.isRinging == true)
    }

    @Test func stopRinging_afterStartRinging_resetsState() {
        let manager = SleepAlarmManager()
        manager.startRinging()
        #expect(manager.isRinging == true)
        manager.stopRinging()
        #expect(manager.isRinging == false)
    }

    @Test func snooze_preservesCycles_incrementsCount() {
        let manager = SleepAlarmManager()
        let future = Date().addingTimeInterval(3600)
        manager.scheduleAlarm(at: future, cycles: 6)
        manager.startRinging()

        manager.snooze(minutes: 10)

        #expect(manager.scheduledCycles == 6) // preserved
        #expect(manager.snoozeCount == 1)
        #expect(manager.isRinging == false) // snooze calls stopRinging
        #expect(manager.isAlarmScheduled == true) // rescheduled
    }

    @Test func scheduleAlarm_thenCancel_doesNotCrash() {
        let manager = SleepAlarmManager()
        let future = Date().addingTimeInterval(3600)
        manager.scheduleAlarm(at: future, cycles: 3)
        manager.cancelAlarm()
        // Calling cancel again should be safe
        manager.cancelAlarm()
        #expect(manager.isAlarmScheduled == false)
    }
}

// MARK: - SleepAlarmMetadata Tests

struct SleepAlarmMetadataTests {

    @Test func init_setsProperties() {
        let meta = SleepAlarmMetadata(cycles: 5, duration: "7h 30m")
        #expect(meta.cycles == 5)
        #expect(meta.duration == "7h 30m")
    }

    @Test func codable_roundTrip() throws {
        let original = SleepAlarmMetadata(cycles: 4, duration: "6 hours")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SleepAlarmMetadata.self, from: data)
        #expect(decoded.cycles == original.cycles)
        #expect(decoded.duration == original.duration)
    }

    @Test func hashable_equalValuesMatch() {
        let a = SleepAlarmMetadata(cycles: 3, duration: "4h 30m")
        let b = SleepAlarmMetadata(cycles: 3, duration: "4h 30m")
        #expect(a == b)
        #expect(a.hashValue == b.hashValue)
    }
}

// MARK: - SnoozeAlarmIntent Tests

struct SnoozeAlarmIntentTests {

    @Test func title_isCorrect() {
        #expect(SnoozeAlarmIntent.title == "Snooze Alarm")
    }

    @Test func canBeInstantiated() {
        let intent = SnoozeAlarmIntent()
        #expect(intent != nil)
    }

    @Test func perform_completesWithoutThrowing() async throws {
        let intent = SnoozeAlarmIntent()
        _ = try await intent.perform()
    }
}

// MARK: - AudioManager Tests

struct AudioManagerTests {

    @Test func initialState_isCorrect() {
        let manager = AudioManager()
        #expect(manager.isPlaying == false)
        #expect(manager.sleepDetected == false)
        #expect(manager.sleepTime == nil)
        #expect(manager.volume == 0.7)
        #expect(manager.isConfirmingSleep == false)
    }

    @Test func stop_resetsAllState() {
        let manager = AudioManager()
        manager.stop()
        #expect(manager.isPlaying == false)
        #expect(manager.isConfirmingSleep == false)
    }

    @Test func setVolume_updatesVolume() {
        let manager = AudioManager()
        manager.setVolume(0.3)
        #expect(manager.volume == 0.3)

        manager.setVolume(1.0)
        #expect(manager.volume == 1.0)

        manager.setVolume(0.0)
        #expect(manager.volume == 0.0)
    }

    @Test func defaultVolume_is0point7() {
        let manager = AudioManager()
        #expect(manager.volume == 0.7)
    }
}

// MARK: - AppState Tests

struct AppStateTests {

    @Test func allStatesExist() {
        let states: [AppState] = [.idle, .playingNoise, .sleepDetected, .alarmSet]
        #expect(states.count == 4)
    }

    @Test func statesAreDistinct() {
        let idle: AppState = .idle
        let playing: AppState = .playingNoise
        let detected: AppState = .sleepDetected
        let set: AppState = .alarmSet

        switch idle {
        case .idle: break
        default: Issue.record("idle should match .idle")
        }
        switch playing {
        case .playingNoise: break
        default: Issue.record("playing should match .playingNoise")
        }
        switch detected {
        case .sleepDetected: break
        default: Issue.record("detected should match .sleepDetected")
        }
        switch set {
        case .alarmSet: break
        default: Issue.record("set should match .alarmSet")
        }
    }
}

// MARK: - SleepRecord Tests

struct SleepRecordTests {

    // MARK: - Initialization

    @Test func init_setsAllProperties() {
        let sleep = Date(timeIntervalSince1970: 1711500000) // fixed time
        let wake = sleep.addingTimeInterval(6 * 3600) // 6 hours later

        let record = SleepRecord(sleepTime: sleep, wakeTime: wake, cycles: 4, noiseType: "Rain")

        #expect(record.sleepTime == sleep)
        #expect(record.wakeTime == wake)
        #expect(record.cycles == 4)
        #expect(record.noiseType == "Rain")
    }

    @Test func init_setsDateToStartOfWakeDay() {
        let sleep = Date(timeIntervalSince1970: 1711500000)
        let wake = sleep.addingTimeInterval(6 * 3600)

        let record = SleepRecord(sleepTime: sleep, wakeTime: wake, cycles: 4, noiseType: "Rain")

        let expectedDate = Calendar.current.startOfDay(for: wake)
        #expect(record.date == expectedDate)
    }

    // MARK: - duration

    @Test func duration_calculatesCorrectInterval() {
        let sleep = Date(timeIntervalSince1970: 1711500000)
        let wake = sleep.addingTimeInterval(7.5 * 3600) // 7.5 hours

        let record = SleepRecord(sleepTime: sleep, wakeTime: wake, cycles: 5, noiseType: "Ocean")

        #expect(record.duration == 7.5 * 3600)
    }

    @Test func duration_exactCycles() {
        let sleep = Date()
        // 4 cycles = 6 hours exactly
        let wake = sleep.addingTimeInterval(4 * 90 * 60)

        let record = SleepRecord(sleepTime: sleep, wakeTime: wake, cycles: 4, noiseType: "Fan")

        #expect(record.duration == 4 * 90 * 60)
    }

    // MARK: - durationText

    @Test func durationText_wholeHours() {
        let sleep = Date()
        let wake = sleep.addingTimeInterval(6 * 3600) // exactly 6 hours

        let record = SleepRecord(sleepTime: sleep, wakeTime: wake, cycles: 4, noiseType: "Rain")

        #expect(record.durationText == "6h")
    }

    @Test func durationText_hoursAndMinutes() {
        let sleep = Date()
        let wake = sleep.addingTimeInterval(7.5 * 3600) // 7h 30m

        let record = SleepRecord(sleepTime: sleep, wakeTime: wake, cycles: 5, noiseType: "Rain")

        #expect(record.durationText == "7h 30m")
    }

    @Test func durationText_shortSleep() {
        let sleep = Date()
        let wake = sleep.addingTimeInterval(90 * 60) // 1h 30m = 1 cycle

        let record = SleepRecord(sleepTime: sleep, wakeTime: wake, cycles: 1, noiseType: "Forest")

        #expect(record.durationText == "1h 30m")
    }

    @Test func durationText_withOddMinutes() {
        let sleep = Date()
        let wake = sleep.addingTimeInterval(5 * 3600 + 15 * 60) // 5h 15m

        let record = SleepRecord(sleepTime: sleep, wakeTime: wake, cycles: 3, noiseType: "Fan")

        #expect(record.durationText == "5h 15m")
    }
}

// MARK: - LocalizationManager Tests

@Suite(.serialized)
struct LocalizationManagerTests {

    // MARK: - Language enum

    @Test func language_allCases_containsThree() {
        #expect(LocalizationManager.Language.allCases.count == 3)
    }

    @Test func language_rawValues() {
        #expect(LocalizationManager.Language.english.rawValue == "en")
        #expect(LocalizationManager.Language.chinese.rawValue == "zh")
        #expect(LocalizationManager.Language.japanese.rawValue == "ja")
    }

    @Test func language_displayNames() {
        #expect(LocalizationManager.Language.english.displayName == "English")
        #expect(LocalizationManager.Language.chinese.displayName == "中文")
        #expect(LocalizationManager.Language.japanese.displayName == "日本語")
    }

    @Test func language_id_matchesRawValue() {
        for lang in LocalizationManager.Language.allCases {
            #expect(lang.id == lang.rawValue)
        }
    }

    @Test func language_rawValue_roundTrip() {
        for lang in LocalizationManager.Language.allCases {
            let restored = LocalizationManager.Language(rawValue: lang.rawValue)
            #expect(restored == lang)
        }
    }

    // MARK: - Translation

    @Test func t_english_returnsCorrectTranslation() {
        let loc = LocalizationManager()
        loc.current = .english

        #expect(loc.t("wake_window") == "Wake Window")
        #expect(loc.t("good_morning") == "Good Morning")
        #expect(loc.t("start") == "Start")
        #expect(loc.t("settings") == "Settings")
        #expect(loc.t("snooze") == "5 more minutes")
    }

    @Test func t_chinese_returnsCorrectTranslation() {
        let loc = LocalizationManager()
        loc.current = .chinese

        #expect(loc.t("wake_window") == "唤醒窗口")
        #expect(loc.t("good_morning") == "早上好")
        #expect(loc.t("start") == "开始")
        #expect(loc.t("settings") == "设置")
        #expect(loc.t("snooze") == "再睡5分钟")
    }

    @Test func t_japanese_returnsCorrectTranslation() {
        let loc = LocalizationManager()
        loc.current = .japanese

        #expect(loc.t("wake_window") == "起床ウィンドウ")
        #expect(loc.t("good_morning") == "おはようございます")
        #expect(loc.t("start") == "スタート")
        #expect(loc.t("settings") == "設定")
        #expect(loc.t("snooze") == "あと5分")
    }

    @Test func t_unknownKey_returnsKeyItself() {
        let loc = LocalizationManager()
        loc.current = .english

        #expect(loc.t("nonexistent_key") == "nonexistent_key")
        #expect(loc.t("") == "")
        #expect(loc.t("some_random_thing") == "some_random_thing")
    }

    @Test func t_chinese_hasAllRequiredKeys() {
        let loc = LocalizationManager()
        loc.current = .chinese
        let requiredKeys = [
            "wake_window", "drag_hint", "good_morning", "tap_dismiss",
            "snooze", "you_slept", "playing", "start", "stop", "settings",
            "language", "history", "about", "volume", "no_history",
            "sleep_time", "wake_time", "cycles", "detecting_sleep",
            "ready_sleep", "lets_go", "next", "skip",
            "earliest_wake", "latest_wake", "cancel_alarm"
        ]
        for key in requiredKeys {
            #expect(loc.t(key) != key, "Missing Chinese translation for '\(key)'")
        }
    }

    @Test func t_japanese_hasAllRequiredKeys() {
        let loc = LocalizationManager()
        loc.current = .japanese
        let requiredKeys = [
            "wake_window", "drag_hint", "good_morning", "tap_dismiss",
            "snooze", "you_slept", "playing", "start", "stop", "settings",
            "language", "history", "about", "volume", "no_history",
            "sleep_time", "wake_time", "cycles", "detecting_sleep",
            "ready_sleep", "lets_go", "next", "skip",
            "earliest_wake", "latest_wake", "cancel_alarm"
        ]
        for key in requiredKeys {
            #expect(loc.t(key) != key, "Missing Japanese translation for '\(key)'")
        }
    }

    @Test func t_switchingLanguage_changesOutput() {
        let loc = LocalizationManager()

        loc.current = .english
        let english = loc.t("good_morning")

        loc.current = .chinese
        let chinese = loc.t("good_morning")

        loc.current = .japanese
        let japanese = loc.t("good_morning")

        // All three should be different
        #expect(english != chinese)
        #expect(english != japanese)
        #expect(chinese != japanese)
    }

    // MARK: - Persistence
    // Note: Tests that write/read UserDefaults are serialized to avoid races.

    @Test func languageChange_persistsToUserDefaults() {
        let defaults = UserDefaults.standard
        let loc = LocalizationManager()
        loc.current = .japanese
        #expect(defaults.string(forKey: "appLanguage") == "ja")
        #expect(defaults.bool(forKey: "hasExplicitLanguageChoice") == true)

        loc.current = .chinese
        #expect(defaults.string(forKey: "appLanguage") == "zh")

        // Clean up
        loc.current = .english
        defaults.removeObject(forKey: "hasExplicitLanguageChoice")
    }

    @Test func init_restoresExplicitChoice() {
        let defaults = UserDefaults.standard
        defaults.set("ja", forKey: "appLanguage")
        defaults.set(true, forKey: "hasExplicitLanguageChoice")
        let loc = LocalizationManager()
        #expect(loc.current == .japanese)

        // Clean up
        defaults.set("en", forKey: "appLanguage")
        defaults.removeObject(forKey: "hasExplicitLanguageChoice")
    }

    @Test func init_migratesExistingUser() {
        let defaults = UserDefaults.standard
        // Simulate existing user: has appLanguage but no explicit flag
        defaults.set("zh", forKey: "appLanguage")
        defaults.removeObject(forKey: "hasExplicitLanguageChoice")

        let loc = LocalizationManager()
        #expect(loc.current == .chinese)
        #expect(defaults.bool(forKey: "hasExplicitLanguageChoice") == true)

        // Clean up
        defaults.removeObject(forKey: "appLanguage")
        defaults.removeObject(forKey: "hasExplicitLanguageChoice")
    }

    @Test func init_firstLaunch_autoDetectsLanguage() {
        let defaults = UserDefaults.standard
        // Simulate fresh install: no stored values
        defaults.removeObject(forKey: "appLanguage")
        defaults.removeObject(forKey: "hasExplicitLanguageChoice")

        let loc = LocalizationManager()
        // Should pick a valid language (auto-detected or English fallback)
        let validLanguages = LocalizationManager.Language.allCases
        #expect(validLanguages.contains(loc.current))
        // Should store the detected language
        #expect(defaults.string(forKey: "appLanguage") != nil)
        // Should NOT set explicit flag
        #expect(defaults.bool(forKey: "hasExplicitLanguageChoice") == false)

        // Clean up
        defaults.removeObject(forKey: "appLanguage")
        defaults.removeObject(forKey: "hasExplicitLanguageChoice")
    }

    @Test func init_invalidStoredValue_withExplicitFlag_defaultsToEnglish() {
        let defaults = UserDefaults.standard
        defaults.set("invalid_lang", forKey: "appLanguage")
        defaults.set(true, forKey: "hasExplicitLanguageChoice")
        let loc = LocalizationManager()
        // Invalid rawValue with explicit flag → falls through to auto-detect
        let validLanguages = LocalizationManager.Language.allCases
        #expect(validLanguages.contains(loc.current))

        // Clean up
        defaults.removeObject(forKey: "appLanguage")
        defaults.removeObject(forKey: "hasExplicitLanguageChoice")
    }

    // MARK: - Bedtime Reminder Translations

    // MARK: - New ClockDial Translation Keys

    @Test func t_stopAndCancelAlarm_english() {
        let loc = LocalizationManager()
        loc.current = .english
        #expect(loc.t("stop") == "Stop")
        #expect(loc.t("cancel_alarm") == "Cancel alarm")
    }

    @Test func t_stopAndCancelAlarm_chinese() {
        let loc = LocalizationManager()
        loc.current = .chinese
        #expect(loc.t("stop") == "停止")
        #expect(loc.t("cancel_alarm") == "取消闹钟")
    }

    @Test func t_stopAndCancelAlarm_japanese() {
        let loc = LocalizationManager()
        loc.current = .japanese
        #expect(loc.t("stop") == "停止")
        #expect(loc.t("cancel_alarm") == "アラームを取消")
    }

    // MARK: - Bedtime Reminder Translations

    @Test func t_bedtimeReminder_english() {
        let loc = LocalizationManager()
        loc.current = .english
        #expect(loc.t("bedtime_reminder") == "Bedtime Reminder")
        #expect(loc.t("reminder_time") == "Reminder Time")
    }

    @Test func t_bedtimeReminder_chinese() {
        let loc = LocalizationManager()
        loc.current = .chinese
        #expect(loc.t("bedtime_reminder") == "就寝提醒")
        #expect(loc.t("reminder_time") == "提醒时间")
    }

    @Test func t_bedtimeReminder_japanese() {
        let loc = LocalizationManager()
        loc.current = .japanese
        #expect(loc.t("bedtime_reminder") == "就寝リマインダー")
        #expect(loc.t("reminder_time") == "リマインダー時間")
    }
}

// MARK: - BedtimeReminderManager Tests

struct BedtimeReminderManagerTests {

    @Test func schedule_doesNotThrow() {
        // Just verify it can be called without crashing
        BedtimeReminderManager.schedule(hour: 22, minute: 30)
    }

    @Test func cancel_doesNotThrow() {
        BedtimeReminderManager.cancel()
    }

    @Test func schedule_thenCancel_doesNotThrow() {
        BedtimeReminderManager.schedule(hour: 23, minute: 0)
        BedtimeReminderManager.cancel()
    }

    @Test func schedule_variousTimes() {
        // Edge cases for hour/minute
        BedtimeReminderManager.schedule(hour: 0, minute: 0)    // midnight
        BedtimeReminderManager.schedule(hour: 12, minute: 0)   // noon
        BedtimeReminderManager.schedule(hour: 23, minute: 59)  // last minute of day
        BedtimeReminderManager.cancel()
    }
}

// MARK: - StartSleepIntent Tests

struct StartSleepIntentTests {

    @Test func intent_hasCorrectTitle() {
        #expect(StartSleepIntent.title == "Start Sleep Session")
    }

    @Test func intent_opensApp() {
        #expect(StartSleepIntent.openAppWhenRun == true)
    }

    @Test func intent_canBeInstantiated() {
        let intent = StartSleepIntent()
        #expect(intent != nil)
    }

    @Test func shortcuts_hasEntries() {
        let shortcuts = AirAlarmShortcuts.appShortcuts
        #expect(shortcuts.count == 1)
    }
}

// MARK: - Widget Data Keys Tests

struct WidgetDataTests {

    @Test func sharedDefaults_writeAndRead() {
        // Test that we can write/read from the shared suite
        // Note: In unit tests, App Groups might not be available,
        // so we test with standard UserDefaults as a proxy
        let defaults = UserDefaults.standard
        let testKey = "test_lastSleepDuration"

        defaults.set("7h 30m", forKey: testKey)
        #expect(defaults.string(forKey: testKey) == "7h 30m")

        defaults.set(5, forKey: "test_lastSleepCycles")
        #expect(defaults.integer(forKey: "test_lastSleepCycles") == 5)

        let date = Date()
        defaults.set(date, forKey: "test_lastSleepDate")
        let restored = defaults.object(forKey: "test_lastSleepDate") as? Date
        #expect(restored != nil)

        // Clean up
        defaults.removeObject(forKey: testKey)
        defaults.removeObject(forKey: "test_lastSleepCycles")
        defaults.removeObject(forKey: "test_lastSleepDate")
    }
}
