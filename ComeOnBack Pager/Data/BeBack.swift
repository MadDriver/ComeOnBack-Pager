import Foundation
import OSLog

struct BeBack: Hashable, Identifiable, Codable {
    var id = UUID()
    var initials: String
    var time: Time
    var forPosition: String?
    var acknowledged: Bool
    
    enum CodingKeys: String, CodingKey {
        case initials
        case time
        case forPosition
        case acknowledged
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
