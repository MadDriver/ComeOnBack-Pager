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
    private let logger = Logger(subsystem: Logger.subsystem, category: "ComeOnBackPagerApp")
    @AppStorage("facilityID") var facilityID: String?

    init() {
        API.facilityID = facilityID
    }
    
    var body: some Scene {
        WindowGroup {
            if facilityID == nil {
                FacilityPickerScreen(facilityID: $facilityID)
            } else {
                HomeScreen()
            }
        }
    }
}

extension Logger {
    public static var subsystem = Bundle.main.bundleIdentifier!
}
