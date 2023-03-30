//
//  Controller.swift
//  ComeOnBack
//
//  Created by Calvin Shultz on 3/10/23.
//

import Foundation

struct Controller: Hashable, Identifiable, Codable  {
    
    let id = UUID()
    var firstName: String
    var lastName: String
    let initials: String
    var positionAssigned: String?
    var beBackTime: String?
    var phoneNumber: Int?
    var isPagedBack: Bool
    
//    static let allControllers: [Controller] = Bundle.main.decode(file: "controller.json")
//    static let sampleController: Controller = allControllers[0]
    
}

