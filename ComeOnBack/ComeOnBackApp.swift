//
//  ComeOnBackApp.swift
//  ComeOnBack
//
//  Created by Calvin Shultz on 3/9/23.
//

import SwiftUI

@main
struct ComeOnBackApp: App {
    
    @StateObject var pagingVM = PagingViewModel()
    
    var body: some Scene {
        WindowGroup {
            Home()
                .environmentObject(pagingVM)
        }
    }
}
