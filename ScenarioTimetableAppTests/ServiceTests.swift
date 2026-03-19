// MARK: - Service Tests
// Owner: Asher
//
// Tests for data services (API, persistence, calendar).
// Consider mocking network responses for UCLAPIService tests.
// Test cases:
// - Parse valid UCL API response → correct [TimetableEntry]
// - Handle API error / invalid JSON gracefully
// - Save and load tasks round-trip
// - Save and load preferences round-trip

import XCTest
@testable import ScenarioTimetableApp

final class ServiceTests: XCTestCase {
    var service: PersistenceService!
    
    override func setUp() {
        super.setUp()
        service = PersistenceService()
    }
    
    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "tasks")
        UserDefaults.standard.removeObject(forKey: "sessions")
        UserDefaults.standard.removeObject(forKey: "preferences")
        super.tearDown()
    }
    
    func testSaveAndLoadTasks() throws {
        
        let task = StudyTask(
            title:"testStudyTask",
            subject: "OOP",
            moduleCode: "COMP0004",
            deadline: Date(),
            priority: .high,
            estimatedTime: 60,
            completedTime: 20,
            isComplete: false
        )
        
        try service.saveTasks([task])
        let loadedTasks: [StudyTask] = try service.loadTasks()
        
        XCTAssertEqual(loadedTasks.count, 1)
    }
    
    func testLoadTasksEmpty() throws {
        let loadedTasks: [StudyTask] = try service.loadTasks()
        
        XCTAssertTrue(loadedTasks.isEmpty)
    }
    
    func testSaveAndLoadPreferences() throws {
        
        let nineAM = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!
        let fivePM = Calendar.current.date(bySettingHour: 17, minute: 0, second: 0, of: Date())!
        
        let preferences = UserPreferences(
            preferredStudyStartTime: nineAM,
            preferredStudyEndTime: fivePM,
            maxSessionLength: 90,
            minBreakBetweenSessions: 15,
            preferredDaysOff: [.saturday],
            weeklyStudyGoalTime: 360,
            firstDayOfWeek: .monday
        )
        
        try service.savePreferences(preferences)
        let loadedPreferences: UserPreferences = try service.loadPreferences()
        
        XCTAssertEqual(loadedPreferences.preferredStudyStartTime, nineAM)
        XCTAssertEqual(loadedPreferences.maxSessionLength, 90)
        XCTAssertEqual(loadedPreferences.preferredDaysOff, [.saturday])
    }
    
    func testCannotLoadMultiplePreferences() throws {
        return
    }
    
    func testLoadPreferencesThrowsWhenEmpty() throws {
        XCTAssertThrowsError(try service.loadPreferences()) { error in
            XCTAssertTrue(error is PersistenceService.PersistenceError)
        }
    }
    
}
