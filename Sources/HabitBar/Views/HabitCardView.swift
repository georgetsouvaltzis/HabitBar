import HabitBarCore
import SwiftUI

struct HabitCardView: View {
    let habit: Habit
    let isSelected: Bool
    @Bindable var model: HabitBarModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            row
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.snappy) {
                        model.selectedHabitID = isSelected ? nil : habit.id
                    }
                }

            if isSelected {
                HabitExpandedView(habit: habit, model: model)
                    .padding(.top, 14)
            }
        }
        .padding(isSelected ? 14 : 12)
        .background(cardFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isSelected ? accent.opacity(0.72) : Color.secondary.opacity(0.12), lineWidth: isSelected ? 1.4 : 1)
        }
        .shadow(color: .black.opacity(isSelected ? 0.18 : 0.08), radius: isSelected ? 14 : 6, y: isSelected ? 8 : 3)
    }

    private var row: some View {
        HStack(spacing: 13) {
            Image(systemName: habit.symbolName)
                .font(.system(size: isSelected ? 24 : 19, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: isSelected ? 52 : 42, height: isSelected ? 52 : 42)
                .background(accent, in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(habit.name)
                    .lineLimit(1)
                    .font(.system(size: isSelected ? 20 : 16, weight: .bold, design: .rounded))

                Text(habit.schedule.title)
                    .font(.system(size: isSelected ? 13 : 12, weight: .semibold))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if habit.reminder.isEnabled {
                Image(systemName: "bell.fill")
                    .foregroundStyle(.orange)
                    .font(.system(size: 12, weight: .semibold))
            }

            Button {
                model.toggleToday(for: habit)
            } label: {
                Image(systemName: isCompletedToday ? "checkmark.square.fill" : "square")
                    .foregroundStyle(completionTint)
                    .font(.system(size: isSelected ? 24 : 21, weight: .semibold))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isCompletedToday ? "Undo today" : "Complete today")
            .accessibilityIdentifier(AccessibilityID.completeButton(habit.id.uuidString))
            .disabled(!canToggleToday)

            HStack(spacing: 3) {
                Image(systemName: "flame.fill")
                    .font(.caption2)
                Text("\(model.stats(for: habit).currentStreak)")
                    .font(.system(size: isSelected ? 18 : 15, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }
            .foregroundStyle(accent)
            .frame(minWidth: 32, alignment: .trailing)
            .accessibilityLabel("\(model.stats(for: habit).currentStreak) day streak")

            Image(systemName: "chevron.down")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.secondary)
                .rotationEffect(.degrees(isSelected ? 180 : 0))
                .animation(.snappy, value: isSelected)
        }
    }

    private var isCompletedToday: Bool {
        if case .completed = model.dayState(for: habit, date: Date()) {
            return true
        }
        return false
    }

    private var canToggleToday: Bool {
        switch model.dayState(for: habit, date: Date()) {
        case .completed, .today:
            true
        case .graceEligible, .missed, .future, .offSchedule:
            false
        }
    }

    private var completionTint: Color {
        if isCompletedToday {
            return accent
        }

        return canToggleToday ? .secondary : .secondary.opacity(0.32)
    }

    private var accent: Color {
        Color(habitColor: habit.color, colorScheme: colorScheme)
    }

    private var cardFill: some ShapeStyle {
        isSelected ? AnyShapeStyle(.regularMaterial) : AnyShapeStyle(.thinMaterial)
    }
}
