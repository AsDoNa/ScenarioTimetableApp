// MARK: - Timetable Entry Detail View
// Owner: Josh
//
// Shows details for a timetable class entry.
// Includes a map view if coordinates are available.

import SwiftUI
import MapKit

struct TimetableEntryDetailView: View {
    let entry: TimetableEntry

    @Environment(\.dismiss) private var dismiss

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d 'at' HH:mm"
        return f
    }()

    private var durationMinutes: Int {
        Int(entry.endTime.timeIntervalSince(entry.startTime) / 60)
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

    private var sessionTypeString: String {
        switch entry.type {
        case .lecture: return "Lecture"
        case .tutorial: return "Tutorial"
        case .lab: return "Lab"
        case .problemBasedLearning: return "Problem-Based Learning"
        case .unknown(let s): return s.isEmpty ? "Class" : s
        }
    }

    private var hasValidCoordinates: Bool {
        entry.locationCoords.lat != 0 || entry.locationCoords.lon != 0
    }

    private var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: entry.locationCoords.lat, longitude: entry.locationCoords.lon)
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Module") {
                    LabeledContent("Name", value: entry.moduleName)
                    LabeledContent("Code", value: entry.moduleCode)
                    LabeledContent("Type", value: sessionTypeString)

                    if !entry.lecturerName.isEmpty {
                        LabeledContent("Lecturer", value: entry.lecturerName)
                    }
                }

                Section("Time") {
                    LabeledContent("Start") {
                        Text(Self.timeFormatter.string(from: entry.startTime))
                    }
                    LabeledContent("End") {
                        Text(Self.timeFormatter.string(from: entry.endTime))
                    }
                    LabeledContent("Duration", value: durationDisplay)
                }

                Section("Location") {
                    if !entry.location.isEmpty {
                        LabeledContent("Room", value: entry.location)
                    }

                    if hasValidCoordinates {
                        Map(initialPosition: .region(MKCoordinateRegion(
                            center: coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                        ))) {
                            Marker(entry.location.isEmpty ? entry.moduleName : entry.location, coordinate: coordinate)
                        }
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                }
            }
            .navigationTitle("Class Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
