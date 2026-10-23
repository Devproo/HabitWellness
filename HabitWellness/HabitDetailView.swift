//
//  HabitDetailView.swift
//  HabitWellness
//
//  Created by ipeerless on 22/10/2026.
//


import SwiftUI
import SwiftData

struct HabitDetailView: View {
    let habit: Habit

    private let calendar = Calendar.current

    private var scheduledWeekdays: [Int] {
        habit.scheduledWeekdays 
    }

    private let weekdays: [(name: String, short: String, value: Int)] = [
        ("Monday", "Mon", 2),
        ("Tuesday", "Tue", 3),
        ("Wednesday", "Wed", 4),
        ("Thursday", "Thu", 5),
        ("Friday", "Fri", 6),
        ("Saturday", "Sat", 7),
        ("Sunday", "Sun", 1)
    ]

    private var recentDays: [Date] {
        let today = calendar.startOfDay(for: .now)

        return (0..<14).compactMap {
            calendar.date(byAdding: .day, value: -$0, to: today)
        }.reversed()
    }

    private func isCompleted(on date: Date) -> Bool {
        habit.completions.contains {
            calendar.isDate($0.date, inSameDayAs: date)
        }
    }

    private func isScheduled(on date: Date) -> Bool {
        scheduledWeekdays.contains(
            calendar.component(.weekday, from: date)
        )
    }

    private var totalCompletions: Int {
        habit.completedDays.count
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Image(systemName: habit.icon)
                        .font(.system(size: 36))
                        .foregroundStyle(.green)

                    Text(habit.name)
                        .font(.title2.bold())

                    if !habit.details.isEmpty {
                        Text(habit.details)
                            .foregroundStyle(.secondary)
                    }

                    Text("Created \(habit.createdAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }

            Section("Statistics") {
                LabeledContent("Current streak") {
                    Label("\(habit.currentStreak) days", systemImage: "flame.fill")
                        .foregroundStyle(.orange)
                }

                LabeledContent("Best streak") {
                    Text("\(habit.bestStreak) days")
                }

                LabeledContent("Total completions") {
                    Text("\(totalCompletions)")
                }
            }

            Section("Schedule") {
                ForEach(weekdays, id: \.value) { day in
                    HStack {
                        Text(day.name)

                        Spacer()

                        if scheduledWeekdays.contains(day.value) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        } else {
                            Image(systemName: "minus.circle")
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }

            Section("Last 14 Days") {
                HStack(spacing: 0) {
                    ForEach(recentDays, id: \.self) { date in
                        VStack(spacing: 8) {
                            Text(date.formatted(.dateTime.weekday(.narrow)))
                                .font(.caption2)
                                .foregroundStyle(.secondary)

                            if isCompleted(on: date) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            } else if isScheduled(on: date) {
                                Image(systemName: "circle")
                                    .foregroundStyle(.secondary)
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
                .padding(.vertical, 8)
            }
            
            Section {
                NavigationLink {
                    MonthlyHabitHistoryView(habit: habit)
                } label: {
                    Label("View Monthly Calendar", systemImage: "calendar")
                }
            }

        }
        .navigationTitle("Habit Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}
