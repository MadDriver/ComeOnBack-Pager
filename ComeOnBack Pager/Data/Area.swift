//
//  Area.swift
//  ComeOnBack Pager
//

import Foundation

struct Area: Identifiable {
    /// Identity is the area name (stable across refetches; also keeps the sign-in
    /// area picker's selection matching after a poll swaps in fresh instances).
    var id: String { name }
    var name: String
    var facility: String?
    /// Nullable elements preserved so `PagingView`'s grid can render empty slots; v3
    /// sends plain strings, which decode into `.some`.
    var positions: [String?]
    var controllers: [Controller]
}

extension Area: Decodable {
    enum CodingKeys: String, CodingKey {
        case name, facility, positions, controllers
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = (try? c.decode(String.self, forKey: .name)) ?? ""
        facility = try? c.decode(String.self, forKey: .facility)
        positions = (try? c.decode([String?].self, forKey: .positions)) ?? []
        controllers = (try? c.decode(LossyArray<Controller>.self, forKey: .controllers))?.elements ?? []
    }
}

extension Area: Hashable {
    static func == (lhs: Area, rhs: Area) -> Bool { lhs.name == rhs.name }
    func hash(into hasher: inout Hasher) { hasher.combine(name) }
}

extension Area: Comparable {
    static func < (lhs: Area, rhs: Area) -> Bool {
        return lhs.name < rhs.name
    }
}
