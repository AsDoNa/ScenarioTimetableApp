// MARK: - Timetable ViewModel
// Owner: Adry
//
// Manages the timetable state and coordinates between:
// - UCLAPIService (fetching timetable data)
// - CalendarService (fetching personal events)
// - SchedulingAlgorithm (generating study sessions)
// - TimetableView (displaying the result)
//
// This is an @Observable class that the Views bind to.

import Foundation
import Observation

@Observable
final class TimetableViewModel {

    // MARK: - State exposed to Views

    var weekSchedule: WeekSchedule?
    var isLoading: Bool = false
    var errorMessage: String?

    // MARK: - Dependencies

    private let uclAPIService: UCLAPIServiceProtocol
    private let persistenceService: PersistenceServiceProtocol
    private let calendarService: CalendarServiceProtocol?

    // MARK: - Init

    init(
        uclAPIService: UCLAPIServiceProtocol,
        persistenceService: PersistenceServiceProtocol,
        calendarService: CalendarServiceProtocol? = nil
    ) {
        self.uclAPIService = uclAPIService
        self.persistenceService = persistenceService
        self.calendarService = calendarService
    }

    // MARK: - Timetable Loading

    func loadWeekSchedule(startDate: Date) async {
        isLoading = true
        errorMessage = nil

        do {
            // Authenticate and fetch timetable
            try await uclAPIService.authenticate()
            let timetable = try await uclAPIService.fetchTimetable(for: nil)

            // Load stored study sessions
            let sessions = try persistenceService.loadSessions()

            // Optionally load calendar events
            var events: [CalendarEvent] = []
            if let calendarService {
                let range = DateInterval(
                    start: startDate,
                    duration: 7 * 24 * 60 * 60
                )
                events = try await calendarService.fetchEvents(for: range)
            }

            weekSchedule = WeekSchedule(
                weekStartDate: startDate,
                timetableEntries: timetable,
                studySessions: sessions,
                calendarEvents: events
            )

        } catch {
            print("Full error: \(error)")
            errorMessage = "Failed to load schedule: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - Save Study Sessions

    func saveStudySessions(_ sessions: [StudySession]) async {
        do {
            try persistenceService.saveSessions(sessions)
            weekSchedule?.studySessions = sessions
        } catch {
            errorMessage = "Failed to save study sessions"
        }
        do {
            guard let dateRange = weekDateRange else { return }
            try calendarService?.clearStudySessions(for: dateRange)
            try await calendarService?.exportStudySessions(sessions)
        } catch {
            errorMessage = "Failed to export study sessions to calendar"
        }
    }
    
    func exportStudySessions() async throws {
        guard let dateRange = weekDateRange else { return }
        try calendarService?.clearStudySessions(for: dateRange)
        try await calendarService?.exportStudySessions(weekSchedule?.studySessions ?? [])
    }

    // MARK: - Clear Schedule

    func clearStudySessions() async {
        await saveStudySessions([])
    }

    // MARK: - Refresh Week

    func refreshWeek() async {
        guard let start = weekSchedule?.weekStartDate else { return }
        await loadWeekSchedule(startDate: start)
    }
    
    // MARK: - Helpers
    private var weekDateRange: DateInterval? {
        guard let startDate = weekSchedule?.weekStartDate else { return nil }
        let endDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate)!
        return DateInterval(start: startDate, end: endDate)
    }

}
    // TODO: Implement
    //
    // Published state:
    // - var weekSchedule: WeekSchedule?
    // - var isLoading: Bool
    // - var errorMessage: String?
    //
    // Methods:
    // - func fetchTimetable() async
    // - func generateSchedule() async
    // - func refreshWeek() async

