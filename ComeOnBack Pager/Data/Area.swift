//
//  File.swift
//  ComeOnBack Pager
//
//  Created by user on 1/21/24.
//

import Foundation

struct Area: Identifiable, Hashable, Equatable {
    var id = UUID()
    var name: String
}

extension Area: Comparable {
    static func < (lhs: Area, rhs: Area) -> Bool {
        return lhs.name < rhs.name
    }
}
