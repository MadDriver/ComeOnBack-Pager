//
//  AuthClaims.swift
//  ComeOnBack Pager
//
//  Claims read from an atcauth access-token payload. The access token is an RS256
//  JWT; the client decodes the payload *only* — there is no client-side signature
//  verification (the API verifies against atcauth's JWKS).
//
//  A **console** principal (what this kiosk enrolls as) carries
//  `roles: ["console:<fac>"]` and has **no** `initials`/`empid`; `facility_id` may
//  be absent (the facility comes from the role suffix). The `roles` claim is the
//  gate the pager's `Session` derivation switches on.
//

import Foundation

struct AuthClaims: Equatable {
    let facilityId: String?
    let initials: String?
    let empid: Int?
    /// atcauth role claims, e.g. `["console:A11"]`. Drives the console session
    /// derivation (`sessionFrom` / `consoleFacility`).
    let roles: [String]?
    /// Absolute expiry, derived from the `exp` claim (seconds since epoch). Drives
    /// proactive refresh in the network layer.
    let expiry: Date?
}

enum JWTDecoder {
    /// Decode the payload segment of a JWT. Returns nil for any malformed /
    /// undecodable token (too few segments, bad base64url, non-JSON payload) — an
    /// unusable token maps to "no session", never a crash.
    static func claims(from accessToken: String) -> AuthClaims? {
        let segments = accessToken.split(separator: ".", omittingEmptySubsequences: false)
        guard segments.count >= 2,
              let payloadData = Data(base64URLEncoded: String(segments[1])),
              let dto = try? JSONDecoder().decode(ClaimsDTO.self, from: payloadData)
        else { return nil }

        return AuthClaims(
            facilityId: dto.facility_id,
            initials: dto.initials,
            empid: dto.empid,
            roles: dto.roles,
            expiry: dto.exp.map { Date(timeIntervalSince1970: $0) }
        )
    }

    // Snake_case wire keys; `ignoreUnknownKeys` is implicit in Swift's Codable
    // (unlisted keys are skipped), so extra atcauth claims (aud/iss/…) are tolerated.
    private struct ClaimsDTO: Decodable {
        let facility_id: String?
        let initials: String?
        let empid: Int?
        let roles: [String]?
        let exp: Double?
    }
}
