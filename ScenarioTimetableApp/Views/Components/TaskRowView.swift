// MARK: - Task Row View (Component)
// Owner: Josh
//
// A reusable component that renders a single task row
// in the task list. Used by TaskListView.
// Shows: title, subject, deadline, priority indicator, completion status, progress.

import SwiftUI

struct TaskRowView: View {
    let task: StudyTask
    var onToggleComplete: () -> Void

    private var priorityColor: Color {
        switch task.priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }

    private var deadlineText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: task.deadline, relativeTo: Date())
    }

    private var isOverdue: Bool {
        !task.isComplete && task.deadline < Date()
    }

    private var progress: Double {
        guard task.estimatedTime > 0 else { return 0 }
        return min(Double(task.completedTime) / Double(task.estimatedTime), 1.0)
    }

    private var estimatedDisplay: String {
        let hours = task.estimatedTime / 60
        let minutes = task.estimatedTime % 60
        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Completion toggle
            Button {
                onToggleComplete()
            } label: {
                Image(systemName: task.isComplete ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(task.isComplete ? .green : .secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .strikethrough(task.isComplete)
                    .foregroundStyle(task.isComplete ? .secondary : .primary)

                Text(task.subject)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    // Priority badge
                    Text(task.priority.rawValue.capitalized)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(priorityColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(priorityColor.opacity(0.12))
                        .clipShape(Capsule())

                    // Deadline
                    Label(deadlineText, systemImage: isOverdue ? "exclamationmark.circle" : "calendar")
                        .font(.caption2)
                        .foregroundStyle(isOverdue ? .red : .secondary)

                    Spacer()

                    // Estimated time
                    Text(estimatedDisplay)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                // Progress bar (only for active tasks with progress)
                if task.estimatedTime > 0 && !task.isComplete {
                    ProgressView(value: progress)
                        .tint(progress >= 1.0 ? .green : .accentColor)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
