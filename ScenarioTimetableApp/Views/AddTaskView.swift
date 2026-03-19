// MARK: - Add Task View
// Owner: Josh
//
// A form for creating a new study task.
// Fields:
// - Task title (text)
// - Subject (text)
// - Module code (optional)
// - Deadline (date picker)
// - Priority (segmented control: High / Medium / Low)
// - Estimated hours & minutes (steppers)
//
// Submits to TaskViewModel.addTask()

import SwiftUI

struct AddTaskView: View {
    var viewModel: TaskViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var subject = ""
    @State private var moduleCode = ""
    @State private var deadline = Date().addingTimeInterval(7 * 24 * 60 * 60)
    @State private var priority: StudyTask.Priority = .medium
    @State private var estimatedHours = 2
    @State private var estimatedMinutes = 0

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
        && !subject.trimmingCharacters(in: .whitespaces).isEmpty
        && (estimatedHours > 0 || estimatedMinutes > 0)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Task Details") {
                    TextField("Title", text: $title)
                    TextField("Subject", text: $subject)
                    TextField("Module Code (optional)", text: $moduleCode)
                }

                Section("Schedule") {
                    DatePicker("Deadline", selection: $deadline, displayedComponents: [.date, .hourAndMinute])

                    Picker("Priority", selection: $priority) {
                        Text("High").tag(StudyTask.Priority.high)
                        Text("Medium").tag(StudyTask.Priority.medium)
                        Text("Low").tag(StudyTask.Priority.low)
                    }
                    .pickerStyle(.segmented)
                }

                Section("Estimated Time") {
                    Stepper("Hours: \(estimatedHours)", value: $estimatedHours, in: 0...100)
                    Stepper("Minutes: \(estimatedMinutes)", value: $estimatedMinutes, in: 0...55, step: 5)

                    if estimatedHours > 0 || estimatedMinutes > 0 {
                        Text("Total: \(estimatedHours)h \(estimatedMinutes)m")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addTask()
                    }
                    .disabled(!isValid)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func addTask() {
        let totalMinutes = estimatedHours * 60 + estimatedMinutes
        let task = StudyTask(
            title: title.trimmingCharacters(in: .whitespaces),
            subject: subject.trimmingCharacters(in: .whitespaces),
            moduleCode: moduleCode.isEmpty ? nil : moduleCode.trimmingCharacters(in: .whitespaces),
            deadline: deadline,
            priority: priority,
            estimatedTime: totalMinutes,
            completedTime: 0,
            isComplete: false
        )
        Task {
            await viewModel.addTask(task)
        }
        dismiss()
    }
}
