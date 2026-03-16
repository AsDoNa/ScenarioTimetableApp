// MARK: - WeekSchedule Model
// Owner: Asher
//
// Represents a full week's schedule, combining:
// - Fixed timetable entries (classes from UCL API)
// - Scheduled study sessions (from the algorithm)
// - Personal calendar events (if imported)
//
// This is the main data structure the Views display.

import Foundation

struct WeekSchedule: Codable {
    let weekStartDate: Date
    var timetableEntries: [TimetableEntry]
    var studySessions: [StudySession]
    var calendarEvents: [CalendarEvent]
    // TODO computed freeSlots [TimeSlot]
}
