import Foundation
import OSLog

enum APIError: Error {
    case invalidServerResponse
    case invalidParameters
}

class API {
    private let logger = Logger(subsystem: Logger.subsystem, category: "API")
//    static let serverURL = "http://127.0.0.1:5000/"
    static let serverURL = "http://d01.org/pager/"
    
    enum endPoint: String {
        case beBack = "beback"
        case controllerList = "controllers"
        case signIn = "signin"
        case signOut = "signout"
        case signedIn = "signedin"
        case moveOnPosition = "moveonposition"
        case moveOffPosition = "moveoffposition"
        
        func getURL() -> URL {
            return URL(string: serverURL + self.rawValue)!
        }
    }
    
    func buildGETRequest(forEndpoint endPoint: endPoint) -> URLRequest {
        return URLRequest(url: endPoint.getURL())
    }
    
    func buildPOSTRequest(forEndpoint endPoint: endPoint, json: [String: Any]) throws -> URLRequest  {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: json) else {
            logger.error("Error encoding JSON string \(json)")
            throw APIError.invalidParameters
        }
        var request = URLRequest(url: endPoint.getURL())
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }
    
    func submitBeBack(initials: String, time: Time, forPosition: String?) async throws -> BeBack{
        logger.info("submitBeBack(initials: \(initials) time: \(time) forPosition: \(forPosition ?? "nil")")
        
        var json: [String: Any] = ["initials": initials, "time": time.stringValue]
        if forPosition != nil {
            json["forPosition"] = forPosition
        }
        
        let request = try buildPOSTRequest(forEndpoint: .beBack, json: json)
        let (data, response) = try await URLSession.shared.data(for: request)
        
        let returnString = String(data: data, encoding: .utf8) ?? "could not decode return data"
        logger.debug("Got server response: \(returnString)")
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 else {
            logger.error("Invalid server response in submitBeBack()")
            throw APIError.invalidServerResponse
        }
        
        return BeBack(initials: initials, time: time, forPosition: forPosition, acknowledged: false)
    }
    
    func removeBeBack(initials: String) async throws {
        logger.info("Removing BeBack for \(initials)")
        let json = ["initials": initials]
        var request = try buildPOSTRequest(forEndpoint: .beBack, json: json)
        request.httpMethod = "DELETE"
        let (data, response) = try await URLSession.shared.data(for: request)
        let returnString = String(data: data, encoding: .utf8) ?? "could not decode return data"
        logger.debug("Got server response: \(returnString)")
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            logger.error("Invalid server response in removeBeBack(\(initials))")
            throw APIError.invalidServerResponse
        }
    }
    
    func signIn(initials: String) async throws {
        logger.info("Signing in \(initials)")
        let json = ["initials": initials]
        let request = try buildPOSTRequest(forEndpoint: .signIn, json: json)
        let (data, response) = try await URLSession.shared.data(for: request)
        let returnString = String(data: data, encoding: .utf8) ?? "could not decode return data"
        logger.debug("Got server response: \(returnString)")
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            logger.error("Invalid server response in signIn(\(initials))")
            throw APIError.invalidServerResponse
        }
    }
    
    func signOut(initials: String) async throws {
        logger.info("Signing out \(initials)")
        let json = ["initials": initials]
        let request = try buildPOSTRequest(forEndpoint: .signOut, json: json)
        let (data, response) = try await URLSession.shared.data(for: request)
        let returnString = String(data: data, encoding: .utf8) ?? "could not decode return data"
        logger.debug("Got server response: \(returnString)")
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            logger.error("Invalid server response in signOut\(initials)")
            throw APIError.invalidServerResponse
        }
    }
    
    func moveOnPosition(initials: String) async throws {
        logger.info("Moving on position \(initials)")
        let json = ["initials": initials]
        let request = try buildPOSTRequest(forEndpoint: .moveOnPosition, json: json)
        let (data, response) = try await URLSession.shared.data(for: request)
        let returnString = String(data: data, encoding: .utf8) ?? "could not decode return data"
        logger.debug("Got server response: \(returnString)")
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            logger.error("Invalid server response in moveOnPosition(\(initials)")
            throw APIError.invalidServerResponse
        }
    }
    
    func moveOffPosition(initials: String) async throws {
        logger.info("Moving off position \(initials)")
        let json = ["initials": initials]
        let request = try buildPOSTRequest(forEndpoint: .moveOffPosition, json: json)
        let (data, response) = try await URLSession.shared.data(for: request)
        let returnString = String(data: data, encoding: .utf8) ?? "could not decode return data"
        logger.debug("Got server response: \(returnString)")
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            logger.error("Invalid server response in moveOffPosition(\(initials)")
            throw APIError.invalidServerResponse
        }
    }
    
    func getControllerList() async throws -> [Controller] {
        logger.info("Getting controller list")
        let request = buildGETRequest(forEndpoint: .controllerList)
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            logger.error("Invalid server response in getControllerList")
            throw APIError.invalidServerResponse
        }
        
        let controllers = try JSONDecoder().decode([Controller].self, from: data)
        logger.info("Got \(controllers.count) controllers")
        return controllers
    }
    
    func getSignedInControllers() async throws -> [Controller] {
        logger.info("Getting signed in controllers")
        let request = buildGETRequest(forEndpoint: .signedIn)
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            logger.error("Invalid server response in getSignedInControllerList")
            throw APIError.invalidServerResponse
        }
        
        let siControllers = try JSONDecoder().decode([Controller].self, from: data)
        logger.info("Got \(siControllers.count) signed in controllers")
        return siControllers
    }
}
