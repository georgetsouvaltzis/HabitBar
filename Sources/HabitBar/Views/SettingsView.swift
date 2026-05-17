import HabitBarCore
import AppKit
import SwiftUI
import UserNotifications

struct SettingsView: View {
    @Bindable var model: HabitBarModel
    @State private var notificationStatus = "Checking..."
    @State private var notificationAuthorizationStatus: UNAuthorizationStatus?

    var body: some View {
        Form {
            Picker("Appearance", selection: Binding(
                get: { model.snapshot.theme },
                set: { model.setTheme($0) }
            )) {
                ForEach(AppTheme.allCases) { theme in
                    Text(theme.title).tag(theme)
                }
            }
            .pickerStyle(.segmented)

            Text("Habit colors are customized per habit and adjusted for readability in light and dark mode.")
                .font(.caption)
                .foregroundStyle(.secondary)

            LabeledContent("Notifications", value: notificationStatus)

            if notificationAuthorizationStatus == .notDetermined {
                Button("Enable Notifications") {
                    Task {
                        await requestNotificationPermission()
                    }
                }
            } else if notificationAuthorizationStatus == .denied {
                Button("Open Notification Settings", action: openNotificationSettings)
            }
        }
        .padding()
        .task {
            await refreshNotificationStatus()
        }
    }

    private func refreshNotificationStatus() async {
        guard AppRuntime.isAppBundle else {
            await MainActor.run {
                notificationStatus = "Unavailable in raw SwiftPM run"
            }
            return
        }

        let settings = await UNUserNotificationCenter.current().notificationSettings()

        await MainActor.run {
            notificationStatus = switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                "Allowed"
            case .denied:
                "Denied - enable in System Settings"
            case .notDetermined:
                "Not requested"
            @unknown default:
                "Unknown"
            }
            notificationAuthorizationStatus = settings.authorizationStatus
        }
    }

    private func requestNotificationPermission() async {
        do {
            _ = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
        } catch {
            await MainActor.run {
                notificationStatus = error.localizedDescription
            }
        }

        await refreshNotificationStatus()
    }

    private func openNotificationSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension") else { return }
        NSWorkspace.shared.open(url)
    }
}
