//
//  ControllerParser.swift
//  ComeOnBack
//
//  Created by Calvin Shultz on 3/27/23.
//

import Foundation
import SwiftSoup

class ControllerParser {
    
    func getControllers() -> String {
        
        let controllerList = "controllerList"
        
        guard let htmlString = Bundle.main.path(forResource: controllerList, ofType: "html") else {
            return "jlfjsdlksfld"
        }
        return htmlString
    }
    
}
