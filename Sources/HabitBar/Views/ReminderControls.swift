import HabitBarCore
import SwiftUI

struct ReminderTimePicker: View {
    @Binding var reminder: HabitReminder

    let isEnabled: Bool

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 9) {
                TimeStepper(value: hourBinding, range: 1...12, label: "Hour") { hour in
                    "\(hour)"
                }
                .frame(width: 58)

                Text(":")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.tertiary)

                TimeStepper(value: $reminder.minute, range: 0...59, label: "Minute") { minute in
                    String(format: "%02d", minute)
                }
                .frame(width: 62)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
            }

            Picker("Period", selection: periodBinding) {
                Text("AM").tag(TimePeriod.am)
                Text("PM").tag(TimePeriod.pm)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 82)
        }
        .frame(width: 256, alignment: .leading)
        .disabled(!isEnabled)
    }

    private var hourBinding: Binding<Int> {
        Binding {
            reminder.displayHour
        } set: { newValue in
            reminder.setDisplayHour(newValue)
        }
    }

    private var periodBinding: Binding<TimePeriod> {
        Binding {
            reminder.timePeriod
        } set: { newValue in
            reminder.setTimePeriod(newValue)
        }
    }
}

private struct TimeStepper: View {
    @Binding var value: Int
    @State private var text: String
    @FocusState private var isFocused: Bool

    let range: ClosedRange<Int>
    let label: String
    let format: (Int) -> String

    init(value: Binding<Int>, range: ClosedRange<Int>, label: String, format: @escaping (Int) -> String) {
        _value = value
        _text = State(initialValue: format(value.wrappedValue))
        self.range = range
        self.label = label
        self.format = format
    }

    var body: some View {
        HStack(spacing: 8) {
            TextField(label, text: $text)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .textFieldStyle(.plain)
                .multilineTextAlignment(.trailing)
                .lineLimit(1)
                .frame(width: 30)
                .focused($isFocused)
                .onSubmit(commitText)
                .onChange(of: text) { _, newValue in
                    updateValue(from: newValue)
                }
                .onChange(of: value) { _, newValue in
                    if !isFocused {
                        text = format(newValue)
                    }
                }
                .onChange(of: isFocused) { _, hasFocus in
                    if !hasFocus {
                        commitText()
                    }
                }
                .onDisappear(perform: commitText)

            Stepper(label, onIncrement: incrementValue, onDecrement: decrementValue)
                .labelsHidden()
                .controlSize(.small)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
        .accessibilityValue(format(value))
    }

    private func updateValue(from text: String) {
        let sanitizedText = sanitized(text)
        if sanitizedText != text {
            self.text = sanitizedText
            return
        }

        guard let typedValue = Int(sanitizedText) else { return }

        let clampedValue = min(max(typedValue, range.lowerBound), range.upperBound)
        value = clampedValue
        if typedValue != clampedValue {
            self.text = format(clampedValue)
        }
    }

    private func commitText() {
        guard let typedValue = Int(sanitized(text)) else {
            text = format(value)
            return
        }

        value = min(max(typedValue, range.lowerBound), range.upperBound)
        text = format(value)
    }

    private func incrementValue() {
        let currentValue = committedValue()
        let nextValue = currentValue >= range.upperBound ? range.lowerBound : currentValue + 1
        setValue(nextValue)
    }

    private func decrementValue() {
        let currentValue = committedValue()
        let nextValue = currentValue <= range.lowerBound ? range.upperBound : currentValue - 1
        setValue(nextValue)
    }

    private func committedValue() -> Int {
        guard let typedValue = Int(sanitized(text)) else { return value }
        return min(max(typedValue, range.lowerBound), range.upperBound)
    }

    private func setValue(_ newValue: Int) {
        value = newValue
        text = format(newValue)
    }

    private func sanitized(_ text: String) -> String {
        let digits = text.filter(\.isNumber)
        return String(digits.prefix(String(range.upperBound).count))
    }
}

struct ReminderLeadTimePicker: View {
    @Binding var reminder: HabitReminder

    let accent: Color
    let isEnabled: Bool

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
            ForEach(ReminderLeadTime.allCases, id: \.self) { leadTime in
                ReminderLeadTimeChip(
                    title: leadTime.title,
                    isSelected: reminder.leadTimes.contains(leadTime),
                    accent: accent
                ) {
                    toggle(leadTime)
                }
                .disabled(!isEnabled)
            }
        }
        .frame(width: 256, alignment: .leading)
    }

    private var columns: [GridItem] {
        [
            GridItem(.flexible(minimum: 118), spacing: 10),
            GridItem(.flexible(minimum: 118), spacing: 10)
        ]
    }

    private func toggle(_ leadTime: ReminderLeadTime) {
        if reminder.leadTimes.contains(leadTime), reminder.leadTimes.count > 1 {
            reminder.leadTimes.remove(leadTime)
        } else {
            reminder.leadTimes.insert(leadTime)
        }
    }
}

private struct ReminderLeadTimeChip: View {
    let title: String
    let isSelected: Bool
    let accent: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity, minHeight: 24)
                .padding(.horizontal, 8)
                .background(isSelected ? AnyShapeStyle(accent) : AnyShapeStyle(.thinMaterial), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

enum TimePeriod: String, Hashable {
    case am
    case pm
}

private extension HabitReminder {
    var displayHour: Int {
        hour % 12 == 0 ? 12 : hour % 12
    }

    var timePeriod: TimePeriod {
        hour >= 12 ? .pm : .am
    }

    mutating func setDisplayHour(_ displayHour: Int) {
        let normalizedHour = displayHour == 12 ? 0 : displayHour
        hour = timePeriod == .pm ? normalizedHour + 12 : normalizedHour
    }

    mutating func setTimePeriod(_ period: TimePeriod) {
        let currentDisplayHour = displayHour
        hour = period == .pm
            ? (currentDisplayHour == 12 ? 12 : currentDisplayHour + 12)
            : (currentDisplayHour == 12 ? 0 : currentDisplayHour)
    }
}
