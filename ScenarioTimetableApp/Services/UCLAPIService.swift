// MARK: - UCL API Service
// Owner: Asher
//
// Fetches the student's timetable from the UCL API.
// Documentation: https://uclapi.com
//
// Key responsibilities:
// - Authenticate with UCL API (OAuth token)
// - Fetch timetable for current term
// - Parse JSON response into [TimetableEntry]
// - Handle network errors gracefully

import Foundation
import AuthenticationServices
import UIKit

class UCLAPIService: NSObject, UCLAPIServiceProtocol {
    
    enum UCLAPIError: Error {
            case notAuthenticated
            case networkError
            case decodingError
    }
    
    private var token : String?
    
    private let clientID: String = Bundle.main.infoDictionary?["UCL_CLIENT_ID"] as? String ?? ""
    private let callbackURL: String = Bundle.main.infoDictionary?["UCL_CALLBACK_URL"] as? String ?? ""
    private let clientSecret: String = Bundle.main.infoDictionary?["UCL_CLIENT_SECRET"] as? String ?? ""

    
    func authenticate() async throws {
        var components = URLComponents(string: "https://uclapi.com/oauth/authorise")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "state", value: UUID().uuidString),
            URLQueryItem(name: "scope", value: "personal_timetable")
        ]
        let url = components.url!
        
        let callbackScheme = "timetableapp"
        
        let code = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            let session = ASWebAuthenticationSession(url: url, callbackURLScheme: callbackScheme) { callbackURL, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let callbackURL,
                      let code = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?
                    .queryItems?.first(where: { $0.name == "code" })?.value
                else {
                    continuation.resume(throwing: UCLAPIError.networkError)
                    return
                }
                continuation.resume(returning: code)
            }
            session.presentationContextProvider = self
            session.start()
        }
        self.token = try await exchangeCodeForToken(code)
    }
    
    private struct TokenResponse: Codable {
        let token: String
        let ok: Bool
    }

    private func exchangeCodeForToken(_ code: String) async throws -> String {
        var components = URLComponents(string: "https://uclapi.com/oauth/token")!
            components.queryItems = [
                URLQueryItem(name: "client_id", value: clientID),
                URLQueryItem(name: "client_secret", value: clientSecret),
                URLQueryItem(name: "code", value: code)
            ]
        
        let (data, _) = try await URLSession.shared.data(from: components.url!)
        
        let response = try JSONDecoder().decode(TokenResponse.self, from: data)
            return response.token
        
    }
    
    private struct TimetableResponse: Codable {
        let ok: Bool
        let timetable: TimetableWrapper
        
        struct TimetableWrapper: Codable {
            let date: [RawEvent]
            
            struct RawEvent: Codable {
                let start_time: String
                let end_time: String
                let session_type_str: String
                let location: Location
                let module: Module
                let contact: String
                
                struct Location: Codable {
                    let name: String
                    let coordinates: Coordinates
                    
                    struct Coordinates: Codable {
                        let lat: String
                        let lng: String
                    }
                }
                
                struct Module: Codable {
                    let module_id: String
                    let name: String
                }
            }
        }
    }

    
    
    func fetchTimetable(for date: Date = Date()) async throws -> [TimetableEntry] {
        guard let token else { throw UCLAPIError.notAuthenticated }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)
        
        var components = URLComponents(string: "https://uclapi.com/timetable/personal")!
        components.queryItems = [
            URLQueryItem(name: "client_secret", value: clientSecret),
            URLQueryItem(name: "date", value: dateString)
        ]
        
        let url = components.url!

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        let response = try JSONDecoder().decode(TimetableResponse.self, from: data)
        let rawEvents = response.timetable.date
        
        let isoFormatter = ISO8601DateFormatter()
        

        let entries = try rawEvents.map { raw in
            guard let startTime = isoFormatter.date(from: raw.start_time),
                  let endTime = isoFormatter.date(from: raw.end_time) else {
                throw UCLAPIError.decodingError
            }
            return TimetableEntry(
                moduleName: raw.module.name,
                moduleCode: raw.module.module_id,
                lecturerName: raw.contact,
                startTime: startTime,
                endTime: endTime,
                location: raw.location.name,
                locationCoords: Coordinates(lat: Double(raw.location.coordinates.lat) ?? 0.0, lon: Double(raw.location.coordinates.lng) ?? 0.0),
                type: .unknown(raw.session_type_str)
            )
        }

        return entries
    }
}

extension UCLAPIService: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.keyWindow ?? ASPresentationAnchor()
    }
}
