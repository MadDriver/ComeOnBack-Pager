import Foundation
import OSLog

struct BeBack: Hashable, Identifiable, Codable {
    var id = UUID()
    var initials: String
    var time: String
    var forPosition: String?
    
    enum CodingKeys: String, CodingKey {
        case initials
        case time
        case forPosition
    }
}

extension BeBack: CustomStringConvertible {
    var description: String {
        if let forPosition = self.forPosition {
            return "\(initials)-\(time)-\(forPosition)"
        }
        return "\(initials)-\(time)"
    }
    
    
}
