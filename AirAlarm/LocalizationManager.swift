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
        didSet { UserDefaults.standard.set(current.rawValue, forKey: "appLanguage") }
    }

    init() {
        let stored = UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
        current = Language(rawValue: stored) ?? .english
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
            "settings": "Settings",
            "language": "Language",
            "history": "Sleep History",
            "about": "About",
            "volume": "Volume",
            "no_history": "No sleep records yet",
            "sleep_time": "Sleep",
            "wake_time": "Wake",
            "cycles": "cycles",
            "detecting_sleep": "Detecting sleep...",
            "ready_sleep": "Ready to Sleep?",
            "ready_subtitle": "AirAlarm will play soothing sounds\nand wake you at the perfect moment\nin your sleep cycle.",
            "lets_go": "Let's Go",
            "airpods_connected": "AirPods Connected",
            "put_airpods": "Put on Your AirPods",
            "airpods_subtitle_connected": "You're all set. Tap Next to continue.",
            "airpods_subtitle": "We need AirPods to detect when you fall asleep.",
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
            "onboarding_title_2": "Your AirPods Know\nWhen You Sleep",
            "onboarding_desc_2": "AirAlarm plays soothing sounds through\nyour AirPods. When they detect you've\nfallen asleep, we start counting\nyour sleep cycles.",
            "onboarding_title_3": "Set Your Wake Window",
            "onboarding_desc_3": "Choose when you'd like to wake up.\nAirAlarm picks the perfect moment\nwithin your 90-minute window —\nright at the end of a sleep cycle.",
            "best_wake_time": "Best time to wake",
            "ninety_min": "90 min",
            "widget_no_data": "No sleep data yet",
            "widget_slept": "Slept",
            "widget_sleep_summary": "Sleep Summary",
            "widget_description": "Shows your last sleep session",
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
            "settings": "设置",
            "language": "语言",
            "history": "睡眠记录",
            "about": "关于",
            "volume": "音量",
            "no_history": "暂无睡眠记录",
            "sleep_time": "入睡",
            "wake_time": "醒来",
            "cycles": "个周期",
            "detecting_sleep": "正在检测入睡...",
            "ready_sleep": "准备好睡觉了吗？",
            "ready_subtitle": "AirAlarm 会播放舒缓的声音\n并在最佳时刻将你唤醒",
            "lets_go": "开始吧",
            "airpods_connected": "AirPods 已连接",
            "put_airpods": "请戴上 AirPods",
            "airpods_subtitle_connected": "一切就绪，点击下一步继续。",
            "airpods_subtitle": "我们需要 AirPods 来检测你的入睡。",
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
            "onboarding_title_2": "你的 AirPods 知道\n你何时入睡",
            "onboarding_desc_2": "AirAlarm 通过 AirPods 播放舒缓的声音。\n当检测到你已入睡时，\n我们开始计算你的睡眠周期。",
            "onboarding_title_3": "设置唤醒窗口",
            "onboarding_desc_3": "选择你想要醒来的时间。\nAirAlarm 会在你的90分钟窗口内\n选择最佳时刻——\n恰好在一个睡眠周期结束时。",
            "best_wake_time": "最佳唤醒时间",
            "ninety_min": "90 分钟",
            "widget_no_data": "暂无睡眠数据",
            "widget_slept": "睡了",
            "widget_sleep_summary": "睡眠摘要",
            "widget_description": "显示你最近的睡眠记录",
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
            "settings": "設定",
            "language": "言語",
            "history": "睡眠履歴",
            "about": "について",
            "volume": "音量",
            "no_history": "睡眠記録はまだありません",
            "sleep_time": "就寝",
            "wake_time": "起床",
            "cycles": "サイクル",
            "detecting_sleep": "睡眠を検出中...",
            "ready_sleep": "おやすみの準備はできましたか？",
            "ready_subtitle": "AirAlarmは心地よい音を再生し\n睡眠サイクルの最適なタイミングで\nあなたを起こします",
            "lets_go": "始めましょう",
            "airpods_connected": "AirPods 接続済み",
            "put_airpods": "AirPodsを装着してください",
            "airpods_subtitle_connected": "準備完了です。次へをタップしてください。",
            "airpods_subtitle": "睡眠を検出するためにAirPodsが必要です。",
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
            "onboarding_title_2": "AirPodsがあなたの\n眠りを感知します",
            "onboarding_desc_2": "AirAlarmはAirPodsを通じて\n心地よい音を再生します。\n眠りを検知すると\n睡眠サイクルのカウントを開始します。",
            "onboarding_title_3": "起床ウィンドウを設定",
            "onboarding_desc_3": "起きたい時間帯を選んでください。\nAirAlarmが90分のウィンドウ内で\n最適なタイミングを選びます——\n睡眠サイクルの終わりに合わせて。",
            "best_wake_time": "最適な起床タイミング",
            "ninety_min": "90分",
            "widget_no_data": "睡眠データなし",
            "widget_slept": "睡眠",
            "widget_sleep_summary": "睡眠サマリー",
            "widget_description": "最新の睡眠セッションを表示",
        ]
    ]
}
