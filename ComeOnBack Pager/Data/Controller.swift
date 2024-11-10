import Foundation
import OSLog

enum ControllerStatus: String, Codable {
    case AVAILABLE
    case PAGED_BACK
    case PAGED_BACK_ACKNOWLEDGED
    case ON_POSITION
    case OTHER_DUTIES
    case SIGNED_IN
    case NOT_SIGNED_IN
}

struct Controller: Hashable, Identifiable  {
//    private let logger = Logger(subsystem: Logger.subsystem, category: "Controller")
    var id = UUID()
    var initials: String
    var isDev: Bool
    var status: ControllerStatus
    var beBack: BeBack? = nil
    var atTime: Date?
    var signInTime: Date?
    var registered: Bool
    var areaString: String
}

extension Controller: Codable {
    enum CodingKeys: String, CodingKey {
        case initials
        case isDev
        case status
        case beBack
        case registered
        case atTime
        case signInTime
        case areaString = "area"
    }
}

extension Controller: CustomStringConvertible {
    var description: String {
        if let beBack = self.beBack {
            return "\(initials)-\(status)-\(beBack)"
        }
        return "\(initials)-\(status)"
    }
    
}

extension Controller: Comparable {
    static func < (lhs: Controller, rhs: Controller) -> Bool {
        guard let lhsDate = lhs.atTime, let rhsDate = rhs.atTime else {
            let logger = Logger(subsystem: Logger.subsystem, category: "Controller:Comparable")
            logger.error("Trying to sort controllers without atTimes defined. \(lhs)-\(rhs)")
            return false
        }
        return lhsDate < rhsDate
    }
}

extension Controller {
    static let mock_data = [
        Controller(initials: "XX", isDev: false, status: .AVAILABLE, atTime: Date(), signInTime: Date(), registered: true, areaString: ""),
        Controller(initials: "YY", isDev: true, status: .ON_POSITION, atTime: Date(), signInTime: Date(), registered: false, areaString: ""),
        Controller(initials: "ZZ", isDev: false, status: .ON_POSITION, atTime: Date(), signInTime: Date(), registered: false, areaString: ""),
    ]
}
