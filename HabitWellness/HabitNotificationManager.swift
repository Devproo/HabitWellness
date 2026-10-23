//
//  HabitNotificationManager.swift
//  HabitWellness
//
//  Created by ipeerless on 22/10/2026.
//


import Foundation
import UIKit
import UserNotifications

enum HabitNotificationManager {
    private static let center = UNUserNotificationCenter.current()

    static func requestPermission() async -> Bool {
        do {
            return try await center.requestAuthorization(
                options: [.alert, .sound, .badge]
            )
        } catch {
            print("Notification permission error: \(error)")
            return false
        }
    }

    static func notificationsAllowed() async -> Bool {
        let settings = await center.notificationSettings()

        return settings.authorizationStatus == .authorized
            || settings.authorizationStatus == .provisional
    }

    static func scheduleReminder(for habit: Habit) async {
        cancelReminders(for: habit)

        guard
            await notificationsAllowed(),
            let hour = habit.reminderHour,
            let minute = habit.reminderMinute,
            !habit.isArchived
        else {
            return
        }

        let weekdays = habit.scheduledWeekdays 

        for weekday in weekdays {
            var components = DateComponents()
            components.weekday = weekday
            components.hour = hour
            components.minute = minute

            let content = UNMutableNotificationContent()
            content.title = habit.name
            content.body = "Time for your habit."
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(
                dateMatching: components,
                repeats: true
            )

            let request = UNNotificationRequest(
                identifier: notificationIdentifier(for: habit, weekday: weekday),
                content: content,
                trigger: trigger
            )

            do {
                try await center.add(request)
            } catch {
                print("Could not schedule reminder: \(error)")
            }
        }
    }

    static func cancelReminders(for habit: Habit) {
        let identifiers = (1...7).map {
            notificationIdentifier(for: habit, weekday: $0)
        }

        center.removePendingNotificationRequests(
            withIdentifiers: identifiers
        )
    }

    static func openNotificationSettings() {
        guard let url = URL(
            string: UIApplication.openNotificationSettingsURLString
        ) else {
            return
        }

        Task { @MainActor in
            await UIApplication.shared.open(url)
        }
    }

    private static func notificationIdentifier(
        for habit: Habit,
        weekday: Int
    ) -> String {
        "habit-\(habit.id.uuidString)-\(weekday)"
    }
}
