// MARK: - Study Session Detail View
// Owner: Josh
//
// Shows details for a scheduled study session.
// Allows marking the parent task as complete.

import SwiftUI

struct StudySessionDetailView: View {
    let session: StudySession
    var viewModel: TimetableViewModel

    @Environment(\.dismiss) private var dismiss

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d 'at' HH:mm"
        return f
    }()

    private var durationMinutes: Int {
        Int(session.endTime.timeIntervalSince(session.startTime) / 60)
    }

    private var durationDisplay: String {
        let hours = durationMinutes / 60
        let minutes = durationMinutes % 60
        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }

    private var parentTask: StudyTask? {
        viewModel.tasks.first { $0.id == session.taskID }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Task") {
                    LabeledContent("Title", value: session.taskTitle)

                    if let code = session.moduleCode, !code.isEmpty {
                        LabeledContent("Module Code", value: code)
                    }
                }

                Section("Time") {
                    LabeledContent("Start") {
                        Text(Self.timeFormatter.string(from: session.startTime))
                    }
                    LabeledContent("End") {
                        Text(Self.timeFormatter.string(from: session.endTime))
                    }
                    LabeledContent("Duration", value: durationDisplay)
                }

                if let task = parentTask {
                    Section {
                        Button {
                            viewModel.toggleTaskComplete(taskID: task.id)
                            dismiss()
                        } label: {
                            Label(
                                task.isComplete ? "Mark Incomplete" : "Mark Complete",
                                systemImage: task.isComplete ? "xmark.circle" : "checkmark.circle"
                            )
                        }
                        .foregroundStyle(task.isComplete ? .orange : .green)
                    }
                }
            }
            .navigationTitle("Study Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
