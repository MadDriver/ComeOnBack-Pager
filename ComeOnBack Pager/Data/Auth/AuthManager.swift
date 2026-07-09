//
//  AuthManager.swift
//  ComeOnBack Pager
//
//  Owns the token lifecycle: code exchange, single-flight rotating refresh, and
//  revoke-on-logout. A Swift `actor`.
//
//  Rotation safety (the rule that bites): atcauth rotates the refresh token on every
//  use with reuse detection, so presenting an already-rotated token revokes the
//  entire chain and logs the whole fleet out. Two guarantees:
//
//  - **Single-flight.** Concurrent callers coalesce onto one in-flight refresh
//    `Task`; they never each present the (soon-rotated) refresh token. The actor's
//    serialized execution makes the "is a refresh already running?" check-and-set
//    atomic (there is no `await` between reading and assigning `inFlight`).
//  - **Persist-before-release.** The rotated pair is written to the `TokenStore`
//    (a synchronous, awaited Keychain write) *inside* `performRefresh`, before the
//    result is returned and before `inFlight` is cleared — so any later caller reads
//    the durably-persisted new token, and a crash mid-refresh can't strand the user.
//

import Foundation

actor AuthManager {
    private let oauth: OAuthTokenClient
    private let store: TokenStoring
    /// Invoked (best-effort) when a refresh clears the tokens on `invalid_grant`, so
    /// the `@MainActor` `SessionStore` can drop to `.loggedOut` even when the refresh
    /// was triggered deep in the network layer rather than by an explicit logout.
    private let onInvalidated: (@Sendable () -> Void)?

    /// The in-flight refresh, if one is running. Non-nil ⇒ a concurrent caller is
    /// mid-refresh and new callers must await it, not start their own.
    private var inFlight: Task<String, Error>?

    init(
        oauth: OAuthTokenClient = URLSessionOAuthClient(),
        store: TokenStoring = KeychainTokenStore(),
        onInvalidated: (@Sendable () -> Void)? = nil
    ) {
        self.oauth = oauth
        self.store = store
        self.onInvalidated = onInvalidated
    }

    // MARK: - Session bootstrap

    /// The session implied by the currently-stored token, without any network call.
    func currentSession() -> Session {
        sessionFrom(try? store.load())
    }

    /// The stored access token, if any, without refreshing.
    func currentAccessToken() -> String? {
        (try? store.load())?.accessToken
    }

    // MARK: - Login

    /// Exchange an authorization-code redirect (with its PKCE verifier) for tokens
    /// and persist them.
    func exchange(code: String, verifier: String) async -> LoginResult {
        let raw: RawTokens
        do {
            raw = try await oauth.exchangeCode(code: code, verifier: verifier)
        } catch {
            return .failed(message: loginMessage(for: error))
        }
        guard let refresh = raw.refreshToken else {
            return .failed(message: "Enrollment failed: missing refresh token.")
        }
        let tokens = StoredTokens(accessToken: raw.accessToken, refreshToken: refresh)
        do {
            try store.save(tokens)
        } catch {
            return .failed(message: "Enrollment failed: could not store credentials.")
        }
        switch sessionFrom(tokens) {
        case .loggedIn:
            return .success(sessionFrom(tokens))
        case .loggedOut:
            // A valid token with no `console:<fac>` role is a mobile/admin token, not
            // a facility console — reject rather than land in a broken board UI. Clear
            // the just-stored tokens so a retry starts clean.
            try? store.clear()
            return .failed(message: "This account isn't a console for any facility.")
        }
    }

    // MARK: - Refresh (single-flight)

    /// Return a valid access token, refreshing under single-flight if needed.
    ///
    /// - Parameter previous: the access token that was found stale/rejected (e.g. the
    ///   one that got a 401), or nil to force a refresh. If, when the refresh runs, the
    ///   stored access token already differs, a concurrent caller has refreshed — that
    ///   token is returned without presenting the (now rotated) refresh token again.
    func validAccessToken(previous: String?) async -> TokenRefreshResult {
        // Coalesce: if a refresh is already running, await its result. The check and
        // the assignment below are not separated by an `await`, so at most one caller
        // ever creates the Task.
        if let inFlight {
            return await result(of: inFlight)
        }
        // Only this caller reaches past the assignment; coalescing callers return via
        // the branch above and never touch `inFlight`. So clearing it unconditionally
        // once the task completes is correct (no other code can reassign it while it
        // is non-nil — that is exactly what forces others to coalesce).
        let task = Task { try await performRefresh(previous: previous) }
        inFlight = task
        let outcome = await result(of: task)
        inFlight = nil
        return outcome
    }

    private func result(of task: Task<String, Error>) async -> TokenRefreshResult {
        do {
            return .refreshed(accessToken: try await task.value)
        } catch let error as RefreshFailure {
            switch error {
            case .loggedOut: return .loggedOut
            case .transient(let message): return .failed(message: message)
            }
        } catch {
            return .failed(message: "Could not refresh session.")
        }
    }

    /// The actual rotation, run inside the single-flight `Task`. Persists the new pair
    /// before returning.
    private func performRefresh(previous: String?) async throws -> String {
        guard let current = try? store.load() else { throw RefreshFailure.loggedOut }

        // A concurrent caller already rotated: return the fresh token as-is.
        if let previous, current.accessToken != previous {
            return current.accessToken
        }

        let raw: RawTokens
        do {
            raw = try await oauth.refresh(refreshToken: current.refreshToken)
        } catch let error as OAuthError where error.isInvalidGrant {
            try? store.clear()
            onInvalidated?()
            throw RefreshFailure.loggedOut
        } catch let error as OAuthError where error == .network {
            throw RefreshFailure.transient("Unable to connect. Please check your internet connection.")
        } catch {
            throw RefreshFailure.transient("Could not refresh session.")
        }

        let rotated = StoredTokens(
            accessToken: raw.accessToken,
            refreshToken: raw.refreshToken ?? current.refreshToken
        )
        // Persist the rotation BEFORE returning / releasing single-flight.
        try store.save(rotated)
        return rotated.accessToken
    }

    // MARK: - Logout

    /// Revoke the refresh token (best-effort) and clear local tokens. Logout must
    /// succeed even when revocation can't reach the server.
    func revokeAndClear() async {
        if let current = try? store.load() {
            try? await oauth.revoke(refreshToken: current.refreshToken)
        }
        try? store.clear()
    }

    // MARK: - Helpers

    private func loginMessage(for error: Error) -> String {
        if let oauth = error as? OAuthError, oauth == .network {
            return "Unable to connect. Please check your internet connection."
        }
        return "Enrollment failed. Please try again."
    }

    /// Internal failure classification for the single-flight `Task` (which can only
    /// throw, not return an enum).
    private enum RefreshFailure: Error {
        case loggedOut
        case transient(String)
    }
}
