// MARK: - StudySession Model
// Owner: Asher
//
// A scheduled study block — the OUTPUT of the scheduling algorithm.
// Maps a StudyTask to a specific time slot in the user's free time.

import Foundation

struct StudySession: Identifiable, Codable {
    let id: UUID
    // TODO: Define properties, e.g.:
    // - taskID: UUID             (links back to the StudyTask)
    // - date: Date
    // - startTime: Date
    // - endTime: Date
    // - taskTitle: String        (denormalised for display convenience)
}
