import Foundation
import OSLog

enum APIError: Error {
    case invalidServerResponse
    case invalidParameters
    case facilityNameNotSet
    case invalidFacilityName
}

enum HTTPMethod: String {
    case POST
    case GET
    case DELETE
}

enum APIServer: String {
    case local = "http://127.0.0.1:5000/"
    case production = "https://atcpager.com/"
}

class API {
    private let logger = Logger(subsystem: Logger.subsystem, category: "API")
    static let server = APIServer.production
    static let clientAPIVersion = 0.1
    static var facilityName: String? = nil
    
    enum endPoint: String {
        case registerPager = "registerpager"
        case beBack = "beback"
        case controllerList = "controllers"
        case signIn = "signin"
        case signOut = "signout"
        case signedIn = "signedin"
        case moveOnPosition = "moveonposition"
        case moveOffPosition = "moveoffposition"
        
        func getURL() throws -> URL {
            guard let facilityName = facilityName else { throw APIError.facilityNameNotSet }
            return URL(string: "\(server.rawValue)/\(facilityName)/\(self.rawValue)")!
        }
    }
    
    func buildRequest(forEndpoint endPoint: endPoint, method: HTTPMethod, queryItems: [URLQueryItem] = [], json: [String: Any]? = nil) throws -> URLRequest  {
        var request = URLRequest(url: try endPoint.getURL())
        request.httpMethod = method.rawValue
        request.url?.append(queryItems: queryItems)
        
        if let json = json {
            guard let jsonData = try? JSONSerialization.data(withJSONObject: json) else {
                logger.error("Error encoding JSON string \(json)")
                throw APIError.invalidParameters
            }
            request.httpBody = jsonData
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
        }

        request.setValue("\(API.clientAPIVersion)", forHTTPHeaderField: "API-Version")
        return request
    }
    
    func submitBeBack(initials: String, time: Time, forPosition: String?) async throws -> BeBack{
        logger.info("submitBeBack(initials: \(initials) time: \(time) forPosition: \(forPosition ?? "nil")")
        
        var json: [String: Any] = ["initials": initials, "time": time.stringValue]
        if forPosition != nil {
            json["forPosition"] = forPosition
        }
        
        let request = try buildRequest(forEndpoint: .beBack, method: .POST, json: json)
        let (data, response) = try await URLSession.shared.data(for: request)
        
        let returnString = String(data: data, encoding: .utf8) ?? "could not decode return data"
        logger.debug("Got server response: \(returnString)")
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 else {
            logger.error("Invalid server response in submitBeBack()")
            throw APIError.invalidServerResponse
        }
        
        return BeBack(initials: initials, time: time, forPosition: forPosition, acknowledged: false)
    }
    
    func registerPager() async throws {
        logger.info("registerPager with facilityName \(API.facilityName ?? "nil")")
        
        let request = try buildRequest(forEndpoint: .registerPager, method: .POST)
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (httpResponse.statusCode != 200 || httpResponse.statusCode != 404) else {
            logger.error("Invalid server response in submitBeBack()")
            throw APIError.invalidServerResponse
        }
        
        if httpResponse.statusCode == 404 {
            throw APIError.invalidFacilityName
        }
    }
    
    func removeBeBack(initials: String) async throws {
        logger.info("Removing BeBack for \(initials)")
        let json = ["initials": initials]
        var request = try buildRequest(forEndpoint: .beBack, method: .POST, json: json)
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
        let request = try buildRequest(forEndpoint: .signIn, method: .POST, json: json)
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
        let request = try buildRequest(forEndpoint: .signOut, method: .POST, json: json)
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
        let request = try buildRequest(forEndpoint: .moveOnPosition, method: .POST, json: json)
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
        let request = try buildRequest(forEndpoint: .moveOffPosition, method: .POST, json: json)
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
        let request = try buildRequest(forEndpoint: .controllerList, method: .GET)
        let (data, response) = try await URLSession.shared.data(for: request)
        logger.info("\(String(data: data, encoding: .utf8) ?? "could not decode return data"))")
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
        let request = try buildRequest(forEndpoint: .signedIn, method: .GET)
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
