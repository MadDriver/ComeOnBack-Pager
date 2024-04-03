import Foundation
import OSLog

enum BeBackError: Error {
    case initializationError
}

struct BeBack: Identifiable, Hashable {
    private static let logger = Logger(subsystem: Logger.subsystem, category: "BeBack")
    var id = UUID()
    var asap: Bool
    var atTime: BasicTime?
    var forPosition: String?
    var acknowledged: Bool
    var date: Date?
    
    init(atTime: BasicTime, forPosition: String? = nil, acknowledged:Bool = false) {
        self.asap = false
        self.atTime = atTime
        self.forPosition = forPosition
        self.acknowledged = acknowledged
        self.date = Date().from(hours: atTime.hours, minutes: atTime.minutes)
    }
    
    init(timeString: String, forPosition: String? = nil, acknowledged:Bool = false) throws {
        self.forPosition = forPosition
        self.acknowledged = acknowledged
        
        if timeString == "ASAP" {
            self.asap = true
            self.atTime = nil
            self.date = nil
            return
        }
        
        guard let basicTime = try? BasicTime(timeString) else {
            throw BeBackError.initializationError
        }
        self.asap = false
        self.atTime = basicTime
        self.date = Date().from(hours: basicTime.hours, minutes: basicTime.minutes)
    }
    
    var stringValue: String {
        if self.asap {
            return "ASAP"
        }
        return self.atTime?.stringValue ?? "Undefined"
    }
}

extension BeBack: CustomStringConvertible {
    var description: String {
        let forPosition = self.forPosition != nil ? "for position (forPosition)" : ""
        let timeText = self.asap ? "ASAP" : "\(atTime?.stringValue ?? "undefined")"
        return "\(timeText)\(forPosition) - Ack? \(acknowledged)"
    }
}

extension BeBack: Comparable {
    static func < (lhs: BeBack, rhs: BeBack) -> Bool {
        if lhs.asap { return true }
        if rhs.asap { return false }
        guard let lhsTime = lhs.atTime,
              let rhsTime = rhs.atTime else {
            // This is bad. Should not happen.
            return false
        }
        return lhsTime < rhsTime
    }
}

extension BeBack: Codable {
    enum CodingKeys: String, CodingKey {
        case forPosition
        case acknowledged
        case timeString = "time"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        let position = try values.decodeIfPresent(String.self, forKey: .forPosition)
        let ack = try values.decode(Bool.self, forKey: .acknowledged)
        let timeString = try values.decode(String.self, forKey: .timeString)
        try self.init(timeString: timeString, forPosition: position, acknowledged: ack)
    
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(forPosition, forKey: .forPosition)
        try container.encode(acknowledged, forKey: .acknowledged)
        try container.encode(self.stringValue, forKey: .timeString)
    }
}

extension BeBack {
    // MARK: Storage
    static let SUITE_NAME = "group.co.amalgamated.ComeOnBackPager"
    func store() {
        guard let userDefaults = UserDefaults(suiteName: BeBack.SUITE_NAME) else {
            BeBack.logger.error("Could not load UserDefaults")
            return
        }
        BeBack.logger.debug("Storing beBack: (\(description))")
        userDefaults.setValue(stringValue, forKey: "beBackAt")
        userDefaults.setValue(forPosition ?? "", forKey: "forPosition")
        userDefaults.setValue(acknowledged, forKey: "acknowledged")
    }
    
    static func loadFromStorage() -> BeBack? {
        guard let userDefaults = UserDefaults(suiteName: BeBack.SUITE_NAME),
              let timeString = userDefaults.string(forKey: "beBackAt") else {
            BeBack.logger.debug("Could not load beBack from storage")
            return nil
        }
        BeBack.logger.info("Loading BeBack from storage")
        
        let forPositionStorage = userDefaults.string(forKey: "forPosition")
        
        return try? BeBack(timeString: timeString,
                      forPosition: forPositionStorage == "" ? nil : forPositionStorage,
                      acknowledged: userDefaults.bool(forKey: "acknowledged")
        )
    }
    
    static func clearStorage() {
        guard let userDefaults = UserDefaults(suiteName: BeBack.SUITE_NAME) else {
            BeBack.logger.error("Could not load UserDefaults")
            return
        }
        userDefaults.removeObject(forKey: "beBackAt")
        userDefaults.removeObject(forKey: "forPosition")
        userDefaults.removeObject(forKey: "acknowledged")
    }
}
