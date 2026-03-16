// MARK: - StudySession Model
// Owner: Asher
//
// A scheduled study block — the OUTPUT of the scheduling algorithm.
// Maps a StudyTask to a specific time slot in the user's free time.

import Foundation

struct StudySession: Identifiable, Codable {
    let id: UUID = UUID()
    let taskID: UUID
    let startTime: Date
    let endTime: Date
    let taskTitle: String
    let moduleCode: String?
}
