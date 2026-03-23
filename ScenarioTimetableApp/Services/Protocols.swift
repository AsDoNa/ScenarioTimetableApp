// MARK: - Service Protocols
// Owner: Asher
//
// Holds protocols for all services.

import Foundation

protocol CalendarServiceProtocol {
    func requestCalendarAccess() async throws
    func availableCalendars() -> [(id: String, title: String)]
    func fetchEvents(for dateRange: DateInterval, calendars: [String]) async throws -> [CalendarEvent]
    func exportStudySessions(_ sessions: [StudySession]) async throws
    func clearStudySessions(for dateRange : DateInterval) throws
}

protocol PersistenceServiceProtocol {
    func saveTasks(_ tasks: [StudyTask]) throws
    func loadTasks() throws -> [StudyTask]
    func savePreferences(_ prefs: UserPreferences) throws
    func loadPreferences() throws -> UserPreferences
    func saveSessions(_ sessions: [StudySession]) throws
    func loadSessions() throws -> [StudySession]
    func clearAll()
}

protocol UCLAPIServiceProtocol {
    func fetchTimetable(for date: Date?) async throws -> [TimetableEntry]
    func authenticate() async throws
}
