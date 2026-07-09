//
//  APIConfig.swift
//  ComeOnBack Pager
//
//  Base URL for the ComeOnBack v3 API (the `comeonback-web` host), per build
//  configuration. Note this is the *API* host, distinct from the atcauth issuer
//  (`OAuthConfig.baseURL`). Replaces the v1 hardcoded `APIServer` enum.
//
//  Path shape is `{baseURL}/api/v3/{facility}[/…]`; `{facility}` comes from the
//  console token's role (never user input), composed per-request in `APIClient`.
//

import Foundation

enum APIConfig {
    /// Prod ships against the public API host; DEBUG points at the local dev stack
    /// (`stack/main`, comeonback-web on 8085). The simulator reaches the host via
    /// `localhost`.
    static var baseURL: URL {
        #if DEBUG
        return URL(string: "http://localhost:8085")!
        #else
        return URL(string: "https://atcpager.com")!
        #endif
    }

    /// Refresh proactively when the access token is within this window of expiry, so
    /// a request rarely races a 401 (drive refresh off `exp`).
    static let proactiveRefreshWindow: TimeInterval = 60

    /// Facility-status poll cadence — matches the web console (`v3StatusStore.ts`).
    static let pollInterval: TimeInterval = 4
}
