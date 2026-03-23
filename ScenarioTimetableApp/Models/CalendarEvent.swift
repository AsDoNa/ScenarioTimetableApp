// MARK: - CalendarEvent Model
// Owner: Asher
//
// Represents a single event from the user's loaded calendars.

import Foundation

struct CalendarEvent: Identifiable, Codable {
    
    let id: UUID = UUID()
    let title: String
    let startTime: Date
    let endTime: Date
    let location: String?
    let locationCoords: Coordinates?
    let calendarName: String
}
