//
//  SessionStore.swift
//  ComeOnBack Pager
//
//  The app-facing session coordinator: a `@MainActor ObservableObject` whose
//  `@Published session` is the single gate `ComeOnBackPagerApp` switches on
//  (replacing the old `@AppStorage("facilityID")` gate). Owns the enrollment/logout
//  entry points the UI drives; token mechanics live in the `AuthManager` actor.
//

import Foundation
import SwiftUI

@MainActor
final class SessionStore: ObservableObject {
    @Published private(set) var session: Session = .loggedOut
    @Published var isLoggingIn = false
    /// Non-nil after a failed enrollment; surfaced on the enrollment screen.
    @Published var loginError: String?
    /// Terminal, app-wide block raised by the `APIClient` choke point: 410 → upgrade.
    /// `ComeOnBackPagerApp` presents it above everything.
    @Published var appLock: AppLockState = .none

    private let auth: AuthManager
    private let loginService: WebAuthLoginService

    /// The v3 console client, built on this store's `AuthManager` (its single-flight
    /// rotating refresh) and wired to raise `appLock` / force re-enroll. Lazily created
    /// so its callbacks can capture `self`. The board calls through here.
    lazy private(set) var api: APIClient = APIClient(
        auth: auth,
        onLock: { [weak self] state in
            Task { @MainActor in self?.raiseLock(state) }
        },
        onForceLogout: { [weak self] in
            Task { @MainActor in await self?.forceLoggedOut() }
        }
    )

    init(auth: AuthManager? = nil, loginService: WebAuthLoginService? = nil) {
        // Constructed here (not as a default argument) because `WebAuthLoginService`
        // is `@MainActor`-isolated and default arguments evaluate nonisolated.
        self.loginService = loginService ?? WebAuthLoginService()
        if let auth {
            self.auth = auth
        } else {
            // Wire the actor's "chain died" callback back to the published state so a
            // background refresh that hits `invalid_grant` drops the UI to enrollment
            // without an explicit logout. A Sendable box lets the closure capture
            // `self` only after init completes (Swift-6-safe).
            let box = InvalidationCallbackBox()
            let manager = AuthManager(onInvalidated: { box.callback?() })
            self.auth = manager
            box.callback = { [weak self] in
                Task { @MainActor in self?.session = .loggedOut }
            }
        }
    }

    /// Restore the session from stored tokens on launch. No network call.
    func bootstrap() async {
        session = await auth.currentSession()
    }

    /// Present the OAuth enrollment sheet and, on success, move to `.loggedIn`.
    func login() async {
        loginError = nil
        appLock = .none
        isLoggingIn = true
        defer { isLoggingIn = false }

        let grant: AuthorizationGrant
        do {
            grant = try await loginService.requestAuthorization()
        } catch WebAuthError.cancelled {
            return // user dismissed the sheet — silent
        } catch {
            loginError = "Enrollment was interrupted. Please try again."
            return
        }

        switch await auth.exchange(code: grant.code, verifier: grant.verifier) {
        case .success(let newSession):
            session = newSession
        case .failed(let message):
            loginError = message
        }
    }

    /// Revoke + clear, then drop to enrollment. Used by the manual "sign out /
    /// re-enroll" affordance.
    func logout() async {
        await auth.revokeAndClear()
        session = .loggedOut
        appLock = .none
    }

    /// Raise a terminal lock from the network layer (410 upgrade).
    func raiseLock(_ state: AppLockState) {
        appLock = state
    }

    /// Unrecoverable 401 / revoked console (403) deep in the network layer — clear and
    /// drop to enrollment.
    func forceLoggedOut() async {
        await auth.revokeAndClear()
        session = .loggedOut
        appLock = .none
    }
}

/// A mutable, Sendable holder for the deferred `onInvalidated` callback (see `init`).
/// The single writer is the main-actor `SessionStore.init`; the actor reads it, so a
/// reference box (not a captured `var`) keeps the closure `@Sendable`-clean.
private final class InvalidationCallbackBox: @unchecked Sendable {
    var callback: (@Sendable () -> Void)?
}
