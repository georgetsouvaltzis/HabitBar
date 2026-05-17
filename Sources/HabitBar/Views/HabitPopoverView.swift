import HabitBarCore
import SwiftUI

struct HabitPopoverView: View {
    @Bindable var model: HabitBarModel

    var body: some View {
        VStack(spacing: 0) {
            header

            Group {
                if model.isShowingEditor, let editingHabit = model.editingHabit {
                    HabitEditorView(habit: editingHabit, model: model)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                } else if model.isShowingArchive {
                    archiveView
                } else if model.activeHabits.isEmpty {
                    EmptyStateView {
                        model.addHabit()
                    }
                } else {
                    VStack(spacing: 12) {
                        TodaySummaryView(model: model)
                            .padding(.horizontal, 12)

                        ScrollView {
                            LazyVStack(spacing: 10) {
                                ForEach(model.activeHabits) { habit in
                                    HabitCardView(habit: habit, isSelected: model.selectedHabitID == habit.id, model: model)
                                        .accessibilityIdentifier(AccessibilityID.habitRow(habit.id.uuidString))
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.bottom, 12)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if !model.isShowingEditor {
                footer
            }
        }
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(Color.black.opacity(0.08))
                .ignoresSafeArea()
        }
        .accessibilityIdentifier(AccessibilityID.menuRoot)
        .alert("Habit Bar", isPresented: Binding(
            get: { model.errorMessage != nil },
            set: { if !$0 { model.errorMessage = nil } }
        )) {
            Button("OK") { model.errorMessage = nil }
        } message: {
            Text(model.errorMessage ?? "")
        }
    }

    private var header: some View {
        Group {
            if model.isShowingEditor, let editingHabit = model.editingHabit {
                HStack {
                    Spacer()

                    Text(editorTitle(for: editingHabit))
                        .font(.system(size: 15, weight: .semibold, design: .rounded))

                    Spacer()

                    Button {
                        model.editingHabit = nil
                        model.isShowingEditor = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 17, weight: .semibold))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Cancel")
                }
            } else {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Habit Bar")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                        Text("Today")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, model.isShowingEditor ? 12 : 16)
        .padding(.bottom, model.isShowingEditor ? 8 : 12)
    }

    private func editorTitle(for habit: Habit) -> String {
        model.snapshot.habits.contains(where: { $0.id == habit.id }) ? "Edit Habit" : "New Habit"
    }

    private var footer: some View {
        HStack {
            Button {
                model.addHabit()
            } label: {
                Label("Add", systemImage: "plus")
            }
            .accessibilityIdentifier(AccessibilityID.addHabit)

            Spacer()

            Button {
                model.isShowingArchive.toggle()
            } label: {
                Label(
                    model.isShowingArchive ? "Today" : "Archive",
                    systemImage: model.isShowingArchive ? "list.bullet" : "archivebox"
                )
            }
            .accessibilityIdentifier(AccessibilityID.archive)
        }
        .buttonStyle(FooterButtonStyle())
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background {
            Rectangle()
                .fill(.thinMaterial)
                .overlay(alignment: .top) {
                    Divider().opacity(0.45)
                }
        }
    }

    private var archiveView: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                if model.archivedHabits.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "archivebox")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        Text("No archived habits")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 320)
                } else {
                    ForEach(model.archivedHabits) { habit in
                        HStack {
                            Label(habit.name, systemImage: habit.symbolName)
                                .lineLimit(1)

                            Spacer()

                            Button("Restore \(habit.name)") {
                                model.restore(habit)
                            }
                        }
                        .padding(12)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }
            }
            .padding(12)
        }
    }
}

private struct TodaySummaryView: View {
    @Bindable var model: HabitBarModel

    var body: some View {
        HStack(spacing: 0) {
            SummaryMetric(
                title: "day streak",
                value: "\(bestCurrentStreak)",
                systemImage: "flame",
                tint: .green
            )
            SummaryDivider()
            SummaryMetric(
                title: "done",
                value: "\(completedToday)",
                systemImage: "checkmark.circle.fill",
                tint: .green
            )
            SummaryDivider()
            SummaryMetric(
                title: "up next",
                value: "\(remainingToday)",
                systemImage: "flame.fill",
                tint: .orange
            )
            SummaryDivider()
            SummaryMetric(
                title: "week",
                value: "\(weekCompletionPercent)%",
                systemImage: "chart.line.uptrend.xyaxis",
                tint: .blue
            )
        }
        .padding(.vertical, 10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.secondary.opacity(0.14), lineWidth: 1)
        }
    }

    private var completedToday: Int {
        model.activeHabits.filter { habit in
            if case .completed = model.dayState(for: habit, date: Date()) {
                return true
            }
            return false
        }.count
    }

    private var remainingToday: Int {
        model.activeHabits.filter { habit in
            switch model.dayState(for: habit, date: Date()) {
            case .today, .graceEligible:
                return true
            case .completed, .missed, .future, .offSchedule:
                return false
            }
        }.count
    }

    private var bestCurrentStreak: Int {
        model.activeHabits.map { model.stats(for: $0).currentStreak }.max() ?? 0
    }

    private var weekCompletionPercent: Int {
        let stats = model.activeHabits.map { model.stats(for: $0) }
        let due = stats.reduce(0) { $0 + $1.dueThisWeek }
        guard due > 0 else { return 0 }
        let completed = stats.reduce(0) { $0 + $1.completedThisWeek }
        return Int((Double(completed) / Double(due) * 100).rounded())
    }
}

private struct SummaryMetric: View {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(spacing: 3) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(tint)
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .monospacedDigit()
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }
}

private struct SummaryDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.secondary.opacity(0.16))
            .frame(width: 1, height: 52)
    }
}

private struct FooterButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            .opacity(configuration.isPressed ? 0.72 : 1)
    }
}
