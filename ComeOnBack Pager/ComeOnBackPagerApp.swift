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
    var body: some Scene {
        WindowGroup {
            if facilityID == nil {
                FacilityPickerScreen(facilityID: $facilityID)
            } else {
                HomeScreen()
            }
        }
        .onChange(of: facilityID) { newValue in
            logger.info("onchangeof facilityID")
            API.facilityName = newValue
        }
    }
}

extension Logger {
    public static var subsystem = Bundle.main.bundleIdentifier!
}
