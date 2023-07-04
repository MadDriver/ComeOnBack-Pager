//
//  Controller.swift
//  ComeOnBack
//
//  Created by Calvin Shultz on 3/10/23.
//

import Foundation

enum ControllerStatus: String, Codable {
    case AVAILABLE
    case PAGED_BACK
    case ON_POSITION
    case OTHER_DUTIES
}

struct Controller: Hashable, Identifiable, Codable  {
    var id = UUID()
    var initials: String
    var area: String
    var isDev: Bool
    var status: ControllerStatus// = .AVAILABLE
    var beBack: BeBack? = nil
    
    var isPagedBack: Bool {
        return beBack != nil
    }
    
    enum CodingKeys: String, CodingKey {
        case initials
        case area
        case isDev
        case status
        case beBack
    }
}
