import Foundation
import HabitBarCore
import OSLog
import UserNotifications

protocol NotificationScheduling {
    func synchronize(habits: [Habit], entries: [HabitEntry], referenceDate: Date)
}

enum NotificationSchedulerFactory {
    static func makeDefault() -> NotificationScheduling {
        AppRuntime.isAppBundle ? UserNotificationScheduler() : DisabledNotificationScheduler()
    }
}

enum AppRuntime {
    static var isAppBundle: Bool {
        Bundle.main.bundleURL.pathExtension == "app"
    }
}

struct DisabledNotificationScheduler: NotificationScheduling {
    func synchronize(habits: [Habit], entries: [HabitEntry], referenceDate: Date) {}
}

struct UserNotificationScheduler: NotificationScheduling {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.georgetsouvaltzis.HabitBar",
        category: "Notifications"
    )

    private let planner = NotificationPlanner()

    init() {
        NotificationForegroundPresenter.install()
    }

    func synchronize(habits: [Habit], entries: [HabitEntry], referenceDate: Date = Date()) {
        guard AppRuntime.isAppBundle else { return }

        let plans = planner.plans(habits: habits, entries: entries, referenceDate: referenceDate)
        let center = UNUserNotificationCenter.current()
        Self.logger.info("Notification sync started: plans=\(plans.count, privacy: .public)")

        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error {
                Self.logger.error("Notification authorization error: \(error.localizedDescription, privacy: .public)")
            }
            guard granted else {
                Self.logger.warning("Notification authorization not granted")
                Task {
                    let settings = await center.notificationSettings()
                    Self.logger.warning("Notification authorization status: \(String(describing: settings.authorizationStatus), privacy: .public)")
                }
                return
            }
            center.removeAllPendingNotificationRequests()

            let group = DispatchGroup()
            for plan in plans {
                let content = UNMutableNotificationContent()
                content.title = plan.title
                content.subtitle = plan.leadTime.title
                content.body = plan.body
                content.sound = .default
                content.userInfo = [NotificationRouting.habitIDKey: plan.habitID.uuidString]

                var components = DateComponents()
                components.hour = plan.hour
                components.minute = plan.minute
                components.weekday = plan.weekday?.rawValue

                if let targetDate = plan.targetDate {
                    let calendar = Calendar.current
                    components.year = calendar.component(.year, from: targetDate)
                    components.month = calendar.component(.month, from: targetDate)
                    components.day = calendar.component(.day, from: targetDate)
                }

                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: components,
                    repeats: plan.targetDate == nil
                )
                let nextDate = trigger.nextTriggerDate()?.formatted(date: .numeric, time: .standard) ?? "nil"
                let request = UNNotificationRequest(
                    identifier: notificationIdentifier(for: plan),
                    content: content,
                    trigger: trigger
                )
                group.enter()
                center.add(request) { error in
                    defer { group.leave() }
                    if let error {
                        Self.logger.error("Notification add failed: id=\(request.identifier, privacy: .public), error=\(error.localizedDescription, privacy: .public)")
                    } else {
                        Self.logger.info("Notification added: id=\(request.identifier, privacy: .public), lead=\(plan.leadTime.title, privacy: .public), next=\(nextDate, privacy: .public)")
                    }
                }
            }

            group.notify(queue: .global()) {
                center.getPendingNotificationRequests { requests in
                    Self.logger.info("Pending notification requests: count=\(requests.count, privacy: .public)")
                }
            }
        }
    }

    private func notificationIdentifier(for plan: NotificationPlan) -> String {
        if let weekday = plan.weekday {
            return "habit.\(plan.habitID.uuidString).weekday.\(weekday.rawValue).lead.\(plan.leadTime.rawValue)"
        }

        if let targetDate = plan.targetDate {
            let day = ISO8601DateFormatter().string(from: targetDate)
            return "habit.\(plan.habitID.uuidString).date.\(day).lead.\(plan.leadTime.rawValue)"
        }

        return "habit.\(plan.habitID.uuidString).lead.\(plan.leadTime.rawValue)"
    }
}

private final class NotificationForegroundPresenter: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationForegroundPresenter()

    static func install() {
        UNUserNotificationCenter.current().delegate = shared
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let logger = Logger(
            subsystem: Bundle.main.bundleIdentifier ?? "com.georgetsouvaltzis.HabitBar",
            category: "Notifications"
        )
        logger.info("Notification will present: id=\(notification.request.identifier, privacy: .public)")
        completionHandler([.banner, .list, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        defer { completionHandler() }

        guard let habitID = response.notification.request.content.userInfo[NotificationRouting.habitIDKey] as? String else {
            return
        }

        NotificationRouting.route(habitIDString: habitID)
    }
}
