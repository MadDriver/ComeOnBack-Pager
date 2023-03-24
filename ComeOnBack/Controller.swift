//
//  Controller.swift
//  ComeOnBack
//
//  Created by Calvin Shultz on 3/10/23.
//

import Foundation

struct Controller: Hashable, Identifiable  {
    
    var id = UUID()
    var initials: String
    var positionAssigned: String?
    var beBackTime: String?
    var isPagedBack: Bool
    
}
