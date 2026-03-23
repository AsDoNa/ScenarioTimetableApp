// MARK: - Task List View
// Owner: Josh
//
// Displays all study tasks in a scrollable list.
// Features:
// - Sort/filter by deadline, priority, title
// - Swipe to delete
// - Tap row to edit task
// - Leading swipe to toggle completion
// - "Add Task" button -> navigates to AddTaskView
//
// Binds to TaskViewModel for data.

import SwiftUI

struct TaskListView: View {

    @State private var viewModel = TaskViewModel(persistenceService: PersistenceService())
    @State private var showAddTask = false
    @State private var taskToEdit: StudyTask?
    @State private var sortBy: SortOption = .deadline

    enum SortOption: String, CaseIterable {
        case deadline = "Deadline"
        case priority = "Priority"
        case title = "Title"
    }

    // MARK: - Sorted / filtered lists

    private var sortedTasks: [StudyTask] {
        switch sortBy {
        case .deadline:
            return viewModel.tasks.sorted { $0.deadline < $1.deadline }
        case .priority:
            return viewModel.tasks.sorted { priorityRank($0.priority) < priorityRank($1.priority) }
        case .title:
            return viewModel.tasks.sorted {
                $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
            }
        }
    }

    private var activeTasks: [StudyTask] {
        sortedTasks.filter { !$0.isComplete }
    }

    private var completedTasks: [StudyTask] {
        sortedTasks.filter { $0.isComplete }
    }

    private func priorityRank(_ p: StudyTask.Priority) -> Int {
        switch p {
        case .high: return 0
        case .medium: return 1
        case .low: return 2
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading tasks...")
                } else if viewModel.tasks.isEmpty {
                    ContentUnavailableView {
                        Label("No Tasks", systemImage: "tray")
                    } description: {
                        Text("Add study tasks to start scheduling your week.")
                    } actions: {
                        Button("Add Task") {
                            showAddTask = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    taskList
                }
            }
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Picker("Sort By", selection: $sortBy) {
                            ForEach(SortOption.allCases, id: \.self) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                    } label: {
                        Label("Sort", systemImage: "arrow.up.arrow.down")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddTask = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddTask) {
                AddTaskView(viewModel: viewModel)
            }
            .sheet(item: $taskToEdit) { task in
                AddTaskView(viewModel: viewModel, taskToEdit: task)
            }
            .task {
                await viewModel.loadTasks()
            }
            .refreshable {
                await viewModel.loadTasks()
            }
            .overlay {
                if let error = viewModel.errorMessage {
                    VStack {
                        Spacer()
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.red.opacity(0.9), in: Capsule())
                            .padding(.bottom)
                    }
                }
            }
        }
    }

    // MARK: - Subviews

    private var taskList: some View {
        List {
            if !activeTasks.isEmpty {
                Section("Active (\(activeTasks.count))") {
                    ForEach(activeTasks) { task in
                        TaskRowView(task: task) {
                            Task { await viewModel.toggleComplete(task) }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            taskToEdit = task
                        }
                    }
                    .onDelete { offsets in
                        for index in offsets {
                            let task = activeTasks[index]
                            Task { await viewModel.deleteTask(task) }
                        }
                    }
                }
            }

            if !completedTasks.isEmpty {
                Section("Completed (\(completedTasks.count))") {
                    ForEach(completedTasks) { task in
                        TaskRowView(task: task) {
                            Task { await viewModel.toggleComplete(task) }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            taskToEdit = task
                        }
                    }
                    .onDelete { offsets in
                        for index in offsets {
                            let task = completedTasks[index]
                            Task { await viewModel.deleteTask(task) }
                        }
                    }
                }
            }
        }
    }
}
