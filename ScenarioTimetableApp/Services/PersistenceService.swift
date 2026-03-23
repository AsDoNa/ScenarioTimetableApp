// MARK: - Persistence Service
// Owner: Asher
//
// Handles local data storage for:
// - Study tasks (CRUD)
// - User preferences
// - Generated study sessions
//
// Data is encrypted at rest using AES-GCM (CryptoKit)
// with the symmetric key stored in the Keychain.

import Foundation
import CryptoKit

class PersistenceService: PersistenceServiceProtocol {

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    enum PersistenceError: Error {
        case notFound
        case encryptionFailed
        case decryptionFailed
    }

    // MARK: - Encryption Key

    private static let symmetricKeyTag = "com.scenariotimetable.encryptionKey"

    /// Loads the AES-256 key from Keychain, or generates and stores a new one.
    private var symmetricKey: SymmetricKey {
        if let existingData = KeychainService.load(key: Self.symmetricKeyTag) {
            return SymmetricKey(data: existingData)
        }
        let newKey = SymmetricKey(size: .bits256)
        let keyData = newKey.withUnsafeBytes { Data($0) }
        try? KeychainService.save(key: Self.symmetricKeyTag, data: keyData)
        return newKey
    }

    // MARK: - Encrypt / Decrypt helpers

    private func encrypt(_ data: Data) throws -> Data {
        let sealedBox = try AES.GCM.seal(data, using: symmetricKey)
        guard let combined = sealedBox.combined else {
            throw PersistenceError.encryptionFailed
        }
        return combined
    }

    private func decrypt(_ data: Data) throws -> Data {
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealedBox, using: symmetricKey)
    }

    // MARK: - Helpers

    private func saveEncrypted(_ plainData: Data, forKey key: String) throws {
        let encrypted = try encrypt(plainData)
        UserDefaults.standard.set(encrypted, forKey: key)
    }

    private func loadDecrypted(forKey key: String) throws -> Data {
        guard let encrypted = UserDefaults.standard.data(forKey: key) else {
            throw PersistenceError.notFound
        }
        return try decrypt(encrypted)
    }

    // MARK: - Migration (reads unencrypted if decryption fails)

    /// Attempts decryption first; if that fails, tries reading raw data (pre-encryption migration).
    private func loadWithMigration<T: Decodable>(forKey key: String, type: T.Type) throws -> T {
        guard let stored = UserDefaults.standard.data(forKey: key) else {
            throw PersistenceError.notFound
        }

        // Try decrypting first (new format)
        if let decrypted = try? decrypt(stored),
           let decoded = try? decoder.decode(T.self, from: decrypted) {
            return decoded
        }

        // Fall back to raw JSON (old unencrypted format) and re-encrypt
        let decoded = try decoder.decode(T.self, from: stored)
        let reEncrypted = try encrypt(stored)
        UserDefaults.standard.set(reEncrypted, forKey: key)
        return decoded
    }

    // MARK: - Tasks

    func saveTasks(_ tasks: [StudyTask]) throws {
        let data = try encoder.encode(tasks)
        try saveEncrypted(data, forKey: "tasks")
    }

    func loadTasks() throws -> [StudyTask] {
        do {
            return try loadWithMigration(forKey: "tasks", type: [StudyTask].self)
        } catch PersistenceError.notFound {
            return []
        }
    }

    // MARK: - Preferences

    func savePreferences(_ prefs: UserPreferences) throws {
        let data = try encoder.encode(prefs)
        try saveEncrypted(data, forKey: "preferences")
    }

    func loadPreferences() throws -> UserPreferences {
        return try loadWithMigration(forKey: "preferences", type: UserPreferences.self)
    }

    // MARK: - Sessions

    func saveSessions(_ sessions: [StudySession]) throws {
        let data = try encoder.encode(sessions)
        try saveEncrypted(data, forKey: "sessions")
    }

    func loadSessions() throws -> [StudySession] {
        do {
            return try loadWithMigration(forKey: "sessions", type: [StudySession].self)
        } catch PersistenceError.notFound {
            return []
        }
    }
    
    func clearAll() {
        try? saveTasks([])
        try? saveSessions([])
        try? savePreferences(UserPreferences.default)
        try? KeychainService.delete(key: "uclToken")
        UserDefaults.standard.removeObject(forKey: "studyCalendarIdentifier")
    }
}
