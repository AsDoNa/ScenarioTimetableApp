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
    private(set) var tasks: [StudyTask] = []

    // MARK: - Dependencies

    private let uclAPIService: UCLAPIServiceProtocol
    private let persistenceService: PersistenceServiceProtocol
    let calendarService: CalendarServiceProtocol?

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

    // MARK: - Preferences Helper (Task #1)

    /// Loads user preferences, falling back to sensible defaults on first launch.
    private func loadPreferencesOrDefault() -> UserPreferences {
        do {
            return try persistenceService.loadPreferences()
        } catch {
            let cal = Calendar.current
            let today = cal.startOfDay(for: Date())
            return UserPreferences(
                preferredStudyStartTime: cal.date(bySettingHour: 9, minute: 0, second: 0, of: today)!,
                preferredStudyEndTime: cal.date(bySettingHour: 17, minute: 0, second: 0, of: today)!,
                maxSessionLength: 90,
                minBreakBetweenSessions: 15,
                preferredDaysOff: [.saturday],
                weeklyStudyGoalTime: 20 * 60,
                firstDayOfWeek: .monday
            )
        }
    }

    // MARK: - Timetable Loading

    func loadWeekSchedule(startDate: Date) async {
        isLoading = true
        errorMessage = nil

        do {
            // Authenticate and fetch timetable
            try await uclAPIService.authenticate()
            let allEntries = try await uclAPIService.fetchTimetable(for: nil)

            // Task #3: Filter entries to only the selected week
            let weekEnd = startDate.addingTimeInterval(7 * 24 * 60 * 60)
            let timetable = allEntries.filter { entry in
                entry.startTime >= startDate && entry.startTime < weekEnd
            }

            // Load stored study sessions
            let sessions = try persistenceService.loadSessions()

            // Load tasks for scheduling
            tasks = try persistenceService.loadTasks()

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

            // Task #2: Auto-generate schedule if there are active tasks
            let activeTasks = tasks.filter { !$0.isComplete }
            if !activeTasks.isEmpty {
                generateSchedule()
            }

        } catch {
            errorMessage = "Failed to load schedule: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - Generate Schedule (Task #2)

    /// Runs the scheduling algorithm and saves the result.
    func generateSchedule() {
        guard let schedule = weekSchedule else { return }

        let preferences = loadPreferencesOrDefault()
        let activeTasks = tasks.filter { !$0.isComplete }

        guard !activeTasks.isEmpty else { return }

        let sessions = SchedulingAlgorithm.generateSchedule(
            timetable: schedule.timetableEntries,
            calendarEvents: schedule.calendarEvents,
            tasks: activeTasks,
            preferences: preferences,
            weekStartDate: schedule.weekStartDate
        )

        saveStudySessions(sessions)
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

    // MARK: - Export to Calendar (Task #7)

    func exportToCalendar() async {
        guard let sessions = weekSchedule?.studySessions, !sessions.isEmpty else { return }

        do {
            try await calendarService?.exportStudySessions(sessions)
        } catch {
            errorMessage = "Failed to export to calendar: \(error.localizedDescription)"
        }
    }

    // MARK: - Task Helpers

    /// Reload tasks from persistence (used when tasks change externally).
    func reloadTasks() {
        do {
            tasks = try persistenceService.loadTasks()
        } catch {
            errorMessage = "Failed to load tasks"
        }
    }

    /// Toggle a task's completion status (used from detail views).
    func toggleTaskComplete(taskID: UUID) {
        guard var allTasks = try? persistenceService.loadTasks(),
              let index = allTasks.firstIndex(where: { $0.id == taskID }) else { return }

        allTasks[index].isComplete.toggle()

        do {
            try persistenceService.saveTasks(allTasks)
            tasks = allTasks
        } catch {
            errorMessage = "Failed to update task"
        }
    }
}
