//
//  ComeOnBackApp.swift
//  ComeOnBack
//
//  Created by Calvin Shultz on 3/9/23.
//

import SwiftUI
import OSLog

@main
struct ComeOnBackPagerApp: App {
    var body: some Scene {
        WindowGroup {
            HomeScreen()
        }
    }
}

extension Logger {
    public static var subsystem = Bundle.main.bundleIdentifier!
}
