// MARK: - Scheduling Algorithm
// Owner: Salavat
//
// The core scheduling engine. This is a PURE FUNCTION layer:
// - Takes inputs: timetable entries, study tasks, user preferences
// - Returns output: an array of StudySessions placed into free time
// - No side effects, no network calls, no UI — just logic.

import Foundation

class SchedulingAlgorithm {

    // constants
    private static let MIN_SESSION_MINUTES = 15

    private struct DayState {
        let date: Date
        var freeSlots: [TimeSlot]
        var scheduledMinutes: Int

        // Checks availability study slot for required time period
        func hasCapacity(minimumMinutes: Int) -> Bool {
            freeSlots.contains { slot in
                Int(slot.endTime.timeIntervalSince(slot.startTime) / 60) >= minimumMinutes
            }
        }
    }

    // Main entry point:
    static func generateSchedule(
        timetable: [TimetableEntry], 
        calendarEvents: [CalendarEvent],
        tasks: [StudyTask], 
        preferences: UserPreferences,
        weekStartDate: Date
        ) -> [StudySession] {
            let activeDays = buildActiveDays(weekStart: weekStartDate, daysOff: preferences.preferredDaysOff)
            guard !activeDays.isEmpty else { return [] }

            var queue = buildDayQueue(
                activeDays: activeDays, 
                timetable: timetable, 
                calendarEvents: calendarEvents, 
                preferences: preferences
            )

            let sortedTasks = filterAndSortTasks(tasks)
            guard !sortedTasks.isEmpty else { return [] }

            var allSessions: [StudySession] = []

            for task in sortedTasks {
                var remaining = task.estimatedTime - task.completedTime

                while remaining > 0 {
                    guard let idx = pickLeastLoadedIndex(in: queue, minimumMinutes: MIN_SESSION_MINUTES)
                    else { break }

                    guard let session = placeNextSession(
                        task: task,
                        maxSessionMinutes: min(remaining, preferences.maxSessionLength),
                        on: idx,
                        in: &queue,
                        minBreak: preferences.minBreakBetweenSessions
                        )
                    else { break }

                    remaining -= Int(session.endTime.timeIntervalSince(session.startTime) / 60)
                    allSessions.append(session)
                }
            }

            return allSessions.sorted { $0.startTime < $1.startTime }
        }

    private static func placeNextSession(
        task: StudyTask,
        maxSessionMinutes: Int,
        on dayIndex: Int,
        in queue: inout [DayState],
        minBreak: Int
    ) -> StudySession? {
        // Find the first free slot that is large enough to fit the session
        guard let slotIndex = queue[dayIndex].freeSlots.firstIndex(where: { slot in
            Int(slot.endTime.timeIntervalSince(slot.startTime) / 60) >= MIN_SESSION_MINUTES
        }) else { return nil }

        // Get the slot and compute the session length
        let slot = queue[dayIndex].freeSlots[slotIndex]
        let slotMinutes = Int(slot.endTime.timeIntervalSince(slot.startTime) / 60)
        let sessionLen  = min(maxSessionMinutes, slotMinutes)

        let sessionStart = slot.startTime
        let sessionEnd   = sessionStart.addingTimeInterval(TimeInterval(sessionLen * 60))

        let session = StudySession(
            taskID:     task.id,
            startTime:  sessionStart,
            endTime:    sessionEnd,
            taskTitle:  task.title,
            moduleCode: task.moduleCode
        )

        let newSlotStart     = sessionEnd.addingTimeInterval(TimeInterval(minBreak * 60))
        let remainingMinutes = Int(slot.endTime.timeIntervalSince(newSlotStart) / 60)

        if remainingMinutes >= MIN_SESSION_MINUTES {
            queue[dayIndex].freeSlots[slotIndex] = TimeSlot(startTime: newSlotStart, endTime: slot.endTime)
        } else {
            queue[dayIndex].freeSlots.remove(at: slotIndex)
        }

        queue[dayIndex].scheduledMinutes += sessionLen
        return session
    }
    
    private static func pickLeastLoadedIndex(
        in queue: [DayState],
        minimumMinutes: Int
    ) -> Int? {
        queue
            .enumerated()
            .filter { $0.element.hasCapacity(minimumMinutes: minimumMinutes) }
            .min { $0.element.scheduledMinutes < $1.element.scheduledMinutes }?
            .offset
    }

    private static func buildDayQueue(
        activeDays: [Date],
        timetable: [TimetableEntry],
        calendarEvents: [CalendarEvent],
        preferences: UserPreferences,
        calendar: Calendar = .current
    ) -> [DayState] {
        activeDays.compactMap { day in
            let timetableBlocked: [(start: Date, end: Date)] = timetable
                .filter { calendar.isDate($0.startTime, inSameDayAs: day) }
                .map { ($0.startTime, $0.endTime) }

            let calendarBlocked: [(start: Date, end: Date)] = calendarEvents
                .filter { calendar.isDate($0.startTime, inSameDayAs: day) }
                .map { ($0.startTime, $0.endTime) }

            let allBlocked = mergeOverlapping(timetableBlocked + calendarBlocked)

            guard let window = applyWorkingWindow(to: day, prefs: preferences, calendar: calendar)
            else { return nil }

            let slots = computeFreeSlots(window: window, blocked: allBlocked)

            return DayState(date: day, freeSlots: slots, scheduledMinutes: 0)
        }
    }

    
    // Helper function to build the active days array:
    static func buildActiveDays(
        weekStart: Date,
        daysOff: [UserPreferences.Weekday],
        calendar: Calendar = .current
    ) -> [Date] {
        (0..<7).compactMap { offset -> Date? in
            guard let day = calendar.date(byAdding: .day, value: offset, to: weekStart)
            else { return nil }
            let weekday = weekdayEnum(from: day, calendar: calendar)
            return daysOff.contains(weekday) ? nil : day
        }
    }

    // Helper function to get the weekday enum from a date:
    private static func weekdayEnum(
        from date: Date,
        calendar: Calendar
    ) -> UserPreferences.Weekday {
        switch calendar.component(.weekday, from: date) {
            case 1: return .sunday
            case 2: return .monday
            case 3: return .tuesday
            case 4: return .wednesday
            case 5: return .thursday
            case 6: return .friday
            default: return .saturday
        }
    }

    // Helper function to merge overlapping intervals:
    static func mergeOverlapping(
        _ intervals: [(start: Date, end: Date)]
    ) -> [(start: Date, end: Date)] {
        guard !intervals.isEmpty else { return [] }

        let sorted = intervals.sorted { $0.start < $1.start }
        var merged: [(start: Date, end: Date)] = [sorted[0]]

        for interval in sorted.dropFirst() {
            let last = merged[merged.count - 1]
            if interval.start <= last.end {
                merged[merged.count - 1] = (start: last.start, end: max(last.end, interval.end))
            } else {
                merged.append(interval)
            }
        }
        return merged
    }

    static func applyWorkingWindow(
        to day: Date,
        prefs: UserPreferences,
        calendar: Calendar = .current
    ) -> (windowStart: Date, windowEnd: Date)? {

        let startComponents = calendar.dateComponents([.hour, .minute], from: prefs.preferredStudyStartTime)
        let endComponents   = calendar.dateComponents([.hour, .minute], from: prefs.preferredStudyEndTime)

        var dayComponents = calendar.dateComponents([.year, .month, .day], from: day)

        dayComponents.hour   = startComponents.hour
        dayComponents.minute = startComponents.minute
        dayComponents.second = 0
        guard let windowStart = calendar.date(from: dayComponents) else { return nil }

        dayComponents.hour   = endComponents.hour
        dayComponents.minute = endComponents.minute
        guard let windowEnd = calendar.date(from: dayComponents) else { return nil }

        guard windowStart < windowEnd else { return nil }

        return (windowStart, windowEnd)
    }


    // Helper function to compute the free slots:
    static func computeFreeSlots(
        window: (windowStart: Date, windowEnd: Date),
        blocked: [(start: Date, end: Date)]  // intervals that are already merged and sorted
    ) -> [TimeSlot] {

        var slots: [TimeSlot] = []
        var pointer = window.windowStart

        for block in blocked {
            let blockStart = max(block.start, window.windowStart)
            let blockEnd   = min(block.end,   window.windowEnd)

            guard blockStart < blockEnd else { continue } // block is fully outside window

            if pointer < blockStart {
                // Gap between pointer and this block
                let gapMinutes = Int(blockStart.timeIntervalSince(pointer) / 60)
                if gapMinutes >= MIN_SESSION_MINUTES {
                    slots.append(TimeSlot(startTime: pointer, endTime: blockStart))
                }
            }
            // Advance pointer past this block
            pointer = max(pointer, blockEnd)
        }

        // Trailing gap between last block and end of window
        if pointer < window.windowEnd {
            let gapMinutes = Int(window.windowEnd.timeIntervalSince(pointer) / 60)
            if gapMinutes >= MIN_SESSION_MINUTES {
                slots.append(TimeSlot(startTime: pointer, endTime: window.windowEnd))
            }
        }

        return slots
    }

    static func filterAndSortTasks(_ tasks: [StudyTask]) -> [StudyTask] {
        tasks
            .filter { !$0.isComplete && ($0.estimatedTime - $0.completedTime) > 0 }
            .sorted { a, b in
                let rankA = priorityRank(a.priority)
                let rankB = priorityRank(b.priority)
                if rankA != rankB { return rankA < rankB }
                return a.deadline < b.deadline
            }
    }

    private static func priorityRank(_ priority: StudyTask.Priority) -> Int {
        switch priority {
        case .high:   return 0
        case .medium: return 1
        case .low:    return 2
        }
    }
}
