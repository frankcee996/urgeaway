import Foundation
import UserNotifications

/// Native equivalent of `notifications.js` (`Notifications.enable/disable`).
/// One daily gentle nudge around 10am plus person-created reminders — all
/// scheduled locally via `UNUserNotificationCenter`. There is no server
/// component: nothing is sent anywhere, matching the "stored only on this
/// device" promise in Settings → Privacy & Your Data.
enum NotificationsService {
    static let dailyNudgeId = "urgeaway.daily-nudge"

    enum EnableResult { case ok, denied, error }

    static func enable() async -> EnableResult {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            guard granted else { return .denied }
            scheduleDailyNudge()
            return .ok
        } catch {
            return .error
        }
    }

    static func disable() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [dailyNudgeId])
        center.removeAllPendingNotificationRequests()
    }

    private static func scheduleDailyNudge() {
        let content = UNMutableNotificationContent()
        content.title = "UrgeAway"
        content.body = "A gentle check-in — how's today going?"
        content.sound = .default
        var comps = DateComponents(); comps.hour = 10; comps.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request = UNNotificationRequest(identifier: dailyNudgeId, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    /// Person-created reminder (Settings → Notifications & Reminders → "+ Add
    /// a reminder"), scheduled as its own local notification — equivalent to
    /// `Notifications.scheduleReminder` in the web version.
    static func schedule(reminder: Reminder) {
        let content = UNMutableNotificationContent()
        content.title = "UrgeAway"
        content.body = reminder.message.isEmpty ? "This is your reminder." : reminder.message
        content.sound = .default
        var comps = DateComponents(); comps.hour = reminder.hour; comps.minute = reminder.minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: reminder.repeatDaily)
        let request = UNNotificationRequest(identifier: reminder.id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    static func cancel(reminderId: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [reminderId])
    }
}
