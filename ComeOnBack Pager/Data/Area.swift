//
//  File.swift
//  ComeOnBack Pager
//
//  Created by user on 1/21/24.
//

import Foundation

struct Area: Identifiable, Hashable {
    var id = UUID()
    var name: String
    var positions: [String?]
}

extension Area: Codable {
    enum CodingKeys: String, CodingKey {
        case name
        case positions
    }
}

extension Area: Comparable {
    static func < (lhs: Area, rhs: Area) -> Bool {
        return lhs.name < rhs.name
    }
}
