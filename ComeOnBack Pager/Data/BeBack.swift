import Foundation

struct BeBack: Identifiable, Hashable {
    var id = UUID()
    /// The parsed clock time, set ONLY when the server sent `HH:MM`. Nil for a
    /// sentinel (`ASAP`, `SOON`, or anything unrecognized).
    var atTime: BasicTime?
    /// The raw server text for a non-`HH:MM` time (`ASAP`/`SOON`/unknown), kept opaque
    /// and rendered as-is. Nil when `atTime` is set.
    var sentinel: String?
    var forPosition: String?
    var acknowledged: Bool
    /// Today's date at `atTime` (HH:MM only); nil for a sentinel.
    var date: Date?
    /// Training-team context, stamped on a paged-back team member's be-back
    /// (contract §6). Decoded for R1; the board renders it in R2.
    var training: Bool?
    var role: String?
    var partnerInitials: String?

    /// Non-throwing sentinel rule: `HH:MM` parses to a clock time; `ASAP`, `SOON`, and
    /// any unrecognized value are kept opaque and rendered verbatim — the board never
    /// crashes on an unfamiliar time.
    init(
        timeString: String,
        forPosition: String? = nil,
        acknowledged: Bool = false,
        training: Bool? = nil,
        role: String? = nil,
        partnerInitials: String? = nil
    ) {
        self.forPosition = forPosition
        self.acknowledged = acknowledged
        self.training = training
        self.role = role
        self.partnerInitials = partnerInitials

        if let basicTime = try? BasicTime(timeString) {
            self.atTime = basicTime
            self.sentinel = nil
            self.date = Date().from(hours: basicTime.hours, minutes: basicTime.minutes)
        } else {
            self.atTime = nil
            self.sentinel = timeString
            self.date = nil
        }
    }

    /// The value to page with / render: the clock string for a timed be-back, else the
    /// opaque sentinel text.
    var stringValue: String {
        atTime?.stringValue ?? sentinel ?? "Undefined"
    }

    /// True only for the ASAP sentinel (kept for `description`).
    var asap: Bool { sentinel == "ASAP" }
}

extension BeBack: CustomStringConvertible {
    var description: String {
        let position = forPosition.map { " for \($0)" } ?? ""
        return "\(stringValue)\(position) - Ack? \(acknowledged)"
    }
}

extension BeBack: Comparable {
    /// Sentinels (ASAP/SOON/unknown, no clock time) sort ahead of timed be-backs —
    /// "come back now/soon" first — then timed ones by clock.
    static func < (lhs: BeBack, rhs: BeBack) -> Bool {
        switch (lhs.atTime, rhs.atTime) {
        case let (l?, r?): return l < r
        case (nil, _?): return true
        case (_?, nil): return false
        case (nil, nil): return false
        }
    }
}

extension BeBack: Decodable {
    enum CodingKeys: String, CodingKey {
        case forPosition
        case acknowledged
        case training
        case role
        case partnerInitials
        case timeString = "time"
    }

    /// Never throws on value shape (uses the non-throwing `init(timeString:)`); only a
    /// non-object body would throw at `container(keyedBy:)`, which the caller's `try?`
    /// turns into a nil be-back.
    init(from decoder: Decoder) throws {
        let v = try decoder.container(keyedBy: CodingKeys.self)
        let timeString = (try? v.decode(String.self, forKey: .timeString)) ?? "Undefined"
        let position = try? v.decode(String.self, forKey: .forPosition)
        let ack = (try? v.decode(Bool.self, forKey: .acknowledged)) ?? false
        let training = try? v.decode(Bool.self, forKey: .training)
        let role = try? v.decode(String.self, forKey: .role)
        let partner = try? v.decode(String.self, forKey: .partnerInitials)
        self.init(
            timeString: timeString,
            forPosition: position,
            acknowledged: ack,
            training: training,
            role: role,
            partnerInitials: partner
        )
    }
}
