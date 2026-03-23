// MARK: - UserPreferences Model
// Owner: Asher
//
// User's scheduling preferences. The algorithm respects these when
// placing study sessions into free time.

import Foundation

struct UserPreferences: Codable {
    enum Weekday: String, Codable {
        case sunday
        case monday
        case tuesday
        case wednesday
        case thursday
        case friday
        case saturday
    }
    
    static var `default`: UserPreferences {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return UserPreferences(
            preferredStudyStartTime: cal.date(bySettingHour: 9, minute: 0, second: 0, of: today)!,
            preferredStudyEndTime: cal.date(bySettingHour: 17, minute: 0, second: 0, of: today)!,
            maxSessionLength: 90,
            minBreakBetweenSessions: 15,
            preferredDaysOff: [.saturday],
            weeklyStudyGoalTime: 20 * 60,
            firstDayOfWeek: .monday,
            selectedCalendarIdentifiers: [],
            includeCalendarEvents: true
        )
    }
    
    var preferredStudyStartTime: Date
    var preferredStudyEndTime: Date
    var maxSessionLength: Int // Minutes
    var minBreakBetweenSessions: Int // Minutes
    var preferredDaysOff: [Weekday]
    var weeklyStudyGoalTime: Int // Minutes - can be converted to hours for display
    var firstDayOfWeek: Weekday
    var selectedCalendarIdentifiers: [String]
    var includeCalendarEvents: Bool
    
    
    }
