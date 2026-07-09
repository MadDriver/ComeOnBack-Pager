//
//  Session.swift
//  ComeOnBack Pager
//
//  The single reactive source of truth for whether this workstation is enrolled,
//  derived from the stored access token's claims. Replaces the old
//  `@AppStorage("facilityID")` gate — the facility is no longer typed in by hand, it
//  comes from the console token's role.
//
//  A **console** principal carries `roles: ["console:<fac>"]` and no
//  `initials`/`empid`; the pager therefore models only a facility (no per-person
//  identity), mirroring the web console's `facilityForRole()`.
//

import Foundation

enum Session: Equatable {
    case loggedOut
    case loggedIn(facility: String)

    /// The enrolled facility, or nil while logged out. Used for URL building and the
    /// board header.
    var facility: String? {
        if case .loggedIn(let facility) = self { return facility }
        return nil
    }
}

/// Outcome of an authorization-code exchange (enrollment).
enum LoginResult: Equatable {
    case success(Session)
    case failed(message: String)
}

/// Outcome of a token-refresh attempt (consumed by the network layer).
enum TokenRefreshResult: Equatable {
    /// A valid access token is available — freshly rotated, or already rotated by a
    /// concurrent caller that won the single-flight race.
    case refreshed(accessToken: String)
    /// The refresh chain is dead (`invalid_grant` / no stored token) — re-enroll.
    case loggedOut
    /// A transient failure (e.g. network); tokens are left intact so a later attempt
    /// can succeed.
    case failed(message: String)
}

/// The facility a console token governs: the suffix of its first `console:<fac>`
/// role, falling back to the `facility_id` claim. Mirrors the web console's
/// `facilityForRole('console')`. Returns nil for a token that carries no console
/// role at all — such a token cannot back a console session.
func consoleFacility(from claims: AuthClaims) -> String? {
    let prefix = "console:"
    for role in claims.roles ?? [] where role.hasPrefix(prefix) {
        let suffix = String(role.dropFirst(prefix.count))
        return suffix.isEmpty ? claims.facilityId : suffix
    }
    return nil
}

/// Map stored tokens to a [Session]. A token with a `console:<fac>` role backs a
/// console session for that facility; anything else (mobile controller token, admin,
/// malformed) maps to `.loggedOut`.
func sessionFrom(_ tokens: StoredTokens?) -> Session {
    guard let tokens,
          let claims = JWTDecoder.claims(from: tokens.accessToken),
          let facility = consoleFacility(from: claims)
    else { return .loggedOut }

    return .loggedIn(facility: facility)
}
