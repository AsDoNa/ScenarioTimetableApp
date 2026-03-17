// MARK: - Task ViewModel
// Owner: Adry
//
// Manages study task CRUD and triggers rescheduling when tasks change.
// Coordinates between:
// - PersistenceService (saving/loading tasks)
// - SchedulingAlgorithm (re-running when tasks are added/removed)
// - TaskListView / AddTaskView (user interaction)

import Foundation
import Observation

@Observable
final class TaskViewModel {
    var tasks: [StudyTask] = []
    var isLoading: Bool = false
    var errorMessage: String?

    private let persistenceService: PersistenceServiceProtocol

    /// Optional callback so another part of the app can re-run scheduling
    /// whenever tasks are changed.
    var onTasksChanged: (([StudyTask]) -> Void)?

    init(persistenceService: PersistenceServiceProtocol) {
        self.persistenceService = persistenceService
    }

    func loadTasks() async {
        isLoading = true
        errorMessage = nil

        do {
            tasks = try persistenceService.loadTasks()
        } catch {
            errorMessage = "Failed to load tasks: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func addTask(_ task: StudyTask) async {
        tasks.append(task)
        persistTasksAndNotify()
    }

    func deleteTask(_ task: StudyTask) async {
        tasks.removeAll { $0.id == task.id }
        persistTasksAndNotify()
    }

    func toggleComplete(_ task: StudyTask) async {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else {
            return
        }

        tasks[index].isComplete.toggle()
        persistTasksAndNotify()
    }

    func updateTask(_ task: StudyTask) async {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else {
            return
        }

        tasks[index] = task
        persistTasksAndNotify()
    }

    private func persistTasksAndNotify() {
        do {
            try persistenceService.saveTasks(tasks)
            onTasksChanged?(tasks)
        } catch {
            errorMessage = "Failed to save tasks: \(error.localizedDescription)"
        }
    }
}
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
