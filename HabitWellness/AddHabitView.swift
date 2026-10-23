//
//  AddHabitView.swift
//  HabitWellness
//
//  Created by ipeerless on 21/10/2026.
//

import SwiftUI
import SwiftData

struct AddHabitView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    private let habit: Habit?

    @State private var name: String
    @State private var details: String
    @State private var icon: String
    @State private var scheduledWeekdays: Set<Int>
    @State private var reminderEnabled: Bool
    @State private var reminderTime: Date
    @State private var showingNotificationAlert = false
    
    private let icons = [
        "checkmark.circle",
        "book",
        "figure.walk",
        "drop",
        "heart",
        "leaf",
        "moon",
        "dumbbell"
    ]

    private let weekdays: [(name: String, shortName: String, value: Int)] = [
        ("Sunday", "Sun", 1),
        ("Monday", "Mon", 2),
        ("Tuesday", "Tue", 3),
        ("Wednesday", "Wed", 4),
        ("Thursday", "Thu", 5),
        ("Friday", "Fri", 6),
        ("Saturday", "Sat", 7)
    ]

    init(habit: Habit? = nil) {
        self.habit = habit

        _name = State(initialValue: habit?.name ?? "")
        _details = State(initialValue: habit?.details ?? "")
        _icon = State(initialValue: habit?.icon ?? "checkmark.circle")

        _scheduledWeekdays = State(
            initialValue: Set(
                habit?.scheduledWeekdays ?? [1, 2, 3, 4, 5, 6, 7]
            )
        )

        _reminderEnabled = State(
            initialValue: habit?.reminderHour != nil
                && habit?.reminderMinute != nil
        )

        let initialReminderTime: Date

        if let hour = habit?.reminderHour,
           let minute = habit?.reminderMinute {
            initialReminderTime = Calendar.current.date(
                from: DateComponents(hour: hour, minute: minute)
            ) ?? .now
        } else {
            initialReminderTime = Calendar.current.date(
                from: DateComponents(hour: 9, minute: 0)
            ) ?? .now
        }

        _reminderTime = State(initialValue: initialReminderTime)
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var scheduleDescription: String {
        if scheduledWeekdays.count == 7 {
            return "Every day"
        }

        if scheduledWeekdays == Set([2, 3, 4, 5, 6]) {
            return "Weekdays"
        }

        if scheduledWeekdays == Set([1, 7]) {
            return "Weekends"
        }

        if scheduledWeekdays.isEmpty {
            return "Choose at least one day"
        }

        return weekdays
            .filter { scheduledWeekdays.contains($0.value) }
            .map(\.shortName)
            .joined(separator: ", ")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Habit details") {
                    TextField("Habit name", text: $name)
                    TextField("Description (optional)", text: $details)
                }

                Section("Schedule") {
                    Text(scheduleDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack {
                        scheduleButton("Every day", days: Set(1...7))
                        scheduleButton("Weekdays", days: Set(2...6))
                    }

                    HStack {
                        scheduleButton("Weekends", days: Set([1, 7]))
                        scheduleButton("Custom", days: nil)
                    }

                    ForEach(weekdays, id: \.value) { day in
                        Toggle(
                            day.name,
                            isOn: Binding(
                                get: {
                                    scheduledWeekdays.contains(day.value)
                                },
                                set: { isSelected in
                                    if isSelected {
                                        scheduledWeekdays.insert(day.value)
                                    } else {
                                        scheduledWeekdays.remove(day.value)
                                    }
                                }
                            )
                        )
                    }
                }

                Section("Reminder") {
                    Toggle("Daily Reminder", isOn: $reminderEnabled)

                    if reminderEnabled {
                        DatePicker(
                            "Reminder Time",
                            selection: $reminderTime,
                            displayedComponents: .hourAndMinute
                        )
                    }
                }

                Section("Choose an icon") {
                    LazyVGrid(
                        columns: [
                            GridItem(.adaptive(minimum: 48))
                        ],
                        spacing: 16
                    ) {
                        ForEach(icons, id: \.self) { symbol in
                            Button {
                                icon = symbol
                            } label: {
                                Image(systemName: symbol)
                                    .font(.title2)
                                    .frame(width: 44, height: 44)
                                    .foregroundStyle(
                                        icon == symbol ? .white : .green
                                    )
                                    .background {
                                        Circle()
                                            .fill(
                                                icon == symbol
                                                    ? Color.green
                                                    : Color.green.opacity(0.12)
                                            )
                                    }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(symbol)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle(habit == nil ? "New Habit" : "Edit Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: saveHabit)
                        .disabled(
                            trimmedName.isEmpty || scheduledWeekdays.isEmpty
                        )
                }
            }
            .alert("Notifications Disabled", isPresented: $showingNotificationAlert) {
                Button("Open Settings") {
                    HabitNotificationManager.openNotificationSettings()
                }

                Button("Not Now", role: .cancel) {}
            } message: {
                Text("Allow notifications in Settings to receive your habit reminders.")
            }
        }
    }

    private func scheduleButton(
        _ title: String,
        days: Set<Int>?
    ) -> some View {
        Button(title) {
            if let days {
                scheduledWeekdays = days
            } else if scheduledWeekdays.isEmpty {
                // Custom preserves the current selection for manual editing.
                scheduledWeekdays = Set(1...7)
            }
        }
        .buttonStyle(.bordered)
        .frame(maxWidth: .infinity)
    }

   
   
   
    private func saveHabit() {
        let selectedDays = scheduledWeekdays.sorted()
        let cleanedDetails = details.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        let components = Calendar.current.dateComponents(
            [.hour, .minute],
            from: reminderTime
        )

        let savedHabit: Habit

        if let habit {
            habit.name = trimmedName
            habit.details = cleanedDetails
            habit.icon = icon
            habit.scheduledWeekdays = selectedDays
            savedHabit = habit
        } else {
            let newHabit = Habit(
                name: trimmedName,
                details: cleanedDetails,
                icon: icon,
                scheduledWeekdays: selectedDays
            )

            modelContext.insert(newHabit)
            savedHabit = newHabit
        }

        if reminderEnabled {
            savedHabit.reminderHour = components.hour
            savedHabit.reminderMinute = components.minute
        } else {
            savedHabit.reminderHour = nil
            savedHabit.reminderMinute = nil
            HabitNotificationManager.cancelReminders(for: savedHabit)
        }

        dismiss()

        guard reminderEnabled else {
            return
        }

        Task {
            let granted = await HabitNotificationManager.requestPermission()

            if granted {
                await HabitNotificationManager.scheduleReminder(for: savedHabit)
            } else {
                await MainActor.run {
                    showingNotificationAlert = true
                }
            }
        }
    }



}

