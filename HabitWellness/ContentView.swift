//
//  ContentView.swift
//  HabitWellness
//
//  Created by ipeerless on 21/10/2026.
//


import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(
        filter: #Predicate<Habit> { !$0.isArchived },
        sort: \Habit.createdAt
    )
    private var habits: [Habit]
    
    private var todaysHabits: [Habit] {
//        let weekday = Calendar.current.component(.weekday, from: .now)
//
//        return habits.filter { habit in
//            let scheduledDays = habit.scheduledWeekdays ?? [1, 2, 3, 4, 5, 6, 7]
//            return scheduledDays.contains(weekday)
//        }
        habits
    }


    @State private var showingAddHabit = false
    @State private var editingHabit: Habit?

    private var today: Date {
        Calendar.current.startOfDay(for: .now)
    }

    private func isCompleted(_ habit: Habit) -> Bool {
        habit.completions.contains {
            Calendar.current.isDate($0.date, inSameDayAs: today)
        }
    }

   
    private var completedCount: Int {
        todaysHabits.filter { isCompleted($0) }.count
    }

    private var progress: Double {
        guard !todaysHabits.isEmpty else { return 0 }
        return Double(completedCount) / Double(todaysHabits.count)
    }

    
    private var weeklyProgress: (completed: Int, total: Int) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        let weekday = calendar.component(.weekday, from: today)
        let daysSinceMonday = (weekday + 5) % 7

        guard let monday = calendar.date(
            byAdding: .day,
            value: -daysSinceMonday,
            to: today
        ) else {
            return (0, 0)
        }

        var completed = 0
        var total = 0

        for habit in habits {
            let scheduledDays = habit.scheduledWeekdays 

            for offset in 0..<7 {
                guard let date = calendar.date(
                    byAdding: .day,
                    value: offset,
                    to: monday
                ), date <= today else {
                    
                    continue
                }

                let day = calendar.component(.weekday, from: date)

                guard scheduledDays.contains(day) else {
                    continue
                }

                total += 1

                
                if habit.completions.contains(where: {
                    calendar.isDate($0.date, inSameDayAs: date)
                }) {
                    completed += 1
                }

            }
        }

        return (completed, total)
    }

    private var weeklyProgressValue: Double {
        guard weeklyProgress.total > 0 else { return 0 }
        return Double(weeklyProgress.completed) / Double(weeklyProgress.total)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(Date.now.formatted(
                            .dateTime.weekday(.wide).month(.wide).day()
                        ))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                        Text("Build better habits.")
                            .font(.title2.bold())

                        ProgressView(value: progress)
                            .tint(.green)

                       
                        Text("\(completedCount) of \(todaysHabits.count) habits completed")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Divider()

                        Text("This week's progress")
                            .font(.headline)

                        ProgressView(value: weeklyProgressValue)
                            .tint(.blue)

                        Text(
                            weeklyProgress.total == 0
                                ? "No scheduled habit-days this week yet"
                                : "\(weeklyProgress.completed) of \(weeklyProgress.total) scheduled habit-days completed"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)



                    }
                    .padding(.vertical, 8)
                    .listRowSeparator(.hidden)
                }

                Section("Today's habits") {
                 
                    if todaysHabits.isEmpty {
                        ContentUnavailableView(
                            habits.isEmpty ? "No habits yet" : "No habits scheduled today",
                            systemImage: "leaf",
                            description: Text(
                                habits.isEmpty
                                    ? "Add your first habit to get started."
                                    : "Enjoy your rest day. Your next scheduled habits will appear here."
                            )
                        )
                    }


                    ForEach(todaysHabits) { habit in
                        HStack(spacing: 12) {
                            Image(systemName: habit.icon)
                                .font(.title3)
                                .foregroundStyle(.green)
                                .frame(width: 32, height: 32)

                            VStack(alignment: .leading, spacing: 5) {
                                
                                NavigationLink {
                                    HabitDetailView(habit: habit)
                                } label: {
                                    Text(habit.name)
                                        .font(.body.weight(.medium))
                                        .lineLimit(1)
                                        .foregroundStyle(.primary)
                                }
                                .buttonStyle(.plain)

                                if !habit.details.isEmpty {
                                    Text(habit.details)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }

                                HStack(spacing: 10) {
                                    Label(
                                        "\(habit.currentStreak)",
                                        systemImage: "flame.fill"
                                    )
                                    .foregroundStyle(
                                        habit.currentStreak > 0 ? .orange : .secondary
                                    )

                                    Text("Best: \(habit.bestStreak)")
                                        .foregroundStyle(.secondary)
                                }
                                .font(.caption)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            Button {
                                editingHabit = habit
                            } label: {
                                Image(systemName: "pencil")
                                    .frame(width: 36, height: 40)
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.secondary)
                            .accessibilityLabel("Edit \(habit.name)")

                            Button {
                                HabitNotificationManager.cancelReminders(for: habit)
                                habit.isArchived = true
                            } label: {
                                Image(systemName: "archivebox")
                                    .frame(width: 36, height: 40)
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.secondary)
                            .accessibilityLabel("Archive \(habit.name)")

                            Button {
                                toggleCompletion(for: habit)
                            } label: {
                                Image(
                                    systemName: isCompleted(habit)
                                        ? "checkmark.circle.fill"
                                        : "circle"
                                )
                                .font(.title2)
                                .frame(width: 32, height: 40)
                                .foregroundStyle(
                                    isCompleted(habit) ? .green : .secondary
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(
                                isCompleted(habit)
                                    ? "Mark \(habit.name) incomplete"
                                    : "Mark \(habit.name) complete"
                            )
                        }
                        .padding(.vertical, 6)
                    }
                    .onDelete(perform: deleteHabits)

                }
            }
            .navigationTitle("Today")
         
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink {
                        WeeklyHistoryView()
                    } label: {
                        Label("History", systemImage: "calendar")
                    }
                }

                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink {
                        ArchivedHabitsView()
                    } label: {
                        Label("Archived", systemImage: "archivebox")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddHabit = true
                    } label: {
                        Label("Add Habit", systemImage: "plus")
                    }
                }
            }

            .sheet(isPresented: $showingAddHabit) {
                AddHabitView()
            }
            .sheet(item: $editingHabit) { habit in
                AddHabitView(habit: habit)
            }
         
        }
    }

    private func toggleCompletion(for habit: Habit) {
        if let completion = habit.completions.first(where: {
            Calendar.current.isDate($0.date, inSameDayAs: today)
        }) {
            modelContext.delete(completion)
        } else {
            modelContext.insert(
                HabitCompletion(date: today, habit: habit)
            )
        }
    }

   
 
    private func deleteHabits(at offsets: IndexSet) {
        for index in offsets {
            let habit = todaysHabits[index]
            HabitNotificationManager.cancelReminders(for: habit)
            modelContext.delete(habit)
        }
    }


}
