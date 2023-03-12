//
//  Controller.swift
//  ComeOnBack
//
//  Created by Calvin Shultz on 3/10/23.
//

import Foundation

struct Controller: Identifiable {
    
    var id = UUID()
    var initials: String
    var positionAssigned: String?
    var beBackTime: Int
    var isPagedBack: Bool
    
}
