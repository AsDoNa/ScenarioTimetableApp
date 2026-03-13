// MARK: - TimeSlot Struct
// Owner: Asher
//
// Represents a timeslot (e.g. that is free)

import Foundation

struct TimeSlot: Identifiable, Codable {
    
    let id: UUID = UUID()
    var startTime: Date
    var endTime: Date
}
