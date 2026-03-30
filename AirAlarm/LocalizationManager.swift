import SwiftUI

@Observable
class LocalizationManager {
    enum Language: String, CaseIterable, Identifiable {
        case english = "en"
        case chinese = "zh"
        case japanese = "ja"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .english: return "English"
            case .chinese: return "中文"
            case .japanese: return "日本語"
            }
        }
    }

    var current: Language {
        didSet {
            UserDefaults.standard.set(current.rawValue, forKey: "appLanguage")
            UserDefaults.standard.set(true, forKey: "hasExplicitLanguageChoice")
        }
    }

    init() {
        let defaults = UserDefaults.standard
        let hasExplicit = defaults.bool(forKey: "hasExplicitLanguageChoice")

        if hasExplicit, let stored = defaults.string(forKey: "appLanguage"),
           let lang = Language(rawValue: stored) {
            // User explicitly chose a language in Settings — respect it
            current = lang
        } else {
            // Auto-detect system language (first launch or no explicit choice)
            let preferred = Locale.preferredLanguages.first ?? "en"
            let code = Locale(identifier: preferred).language.languageCode?.identifier ?? "en"
            let detected = Language(rawValue: code) ?? .english
            current = detected
            defaults.set(detected.rawValue, forKey: "appLanguage")
        }
    }

    func t(_ key: String) -> String {
        translations[current]?[key] ?? key
    }

    private let translations: [Language: [String: String]] = [
        .english: [
            "wake_window": "Wake Window",
            "drag_hint": "Drag the arc to adjust · 90 min cycle",
            "good_morning": "Good Morning",
            "tap_dismiss": "Tap to dismiss",
            "snooze": "5 more minutes",
            "you_slept": "You slept",
            "playing": "Playing",
            "start": "Start",
            "stop": "Stop",
            "cancel_alarm": "Cancel alarm",
            "settings": "Settings",
            "language": "Language",
            "history": "Sleep History",
            "about": "About",
            "volume": "Volume",
            "no_history": "No sleep records yet",
            "sleep_time": "Sleep",
            "wake_time": "Wake",
            "cycles": "cycles",
            "detecting_sleep": "Waiting for you to drift off...",
            "ready_sleep": "Ready to Sleep?",
            "ready_subtitle": "AirAlarm will play soothing sounds\nand wake you at the perfect moment\nin your sleep cycle.",
            "lets_go": "Let's Go",
            "airpods_connected": "AirPods Connected",
            "put_airpods": "Put on Your AirPods",
            "airpods_subtitle_connected": "You're all set. Tap Next to continue.",
            "airpods_subtitle": "AirPods help us know when you've drifted off to sleep.",
            "supported_models": "Supported Models",
            "next": "Next",
            "skip": "Skip for Now",
            "earliest_wake": "Earliest Wake",
            "latest_wake": "Latest Wake",
            "bedtime_reminder": "Bedtime Reminder",
            "reminder_time": "Reminder Time",
            "get_started": "Get Started",
            "onboarding_title_1": "Sleep Smarter, Not Longer",
            "onboarding_desc_1": "Your sleep follows 90-minute cycles.\nWaking at the end of a cycle feels refreshing.\nWaking mid-cycle feels groggy —\neven with enough sleep.",
            "onboarding_title_2": "Your AirPods Help\nYou Sleep Better",
            "onboarding_desc_2": "AirAlarm plays soothing sounds through\nyour AirPods. When audio stops playing,\nwe begin timing\nyour sleep cycles.",
            "onboarding_title_3": "Set Your Wake Window",
            "onboarding_desc_3": "Choose when you'd like to wake up.\nAirAlarm picks the perfect moment\nwithin your 90-minute window —\nright at the end of a sleep cycle.",
            "best_wake_time": "Best time to wake",
            "ninety_min": "90 min",
            "widget_no_data": "No sleep data yet",
            "widget_slept": "Slept",
            "widget_sleep_summary": "Sleep Summary",
            "widget_description": "Shows your last sleep session",
            "notif_wake_title": "Time to Wake Up",
            "notif_wake_body": "You've completed %d sleep cycles (%@). This is your optimal wake time!",
            "notif_bedtime_title": "Time to Wind Down",
            "notif_bedtime_body": "Open AirAlarm to start your sleep session",
            "sound_rain": "Rain",
            "sound_ocean": "Ocean",
            "sound_fire": "Fire",
            "sound_forest": "Forest",
            "sound_fan": "Fan",
            "sound_whitenoise": "White Noise",
            "sound_airplane": "Airplane",
            "screen_saver": "Screen Saver",
            "screen_saver_hint": "Keeps the alarm reliable by preventing screen lock. Display dims to black to save power.",
            "screensaver_alert_title": "Keep App Active",
            "screensaver_alert_message": "For a reliable alarm, please keep AirAlarm on screen and avoid switching apps while sleeping. The screen saver will dim the display to save power.",
            "screensaver_alert_ok": "Got it",
            "bg_warning_title": "AirAlarm is in the background",
            "bg_warning_body": "Return to AirAlarm to ensure your alarm rings on time.",
        ],
        .chinese: [
            "wake_window": "唤醒窗口",
            "drag_hint": "拖动弧段调整 · 90 分钟周期",
            "good_morning": "早上好",
            "tap_dismiss": "点击关闭",
            "snooze": "再睡5分钟",
            "you_slept": "你睡了",
            "playing": "正在播放",
            "start": "开始",
            "stop": "停止",
            "cancel_alarm": "取消闹钟",
            "settings": "设置",
            "language": "语言",
            "history": "睡眠记录",
            "about": "关于",
            "volume": "音量",
            "no_history": "暂无睡眠记录",
            "sleep_time": "入睡",
            "wake_time": "醒来",
            "cycles": "个周期",
            "detecting_sleep": "等待入睡中...",
            "ready_sleep": "准备好睡觉了吗？",
            "ready_subtitle": "AirAlarm 会播放舒缓的声音\n并在最佳时刻将你唤醒",
            "lets_go": "开始吧",
            "airpods_connected": "AirPods 已连接",
            "put_airpods": "请戴上 AirPods",
            "airpods_subtitle_connected": "一切就绪，点击下一步继续。",
            "airpods_subtitle": "AirPods 帮助我们感知你何时入睡。",
            "supported_models": "支持的型号",
            "next": "下一步",
            "skip": "暂时跳过",
            "earliest_wake": "最早唤醒",
            "latest_wake": "最晚唤醒",
            "bedtime_reminder": "就寝提醒",
            "reminder_time": "提醒时间",
            "get_started": "开始使用",
            "onboarding_title_1": "睡得更聪明，而非更久",
            "onboarding_desc_1": "你的睡眠遵循90分钟周期。\n在周期结束时醒来会感觉精力充沛。\n在周期中间醒来则昏昏沉沉——\n即使睡眠时间足够。",
            "onboarding_title_2": "AirPods 助你\n安然入睡",
            "onboarding_desc_2": "AirAlarm 通过 AirPods 播放舒缓的声音。\n当音频停止播放后，\n我们开始计算你的睡眠周期。",
            "onboarding_title_3": "设置唤醒窗口",
            "onboarding_desc_3": "选择你想要醒来的时间。\nAirAlarm 会在你的90分钟窗口内\n选择最佳时刻——\n恰好在一个睡眠周期结束时。",
            "best_wake_time": "最佳唤醒时间",
            "ninety_min": "90 分钟",
            "widget_no_data": "暂无睡眠数据",
            "widget_slept": "睡了",
            "widget_sleep_summary": "睡眠摘要",
            "widget_description": "显示你最近的睡眠记录",
            "notif_wake_title": "该起床了",
            "notif_wake_body": "你已完成 %d 个睡眠周期（%@），现在是最佳起床时间！",
            "notif_bedtime_title": "该休息了",
            "notif_bedtime_body": "打开 AirAlarm 开始你的睡眠",
            "sound_rain": "雨声",
            "sound_ocean": "海浪",
            "sound_fire": "篝火",
            "sound_forest": "森林",
            "sound_fan": "风扇",
            "sound_whitenoise": "白噪音",
            "sound_airplane": "飞机",
            "screen_saver": "屏幕保护",
            "screen_saver_hint": "防止锁屏以确保闹钟正常运行，屏幕将变为全黑以节省电量。",
            "screensaver_alert_title": "保持应用活跃",
            "screensaver_alert_message": "为确保闹钟正常响起，请在睡眠期间保持 AirAlarm 在前台，避免切换到其他应用。屏幕保护会将屏幕变暗以节省电量。",
            "screensaver_alert_ok": "知道了",
            "bg_warning_title": "AirAlarm 已进入后台",
            "bg_warning_body": "请返回 AirAlarm 以确保闹钟准时响起。",
        ],
        .japanese: [
            "wake_window": "起床ウィンドウ",
            "drag_hint": "弧をドラッグして調整 · 90分サイクル",
            "good_morning": "おはようございます",
            "tap_dismiss": "タップして閉じる",
            "snooze": "あと5分",
            "you_slept": "睡眠時間",
            "playing": "再生中",
            "start": "スタート",
            "stop": "停止",
            "cancel_alarm": "アラームを取消",
            "settings": "設定",
            "language": "言語",
            "history": "睡眠履歴",
            "about": "について",
            "volume": "音量",
            "no_history": "睡眠記録はまだありません",
            "sleep_time": "就寝",
            "wake_time": "起床",
            "cycles": "サイクル",
            "detecting_sleep": "おやすみ待機中...",
            "ready_sleep": "おやすみの準備はできましたか？",
            "ready_subtitle": "AirAlarmは心地よい音を再生し\n睡眠サイクルの最適なタイミングで\nあなたを起こします",
            "lets_go": "始めましょう",
            "airpods_connected": "AirPods 接続済み",
            "put_airpods": "AirPodsを装着してください",
            "airpods_subtitle_connected": "準備完了です。次へをタップしてください。",
            "airpods_subtitle": "AirPodsがあなたの眠りをサポートします。",
            "supported_models": "対応モデル",
            "next": "次へ",
            "skip": "スキップ",
            "earliest_wake": "最早起床",
            "latest_wake": "最遅起床",
            "bedtime_reminder": "就寝リマインダー",
            "reminder_time": "リマインダー時間",
            "get_started": "始めましょう",
            "onboarding_title_1": "もっと賢く眠ろう",
            "onboarding_desc_1": "睡眠は90分サイクルで進みます。\nサイクルの終わりに起きるとスッキリ。\nサイクルの途中で起きると\n十分寝ても体がだるい。",
            "onboarding_title_2": "AirPodsがあなたの\n眠りをサポート",
            "onboarding_desc_2": "AirAlarmはAirPodsを通じて\n心地よい音を再生します。\n音声の再生が止まると\n睡眠サイクルのカウントを開始します。",
            "onboarding_title_3": "起床ウィンドウを設定",
            "onboarding_desc_3": "起きたい時間帯を選んでください。\nAirAlarmが90分のウィンドウ内で\n最適なタイミングを選びます——\n睡眠サイクルの終わりに合わせて。",
            "best_wake_time": "最適な起床タイミング",
            "ninety_min": "90分",
            "widget_no_data": "睡眠データなし",
            "widget_slept": "睡眠",
            "widget_sleep_summary": "睡眠サマリー",
            "widget_description": "最新の睡眠セッションを表示",
            "notif_wake_title": "起きる時間です",
            "notif_wake_body": "%d回の睡眠サイクル（%@）が完了しました。最適な起床タイミングです！",
            "notif_bedtime_title": "そろそろ休みましょう",
            "notif_bedtime_body": "AirAlarmを開いて睡眠セッションを始めましょう",
            "sound_rain": "雨音",
            "sound_ocean": "波の音",
            "sound_fire": "焚き火",
            "sound_forest": "森林",
            "sound_fan": "ファン",
            "sound_whitenoise": "ホワイトノイズ",
            "sound_airplane": "飛行機",
            "screen_saver": "スクリーンセーバー",
            "screen_saver_hint": "画面ロックを防止してアラームを確実に動作させます。省電力のため画面は黒くなります。",
            "screensaver_alert_title": "アプリをアクティブに保つ",
            "screensaver_alert_message": "アラームを確実に鳴らすため、睡眠中は AirAlarm を画面に表示したまま、他のアプリに切り替えないでください。スクリーンセーバーが画面を暗くして電力を節約します。",
            "screensaver_alert_ok": "了解",
            "bg_warning_title": "AirAlarm がバックグラウンドになりました",
            "bg_warning_body": "アラームを確実に鳴らすため、AirAlarm に戻ってください。",
        ]
    ]
}
