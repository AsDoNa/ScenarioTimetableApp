// MARK: - Task ViewModel
// Owner: Integrator
//
// Manages study task CRUD and triggers rescheduling when tasks change.
// Coordinates between:
// - PersistenceService (saving/loading tasks)
// - SchedulingAlgorithm (re-running when tasks are added/removed)
// - TaskListView / AddTaskView (user interaction)

import Foundation
import Observation

@Observable
class TaskViewModel {
    // TODO: Implement
    //
    // Published state:
    // - var tasks: [StudyTask]
    // - var isLoading: Bool
    //
    // Methods:
    // - func loadTasks() async
    // - func addTask(_ task: StudyTask) async
    // - func deleteTask(_ task: StudyTask) async
    // - func toggleComplete(_ task: StudyTask) async
    // - func updateTask(_ task: StudyTask) async
}
