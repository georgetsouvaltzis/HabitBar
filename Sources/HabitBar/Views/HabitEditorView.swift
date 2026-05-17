import HabitBarCore
import SwiftUI

struct HabitEditorView: View {
    @Environment(\.colorScheme) private var colorScheme

    private static let editorContentWidth: CGFloat = 360
    private static let reminderLabelWidth: CGFloat = 88
    private static let reminderColumnSpacing: CGFloat = 16

    @State private var draft: Habit
    @State private var selectedWeekdays: Set<Weekday>
    @Bindable var model: HabitBarModel

    private let symbols = [
        "figure.walk",
        "book.fill",
        "drop.fill",
        "leaf.fill",
        "cube.box.fill",
        "dumbbell.fill",
        "pencil"
    ]

    private let colorOptions: [HabitColor] = [
        .green,
        .blue,
        .violet,
        HabitColor(red: 0.92, green: 0.24, blue: 0.42),
        .orange,
        HabitColor(red: 0.95, green: 0.68, blue: 0.04),
        .cyan
    ]

    init(habit: Habit, model: HabitBarModel) {
        _draft = State(initialValue: habit)
        _selectedWeekdays = State(initialValue: habit.weekdayValue)
        self.model = model
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                formContent
                    .frame(width: Self.editorContentWidth, alignment: .leading)
                    .padding(.top, 2)
                    .padding(.bottom, 18)
            }

            actionRow
                .frame(width: Self.editorContentWidth, alignment: .trailing)
                .padding(.top, 8)
                .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 24)
    }

    private var formContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            EditorSection(title: "Name") {
                TextField("Morning Walk", text: $draft.name)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier(AccessibilityID.habitNameField)
            }

            EditorSection(title: "Icon") {
                HStack(spacing: 8) {
                    ForEach(symbols, id: \.self) { symbol in
                        EditorIconButton(
                            systemImage: symbol,
                            isSelected: draft.symbolName == symbol,
                            accent: accent
                        ) {
                            draft.symbolName = symbol
                        }
                    }
                }
                .frame(width: Self.editorContentWidth, alignment: .leading)
            }
            .padding(.bottom, 4)

            EditorSection(title: "Color") {
                HStack(spacing: 6) {
                    ForEach(colorOptions, id: \.self) { color in
                        ColorSwatch(
                            color: color,
                            isSelected: draft.color == color,
                            colorScheme: colorScheme
                        ) {
                            draft.color = color
                        }
                    }
                }
                .frame(width: Self.editorContentWidth, alignment: .leading)
            }

            EditorSection(title: "Days") {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(weekdayRows, id: \.self) { row in
                        HStack(spacing: 10) {
                            ForEach(row) { weekday in
                                WeekdayChip(
                                    title: weekday.shortTitle,
                                    isSelected: selectedWeekdays.contains(weekday),
                                    accent: accent
                                ) {
                                    setWeekday(weekday, isSelected: !selectedWeekdays.contains(weekday))
                                }
                            }
                        }
                    }
                }
            }

            Divider().opacity(0.5)
                .padding(.vertical, 2)

            reminderSection
        }
    }

    private var reminderSection: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                Text("Reminder")
                    .font(.system(size: 13, weight: .semibold))

                Spacer()

                Toggle("", isOn: $draft.reminder.isEnabled)
                    .toggleStyle(.switch)
                    .tint(accent)
                    .labelsHidden()
            }
            .padding(.bottom, 2)

            reminderRow("Time") {
                ReminderTimePicker(reminder: $draft.reminder, isEnabled: draft.reminder.isEnabled)
            }
            .opacity(draft.reminder.isEnabled ? 1 : 0.58)

            reminderRow("Schedule", alignment: .top) {
                ReminderLeadTimePicker(reminder: $draft.reminder, accent: accent, isEnabled: draft.reminder.isEnabled)
            }
            .opacity(draft.reminder.isEnabled ? 1 : 0.58)

            VStack(alignment: .leading, spacing: 4) {
                reminderRow("Notification") {
                    TextField("Notification message", text: $draft.reminder.message)
                        .textFieldStyle(.roundedBorder)
                        .disabled(!draft.reminder.isEnabled)
                }

                Text("This is the notification message you'll receive.")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                    .padding(.leading, Self.reminderLabelWidth + Self.reminderColumnSpacing)
            }
            .opacity(draft.reminder.isEnabled ? 1 : 0.58)
        }
    }

    private func reminderRow<Content: View>(
        _ title: String,
        alignment: VerticalAlignment = .center,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(alignment: alignment, spacing: Self.reminderColumnSpacing) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: Self.reminderLabelWidth, alignment: .leading)

            content()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var actionRow: some View {
        HStack(spacing: 12) {
            Spacer()

            Button("Cancel", action: closeEditor)
                .buttonStyle(EditorSecondaryButtonStyle())
                .frame(width: 86)

            Button("Save") {
                model.saveEditedHabit(draft)
            }
            .keyboardShortcut(.defaultAction)
            .buttonStyle(EditorPrimaryButtonStyle(accent: accent))
            .accessibilityIdentifier(AccessibilityID.saveHabit)
            .frame(width: 86)
        }
        .padding(.top, 4)
    }

    private var accent: Color {
        Color(habitColor: draft.color, colorScheme: colorScheme)
    }

    private var weekdayRows: [[Weekday]] {
        [
            Array(Weekday.mondayFirst.prefix(5)),
            Array(Weekday.mondayFirst.suffix(2))
        ]
    }

    private func closeEditor() {
        model.editingHabit = nil
        model.isShowingEditor = false
    }

    private func setWeekday(_ weekday: Weekday, isSelected: Bool) {
        if isSelected {
            selectedWeekdays.insert(weekday)
        } else {
            selectedWeekdays.remove(weekday)
        }

        draft.schedule = .weekdays(selectedWeekdays)
    }

}

private struct EditorSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
            content
        }
    }
}

private struct EditorIconButton: View {
    let systemImage: String
    let isSelected: Bool
    let accent: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .stroke(isSelected ? accent.opacity(0.9) : Color.secondary.opacity(0.16), lineWidth: isSelected ? 2 : 1)
                    .frame(width: isSelected ? 40 : 34, height: isSelected ? 40 : 34)

                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isSelected ? .white : .secondary)
                    .frame(width: 34, height: 34)
                    .background(isSelected ? AnyShapeStyle(accent) : AnyShapeStyle(.thinMaterial), in: Circle())
            }
            .frame(width: 42, height: 42)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(systemImage)
    }
}

private struct ColorSwatch: View {
    let color: HabitColor
    let isSelected: Bool
    let colorScheme: ColorScheme
    let action: () -> Void

    var body: some View {
        let displayColor = Color(habitColor: color, colorScheme: colorScheme)

        Button(action: action) {
            ZStack {
                Circle()
                    .stroke(isSelected ? displayColor : Color.secondary.opacity(0.18), lineWidth: isSelected ? 2 : 1)
                    .frame(width: isSelected ? 38 : 29, height: isSelected ? 38 : 29)

                Circle()
                    .fill(displayColor)
                    .frame(width: 27, height: 27)

                if isSelected {
                    Circle()
                        .stroke(.white.opacity(0.95), lineWidth: 2)
                        .frame(width: 23, height: 23)
                }
            }
            .frame(width: 42, height: 42)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Color")
    }
}

private struct WeekdayChip: View {
    let title: String
    let isSelected: Bool
    let accent: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .lineLimit(1)
                .frame(width: 54)
                .padding(.vertical, 6)
                .background(isSelected ? AnyShapeStyle(accent) : AnyShapeStyle(.thinMaterial), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

private struct EditorPrimaryButtonStyle: ButtonStyle {
    let accent: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(accent, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .opacity(configuration.isPressed ? 0.72 : 1)
    }
}

private struct EditorSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .opacity(configuration.isPressed ? 0.72 : 1)
    }
}

private extension Habit {
    var weekdayValue: Set<Weekday> {
        if case .weekdays(let weekdays) = schedule {
            return weekdays
        }
        return [.monday, .tuesday, .wednesday, .thursday, .friday]
    }
}
