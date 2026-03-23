// MARK: - Timetable View
// Owner: Josh
//
// Displays the weekly timetable as a day-by-day timeline.
// Shows:
// - Fixed classes (from UCL timetable) in blue
// - Scheduled study sessions (from algorithm) in green
// - Personal calendar events in orange
//
// Binds to TimetableViewModel for data.

import SwiftUI

struct TimetableView: View {

    // Each view creates its own dependencies so that ContentView
    // can call TimetableView() with no parameters.
    // During integration (Mon 23rd), Adry can inject shared VMs instead.
    @State private var viewModel = TimetableViewModel(
        uclAPIService: UCLAPIService(),
        persistenceService: PersistenceService(),
        calendarService: CalendarService()
    )
    @State private var taskVM = TaskViewModel(persistenceService: PersistenceService())

    @State private var selectedDay: Date = startOfCurrentWeek()
    @State private var weekStartDate: Date = startOfCurrentWeek()
    @State private var isGenerating = false
    @State private var showScheduleAlert = false
    @State private var scheduleAlertMessage = ""

    private let calendar = Calendar.current
    private let persistence = PersistenceService()

    // MARK: - Computed helpers

    private var weekDays: [Date] {
        (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: weekStartDate)
        }
    }

    /// All events for the selected day, sorted chronologically.
    private var itemsForSelectedDay: [ScheduleItem] {
        guard let schedule = viewModel.weekSchedule else { return [] }
        var items: [ScheduleItem] = []

        items += schedule.timetableEntries
            .filter { calendar.isDate($0.startTime, inSameDayAs: selectedDay) }
            .map { .timetableEntry($0) }

        items += schedule.studySessions
            .filter { calendar.isDate($0.startTime, inSameDayAs: selectedDay) }
            .map { .studySession($0) }

        items += schedule.calendarEvents
            .filter { calendar.isDate($0.startTime, inSameDayAs: selectedDay) }
            .map { .calendarEvent($0) }

        return items.sorted { $0.startTime < $1.startTime }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                weekNavigationHeader
                daySelector
                Divider()

                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Loading timetable...")
                    Spacer()
                } else if let error = viewModel.errorMessage {
                    errorContent(error)
                } else if viewModel.weekSchedule == nil {
                    emptyTimetableContent
                } else if itemsForSelectedDay.isEmpty {
                    freeDayContent
                } else {
                    timelineContent
                }

                if viewModel.weekSchedule != nil {
                    bottomToolbar
                }
            }
            .navigationTitle("Timetable")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task { await viewModel.refreshWeek() }
                        }
                    label: {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
            .alert("Schedule", isPresented: $showScheduleAlert) {
                Button("OK") { }
            } message: {
                Text(scheduleAlertMessage)
            }
            .task {
                await taskVM.loadTasks()
            }
        }
    }

    // MARK: - Subviews

    private var weekNavigationHeader: some View {
        HStack {
            Button {
                shiftWeek(by: -1)
            } label: {
                Image(systemName: "chevron.left")
            }

            Spacer()

            Text(weekRangeString)
                .font(.subheadline)
                .fontWeight(.medium)

            Spacer()

            Button {
                shiftWeek(by: 1)
            } label: {
                Image(systemName: "chevron.right")
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var daySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(weekDays, id: \.self) { day in
                    dayButton(for: day)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }

    private func dayButton(for day: Date) -> some View {
        let isSelected = calendar.isDate(day, inSameDayAs: selectedDay)
        let isToday = calendar.isDateInToday(day)

        return Button {
            selectedDay = day
        } label: {
            VStack(spacing: 4) {
                Text(shortDayName(day))
                    .font(.caption2)
                    .fontWeight(.medium)

                Text("\(calendar.component(.day, from: day))")
                    .font(.callout)
                    .fontWeight(isSelected ? .bold : .regular)
            }
            .frame(width: 44, height: 52)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.accentColor : Color.clear)
            )
            .foregroundStyle(isSelected ? .white : (isToday ? Color.accentColor : .primary))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(isToday && !isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    private var timelineContent: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(itemsForSelectedDay) { item in
                    TimeSlotView(item: item)
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)
        }
    }

    private var emptyTimetableContent: some View {
        VStack {
            Spacer()
            ContentUnavailableView {
                Label("No Timetable", systemImage: "calendar.badge.plus")
            } description: {
                Text("Connect your UCL timetable to get started.")
            } actions: {
                Button("Load Timetable") {
                    Task {
                        await viewModel.loadWeekSchedule(startDate: weekStartDate)
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            Spacer()
        }
    }

    private func errorContent(_ error: String) -> some View {
        VStack {
            Spacer()
            ContentUnavailableView {
                Label("Error", systemImage: "exclamationmark.triangle")
            } description: {
                Text(error)
            } actions: {
                Button("Retry") {
                    Task {
                        await viewModel.loadWeekSchedule(startDate: weekStartDate)
                    }
                }
            }
            Spacer()
        }
    }

    private var freeDayContent: some View {
        VStack {
            Spacer()
            ContentUnavailableView {
                Label("Free Day", systemImage: "sun.max")
            } description: {
                Text("Nothing scheduled for \(longDayName(selectedDay)).")
            }
            Spacer()
        }
    }

    private var bottomToolbar: some View {
        VStack(spacing: 8) {
            Divider()
            HStack(spacing: 12) {
                Button {
                    Task { await generateSchedule() }
                } label: {
                    Label("Generate Schedule", systemImage: "sparkles")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isGenerating || taskVM.tasks.filter({ !$0.isComplete }).isEmpty)
                
                

                if !(viewModel.weekSchedule?.studySessions.isEmpty ?? true) {
                    Button {
                        Task { try? await viewModel.exportStudySessions() }
                    } label: {
                        Label("Export to Calendar", systemImage: "tray.and.arrow.up")
                            .font(.subheadline)
                    }
                    .buttonStyle(.bordered)
                    Button(role: .destructive) {
                        Task { await viewModel.clearStudySessions() }
                    } label: {
                        Label("Clear", systemImage: "trash")
                            .font(.subheadline)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .background(.bar)
    }

    // MARK: - Actions

    private func shiftWeek(by offset: Int) {
        guard let newStart = calendar.date(byAdding: .weekOfYear, value: offset, to: weekStartDate) else { return }
        weekStartDate = newStart
        selectedDay = newStart
        if viewModel.weekSchedule != nil {
            Task { await viewModel.loadWeekSchedule(startDate: newStart) }
        }
    }

    private func generateSchedule() async {
        isGenerating = true

        let preferences: UserPreferences
        do {
            preferences = try persistence.loadPreferences()
        } catch {
            preferences = defaultPreferences()
        }

        let timetable = viewModel.weekSchedule?.timetableEntries ?? []
        let calendarEvents = viewModel.weekSchedule?.calendarEvents ?? []
        let tasks = taskVM.tasks.filter { !$0.isComplete }

        guard !tasks.isEmpty else {
            scheduleAlertMessage = "No active tasks to schedule. Add some tasks first."
            showScheduleAlert = true
            isGenerating = false
            return
        }

        let sessions = SchedulingAlgorithm.generateSchedule(
            timetable: timetable,
            calendarEvents: calendarEvents,
            tasks: tasks,
            preferences: preferences,
            weekStartDate: weekStartDate
        )

        await viewModel.saveStudySessions(sessions)
        

        if sessions.isEmpty {
            scheduleAlertMessage = "Could not place any sessions. Try adjusting your preferences or freeing up time."
        } else {
            let noun = sessions.count == 1 ? "session" : "sessions"
            scheduleAlertMessage = "\(sessions.count) study \(noun) scheduled for this week."
        }
        showScheduleAlert = true
        isGenerating = false
    }

    // MARK: - Helpers

    private var weekRangeString: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        guard let endDate = calendar.date(byAdding: .day, value: 6, to: weekStartDate) else {
            return fmt.string(from: weekStartDate)
        }
        let yearFmt = DateFormatter()
        yearFmt.dateFormat = ", yyyy"
        return "\(fmt.string(from: weekStartDate)) – \(fmt.string(from: endDate))\(yearFmt.string(from: endDate))"
    }

    private func shortDayName(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f.string(from: date)
    }

    private func longDayName(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEEE"
        return f.string(from: date)
    }

    /// Returns the Monday of the current week.
    static func startOfCurrentWeek() -> Date {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let weekday = cal.component(.weekday, from: today)
        // weekday: 1 = Sun, 2 = Mon, … 7 = Sat → offset to Monday
        let daysToSubtract = (weekday + 5) % 7
        return cal.date(byAdding: .day, value: -daysToSubtract, to: today)!
    }

    private func defaultPreferences() -> UserPreferences {
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
