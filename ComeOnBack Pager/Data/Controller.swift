import Foundation
import OSLog

/// v3 controller status. `PAGED_BACK_ACKNOWLEDGED` from v1 is gone — acknowledgement
/// is now the `beBack.acknowledged` boolean. `SIGNED_IN` remains in the contract but
/// the API signs controllers in as `AVAILABLE`, so it is effectively unused (kept for
/// forward-compat + the "newly signed in" derivation). Unknown wire values decode to
/// `.unknown` so a new server status never wedges the whole board decode.
enum ControllerStatus: String, Decodable {
    case AVAILABLE
    case PAGED_BACK
    case ON_POSITION
    case OTHER_DUTIES
    case NOT_SIGNED_IN
    case SIGNED_IN
    case unknown

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = ControllerStatus(rawValue: raw) ?? .unknown
    }
}

struct Controller: Identifiable {
    /// Identity is the controller's initials (stable across the 4s refetch, unlike a
    /// per-decode UUID) — keeps SwiftUI list identity and set membership sane.
    var id: String { initials }
    var initials: String
    var isDev: Bool = false
    var status: ControllerStatus
    var beBack: BeBack? = nil
    var atTime: Date?
    var signInTime: Date?
    var registered: Bool = false
    var areaString: String = ""
    /// v3-only display fields (may be absent on older payloads).
    var name: String? = nil
    var position: String? = nil
}

extension Controller: Decodable {
    enum CodingKeys: String, CodingKey {
        case initials
        case isDev
        case status
        case beBack
        case registered
        case atTime
        case signInTime
        case name
        case position
        case areaString = "area"
    }

    /// Lenient decode: `initials` is the only hard requirement; unknown status →
    /// `.unknown`; a missing/garbage be-back → nil (never throws — see `BeBack`);
    /// timestamps parse leniently to `Date?`. Extra wire keys (e.g. `facility`) are
    /// tolerated (unlisted keys are skipped).
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        initials = try c.decode(String.self, forKey: .initials)
        isDev = (try? c.decode(Bool.self, forKey: .isDev)) ?? false
        status = (try? c.decode(ControllerStatus.self, forKey: .status)) ?? .unknown
        beBack = try? c.decode(BeBack.self, forKey: .beBack)
        registered = (try? c.decode(Bool.self, forKey: .registered)) ?? false
        areaString = (try? c.decode(String.self, forKey: .areaString)) ?? ""
        name = try? c.decode(String.self, forKey: .name)
        position = try? c.decode(String.self, forKey: .position)
        atTime = ISO8601Time.date(from: try? c.decode(String.self, forKey: .atTime))
        signInTime = ISO8601Time.date(from: try? c.decode(String.self, forKey: .signInTime))
    }
}

// Identity + equality by initials (see `id`).
extension Controller: Hashable {
    static func == (lhs: Controller, rhs: Controller) -> Bool {
        lhs.initials == rhs.initials
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(initials)
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

/// Decodes a JSON array element-by-element, skipping (not failing on) any element
/// that can't decode — one malformed controller/area must never wipe the whole board.
struct LossyArray<Element: Decodable>: Decodable {
    let elements: [Element]

    private struct Failable: Decodable {
        let value: Element?
        init(from decoder: Decoder) throws {
            value = try? decoder.singleValueContainer().decode(Element.self)
        }
    }

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        var result: [Element] = []
        while !container.isAtEnd {
            if let value = try container.decode(Failable.self).value {
                result.append(value)
            }
        }
        self.elements = result
    }
}
