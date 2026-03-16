// MARK: - TimetableEntry Model
// Owner: Asher
//
// Represents a single class or event from the UCL timetable.
// This is the raw data fetched from the UCL API.

import Foundation

struct TimetableEntry: Identifiable, Codable {
    
    enum SessionType: Codable {
        case lecture
        case tutorial
        case lab
        case problemBasedLearning
        case unknown(String)
    }
    
    let id: UUID = UUID()
    let moduleName: String
    let moduleCode: String
    let lecturerName: String
    let startTime: Date
    let endTime: Date
    let location: String
    let locationCoords: Coordinates
    let type: SessionType
}
