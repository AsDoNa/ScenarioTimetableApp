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

    @State private var startTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!
    @State private var endTime = Calendar.current.date(bySettingHour: 17, minute: 0, second: 0, of: Date())!
    @State private var maxSessionLength = 90
    @State private var breakDuration = 15
    @State private var weeklyGoalHours = 20
    @State private var firstDayOfWeek: UserPreferences.Weekday = .monday
    @State private var daysOff: Set<UserPreferences.Weekday> = [.saturday]

    @State private var showSavedAlert = false
    @State private var hasLoaded = false

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
            }
            .navigationTitle("Preferences")
            .alert("Saved", isPresented: $showSavedAlert) {
                Button("OK") { }
            } message: {
                Text("Your preferences have been saved.")
            }
            .task {
                loadPreferences()
            }
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
            weeklyGoalHours = prefs.weeklyStudyGoalTime / 60
            firstDayOfWeek = prefs.firstDayOfWeek
            daysOff = Set(prefs.preferredDaysOff)
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
            firstDayOfWeek: firstDayOfWeek
        )
        do {
            try persistenceService.savePreferences(prefs)
            showSavedAlert = true
        } catch {
            // Silently fail — could show error alert here
        }
    }
}
