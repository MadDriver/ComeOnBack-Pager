import Foundation

enum TimeError: Error {
    case InvalidString(error: String)
}

public struct BasicTime: Hashable {
    public let hours: Int // 00-23
    public let minutes: Int // 00-59
    
    public var stringValue: String {
        let hoursString = String(format: "%02d", hours)
        let minutesString = String(format: "%02d", minutes)
        return "\(hoursString):\(minutesString)"
    }
    
    public init(hours: Int, minutes: Int) {
        self.hours = hours
        self.minutes = minutes
    }
    
    public init(_ string: String) throws {
        let stringComponents = string.split(separator: ":")
        
        if (stringComponents.count != 2) {
            throw TimeError.InvalidString(error: "Invalid number of colons in string \(string).")
        }
        
        guard let hours = Int(stringComponents[0]),
              let minutes = Int(stringComponents[1]) else {
            throw TimeError.InvalidString(error: "Invalid time string \(string).")
        }
        
        if (hours < 0 || hours > 23 ||
            minutes < 0 || minutes > 59) {
            throw TimeError.InvalidString(error: "Invalid values in time string \(string)")
        }
        
        self.hours = hours
        self.minutes = minutes
    }
    
    public init?(fromDate date: Date) {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        guard let hour = components.hour,
              let minute = components.minute else {
            return nil
        }
        self.hours = hour
        self.minutes = minute
    }
}

extension BasicTime: CustomStringConvertible {
    public var description: String {
        return stringValue
    }
}

extension BasicTime: Comparable {
    public static func < (lhs: BasicTime, rhs: BasicTime) -> Bool {
        if lhs.hours == rhs.hours {
            return lhs.minutes < rhs.minutes
        }
        return lhs.hours < rhs.hours
    }
}

extension BasicTime: Codable {
    enum CodingKeys: String, CodingKey {
        case time
    }
    
    public init(from decoder: Decoder) throws {
        let timeString = try decoder.singleValueContainer().decode(String.self)
        try self.init(timeString)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(stringValue)
    }
}
