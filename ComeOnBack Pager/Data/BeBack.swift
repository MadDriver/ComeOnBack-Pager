import Foundation
import OSLog

struct BeBack: Hashable, Identifiable, Codable {
    var id = UUID()
    var time: Time
    var forPosition: String?
    var acknowledged: Bool
    
    enum CodingKeys: String, CodingKey {
        case time
        case forPosition
        case acknowledged
    }
}

extension BeBack: CustomStringConvertible {
    var description: String {
        if let forPosition = self.forPosition {
            return "\(time)-\(forPosition)"
        }
        return "\(time)"
    }
}
