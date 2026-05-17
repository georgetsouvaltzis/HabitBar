import XCTest
@testable import HabitBarCore

final class NotificationPlannerTests: XCTestCase {
    private var planner: NotificationPlanner!
    private var calendar: Calendar!

    override func setUp() {
        super.setUp()
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let engine = HabitRuleEngine(habitCalendar: HabitCalendar(calendar: calendar))
        planner = NotificationPlanner(engine: engine)
    }

    func testDoesNotScheduleArchivedHabit() {
        var habit = reminderHabit(schedule: .daily)
        habit.isArchived = true

        XCTAssertFalse(planner.shouldSchedule(habit: habit, entries: [], referenceDate: date("2026-05-12")))
    }

    func testDoesNotScheduleCompletedDailyHabit() {
        let habit = reminderHabit(schedule: .daily)
        let today = date("2026-05-12")
        let entries = [HabitEntry(habitID: habit.id, targetDate: today, completedAt: today, source: .normal)]

        XCTAssertFalse(planner.shouldSchedule(habit: habit, entries: entries, referenceDate: today))
    }

    func testSchedulesWeeklyQuotaUntilQuotaIsSatisfied() {
        let habit = reminderHabit(schedule: .weeklyQuota(3))
        let today = date("2026-05-12")
        let entries = [
            HabitEntry(habitID: habit.id, targetDate: date("2026-05-11"), source: .normal),
            HabitEntry(habitID: habit.id, targetDate: date("2026-05-12"), source: .normal)
        ]

        XCTAssertTrue(planner.shouldSchedule(habit: habit, entries: entries, referenceDate: today))
    }

    func testPlannerUsesCustomReminderBody() {
        let habit = reminderHabit(schedule: .daily, message: "Time for your walk")
        let plan = planner.plans(habits: [habit], entries: [], referenceDate: date("2026-05-12")).first

        XCTAssertEqual(plan?.title, "Morning Walk")
        XCTAssertEqual(plan?.body, "Time for your walk")
        XCTAssertEqual(plan?.hour, 7)
        XCTAssertEqual(plan?.minute, 30)
    }

    func testPlannerCreatesPlanForEachSelectedLeadTime() {
        let habit = reminderHabit(
            schedule: .daily,
            leadTimes: [.oneHourBefore, .rightOnTime, .fifteenMinutesBefore, .thirtyMinutesBefore]
        )
        let plans = planner.plans(habits: [habit], entries: [], referenceDate: date("2026-05-12"))

        XCTAssertEqual(plans.map(\.leadTime), [.oneHourBefore, .rightOnTime, .fifteenMinutesBefore, .thirtyMinutesBefore])
        XCTAssertEqual(plans.map(\.hour), [6, 7, 7, 7])
        XCTAssertEqual(plans.map(\.minute), [30, 30, 15, 0])
    }

    func testWeekdayScheduleCreatesWeekdaySpecificPlans() {
        let habit = reminderHabit(schedule: .weekdays([.monday, .wednesday]))
        let plans = planner.plans(habits: [habit], entries: [], referenceDate: date("2026-05-11"))

        XCTAssertEqual(plans.map(\.targetDate), [date("2026-05-11"), date("2026-05-13")])
    }

    func testWeekdaySchedulePlansWhenSyncingOnOffScheduleDay() {
        let habit = reminderHabit(schedule: .weekdays([.monday, .wednesday]))
        let plans = planner.plans(habits: [habit], entries: [], referenceDate: date("2026-05-12"))

        XCTAssertTrue(planner.shouldSchedule(habit: habit, entries: [], referenceDate: date("2026-05-12")))
        XCTAssertEqual(plans.map(\.targetDate), [date("2026-05-18"), date("2026-05-13")])
    }

    func testWeekdayLeadTimeCrossingMidnightSchedulesPreviousWeekday() {
        let habit = reminderHabit(schedule: .weekdays([.monday]), hour: 0, minute: 30, leadTimes: [.oneHourBefore])
        let plan = planner.plans(habits: [habit], entries: [], referenceDate: date("2026-05-11")).first

        XCTAssertNil(plan?.weekday)
        XCTAssertEqual(plan?.targetDate, date("2026-05-17"))
        XCTAssertEqual(plan?.hour, 23)
        XCTAssertEqual(plan?.minute, 30)
    }

    func testWeekdayLeadTimeSchedulesConcreteNearFutureReminderToday() {
        let habit = reminderHabit(schedule: .weekdays([.sunday]), hour: 2, minute: 55, leadTimes: [.fifteenMinutesBefore])
        let plan = planner.plans(habits: [habit], entries: [], referenceDate: dateTime("2026-05-17 02:39:00")).first

        XCTAssertEqual(plan?.leadTime, .fifteenMinutesBefore)
        XCTAssertEqual(plan?.targetDate, date("2026-05-17"))
        XCTAssertEqual(plan?.hour, 2)
        XCTAssertEqual(plan?.minute, 40)
    }

    func testWeekdayLeadTimeMovesToNextWeekWhenLeadTimeAlreadyPassedToday() {
        let habit = reminderHabit(schedule: .weekdays([.sunday]), hour: 2, minute: 55, leadTimes: [.fifteenMinutesBefore])
        let plan = planner.plans(habits: [habit], entries: [], referenceDate: dateTime("2026-05-17 02:41:00")).first

        XCTAssertEqual(plan?.targetDate, date("2026-05-24"))
        XCTAssertEqual(plan?.hour, 2)
        XCTAssertEqual(plan?.minute, 40)
    }

    func testIntervalScheduleOnlyPlansDueDateOneShotReminder() {
        let habit = reminderHabit(schedule: .interval(everyDays: 3, startDate: date("2026-05-12")))
        let dueDate = date("2026-05-15")
        let plans = planner.plans(habits: [habit], entries: [], referenceDate: dueDate)

        XCTAssertEqual(plans.count, 1)
        XCTAssertNil(plans.first?.weekday)
        XCTAssertEqual(plans.first?.targetDate, dueDate)
    }

    func testIntervalSchedulePlansNextDueDateFromOffScheduleSync() {
        let habit = reminderHabit(schedule: .interval(everyDays: 3, startDate: date("2026-05-12")))
        let plans = planner.plans(habits: [habit], entries: [], referenceDate: date("2026-05-14"))

        XCTAssertTrue(planner.shouldSchedule(habit: habit, entries: [], referenceDate: date("2026-05-14")))
        XCTAssertEqual(plans.count, 1)
        XCTAssertEqual(plans.first?.targetDate, date("2026-05-15"))
    }

    func testIntervalScheduleSkipsCompletedDueDateForNextReminder() {
        let habit = reminderHabit(schedule: .interval(everyDays: 3, startDate: date("2026-05-12")))
        let dueDate = date("2026-05-15")
        let entries = [HabitEntry(habitID: habit.id, targetDate: dueDate, completedAt: dueDate, source: .normal)]
        let plans = planner.plans(habits: [habit], entries: entries, referenceDate: dueDate)

        XCTAssertEqual(plans.count, 1)
        XCTAssertEqual(plans.first?.targetDate, date("2026-05-18"))
    }

    func testIntervalLeadTimeCrossingMidnightSchedulesPreviousDate() {
        let habit = reminderHabit(
            schedule: .interval(everyDays: 3, startDate: date("2026-05-12")),
            hour: 0,
            minute: 30,
            leadTimes: [.oneHourBefore]
        )
        let plans = planner.plans(habits: [habit], entries: [], referenceDate: date("2026-05-15"))

        XCTAssertEqual(plans.first?.targetDate, date("2026-05-14"))
        XCTAssertEqual(plans.first?.hour, 23)
        XCTAssertEqual(plans.first?.minute, 30)
    }

    private func reminderHabit(
        schedule: HabitSchedule,
        message: String = "",
        hour: Int = 7,
        minute: Int = 30,
        leadTimes: Set<ReminderLeadTime> = [.rightOnTime]
    ) -> Habit {
        Habit(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            name: "Morning Walk",
            symbolName: "figure.walk",
            color: .green,
            schedule: schedule,
            reminder: HabitReminder(isEnabled: true, hour: hour, minute: minute, message: message, leadTimes: leadTimes),
            createdAt: date("2026-01-01")
        )
    }

    private func date(_ string: String) -> Date {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: string)!
    }

    private func dateTime(_ string: String) -> Date {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.date(from: string)!
    }
}
