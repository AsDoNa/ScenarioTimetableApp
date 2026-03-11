// MARK: - TimetableEntry Model
// Owner: Asher
//
// Represents a single class or event from the UCL timetable.
// This is the raw data fetched from the UCL API.

import Foundation

struct TimetableEntry: Identifiable, Codable {
    let id: UUID
    // TODO: Define properties, e.g.:
    // - moduleName: String
    // - moduleCode: String
    // - dayOfWeek: Int          (1 = Monday ... 7 = Sunday)
    // - startTime: Date
    // - endTime: Date
    // - location: String
    // - type: String            ("Lecture", "Tutorial", "Lab", etc.)
}
