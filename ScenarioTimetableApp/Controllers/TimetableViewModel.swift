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
            let timetable = try await uclAPIService.fetchTimetable(for: startDate)

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
            errorMessage = "Failed to load schedule: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - Save Study Sessions

    func saveStudySessions(_ sessions: [StudySession]) {
        do {
            try persistenceService.saveSessions(sessions)
            weekSchedule?.studySessions = sessions
        } catch {
            errorMessage = "Failed to save study sessions"
        }
    }

    // MARK: - Clear Schedule

    func clearStudySessions() {
        weekSchedule?.studySessions = []

        do {
            try persistenceService.saveSessions([])
        } catch {
            errorMessage = "Failed to clear study sessions"
        }
    }

    // MARK: - Refresh Week

    func refreshWeek() async {
        guard let start = weekSchedule?.weekStartDate else { return }
        await loadWeekSchedule(startDate: start)
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

