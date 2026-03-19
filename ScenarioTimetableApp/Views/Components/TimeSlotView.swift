// MARK: - Time Slot View (Component)
// Owner: Josh
//
// A reusable component that renders a single event block
// in the timetable timeline. Used by TimetableView.
// Visually distinguishes between:
// - Timetable classes (blue)
// - Study sessions (green)
// - Personal calendar events (orange)

import SwiftUI

/// A unified wrapper for any event displayed on the timetable timeline.
/// Used by both TimeSlotView and TimetableView to handle all event types uniformly.
enum ScheduleItem: Identifiable {
    case timetableEntry(TimetableEntry)
    case studySession(StudySession)
    case calendarEvent(CalendarEvent)

    var id: UUID {
        switch self {
        case .timetableEntry(let e): return e.id
        case .studySession(let s): return s.id
        case .calendarEvent(let e): return e.id
        }
    }

    var startTime: Date {
        switch self {
        case .timetableEntry(let e): return e.startTime
        case .studySession(let s): return s.startTime
        case .calendarEvent(let e): return e.startTime
        }
    }

    var endTime: Date {
        switch self {
        case .timetableEntry(let e): return e.endTime
        case .studySession(let s): return s.endTime
        case .calendarEvent(let e): return e.endTime
        }
    }

    var title: String {
        switch self {
        case .timetableEntry(let e): return e.moduleName
        case .studySession(let s): return s.taskTitle
        case .calendarEvent(let e): return e.title
        }
    }

    var subtitle: String? {
        switch self {
        case .timetableEntry(let e): return e.location
        case .studySession(let s): return s.moduleCode
        case .calendarEvent(let e): return e.location
        }
    }

    var category: String {
        switch self {
        case .timetableEntry(let e):
            switch e.type {
            case .lecture: return "Lecture"
            case .tutorial: return "Tutorial"
            case .lab: return "Lab"
            case .problemBasedLearning: return "PBL"
            case .unknown(let s): return s.isEmpty ? "Class" : s
            }
        case .studySession: return "Study"
        case .calendarEvent: return "Personal"
        }
    }

    var color: Color {
        switch self {
        case .timetableEntry: return .blue
        case .studySession: return .green
        case .calendarEvent: return .orange
        }
    }
}

struct TimeSlotView: View {
    let item: ScheduleItem

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    private var durationMinutes: Int {
        Int(item.endTime.timeIntervalSince(item.startTime) / 60)
    }

    var body: some View {
        HStack(spacing: 0) {
            // Colour bar on the left
            RoundedRectangle(cornerRadius: 2)
                .fill(item.color)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)

                    Spacer()

                    Text(item.category)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(item.color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(item.color.opacity(0.15))
                        .clipShape(Capsule())
                }

                HStack(spacing: 12) {
                    Label(
                        "\(Self.timeFormatter.string(from: item.startTime)) – \(Self.timeFormatter.string(from: item.endTime))",
                        systemImage: "clock"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    Text("\(durationMinutes) min")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                if let subtitle = item.subtitle, !subtitle.isEmpty {
                    Label(subtitle, systemImage: "mappin")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(.leading, 10)
            .padding(.vertical, 8)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(item.color.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
