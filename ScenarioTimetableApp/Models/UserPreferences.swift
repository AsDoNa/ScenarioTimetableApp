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
            includeCalendarEvents: true,
            minSessionLength: 30
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
    var minSessionLength: Int // Minutes

    init(
        preferredStudyStartTime: Date,
        preferredStudyEndTime: Date,
        maxSessionLength: Int,
        minBreakBetweenSessions: Int,
        preferredDaysOff: [Weekday],
        weeklyStudyGoalTime: Int,
        firstDayOfWeek: Weekday,
        selectedCalendarIdentifiers: [String] = [],
        includeCalendarEvents: Bool = true,
        minSessionLength: Int = 30
    ) {
        self.preferredStudyStartTime = preferredStudyStartTime
        self.preferredStudyEndTime = preferredStudyEndTime
        self.maxSessionLength = maxSessionLength
        self.minBreakBetweenSessions = minBreakBetweenSessions
        self.preferredDaysOff = preferredDaysOff
        self.weeklyStudyGoalTime = weeklyStudyGoalTime
        self.firstDayOfWeek = firstDayOfWeek
        self.selectedCalendarIdentifiers = selectedCalendarIdentifiers
        self.includeCalendarEvents = includeCalendarEvents
        self.minSessionLength = minSessionLength
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        preferredStudyStartTime = try container.decode(Date.self, forKey: .preferredStudyStartTime)
        preferredStudyEndTime = try container.decode(Date.self, forKey: .preferredStudyEndTime)
        maxSessionLength = try container.decode(Int.self, forKey: .maxSessionLength)
        minBreakBetweenSessions = try container.decode(Int.self, forKey: .minBreakBetweenSessions)
        preferredDaysOff = try container.decode([Weekday].self, forKey: .preferredDaysOff)
        weeklyStudyGoalTime = try container.decode(Int.self, forKey: .weeklyStudyGoalTime)
        firstDayOfWeek = try container.decode(Weekday.self, forKey: .firstDayOfWeek)
        selectedCalendarIdentifiers = try container.decodeIfPresent([String].self, forKey: .selectedCalendarIdentifiers) ?? []
        includeCalendarEvents = try container.decodeIfPresent(Bool.self, forKey: .includeCalendarEvents) ?? true
        minSessionLength = try container.decodeIfPresent(Int.self, forKey: .minSessionLength) ?? 30
    }
}
