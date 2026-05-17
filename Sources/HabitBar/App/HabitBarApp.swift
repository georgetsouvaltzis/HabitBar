import HabitBarCore
import AppKit
import SwiftUI

@main
struct HabitBarApp: App {
    @Environment(\.openWindow) private var openWindow
    @State private var model = HabitBarModel(uiTesting: ProcessInfo.processInfo.arguments.contains("--ui-testing"))

    var body: some Scene {
        let _ = NotificationRouting.installHandler { habitID in
            openHabit(habitID)
        }

        #if UI_TESTING
        WindowGroup("Habit Bar") {
            HabitPopoverView(model: model)
                .frame(width: 430, height: 620)
                .preferredColorScheme(colorScheme)
        }
        .defaultSize(width: 430, height: 620)
        #else
        MenuBarExtra("Habit Bar", systemImage: "checkmark.square") {
            HabitPopoverView(model: model)
                .frame(width: 430, height: 620)
                .preferredColorScheme(colorScheme)
        }
        .menuBarExtraStyle(.window)
        #endif

        Window("Habit Bar", id: "habit-bar") {
            HabitPopoverView(model: model)
                .frame(width: 430, height: 620)
                .preferredColorScheme(colorScheme)
        }

        Settings {
            SettingsView(model: model)
                .frame(width: 360)
                .preferredColorScheme(colorScheme)
        }
    }

    private func openHabit(_ habitID: UUID) {
        model.showHabitFromNotification(habitID)
        openWindow(id: "habit-bar")
        NSApp.activate(ignoringOtherApps: true)
    }

    private var colorScheme: ColorScheme? {
        switch model.snapshot.theme {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
