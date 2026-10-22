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

    @Relationship(
        deleteRule: .cascade,
        inverse: \HabitCompletion.habit
    )
    var completions: [HabitCompletion]

    init(
        name: String,
        details: String = "",
        icon: String = "checkmark.circle",
        createdAt: Date = .now
    ) {
        self.id = UUID()
        self.name = name
        self.details = details
        self.icon = icon
        self.createdAt = createdAt
        self.isArchived = false
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
