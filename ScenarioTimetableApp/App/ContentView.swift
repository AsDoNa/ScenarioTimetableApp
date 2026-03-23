// MARK: - Root Navigation View
// Owner: Adry
//
// The root view of the app. Sets up tab navigation
// and wires ViewModels to Views.

import SwiftUI

struct ContentView: View {

    @State private var timetableVM = TimetableViewModel(
        uclAPIService: UCLAPIService(),
        persistenceService: PersistenceService(),
        calendarService: CalendarService()
    )
    @State private var taskVM = TaskViewModel(persistenceService: PersistenceService())

    var body: some View {
        TabView {
            TimetableView(viewModel: timetableVM, taskVM: taskVM)
                .tabItem {
                    Label("Timetable", systemImage: "calendar")
                }

            TaskListView(viewModel: taskVM, timetableVM: timetableVM)
                .tabItem {
                    Label("Tasks", systemImage: "list.bullet")
                }

            PreferencesView()
                .tabItem {
                    Label("Preferences", systemImage: "gearshape")
                }
        }
    }
}
