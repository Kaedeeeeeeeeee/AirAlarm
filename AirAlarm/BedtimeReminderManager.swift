import UserNotifications
import Foundation

enum BedtimeReminderManager {
    private static let identifier = "air-alarm-bedtime-reminder"

    static func schedule(hour: Int, minute: Int, localization: LocalizationManager? = nil) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        let content = UNMutableNotificationContent()
        content.title = localization?.t("notif_bedtime_title") ?? "Time to Wind Down"
        content.body = localization?.t("notif_bedtime_body") ?? "Open AirAlarm to start your sleep session"
        content.sound = .default
        content.interruptionLevel = .active

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        center.add(request)
    }

    static func cancel() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
