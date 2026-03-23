// MARK: - Root Navigation View
// Owner: Adry
//
// The root view of the app. Sets up tab navigation
// and wires ViewModels to Views.

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
