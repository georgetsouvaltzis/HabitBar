import XCTest
@testable import HabitBarCore

final class HabitRuleEngineTests: XCTestCase {
    private var calendar: Calendar!
    private var engine: HabitRuleEngine!

    override func setUp() {
        super.setUp()
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        engine = HabitRuleEngine(habitCalendar: HabitCalendar(calendar: calendar))
    }

    func testDailyStreakSkipsTodayWhenPending() {
        let habit = habit(schedule: .daily)
        let today = date("2026-05-12")
        let entries = [
            entry(habit, "2026-05-11"),
            entry(habit, "2026-05-10")
        ]

        let stats = engine.stats(for: habit, entries: entries, referenceDate: today)

        XCTAssertEqual(stats.currentStreak, 2)
        XCTAssertEqual(stats.bestStreak, 2)
    }

    func testYesterdayGraceDoesNotBreakCurrentStreak() {
        let habit = habit(schedule: .daily)
        let today = date("2026-05-12")
        let entries = [
            entry(habit, "2026-05-10"),
            entry(habit, "2026-05-09")
        ]

        let stats = engine.stats(for: habit, entries: entries, referenceDate: today)
        let yesterdayState = engine.dayState(
            habit: habit,
            entries: entries,
            date: date("2026-05-11"),
            referenceDate: today
        )

        XCTAssertEqual(stats.currentStreak, 2)
        XCTAssertEqual(yesterdayState, .graceEligible)
    }

    func testOlderMissBreaksCurrentStreak() {
        let habit = habit(schedule: .daily)
        let today = date("2026-05-12")
        let entries = [
            entry(habit, "2026-05-09"),
            entry(habit, "2026-05-08")
        ]

        let stats = engine.stats(for: habit, entries: entries, referenceDate: today)

        XCTAssertEqual(stats.currentStreak, 0)
        XCTAssertEqual(stats.bestStreak, 2)
    }

    func testWeekdayScheduleIgnoresOffDays() {
        let habit = habit(schedule: .weekdays([.monday, .wednesday, .friday]))
        let friday = date("2026-05-15")
        let entries = [
            entry(habit, "2026-05-13"),
            entry(habit, "2026-05-11")
        ]

        let stats = engine.stats(for: habit, entries: entries, referenceDate: friday)
        let thursdayState = engine.dayState(
            habit: habit,
            entries: entries,
            date: date("2026-05-14"),
            referenceDate: friday
        )

        XCTAssertEqual(stats.currentStreak, 2)
        XCTAssertEqual(thursdayState, .offSchedule)
    }

    func testForwardFilledDaysExtendCurrentAndBestStreak() {
        let habit = habit(schedule: .weekdays([.monday, .tuesday, .wednesday, .thursday, .friday]))
        let today = date("2026-05-15")
        let entries = [
            entry(habit, "2026-05-15"),
            entry(habit, "2026-05-18"),
            entry(habit, "2026-05-19")
        ]

        let stats = engine.stats(for: habit, entries: entries, referenceDate: today)

        XCTAssertEqual(stats.currentStreak, 3)
        XCTAssertEqual(stats.bestStreak, 3)
    }

    func testBestStreakUsesPreviousCompletedRun() {
        let habit = habit(schedule: .weekdays([.monday, .tuesday, .wednesday, .thursday, .friday]))
        let today = date("2026-05-15")
        let entries = [
            entry(habit, "2026-05-04"),
            entry(habit, "2026-05-05"),
            entry(habit, "2026-05-06"),
            entry(habit, "2026-05-07"),
            entry(habit, "2026-05-08"),
            entry(habit, "2026-05-14"),
            entry(habit, "2026-05-15")
        ]

        let stats = engine.stats(for: habit, entries: entries, referenceDate: today)

        XCTAssertEqual(stats.currentStreak, 2)
        XCTAssertEqual(stats.bestStreak, 5)
    }

    func testBestStreakIncludesCurrentWeekRun() {
        let habit = habit(schedule: .weekdays([.monday, .tuesday, .wednesday, .thursday, .friday]))
        let today = date("2026-05-15")
        let entries = [
            entry(habit, "2026-05-11"),
            entry(habit, "2026-05-12"),
            entry(habit, "2026-05-13"),
            entry(habit, "2026-05-14"),
            entry(habit, "2026-05-15")
        ]

        let stats = engine.stats(for: habit, entries: entries, referenceDate: today)

        XCTAssertEqual(stats.currentStreak, 5)
        XCTAssertEqual(stats.bestStreak, 5)
    }

    func testBestStreakUsesVisibleLongerRunWhenForwardFillIsCurrent() {
        calendar.timeZone = TimeZone(secondsFromGMT: 4 * 60 * 60)!
        engine = HabitRuleEngine(habitCalendar: HabitCalendar(calendar: calendar))

        let habit = habit(
            schedule: .weekdays([.monday, .tuesday, .wednesday, .thursday, .friday]),
            createdAt: date("2026-05-15")
        )
        let today = date("2026-05-15")
        let entries = [
            entry(habit, "2026-05-04"),
            entry(habit, "2026-05-05"),
            entry(habit, "2026-05-06"),
            entry(habit, "2026-05-07"),
            entry(habit, "2026-05-08"),
            entry(habit, "2026-05-11"),
            entry(habit, "2026-05-12"),
            entry(habit, "2026-05-13"),
            entry(habit, "2026-05-14"),
            entry(habit, "2026-05-15"),
            entry(habit, "2026-05-26"),
            entry(habit, "2026-05-27"),
            entry(habit, "2026-05-28")
        ]

        let stats = engine.stats(for: habit, entries: entries, referenceDate: today)

        XCTAssertEqual(stats.currentStreak, 3)
        XCTAssertEqual(stats.bestStreak, 10)
        XCTAssertEqual(stats.completedThisWeek, 5)
        XCTAssertEqual(stats.dueThisWeek, 5)
    }

    func testForwardFillAfterMissedTrackingDayStartsNewCurrentStreak() {
        let habit = habit(schedule: .weekdays([.sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday]))
        let today = date("2026-05-15")
        let entries = [
            entry(habit, "2026-05-04"),
            entry(habit, "2026-05-05"),
            entry(habit, "2026-05-06"),
            entry(habit, "2026-05-07"),
            entry(habit, "2026-05-08"),
            entry(habit, "2026-05-09"),
            entry(habit, "2026-05-10"),
            entry(habit, "2026-05-11"),
            entry(habit, "2026-05-12"),
            entry(habit, "2026-05-13"),
            entry(habit, "2026-05-14"),
            entry(habit, "2026-05-15"),
            entry(habit, "2026-05-17")
        ]

        let stats = engine.stats(for: habit, entries: entries, referenceDate: today)

        XCTAssertEqual(stats.currentStreak, 1)
        XCTAssertEqual(stats.bestStreak, 12)
    }

    func testWeekdayBackfillBeforeCreationCountsInStreakStats() {
        let habit = habit(
            schedule: .weekdays([.monday, .tuesday, .wednesday, .thursday, .friday]),
            createdAt: date("2026-05-15")
        )
        let today = date("2026-05-15")
        let entries = [
            entry(habit, "2026-05-11"),
            entry(habit, "2026-05-12"),
            entry(habit, "2026-05-13"),
            entry(habit, "2026-05-14"),
            entry(habit, "2026-05-15")
        ]

        let stats = engine.stats(for: habit, entries: entries, referenceDate: today)

        XCTAssertEqual(stats.currentStreak, 5)
        XCTAssertEqual(stats.bestStreak, 5)
        XCTAssertEqual(stats.completedThisWeek, 5)
        XCTAssertEqual(stats.dueThisWeek, 5)
    }

    func testThisWeekCountsSelectedDaysEvenWhenHabitWasCreatedToday() {
        let habit = habit(
            schedule: .weekdays([.monday, .tuesday, .wednesday, .thursday, .friday]),
            createdAt: date("2026-05-15")
        )
        let today = date("2026-05-15")
        let entries = [
            entry(habit, "2026-05-11"),
            entry(habit, "2026-05-12"),
            entry(habit, "2026-05-13"),
            entry(habit, "2026-05-14"),
            entry(habit, "2026-05-15")
        ]

        let stats = engine.stats(for: habit, entries: entries, referenceDate: today)

        XCTAssertEqual(stats.completedThisWeek, 5)
        XCTAssertEqual(stats.dueThisWeek, 5)
        XCTAssertEqual(stats.completionRate, 1)
    }

    func testCompletionRateUsesSelectedWeekProgress() {
        let habit = habit(
            schedule: .weekdays([.monday, .tuesday, .wednesday, .thursday, .friday]),
            createdAt: date("2026-05-15")
        )
        let today = date("2026-05-15")
        let entries = [
            entry(habit, "2026-05-11"),
            entry(habit, "2026-05-12"),
            entry(habit, "2026-05-13"),
            entry(habit, "2026-05-14")
        ]

        let stats = engine.stats(for: habit, entries: entries, referenceDate: today)

        XCTAssertEqual(stats.completedThisWeek, 4)
        XCTAssertEqual(stats.dueThisWeek, 5)
        XCTAssertEqual(stats.completionRate, 0.8, accuracy: 0.001)
    }

    func testCompletionRateExcludesUnselectedWeekendDays() {
        let habit = habit(schedule: .weekdays([.monday, .tuesday, .wednesday, .thursday, .friday]))
        let today = date("2026-05-15")
        let entries = [
            entry(habit, "2026-05-11"),
            entry(habit, "2026-05-12"),
            entry(habit, "2026-05-13"),
            entry(habit, "2026-05-14"),
            entry(habit, "2026-05-15"),
            entry(habit, "2026-05-16"),
            entry(habit, "2026-05-17")
        ]

        let stats = engine.stats(for: habit, entries: entries, referenceDate: today)

        XCTAssertEqual(stats.completedThisWeek, 5)
        XCTAssertEqual(stats.dueThisWeek, 5)
        XCTAssertEqual(stats.completionRate, 1)
    }

    func testWeekStatsUseMondayBoundaryEvenWhenCalendarStartsOnSunday() {
        calendar.firstWeekday = 1
        engine = HabitRuleEngine(habitCalendar: HabitCalendar(calendar: calendar))

        let habit = habit(schedule: .weekdays([.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday]))
        let sunday = date("2026-05-17")
        let entries = [
            entry(habit, "2026-05-11"),
            entry(habit, "2026-05-12"),
            entry(habit, "2026-05-13"),
            entry(habit, "2026-05-14"),
            entry(habit, "2026-05-15"),
            entry(habit, "2026-05-16"),
            entry(habit, "2026-05-17")
        ]

        let stats = engine.stats(for: habit, entries: entries, referenceDate: sunday)

        XCTAssertEqual(engine.habitCalendar.startOfWeek(containing: sunday), date("2026-05-11"))
        XCTAssertEqual(stats.completedThisWeek, 7)
        XCTAssertEqual(stats.dueThisWeek, 7)
        XCTAssertEqual(stats.completionRate, 1)
    }

    func testEmptyWeekdayScheduleHasNoDueDays() {
        let habit = habit(schedule: .weekdays([]))
        let today = date("2026-05-15")
        let entries = [
            entry(habit, "2026-05-15")
        ]

        let stats = engine.stats(for: habit, entries: entries, referenceDate: today)
        let todayState = engine.dayState(habit: habit, entries: [], date: today, referenceDate: today)

        XCTAssertEqual(todayState, .offSchedule)
        XCTAssertEqual(stats.completedThisWeek, 0)
        XCTAssertEqual(stats.dueThisWeek, 0)
        XCTAssertEqual(stats.completionRate, 0)
    }

    func testDatesBeforeHabitCreationAreOffSchedule() {
        let habit = habit(schedule: .daily, createdAt: date("2026-05-12"))
        let today = date("2026-05-14")

        let state = engine.dayState(
            habit: habit,
            entries: [],
            date: date("2026-05-11"),
            referenceDate: today
        )
        let stats = engine.stats(for: habit, entries: [], referenceDate: today)
        let dueDates = engine.dueDates(for: habit, through: today, lookbackDays: 7)

        XCTAssertEqual(state, .offSchedule)
        XCTAssertEqual(dueDates, [date("2026-05-12"), date("2026-05-13"), date("2026-05-14")])
        XCTAssertEqual(stats.dueThisWeek, 3)
    }

    func testDisabledGraceMakesYesterdayMissed() {
        let habit = habit(schedule: .daily, allowsGrace: false)
        let today = date("2026-05-12")

        let yesterdayState = engine.dayState(
            habit: habit,
            entries: [],
            date: date("2026-05-11"),
            referenceDate: today
        )

        XCTAssertEqual(yesterdayState, .missed)
    }

    func testWeeklyQuotaStreakAdvancesWhenQuotaMet() {
        let habit = habit(schedule: .weeklyQuota(3))
        let today = date("2026-05-12")
        let entries = [
            entry(habit, "2026-05-04"),
            entry(habit, "2026-05-05"),
            entry(habit, "2026-05-06")
        ]

        let stats = engine.stats(for: habit, entries: entries, referenceDate: today)

        XCTAssertEqual(stats.currentStreak, 1)
        XCTAssertEqual(stats.bestStreak, 1)
    }

    func testCompletionSourceDistinguishesGraceAndManualBackfill() {
        XCTAssertEqual(
            engine.completionSource(forTargetDate: date("2026-05-11"), completedAt: date("2026-05-12")),
            .grace
        )
        XCTAssertEqual(
            engine.completionSource(forTargetDate: date("2026-05-09"), completedAt: date("2026-05-12")),
            .manualBackfill
        )
    }

    private func habit(schedule: HabitSchedule, allowsGrace: Bool = true, createdAt: Date? = nil) -> Habit {
        Habit(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            name: "Morning Walk",
            symbolName: "figure.walk",
            color: .green,
            schedule: schedule,
            allowsGrace: allowsGrace,
            createdAt: createdAt ?? date("2026-01-01")
        )
    }

    private func entry(_ habit: Habit, _ day: String, source: CompletionSource = .normal) -> HabitEntry {
        HabitEntry(habitID: habit.id, targetDate: date(day), completedAt: date(day), source: source)
    }

    private func date(_ string: String) -> Date {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: string)!
    }
}
