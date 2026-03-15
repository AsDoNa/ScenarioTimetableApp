// MARK: - Scheduling Algorithm
// Owner: Salavat
//
// The core scheduling engine. This is a PURE FUNCTION layer:
// - Takes inputs: timetable entries, study tasks, user preferences
// - Returns output: an array of StudySessions placed into free time
// - No side effects, no network calls, no UI — just logic.
//
// Algorithm requirements:
// 1. Identify free time slots (gaps between timetable entries)
// 2. Respect user preferences (study hours, break length, days off)
// 3. Prioritise tasks by deadline and priority level
// 4. Distribute study hours across the week (avoid cramming)
// 5. Handle edge cases: not enough free time, overlapping deadlines
//
// Suggested approach:
// - Start with a greedy algorithm (earliest deadline first)
// - Improve later with more sophisticated scheduling if needed

import Foundation

class SchedulingAlgorithm {

    // constants
    private static let MIN_SESSION_MINUTES = 15

    // Main entry point:
    static func generateSchedule(
        timetable: [TimetableEntry], 
        calendarEvents: [CalendarEvent],
        tasks: [StudyTask], 
        preferences: UserPreferences,
        weekStartDate: Date
        ) -> [StudySession] {

            return []
        }
    
    // Helper function to build the active days array:
    private static func buildActiveDays(
        weekStart: Date,
        daysOff: [UserPreferences.Weekday],
        calendar: Calendar = .current
    ) -> [Date] {
        (0..<7).compactMap { offset -> Date? in
            guard let day = calendar.date(byAdding: .day, value: offset, to: weekStart)
            else { return nil }
            let weekday = weekdayEnum(from: day, calendar: calendar)
            return daysOff.contains(weekday) ? nil : day
        }
    }

    // Helper function to get the weekday enum from a date:
    private static func weekdayEnum(
        from date: Date,
        calendar: Calendar
    ) -> UserPreferences.Weekday {
        switch calendar.component(.weekday, from: date) {
            case 1: return .sunday
            case 2: return .monday
            case 3: return .tuesday
            case 4: return .wednesday
            case 5: return .thursday
            case 6: return .friday
            default: return .saturday
        }
    }

    // Helper function to merge overlapping intervals:
    private static func mergeOverlappingIntervals(
        _ intervals: [(start: Date, end: Date)]
    ) -> [(start: Date, end: Date)] {
        guard !intervals.isEmpty else { return [] }

        let sorted = intervals.sorted { $0.start < $1.start }
        var merged: [(start: Date, end: Date)] = [sorted[0]]

        for interval in sorted.dropFirst() {
            let last = merged[merged.count - 1]
            if interval.start <= last.end {
                merged[merged.count - 1] = (start: last.start, end: max(last.end, interval.end))
            } else {
                merged.append(interval)
            }
        }
        return merged
    }

    private static func applyWorkingWindow(
        to day: Date,
        prefs: UserPreferences,
        calendar: Calendar = .current
    ) -> (windowStart: Date, windowEnd: Date)? {

        let startComponents = calendar.dateComponents([.hour, .minute], from: prefs.preferredStudyStartTime)
        let endComponents   = calendar.dateComponents([.hour, .minute], from: prefs.preferredStudyEndTime)

        var dayComponents = calendar.dateComponents([.year, .month, .day], from: day)

        dayComponents.hour   = startComponents.hour
        dayComponents.minute = startComponents.minute
        dayComponents.second = 0
        guard let windowStart = calendar.date(from: dayComponents) else { return nil }

        dayComponents.hour   = endComponents.hour
        dayComponents.minute = endComponents.minute
        guard let windowEnd = calendar.date(from: dayComponents) else { return nil }

        guard windowStart < windowEnd else { return nil }

        return (windowStart, windowEnd)
    }


    // Helper function to compute the free slots:
    private static func computeFreeSlots(
        window: (windowStart: Date, windowEnd: Date),
        blocked: [(start: Date, end: Date)]  // intervals that are already merged and sorted
    ) -> [TimeSlot] {

        var slots: [TimeSlot] = []
        var pointer = window.windowStart

        for block in blocked {
            let blockStart = max(block.start, window.windowStart)
            let blockEnd   = min(block.end,   window.windowEnd)

            guard blockStart < blockEnd else { continue } // block is fully outside window

            if pointer < blockStart {
                // Gap between pointer and this block
                let gapMinutes = Int(blockStart.timeIntervalSince(pointer) / 60)
                if gapMinutes >= MIN_SESSION_MINUTES {
                    slots.append(TimeSlot(startTime: pointer, endTime: blockStart))
                }
            }
            // Advance pointer past this block
            pointer = max(pointer, blockEnd)
        }

        // Trailing gap between last block and end of window
        if pointer < window.windowEnd {
            let gapMinutes = Int(window.windowEnd.timeIntervalSince(pointer) / 60)
            if gapMinutes >= MIN_SESSION_MINUTES {
                slots.append(TimeSlot(startTime: pointer, endTime: window.windowEnd))
            }
        }

        return slots
    }

    private static func filterAndSortTasks(_ tasks: [StudyTask]) -> [StudyTask] {
        tasks
            .filter { !$0.isComplete && ($0.estimatedTime - $0.completedTime) > 0 }
            .sorted { a, b in
                let rankA = priorityRank(a.priority)
                let rankB = priorityRank(b.priority)
                if rankA != rankB { return rankA < rankB }
                return a.deadline < b.deadline
            }
    }

    private static func priorityRank(_ priority: StudyTask.Priority) -> Int {
        switch priority {
        case .high:   return 0
        case .medium: return 1
        case .low:    return 2
        }
    }

    
    // TODO: Implement
    //
    // Main entry point:
    // func generateSchedule(
    //     timetable: [TimetableEntry],
    //     tasks: [StudyTask],
    //     preferences: UserPreferences
    // ) -> [StudySession]
    //
    // Helper functions to consider:
    // - func findFreeSlots(in timetable: [TimetableEntry], preferences: UserPreferences) -> [TimeSlot]
    // - func prioritiseTasks(_ tasks: [StudyTask]) -> [StudyTask]
    // - func fitTaskIntoSlots(task: StudyTask, slots: [TimeSlot]) -> [StudySession]
}
