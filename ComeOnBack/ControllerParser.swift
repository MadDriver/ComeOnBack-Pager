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
        
//        do {
//            let doc: Document = try SwiftSoup.parse(htmlString)
//            return try doc.text()
//
//
//        } catch Exception.Error(_, let message) {
//            print(message)
//        } catch {
//            print("error")
//        }
//        return "Shit is fucked up"
    }
    
}
