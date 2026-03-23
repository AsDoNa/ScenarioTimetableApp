// MARK: - Preferences View
// Owner: Josh
//
// Allows the user to set their scheduling preferences:
// - Preferred study hours (start/end time pickers)
// - Max session length (stepper)
// - Break duration between sessions (stepper)
// - Days off (toggles)
// - Weekly study goal (stepper)
// - First day of week (picker)
//
// Saves via PersistenceService.

import SwiftUI

struct PreferencesView: View {

    private let persistenceService: PersistenceServiceProtocol = PersistenceService()
    private let calendarService: CalendarServiceProtocol = CalendarService()

    @State private var startTime = UserPreferences.default.preferredStudyStartTime
    @State private var endTime = UserPreferences.default.preferredStudyEndTime
    @State private var maxSessionLength = UserPreferences.default.maxSessionLength
    @State private var breakDuration = UserPreferences.default.minBreakBetweenSessions
    @State private var minSessionLength = UserPreferences.default.minSessionLength
    @State private var weeklyGoalHours = UserPreferences.default.weeklyStudyGoalTime / 60
    @State private var firstDayOfWeek = UserPreferences.default.firstDayOfWeek
    @State private var daysOff = Set(UserPreferences.default.preferredDaysOff)
    @State private var includeCalendarEvents = UserPreferences.default.includeCalendarEvents
    @State private var selectedCalendarIdentifiers = UserPreferences.default.selectedCalendarIdentifiers

    @State private var showSavedAlert = false
    @State private var hasLoaded = false
    @State private var showClearConfirmation = false

    @State private var availableCalendars: [(id: String, title: String)] = []

    private let allWeekdays: [UserPreferences.Weekday] = [
        .monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Start Time", selection: $startTime, displayedComponents: .hourAndMinute)
                    DatePicker("End Time", selection: $endTime, displayedComponents: .hourAndMinute)
                } header: {
                    Text("Work Window")
                } footer: {
                    Text("Study sessions will only be scheduled within this window.")
                }

                Section {
                    Stepper("Max session: \(maxSessionLength) min", value: $maxSessionLength, in: 15...240, step: 15)
                    Stepper("Min session: \(minSessionLength) min", value: $minSessionLength, in: 10...60, step: 5)
                    Stepper("Break between: \(breakDuration) min", value: $breakDuration, in: 5...60, step: 5)
                } header: {
                    Text("Session Settings")
                }

                Section {
                    Stepper("Weekly goal: \(weeklyGoalHours) hours", value: $weeklyGoalHours, in: 1...80)
                } header: {
                    Text("Weekly Study Goal")
                }

                Section {
                    ForEach(allWeekdays, id: \.self) { day in
                        Toggle(day.rawValue.capitalized, isOn: Binding(
                            get: { daysOff.contains(day) },
                            set: { isOff in
                                if isOff {
                                    daysOff.insert(day)
                                } else {
                                    daysOff.remove(day)
                                }
                            }
                        ))
                    }
                } header: {
                    Text("Days Off")
                } footer: {
                    Text("No study sessions will be scheduled on selected days.")
                }

                Section {
                    Picker("First day of week", selection: $firstDayOfWeek) {
                        Text("Monday").tag(UserPreferences.Weekday.monday)
                        Text("Sunday").tag(UserPreferences.Weekday.sunday)
                    }
                }
                Section {
                    Toggle("Get Calendar Events", isOn: $includeCalendarEvents)
                }
                if includeCalendarEvents {
                    calendarSection
                }

                Section {
                    Button {
                        savePreferences()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Save Preferences")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                }

                Section {
                    Button(role: .destructive) {
                        showClearConfirmation = true
                    } label: {
                        HStack {
                            Spacer()
                            Label("Delete All My Data", systemImage: "trash")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .foregroundStyle(.red)
                }
                .confirmationDialog("Clear All Data", isPresented: $showClearConfirmation, titleVisibility: .visible) {
                    Button("Clear All My Data", role: .destructive) {
                        persistenceService.clearAll()
                        hasLoaded = false
                        loadPreferences()
                    }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("This will delete all your tasks, sessions, and preferences. This cannot be undone.")
                }
            }
            .navigationTitle("Preferences")
            .alert("Saved", isPresented: $showSavedAlert) {
                Button("OK") { }
            } message: {
                Text("Your preferences have been saved.")
            }
            .task {
                loadPreferences()
                try? await calendarService.requestCalendarAccess()
                availableCalendars = calendarService.availableCalendars()
                if selectedCalendarIdentifiers.isEmpty {
                    selectedCalendarIdentifiers = availableCalendars.map { $0.id }
                }
            }
        }
    }

    private var calendarSection: some View {
        Section {
            ForEach(availableCalendars, id: \.id) { cal in
                Toggle(cal.title, isOn: Binding(
                    get: { selectedCalendarIdentifiers.contains(cal.id) },
                    set: { isOn in
                        if isOn {
                            selectedCalendarIdentifiers.append(cal.id)
                        } else {
                            selectedCalendarIdentifiers.removeAll { $0 == cal.id }
                        }
                    }
                ))
            }
        } header: {
            Text("Calendars to Include")
        } footer: {
            Text("Events from selected calendars will be treated as busy time when scheduling.")
        }
    }



    // MARK: - Persistence

    private func loadPreferences() {
        guard !hasLoaded else { return }
        do {
            let prefs = try persistenceService.loadPreferences()
            startTime = prefs.preferredStudyStartTime
            endTime = prefs.preferredStudyEndTime
            maxSessionLength = prefs.maxSessionLength
            breakDuration = prefs.minBreakBetweenSessions
            minSessionLength = prefs.minSessionLength
            weeklyGoalHours = prefs.weeklyStudyGoalTime / 60
            firstDayOfWeek = prefs.firstDayOfWeek
            daysOff = Set(prefs.preferredDaysOff)
            selectedCalendarIdentifiers = prefs.selectedCalendarIdentifiers
            includeCalendarEvents = prefs.includeCalendarEvents
        } catch {
            // No saved preferences — defaults are already set
        }
        hasLoaded = true
    }

    private func savePreferences() {
        let prefs = UserPreferences(
            preferredStudyStartTime: startTime,
            preferredStudyEndTime: endTime,
            maxSessionLength: maxSessionLength,
            minBreakBetweenSessions: breakDuration,
            preferredDaysOff: Array(daysOff),
            weeklyStudyGoalTime: weeklyGoalHours * 60,
            firstDayOfWeek: firstDayOfWeek,
            selectedCalendarIdentifiers: selectedCalendarIdentifiers,
            includeCalendarEvents: includeCalendarEvents,
            minSessionLength: minSessionLength
        )
        do {
            try persistenceService.savePreferences(prefs)
            showSavedAlert = true
        } catch {
            // Silently fail — could show error alert here
        }
    }
}
