// MARK: - Root Navigation View
// Owner: Adry
//
// The root view of the app. Sets up tab navigation or a NavigationStack
// and wires ViewModels to Views.
// This is where the integrator connects all the pieces together.

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            TimetableView()
                .tabItem {
                    Label("Timetable", systemImage: "calendar")
                }

            TaskListView()
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