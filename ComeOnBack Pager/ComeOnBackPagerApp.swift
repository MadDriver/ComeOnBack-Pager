//
//  ComeOnBackPagerApp.swift
//  ComeOnBack Pager
//
//  Created by Calvin Shultz on 3/9/23.
//

import SwiftUI
import OSLog

@main
struct ComeOnBackPagerApp: App {
    @StateObject private var sessionStore = SessionStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(sessionStore)
                .task { await sessionStore.bootstrap() }
        }
    }
}

/// App gate: the terminal 410 upgrade block outranks everything; otherwise the
/// enrollment state (`SessionStore.session`) decides between the enroll screen and
/// the board. A revoked console (403) clears the session, which lands here as
/// `.loggedOut` → the enroll screen. Replaces the old `@AppStorage("facilityID")` gate.
struct RootView: View {
    @EnvironmentObject var sessionStore: SessionStore

    var body: some View {
        if sessionStore.appLock == .upgradeRequired {
            UpgradeRequiredScreen()
        } else {
            switch sessionStore.session {
            case .loggedOut:
                EnrollmentScreen()
            case .loggedIn:
                HomeScreen(api: sessionStore.api)
            }
        }
    }
}

extension Logger {
    public static var subsystem = Bundle.main.bundleIdentifier!
}
