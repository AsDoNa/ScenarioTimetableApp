// MARK: - Service Protocols
// Owner: Asher
//
// Holds protocols for all services.

import Foundation

protocol CalendarServiceProtocol {
    func requestCalendarAccess() async throws
    func fetchEvents(for dateRange: DateInterval) async throws -> [CalendarEvent]
    func exportStudySessions(_ sessions: [StudySession]) async throws
}

protocol PersistenceServiceProtocol {
    func saveTasks(_ tasks: [StudyTask]) throws
    func loadTasks() throws -> [StudyTask]
    func savePreferences(_ prefs: UserPreferences) throws
    func loadPreferences() throws -> UserPreferences
    func saveSessions(_ sessions: [StudySession]) throws
    func loadSessions() throws -> [StudySession]
}

protocol UCLAPIServiceProtocol {
    func fetchTimetable(for date: Date?) async throws -> [TimetableEntry]
    func authenticate() async throws
}
