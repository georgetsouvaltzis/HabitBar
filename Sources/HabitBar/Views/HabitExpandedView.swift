import HabitBarCore
import SwiftUI

struct HabitExpandedView: View {
    let habit: Habit
    @Bindable var model: HabitBarModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var isConfirmingDelete = false

    var body: some View {
        let stats = model.stats(for: habit)

        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                MetricView(title: "Current", value: "\(stats.currentStreak)", footnote: "days", accent: accent)
                MetricView(title: "Best", value: "\(stats.bestStreak)", footnote: "days", accent: accent)
                MetricView(
                    title: "Completion",
                    value: "\(Int(stats.completionRate * 100))%",
                    footnote: "\(stats.completedThisWeek) of \(stats.dueThisWeek) this week",
                    accent: accent
                )
                MetricView(title: "Reminder", value: reminderValue, footnote: reminderFootnote, accent: accent)
            }

            HistoryGridView(habit: habit, model: model)

            if isConfirmingDelete {
                HStack {
                    Text("Delete this habit?")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button("Cancel") {
                        isConfirmingDelete = false
                    }

                    Button("Confirm Delete") {
                        model.delete(habit)
                    }
                    .foregroundStyle(.red)
                }
                .font(.caption)
            } else {
                HStack {
                    Button("Edit") {
                        model.edit(habit)
                    }
                    .buttonStyle(ExpandedActionButtonStyle())

                    Spacer()

                    Button("Archive") {
                        model.archive(habit)
                    }
                    .buttonStyle(ExpandedActionButtonStyle())

                    Button("Delete", role: .destructive) {
                        isConfirmingDelete = true
                    }
                    .buttonStyle(ExpandedActionButtonStyle())
                }
                .font(.caption)
            }
        }
    }

    private var accent: Color {
        Color(habitColor: habit.color, colorScheme: colorScheme)
    }

    private var reminderValue: String {
        habit.reminder.isEnabled ? habit.reminder.timeLabel : "Off"
    }

    private var reminderFootnote: String {
        habit.reminder.isEnabled ? habit.schedule.title : "No alert"
    }
}

private struct MetricView: View {
    let title: String
    let value: String
    var footnote: String?
    let accent: Color

    var body: some View {
        VStack(spacing: 3) {
            Text(title)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: value.count > 5 ? 16 : 24, weight: .bold, design: .rounded))
                .foregroundStyle(accent)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            if let footnote {
                Text(footnote)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
    }
}

private struct ExpandedActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            .opacity(configuration.isPressed ? 0.72 : 1)
    }
}
