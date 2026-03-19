// MARK: - Calendar Service
// Owner: Asher
//
// Integrates with the iOS Calendar (EventKit) to:
// - Read personal calendar events (so the algorithm avoids double-booking)
// - Optionally write study sessions back to the calendar
//
// Requires user permission via EventKit.

import Foundation
import EventKit
import CoreLocation

class CalendarService:CalendarServiceProtocol {
    private let eventStore = EKEventStore()
    private var hasCalendarAccess: Bool = false
    private var studyCalendar: EKCalendar?
    private let studyCalendarName = "Study Sessions"
    private let studyCalendarKey = "studyCalendarIdentifier"
    
    enum CalendarError: Error {
        case accessDenied
    }
    
    func requestCalendarAccess() async throws {
        hasCalendarAccess = try await eventStore.requestFullAccessToEvents()
    }
    
    func fetchEvents(for dateRange: DateInterval) async throws -> [CalendarEvent] {
        guard hasCalendarAccess else { throw CalendarError.accessDenied }
        let calendars = eventStore.calendars(for: .event).filter { $0 !== studyCalendar }
        let predicate = eventStore.predicateForEvents(withStart: dateRange.start, end: dateRange.end, calendars: calendars)
        let ekEvents = eventStore.events(matching: predicate)
        let calendarEvents = ekEvents.map { ekEvent in
            CalendarEvent(
                title: ekEvent.title,
                startTime: ekEvent.startDate,
                endTime: ekEvent.endDate,
                location: ekEvent.structuredLocation?.title,
                locationCoords: ekEvent.structuredLocation?.geoLocation.map { location in Coordinates(
                    lat: location.coordinate.latitude, lon: location.coordinate.longitude
            )})
        }
        return calendarEvents
    }
    
    private func getOrCreateStudyCalendar() throws -> EKCalendar {
        if let existing = studyCalendar { return existing }
        if let id = UserDefaults.standard.string(forKey: studyCalendarKey),
           let existing = eventStore.calendar(withIdentifier: id) {
            studyCalendar = existing
            return existing
        }
        let calendar = EKCalendar(for: .event, eventStore: eventStore)
        calendar.title = studyCalendarName
        calendar.source = eventStore.defaultCalendarForNewEvents?.source
        try eventStore.saveCalendar(calendar, commit: true)
        UserDefaults.standard.set(calendar.calendarIdentifier, forKey: studyCalendarKey)
        studyCalendar = calendar
        return calendar
    }

    
    func exportStudySessions(_ sessions: [StudySession]) async throws {
        guard hasCalendarAccess else { throw CalendarError.accessDenied }
        let calendar = try getOrCreateStudyCalendar()
        for session in sessions {
            let event = EKEvent(eventStore: eventStore)
            event.title = session.taskTitle
            event.startDate = session.startTime
            event.endDate = session.endTime
            event.calendar = calendar
            try eventStore.save(event, span: .thisEvent)
        }
    }
    
}
