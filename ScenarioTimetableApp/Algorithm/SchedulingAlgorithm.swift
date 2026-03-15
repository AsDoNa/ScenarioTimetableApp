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
