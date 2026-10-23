//
//  MonthlyHabitHistoryView.swift
//  HabitWellness
//
//  Created by ipeerless on 22/10/2026.
//


import SwiftUI

struct MonthlyHabitHistoryView: View {
    let habit: Habit

    @State private var displayedMonth = Calendar.current.startOfMonth(for: .now)

    private let calendar = Calendar.current
    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: 4),
        count: 7
    )

    private var monthDays: [Date?] {
        guard
            let range = calendar.range(of: .day, in: .month, for: displayedMonth),
            let firstDay = calendar.date(
                from: calendar.dateComponents([.year, .month], from: displayedMonth)
            )
        else {
            return []
        }

        // Monday-first calendar layout.
        let weekday = calendar.component(.weekday, from: firstDay)
        let leadingSpaces = (weekday + 5) % 7

        var days = Array<Date?>(repeating: nil, count: leadingSpaces)

        for day in range {
            if let date = calendar.date(
                byAdding: .day,
                value: day - 1,
                to: firstDay
            ) {
                days.append(date)
            }
        }

        return days
    }

    private func isCompleted(_ date: Date) -> Bool {
        habit.completions.contains {
            calendar.isDate($0.date, inSameDayAs: date)
        }
    }

    private func isScheduled(_ date: Date) -> Bool {
        let scheduledDays = habit.scheduledWeekdays 
        return scheduledDays.contains(calendar.component(.weekday, from: date))
    }

    private var monthScheduledDays: [Date] {
        let today = calendar.startOfDay(for: .now)

        return monthDays.compactMap { date in
            guard let date, isScheduled(date) else { return nil }

            // Exclude future scheduled days from this month's summary.
            if calendar.isDate(displayedMonth, equalTo: today, toGranularity: .month),
               date > today {
                return nil
            }

            return date
        }
    }

    private var completedScheduledDays: Int {
        monthScheduledDays.filter { isCompleted($0) }.count
    }

    var body: some View {
        List {
            Section {
                HStack {
                    Button {
                        changeMonth(by: -1)
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .accessibilityLabel("Previous month")

                    Spacer()

                    Text(displayedMonth.formatted(.dateTime.month(.wide).year()))
                        .font(.headline)

                    Spacer()

                    Button {
                        changeMonth(by: 1)
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                    .accessibilityLabel("Next month")
                }
                .buttonStyle(.plain)

                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(["M", "T", "W", "T", "F", "S", "S"].indices, id: \.self) { index in
                        Text(["M", "T", "W", "T", "F", "S", "S"][index])
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }

                    ForEach(monthDays.indices, id: \.self) { index in
                        if let date = monthDays[index] {
                            VStack(spacing: 4) {
                                Text(date.formatted(.dateTime.day()))
                                    .font(.subheadline)

                                if isCompleted(date) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                } else if isScheduled(date) {
                                    Image(systemName: "circle")
                                        .foregroundStyle(.secondary)
                                } else {
                                    Circle()
                                        .fill(.clear)
                                        .frame(width: 8, height: 8)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(
                                calendar.isDateInToday(date)
                                    ? Color.accentColor.opacity(0.12)
                                    : .clear,
                                in: RoundedRectangle(cornerRadius: 8)
                            )
                        } else {
                            Color.clear
                                .frame(height: 38)
                        }
                    }
                }

                Text(
                    "\(completedScheduledDays) of \(monthScheduledDays.count) scheduled days completed"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 8)
            }
        }
        .navigationTitle("Monthly History")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func changeMonth(by amount: Int) {
        guard let newMonth = calendar.date(
            byAdding: .month,
            value: amount,
            to: displayedMonth
        ) else {
            return
        }

        displayedMonth = newMonth
    }
}

private extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? startOfDay(for: date)
    }
}
