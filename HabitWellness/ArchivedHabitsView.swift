//
//  ArchivedHabitsView.swift
//  HabitWellness
//
//  Created by ipeerless on 22/10/2026.
//


import SwiftUI
import SwiftData

struct ArchivedHabitsView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(
        filter: #Predicate<Habit> { $0.isArchived },
        sort: \Habit.createdAt
    )
    private var habits: [Habit]

    var body: some View {
        List {
            if habits.isEmpty {
                ContentUnavailableView(
                    "No archived habits",
                    systemImage: "archivebox",
                    description: Text(
                        "Habits you archive will appear here."
                    )
                )
            }

           
            ForEach(habits) { habit in
                HStack(spacing: 12) {
                    Image(systemName: habit.icon)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 32)

                    VStack(alignment: .leading, spacing: 5) {
                        Text(habit.name)
                            .font(.body.weight(.medium))
                            .lineLimit(1)

                        Text(
                            habit.details.isEmpty
                                ? "\(habit.completions.count) completions saved"
                                : habit.details
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                        if !habit.details.isEmpty {
                            Text("\(habit.completions.count) completions saved")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Button {
                        habit.isArchived = false

                            if habit.reminderHour != nil && habit.reminderMinute != nil {
                                Task {
                                    let granted = await HabitNotificationManager.requestPermission()

                                    if granted {
                                        await HabitNotificationManager.scheduleReminder(for: habit)
                                    }
                                }
                            }
                    } label: {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.body.weight(.medium))
                            .frame(width: 40, height: 40)
                            .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Restore \(habit.name)")
                }
                .padding(.vertical, 6)
            }

        }
        .navigationTitle("Archived Habits")
    }
}
