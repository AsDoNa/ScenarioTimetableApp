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

    /// Full-range data (today → latest deadline) used for month view and multi-week scheduling.
    private(set) var allTimetableEntries: [TimetableEntry] = []
    private(set) var allCalendarEvents: [CalendarEvent] = []

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
            return UserPreferences.default
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

            // Store full-range timetable entries for multi-week scheduling
            allTimetableEntries = allEntries

            // Filter entries to only the selected week for display
            let weekEnd = startDate.addingTimeInterval(7 * 24 * 60 * 60)
            let timetable = allEntries.filter { entry in
                entry.startTime >= startDate && entry.startTime < weekEnd
            }

            // Load stored study sessions
            let sessions = try persistenceService.loadSessions()

            // Load tasks for scheduling
            tasks = try persistenceService.loadTasks()

            // Fetch calendar events for full range (today → latest task deadline)
            var fullRangeEvents: [CalendarEvent] = []
            if let calendarService {
                let today = Calendar.current.startOfDay(for: Date())
                let latestDeadline = tasks.filter({ !$0.isComplete }).compactMap({ $0.deadline }).max()
                let rangeEnd = latestDeadline ?? startDate.addingTimeInterval(7 * 24 * 60 * 60)
                let fullRange = DateInterval(
                    start: today,
                    end: max(rangeEnd, today.addingTimeInterval(7 * 24 * 60 * 60))
                )
                let preferences = loadPreferencesOrDefault()
                if preferences.includeCalendarEvents {
                    fullRangeEvents = try await calendarService.fetchEvents(for: fullRange, calendars: preferences.selectedCalendarIdentifiers)
                }
            }

            // Store full-range calendar events for multi-week scheduling
            allCalendarEvents = fullRangeEvents

            // Filter calendar events to viewed week for display
            let weekEvents = fullRangeEvents.filter { event in
                event.startTime >= startDate && event.startTime < weekEnd
            }

            weekSchedule = WeekSchedule(
                weekStartDate: startDate,
                timetableEntries: timetable,
                studySessions: sessions,
                calendarEvents: weekEvents
            )
        } catch {
            errorMessage = "Failed to load schedule: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - Generate Schedule (Task #2)

    /// Runs the scheduling algorithm and saves the result.
    /// Always generates from today, regardless of the viewed week.
    func generateSchedule() {
        guard weekSchedule != nil else { return }

        let preferences = loadPreferencesOrDefault()
        let activeTasks = tasks.filter { !$0.isComplete }

        guard !activeTasks.isEmpty else { return }

        // Use full-range data and start from today
        let sessions = SchedulingAlgorithm.generateSchedule(
            timetable: allTimetableEntries,
            calendarEvents: allCalendarEvents,
            tasks: activeTasks,
            preferences: preferences,
            startDate: Calendar.current.startOfDay(for: Date())
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

    func exportStudySessions() async throws {
        guard let dateRange = weekDateRange else { return }
        try calendarService?.clearStudySessions(for: dateRange)
        try await calendarService?.exportStudySessions(weekSchedule?.studySessions ?? [])
    }

    // MARK: - Clear Schedule

    func clearStudySessions() {
        guard let dateRange = weekDateRange else {
            saveStudySessions([])
            return
        }
        try? calendarService?.clearStudySessions(for: dateRange)
        saveStudySessions([])
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
