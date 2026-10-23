//
//  Item.swift
//  HabitWellness
//
//  Created by ipeerless on 21/10/2026.
//

import Foundation
import SwiftData

@Model
final class Habit {
    @Attribute(.unique) var id: UUID
    var name: String
    var details: String
    var icon: String
    var createdAt: Date
    var isArchived: Bool

    var reminderHour: Int?
    var reminderMinute: Int?

    // Persist weekday selections as Data instead of [Int].
   
    var scheduledWeekdaysData: Data?

    @Transient
    var scheduledWeekdays: [Int] {
        get {
            guard let data = scheduledWeekdaysData else {
                return [1, 2, 3, 4, 5, 6, 7]
            }

            return (try? JSONDecoder().decode([Int].self, from: data))
                ?? [1, 2, 3, 4, 5, 6, 7]
        }
        set {
            scheduledWeekdaysData = try? JSONEncoder().encode(newValue)
        }
    }



    @Relationship(
        deleteRule: .cascade,
        inverse: \HabitCompletion.habit
    )
    var completions: [HabitCompletion]

    init(
        name: String,
        details: String = "",
        icon: String = "checkmark.circle",
        createdAt: Date = .now,
        scheduledWeekdays: [Int] = [1, 2, 3, 4, 5, 6, 7]
    ) {
        self.id = UUID()
        self.name = name
        self.details = details
        self.icon = icon
        self.createdAt = createdAt
        self.isArchived = false
        self.reminderHour = nil
        self.reminderMinute = nil
        self.scheduledWeekdaysData =
            (try? JSONEncoder().encode(scheduledWeekdays))
            ?? Data()
        self.completions = []
    }
}

@Model
final class HabitCompletion {
    @Attribute(.unique) var id: UUID
    var date: Date
    var habit: Habit?

    init(date: Date = .now, habit: Habit? = nil) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.habit = habit
    }
}

extension Habit {
    var completedDays: Set<Date> {
        let calendar = Calendar.current

        return Set(
            completions.map {
                calendar.startOfDay(for: $0.date)
            }
        )
    }

    var currentStreak: Int {
        let calendar = Calendar.current
        let days = completedDays
        let scheduledDays = scheduledWeekdays

        guard !scheduledDays.isEmpty else { return 0 }

        var day = calendar.startOfDay(for: .now)
        let todayWeekday = calendar.component(.weekday, from: day)

        if scheduledDays.contains(todayWeekday), !days.contains(day) {
            guard let yesterday = calendar.date(
                byAdding: .day,
                value: -1,
                to: day
            ) else {
                return 0
            }

            day = yesterday
        }

        var streak = 0

        while true {
            let weekday = calendar.component(.weekday, from: day)

            if scheduledDays.contains(weekday) {
                guard days.contains(day) else { break }
                streak += 1
            }

            guard let previousDay = calendar.date(
                byAdding: .day,
                value: -1,
                to: day
            ) else {
                break
            }

            day = previousDay
        }

        return streak
    }

    var bestStreak: Int {
        let calendar = Calendar.current
        let days = completedDays
        let scheduledDays = scheduledWeekdays

        guard
            !scheduledDays.isEmpty,
            let firstDay = days.min(),
            let lastDay = days.max()
        else {
            return 0
        }

        var day = firstDay
        var current = 0
        var best = 0

        while day <= lastDay {
            let weekday = calendar.component(.weekday, from: day)

            if scheduledDays.contains(weekday) {
                if days.contains(day) {
                    current += 1
                    best = max(best, current)
                } else {
                    current = 0
                }
            }

            guard let nextDay = calendar.date(
                byAdding: .day,
                value: 1,
                to: day
            ) else {
                break
            }

            day = nextDay
        }

        return best
    }
}
