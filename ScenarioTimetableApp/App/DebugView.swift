// MARK: - Debug View
// Temporary view for integration testing — NOT part of final UI.
// Tests: PersistenceService, SchedulingAlgorithm, UCLAPIService end-to-end.

import SwiftUI

struct DebugView: View {

    // MARK: - State

    @State private var log: [String] = []
    @State private var sessions: [StudySession] = []
    @State private var timetableEntries: [TimetableEntry] = []

    private let persistence = PersistenceService()
    private let uclAPI = UCLAPIService()
    private let calendarService = CalendarService()

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                Section("Persistence + Algorithm") {
                    Button("1. Save a dummy task") { saveTask() }
                    Button("2. Load tasks from disk") { loadTasks() }
                    Button("3. Run scheduling algorithm") { runAlgorithm() }
                    Button("4. Clear all data") { clearAll() }
                        .foregroundStyle(.red)
                }

                Section("Calendar") {
                    Button("8. Fetch calendar events (this week)") {
                        Task { await fetchCalendarEvents() }
                    }
                    Button("9. Export sessions to calendar") {
                        Task { await exportSessions() }
                    }
                    Button("10. Full flow with calendar events") {
                        Task { await fullFlowWithCalendar() }
                    }
                }

                Section("UCL API") {
                    Button("5. Authenticate with UCL") {
                        Task { await authenticate() }
                    }
                    Button("6. Fetch timetable (this week)") {
                        Task { await fetchTimetable() }
                    }
                    Button("7. Full flow: auth → fetch → schedule") {
                        Task { await fullFlow() }
                    }
                }

                if !sessions.isEmpty {
                    Section("Generated Sessions (\(sessions.count))") {
                        ForEach(sessions) { session in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(session.taskTitle)
                                    .font(.headline)
                                Text("\(formatted(session.startTime)) → \(formatted(session.endTime))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }

                Section("Log") {
                    if log.isEmpty {
                        Text("Tap an action above")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(Array(log.enumerated()), id: \.offset) { _, entry in
                            Text(entry)
                                .font(.caption.monospaced())
                        }
                    }
                }
            }
            .navigationTitle("Debug")
        }
    }

    // MARK: - Actions

    private func saveTask() {
        let task = StudyTask(
            title: "Revise Linear Algebra",
            subject: "Mathematics",
            moduleCode: "MATH1402",
            deadline: Date().addingTimeInterval(3 * 24 * 60 * 60), // 3 days from now
            priority: .high,
            estimatedTime: 120,
            completedTime: 0,
            isComplete: false
        )
        do {
            let existing = (try? persistence.loadTasks()) ?? []
            try persistence.saveTasks(existing + [task])
            log("✅ Saved task: \"\(task.title)\"")
        } catch {
            log("❌ Save failed: \(error)")
        }
    }

    private func loadTasks() {
        do {
            let tasks = try persistence.loadTasks()
            log("✅ Loaded \(tasks.count) task(s):")
            for t in tasks {
                log("   • \(t.title) [\(t.priority)] \(t.estimatedTime)min")
            }
        } catch {
            log("❌ Load failed: \(error)")
        }
    }

    private func runAlgorithm() {
        do {
            let tasks = try persistence.loadTasks()
            guard !tasks.isEmpty else {
                log("⚠️ No tasks found — tap 'Save a dummy task' first")
                return
            }

            let prefs = makeDefaultPreferences()
            let weekStart = Calendar.current.startOfDay(for: Date())

            // Fake a 2-hour timetable block today at 10:00–12:00
            let today = weekStart
            var comps = Calendar.current.dateComponents([.year, .month, .day], from: today)
            comps.hour = 10; comps.minute = 0
            let blockStart = Calendar.current.date(from: comps)!
            comps.hour = 12
            let blockEnd = Calendar.current.date(from: comps)!

            let fakeEntry = TimetableEntry(
                moduleName: "Introduction to Algorithms",
                moduleCode: "COMP1234",
                lecturerName: "Dr. Smith",
                startTime: blockStart,
                endTime: blockEnd,
                location: "Room 101",
                locationCoords: Coordinates(lat: 51.524, lon: -0.134),
                type: .unknown("Lecture")
            )

            sessions = SchedulingAlgorithm.generateSchedule(
                timetable: [fakeEntry],
                calendarEvents: [],
                tasks: tasks,
                preferences: prefs,
                weekStartDate: weekStart
            )

            log("✅ Algorithm produced \(sessions.count) session(s)")
            for s in sessions {
                let mins = Int(s.endTime.timeIntervalSince(s.startTime) / 60)
                log("   • \(s.taskTitle): \(formatted(s.startTime)) (\(mins)min)")
            }
        } catch {
            log("❌ Algorithm error: \(error)")
        }
    }

    private func clearAll() {
        do {
            try persistence.saveTasks([])
            try persistence.saveSessions([])
            sessions = []
            log("🗑️ Cleared all tasks and sessions")
        } catch {
            log("❌ Clear failed: \(error)")
        }
    }

    // MARK: - Calendar Actions

    private func fetchCalendarEvents() async {
        log("📆 Fetching calendar events this week...")
        do {
            let range = DateInterval(
                start: Calendar.current.startOfDay(for: Date()),
                duration: 7 * 24 * 60 * 60
            )
            let events = try await calendarService.fetchEvents(for: range)
            log("✅ Found \(events.count) calendar event(s)")
            for e in events.prefix(5) {
                log("   • \(e.title ?? "Untitled"): \(formatted(e.startTime))")
            }
            if events.count > 5 { log("   ... and \(events.count - 5) more") }
        } catch {
            log("❌ Calendar fetch failed: \(error)")
        }
    }

    private func exportSessions() async {
        guard !sessions.isEmpty else {
            log("⚠️ No sessions to export — run algorithm first")
            return
        }
        log("📤 Exporting \(sessions.count) session(s) to calendar...")
        do {
            try await calendarService.exportStudySessions(sessions)
            log("✅ Exported to 'Study Sessions' calendar — check Calendar app")
        } catch {
            log("❌ Export failed: \(error)")
        }
    }

    private func fullFlowWithCalendar() async {
        log("🚀 Full flow with calendar...")
        do {
            log("  [1/4] Authenticating with UCL...")
            try await uclAPI.authenticate()
            log("  ✅ Authenticated")

            log("  [2/4] Fetching timetable...")
            let entries = try await uclAPI.fetchTimetable(for: nil)
            timetableEntries = entries
            log("  ✅ Got \(entries.count) timetable entries")

            log("  [3/4] Fetching calendar events...")
            let range = DateInterval(
                start: Calendar.current.startOfDay(for: Date()),
                duration: 7 * 24 * 60 * 60
            )
            let calEvents = try await calendarService.fetchEvents(for: range)
            log("  ✅ Got \(calEvents.count) calendar event(s)")

            log("  [4/4] Running algorithm...")
            let tasks = try persistence.loadTasks()
            guard !tasks.isEmpty else {
                log("  ⚠️ No tasks — tap 'Save a dummy task' first")
                return
            }
            let weekStart = Calendar.current.startOfDay(for: Date())
            sessions = SchedulingAlgorithm.generateSchedule(
                timetable: entries,
                calendarEvents: calEvents,
                tasks: tasks,
                preferences: makeDefaultPreferences(),
                weekStartDate: weekStart
            )
            log("  ✅ Scheduled \(sessions.count) session(s)")
            for s in sessions {
                let mins = Int(s.endTime.timeIntervalSince(s.startTime) / 60)
                log("   • \(s.taskTitle): \(formatted(s.startTime)) (\(mins)min)")
            }
            log("✅ Full flow complete!")
        } catch {
            log("❌ Full flow failed: \(error)")
        }
    }

    // MARK: - UCL API Actions

    private func authenticate() async {
        log("🔐 Starting UCL OAuth...")
        do {
            try await uclAPI.authenticate()
            log("✅ Authenticated successfully")
        } catch {
            log("❌ Auth failed: \(error)")
        }
    }

    private func fetchTimetable() async {
        log("📅 Fetching timetable...")
        do {
            let entries = try await uclAPI.fetchTimetable(for: Date())
            timetableEntries = entries
            log("✅ Fetched \(entries.count) timetable entry(ies)")
            for e in entries.prefix(5) {
                log("   • \(e.moduleName): \(formatted(e.startTime)) → \(formatted(e.endTime))")
            }
            if entries.count > 5 { log("   ... and \(entries.count - 5) more") }
        } catch {
            log("❌ Fetch failed: \(error)")
        }
    }

    private func fullFlow() async {
        log("🚀 Starting full flow...")
        do {
            // 1. Auth
            log("  [1/3] Authenticating...")
            try await uclAPI.authenticate()
            log("  ✅ Authenticated")

            // 2. Fetch timetable
            log("  [2/3] Fetching timetable...")
            let entries = try await uclAPI.fetchTimetable(for: Date())
            timetableEntries = entries
            log("  ✅ Got \(entries.count) entries")

            // 3. Schedule
            log("  [3/3] Running algorithm...")
            let tasks = try persistence.loadTasks()
            guard !tasks.isEmpty else {
                log("  ⚠️ No tasks — tap 'Save a dummy task' first")
                return
            }
            let weekStart = Calendar.current.startOfDay(for: Date())
            sessions = SchedulingAlgorithm.generateSchedule(
                timetable: entries,
                calendarEvents: [],
                tasks: tasks,
                preferences: makeDefaultPreferences(),
                weekStartDate: weekStart
            )
            log("  ✅ Scheduled \(sessions.count) session(s)")
            log("✅ Full flow complete!")
        } catch {
            log("❌ Full flow failed: \(error)")
        }
    }

    // MARK: - Helpers

    private func log(_ message: String) {
        log.insert(message, at: 0)
    }

    private func formatted(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE HH:mm"
        return f.string(from: date)
    }

    private func makeDefaultPreferences() -> UserPreferences {
        var startComps = DateComponents()
        startComps.hour = 9; startComps.minute = 0
        let start = Calendar.current.date(from: startComps)!

        var endComps = DateComponents()
        endComps.hour = 21; endComps.minute = 0
        let end = Calendar.current.date(from: endComps)!

        return UserPreferences(
            preferredStudyStartTime: start,
            preferredStudyEndTime: end,
            maxSessionLength: 60,
            minBreakBetweenSessions: 15,
            preferredDaysOff: [],
            weeklyStudyGoalTime: 600,
            firstDayOfWeek: .monday
        )
    }
}

#Preview {
    DebugView()
}
