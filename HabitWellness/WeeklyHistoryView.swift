//
//  WeeklyHistoryView.swift
//  HabitWellness
//
//  Created by ipeerless on 22/10/2026.
//


import SwiftUI
import SwiftData

struct WeeklyHistoryView: View {
//    @Query(sort: \Habit.createdAt)
//    private var habits: [Habit]
    @Query(sort: \Habit.createdAt)
    private var habits: [Habit]




    private let calendar = Calendar.current

    private var weekDays: [Date] {
        let today = calendar.startOfDay(for: .now)
        let weekday = calendar.component(.weekday, from: today)
        let daysSinceMonday = (weekday + 5) % 7

        guard let monday = calendar.date(
            byAdding: .day,
            value: -daysSinceMonday,
            to: today
        ) else {
            return [today]
        }

        return (0..<7).compactMap {
            calendar.date(byAdding: .day, value: $0, to: monday)
        }
    }

    private func isCompleted(_ habit: Habit, on date: Date) -> Bool {
        habit.completions.contains {
            calendar.isDate($0.date, inSameDayAs: date)
        }
    }

    private func isScheduled(_ habit: Habit, on date: Date) -> Bool {
        let weekday = calendar.component(.weekday, from: date)
        return (habit.scheduledWeekdays )
            .contains(weekday)
    }

    var body: some View {
        List {
            if habits.isEmpty {
                ContentUnavailableView(
                    "No habits yet",
                    systemImage: "leaf",
                    description: Text("Add a habit to start tracking your week.")
                )
            }

            ForEach(habits) { habit in
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Label(habit.name, systemImage: habit.icon)
                            .font(.headline)

                        HStack(spacing: 0) {
                            ForEach(weekDays, id: \.self) { date in
                                VStack(spacing: 6) {
                                    Text(date.formatted(.dateTime.weekday(.narrow)))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)

                                   
                                    if isScheduled(habit, on: date) {
                                        if isCompleted(habit, on: date) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(.green)
                                        } else {
                                            Image(systemName: "circle")
                                                .foregroundStyle(.secondary)
                                        }
                                    } else {
                                        Image(systemName: "minus")
                                            .foregroundStyle(.tertiary)
                                    }


                                    Text(date.formatted(.dateTime.day()))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }

                        let scheduledDays = weekDays.filter {
                            isScheduled(habit, on: $0)
                        }

                        let completedDays = scheduledDays.filter {
                            isCompleted(habit, on: $0)
                        }

                        Text("\(completedDays.count) of \(scheduledDays.count) scheduled days completed")
                            .font(.caption)
                            .foregroundStyle(.secondary)


                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Weekly History")
    }
}
