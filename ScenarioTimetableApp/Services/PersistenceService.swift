// MARK: - Persistence Service
// Owner: Asher
//
// Handles local data storage for:
// - Study tasks (CRUD)
// - User preferences
// - Cached timetable data
// - Generated study sessions
//
// Options: SwiftData, UserDefaults, or JSON file storage.
// Choose based on complexity needs.

import Foundation

class PersistenceService: PersistenceServiceProtocol {
    // Intended usage: load on app launch, save on app close.
    // In-memory state is managed by the ViewModels.
    
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    enum PersistenceError: Error {
        case notFound
    }
    
    func saveTasks(_ tasks: [StudyTask]) throws {
        let encodedTasks = try encoder.encode(tasks)
        UserDefaults.standard.set(encodedTasks, forKey: "tasks")
    }
    
    func loadTasks() throws -> [StudyTask] {
        guard let data =  UserDefaults.standard.data(forKey: "tasks") else {
            return []
        }
        let tasks = try decoder.decode([StudyTask].self, from: data)
        return tasks
    }
    
    func savePreferences(_ prefs: UserPreferences) throws {
        let encodedPrefs = try encoder.encode(prefs)
        UserDefaults.standard.set(encodedPrefs, forKey: "preferences")
    }
    
    func loadPreferences() throws -> UserPreferences {
        guard let data = UserDefaults.standard.data(forKey: "preferences") else {
            throw PersistenceError.notFound
        }
        let prefs = try decoder.decode(UserPreferences.self, from: data)
        return prefs
    }
    
    func saveSessions(_ sessions: [StudySession]) throws {
        let encodedSessions = try encoder.encode(sessions)
        UserDefaults.standard.set(encodedSessions, forKey: "sessions")
    }
    func loadSessions() throws -> [StudySession] {
        guard let data =  UserDefaults.standard.data(forKey: "sessions") else {
            return []
        }
        let sessions = try decoder.decode([StudySession].self, from: data)
        return sessions
    }
}
