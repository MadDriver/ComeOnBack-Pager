import Foundation

class API {
    static let logger = Logger(subsystem: Logger.subsystem, category: "API")
    static let serverURL = "http://127.0.0.1:5000"
    
    enum endPoints: String {
        case beBack = "beback"
        
        func getURL() -> URL {
            return URL(string: serverURL + self.rawValue)!
        }
    }
    
    func submitBeBack(initials: String, time: String, forPosition: String?) async throws {
        var request = URLRequest(url: endPoints.beBack.getURL())
        request.httpMethod = "POST"
        let data = URLSession.shared.dataTask(with: request)
    }
    
}
