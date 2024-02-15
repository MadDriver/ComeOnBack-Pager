import Foundation

enum ControllerStatus: String, Codable {
    case AVAILABLE
    case PAGED_BACK
    case PAGED_BACK_ACKNOWLEDGED
    case ON_POSITION
    case OTHER_DUTIES
}

struct Controller: Hashable, Identifiable, Codable  {
    static var positionsList = [
        "Departure": ["DR1", "DR2", "DR3", "DR4",
                      "SR1", "SR2", "SR3", "SR4",
                      "FR1", "FR2", "FR3", "FR4",
                      "MO1", "MO2", "MO3", nil,
                      "FD/CD", "CI"],
        
        "Arrival": ["AR1", "AR2", "AR3", "AR4",
                    "FR1", "FR2", "FR3", "FR4",
                    "MO1", "MO2", "MO3", nil,
                    "GJT", "PUB","FD/CD", "CI"],
        
        "OS/TMU": ["DR1", "DR2", "DR3", "DR4",
                   "SR1", "SR2", "SR3", "SR4",
                   "AR1", "AR2", "AR3", "AR4",
                   "FR1", "FR2", "FR3", "FR4",
                   "MO1", "MO2", "MO3", nil,
                   "GJT", "PUB",
                   "FD/CD",  "CI"]
    ]
    
    var id = UUID()
    var initials: String
    var area: String
    var isDev: Bool
    var status: ControllerStatus
    var beBack: BeBack? = nil
    var registered: Bool?
    
    enum CodingKeys: String, CodingKey {
        case initials
        case area
        case isDev
        case status
        case beBack
        case registered
    }
    
    var positions: [String?] {
        return Controller.positionsList[self.area] ?? []
    }
    
    static func newControllerFrom(_ controller: Controller, withStatus status: ControllerStatus) -> Controller {
        var newController = controller
        newController.status = status
        if status == .AVAILABLE {
            newController.beBack = nil
        }
        return newController
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

extension Controller {
    static let mock_data = [
        Controller(initials: "XX", area: "Departure", isDev: false, status: .AVAILABLE, registered: true),
        Controller(initials: "YY", area: "Arrival", isDev: true, status: .ON_POSITION, registered: false),
        Controller(initials: "ZZ", area: "OS/TMU", isDev: false, status: .ON_POSITION, registered: false),
    ]
}
