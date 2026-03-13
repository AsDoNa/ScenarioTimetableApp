// MARK: - StudyTask Model
// Owner: Asher
//
// A study task the user wants to complete (e.g., "Revise Maths Chapter 3").
// Has a deadline, priority, and estimated hours needed.
// The scheduling algorithm uses these to generate StudySessions.

import Foundation

struct StudyTask: Identifiable, Codable {
    enum Priority: String, Codable {
        case high
        case medium
        case low
    }
    
    let id: UUID = UUID()
    var title: String
    var subject: String
    var moduleCode: String?
    var deadline: Date
    var priority: Priority
    var estimatedTime: Int // Estimated time in minutes to give extra flexibility - conversion into hours when necessary by division by 60
    var completedTime: Int // Same reasoning as above
    var isComplete: Bool
}
