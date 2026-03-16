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
    var preferredStudyStartTime: Date
    var preferredStudyEndTime: Date
    var maxSessionLength: Int // Minutes
    var minBreakBetweenSessions: Int // Minutes
    var preferredDaysOff: [Weekday]
    var weeklyStudyGoalTime: Int // Minutes - can be converted to hours for display
    var firstDayOfWeek: Weekday
    }
