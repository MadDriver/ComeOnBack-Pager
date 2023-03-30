//
//  Bundle+Ext.swift
//  ComeOnBack
//
//  Created by Calvin Shultz on 3/25/23.
//

import Foundation

extension Bundle {
    func decode<T: Decodable>(file: String) -> T {
        guard let url = self.url(forResource: file, withExtension: nil) else {
            fatalError("Shit fucked up with url")
        }
        
        guard let data = try? Data(contentsOf: url) else {
            fatalError("Shit fucked up with data")
        }
        
        let decoder = JSONDecoder()
        
        guard let loadedData = try? decoder.decode(T.self, from: data) else {
            fatalError("Shit fucked up with loaded data")
        }
        
        return loadedData
        
    }
}
