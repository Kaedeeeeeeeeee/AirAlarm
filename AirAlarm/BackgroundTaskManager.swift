import BackgroundTasks

enum BackgroundTaskManager {
    static let alarmCheckID = "com.zhangshifeng.airalarm.alarmcheck"

    static func register(alarmManager: AlarmManager) {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: alarmCheckID, using: nil) { task in
            guard let refreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            handleAlarmCheck(task: refreshTask, alarmManager: alarmManager)
        }
    }

    static func scheduleAlarmCheck(at date: Date) {
        let request = BGAppRefreshTaskRequest(identifier: alarmCheckID)
        // Schedule 1 minute before the alarm
        request.earliestBeginDate = date.addingTimeInterval(-60)
        try? BGTaskScheduler.shared.submit(request)
    }

    private static func handleAlarmCheck(task: BGAppRefreshTask, alarmManager: AlarmManager) {
        if let wakeTime = alarmManager.scheduledWakeTime,
           Date() >= wakeTime,
           !alarmManager.isRinging {
            DispatchQueue.main.async {
                alarmManager.startRinging()
            }
        }
        task.setTaskCompleted(success: true)
    }
}
