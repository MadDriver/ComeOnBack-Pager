//
//  OAuthConfig.swift
//  ComeOnBack Pager
//
//  Static OAuth2 client configuration for the `comeonback-console` client against
//  atcauth. Endpoint paths are hardcoded rather than fetched via RFC 8414
//  discovery — they are stable, which keeps the flow free of an extra network
//  round-trip.
//
//  Console deltas vs. the mobile (`comeonback`) client: a console client id, a
//  native custom-scheme redirect, and the `profile` scope. `require_console` gates
//  on the token's **role**, not its `aud`, so no separate client registration is
//  needed beyond the native redirect URI (atcauth M0b).
//

import Foundation

enum OAuthConfig {
    /// atcauth base URL per build configuration: prod ships against the public
    /// issuer, DEBUG points at the local dev stack (`stack/main`, atcauth on 8086).
    static var baseURL: URL {
        #if DEBUG
        return URL(string: "http://localhost:8086")!
        #else
        return URL(string: "https://atcauth.com")!
        #endif
    }

    static let clientID = "comeonback-console"
    static let redirectURI = "comeonback-console://callback"
    static let callbackScheme = "comeonback-console"
    static let scope = "profile"

    static var authorizationEndpoint: URL { baseURL.appendingPathComponent("oauth/authorize") }
    static var tokenEndpoint: URL { baseURL.appendingPathComponent("oauth/token") }
    static var revocationEndpoint: URL { baseURL.appendingPathComponent("oauth/revoke") }
}
