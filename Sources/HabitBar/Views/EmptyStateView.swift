import SwiftUI

struct EmptyStateView: View {
    let addHabit: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
            Text("No active habits")
                .font(.headline)
            Button("Add Habit", action: addHabit)
                .accessibilityIdentifier(AccessibilityID.addHabit)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

