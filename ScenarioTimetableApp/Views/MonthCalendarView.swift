// MARK: - Month Calendar View
// Owner: Josh
//
// Displays a month-grid overview with coloured dots indicating events.
// Tapping a day switches to the week view centred on that day.

import SwiftUI

struct MonthCalendarView: View {

    var viewModel: TimetableViewModel
    @Binding var selectedDay: Date
    @Binding var weekStartDate: Date
    var onSwitchToWeekView: () -> Void

    @State private var displayedMonth: Date = Date()

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    private let weekdayLabels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            monthNavigationHeader
            weekdayHeaderRow
            monthGrid
            Spacer()
        }
    }

    // MARK: - Month Navigation

    private var monthNavigationHeader: some View {
        HStack {
            Button {
                shiftMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
            }

            Spacer()

            Text(monthYearString)
                .font(.subheadline)
                .fontWeight(.medium)

            Spacer()

            Button {
                shiftMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - Weekday Labels

    private var weekdayHeaderRow: some View {
        HStack(spacing: 0) {
            ForEach(weekdayLabels, id: \.self) { label in
                Text(label)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 4)
    }

    // MARK: - Month Grid

    private var monthGrid: some View {
        let days = daysInMonthGrid()
        return LazyVGrid(columns: columns, spacing: 4) {
            ForEach(days, id: \.self) { day in
                if let day {
                    dayCell(for: day)
                } else {
                    Color.clear
                        .frame(height: 44)
                }
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Day Cell

    private func dayCell(for day: Date) -> some View {
        let isToday = calendar.isDateInToday(day)
        let isCurrentMonth = calendar.isDate(day, equalTo: displayedMonth, toGranularity: .month)
        let dots = dotsForDay(day)

        return Button {
            selectedDay = day
            weekStartDate = mondayOfWeek(containing: day)
            onSwitchToWeekView()
        } label: {
            VStack(spacing: 2) {
                Text("\(calendar.component(.day, from: day))")
                    .font(.callout)
                    .fontWeight(isToday ? .bold : .regular)
                    .foregroundStyle(isCurrentMonth ? (isToday ? .white : .primary) : .gray.opacity(0.4))

                HStack(spacing: 3) {
                    ForEach(dots.prefix(3), id: \.self) { color in
                        Circle()
                            .fill(color)
                            .frame(width: 5, height: 5)
                    }
                }
                .frame(height: 5)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isToday ? Color.accentColor : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Event Dots

    /// Returns up to 3 coloured dots for a given day:
    /// - Blue: timetable entry (class)
    /// - Green: study session
    /// - Orange: personal calendar event
    private func dotsForDay(_ day: Date) -> [Color] {
        var colors: [Color] = []

        let hasTimetable = viewModel.allTimetableEntries.contains(where: {
            calendar.isDate($0.startTime, inSameDayAs: day)
        })
        if hasTimetable { colors.append(.blue) }

        let hasStudy = (viewModel.weekSchedule?.studySessions ?? []).contains(where: {
            calendar.isDate($0.startTime, inSameDayAs: day)
        })
        if hasStudy { colors.append(.green) }

        let hasCalendar = viewModel.allCalendarEvents.contains(where: {
            calendar.isDate($0.startTime, inSameDayAs: day)
        })
        if hasCalendar { colors.append(.orange) }

        return colors
    }

    // MARK: - Helpers

    /// Builds an array of optional dates for the month grid.
    /// `nil` entries represent blank cells before the first day.
    private func daysInMonthGrid() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth),
              let daysInMonth = calendar.range(of: .day, in: .month, for: displayedMonth)
        else { return [] }

        let firstDay = monthInterval.start
        // weekday: 1=Sun … 7=Sat → convert to Mon-start offset (0=Mon … 6=Sun)
        let rawWeekday = calendar.component(.weekday, from: firstDay)
        let leadingBlanks = (rawWeekday + 5) % 7

        var grid: [Date?] = Array(repeating: nil, count: leadingBlanks)

        for day in daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                grid.append(date)
            }
        }

        return grid
    }

    private func shiftMonth(by offset: Int) {
        guard let newMonth = calendar.date(byAdding: .month, value: offset, to: displayedMonth) else { return }
        displayedMonth = newMonth
    }

    private var monthYearString: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMMM yyyy"
        return fmt.string(from: displayedMonth)
    }

    /// Returns the Monday of the week containing the given date.
    private func mondayOfWeek(containing date: Date) -> Date {
        let day = calendar.startOfDay(for: date)
        let weekday = calendar.component(.weekday, from: day)
        let daysToSubtract = (weekday + 5) % 7
        return calendar.date(byAdding: .day, value: -daysToSubtract, to: day)!
    }
}
