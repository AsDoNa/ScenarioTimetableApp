// MARK: - StudyTask Model
// Owner: Asher
//
// A study task the user wants to complete (e.g., "Revise Maths Chapter 3").
// Has a deadline, priority, and estimated hours needed.
// The scheduling algorithm uses these to generate StudySessions.

import Foundation

struct StudyTask: Identifiable, Codable {
    let id: UUID
    // TODO: Define properties, e.g.:
    // - title: String
    // - subject: String
    // - deadline: Date
    // - priority: Priority       (enum: high, medium, low)
    // - estimatedHours: Double
    // - completedHours: Double
    // - isComplete: Bool
}
