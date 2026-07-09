//
//  OAuthTokenClient.swift
//  ComeOnBack Pager
//
//  The seam over atcauth's token endpoint (`/oauth/token`) and revocation endpoint
//  (`/oauth/revoke`). A protocol so the single-flight rotating-refresh logic in
//  `AuthManager` is unit-testable with a fake — the code exchange, refresh, and
//  revoke are the only network calls the auth layer makes.
//

import Foundation

/// Raw token-endpoint response.
struct RawTokens: Equatable {
    let accessToken: String
    /// Nil if the server did not return a rotated refresh token; the caller keeps the
    /// prior one. (atcauth rotates on every use, so in practice this is always set.)
    let refreshToken: String?
    let expiresIn: Int?
}

/// Failures from the token endpoint, classified for the refresh state machine.
enum OAuthError: Error, Equatable {
    /// `invalid_grant` — the refresh chain is dead; the user must re-login.
    case invalidGrant
    /// Transient connectivity failure; safe to retry later (tokens left intact).
    case network
    /// Non-2xx that isn't `invalid_grant`.
    case server(status: Int)
    /// 2xx whose body was missing/undecodable or lacked an access token.
    case malformedResponse

    var isInvalidGrant: Bool { self == .invalidGrant }
}

protocol OAuthTokenClient: Sendable {
    /// Exchange an authorization code (+ its PKCE verifier) for tokens.
    func exchangeCode(code: String, verifier: String) async throws -> RawTokens
    /// Present a refresh token for rotation; the response carries the new one.
    func refresh(refreshToken: String) async throws -> RawTokens
    /// Best-effort RFC 7009 revocation of a refresh token.
    func revoke(refreshToken: String) async throws
}

/// `URLSession` form-POST implementation. No client secret (public client); PKCE
/// authenticates the exchange.
final class URLSessionOAuthClient: OAuthTokenClient, @unchecked Sendable {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func exchangeCode(code: String, verifier: String) async throws -> RawTokens {
        try await tokenRequest([
            "grant_type": "authorization_code",
            "code": code,
            "client_id": OAuthConfig.clientID,
            "redirect_uri": OAuthConfig.redirectURI,
            "code_verifier": verifier,
        ])
    }

    func refresh(refreshToken: String) async throws -> RawTokens {
        try await tokenRequest([
            "grant_type": "refresh_token",
            "refresh_token": refreshToken,
            "client_id": OAuthConfig.clientID,
        ])
    }

    func revoke(refreshToken: String) async throws {
        var request = URLRequest(url: OAuthConfig.revocationEndpoint)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = Self.formEncode([
            "token": refreshToken,
            "token_type_hint": "refresh_token",
            "client_id": OAuthConfig.clientID,
        ])
        // RFC 7009 always returns 200; result is ignored (best-effort).
        _ = try? await session.data(for: request)
    }

    // MARK: - Token endpoint

    private func tokenRequest(_ params: [String: String]) async throws -> RawTokens {
        var request = URLRequest(url: OAuthConfig.tokenEndpoint)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = Self.formEncode(params)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw OAuthError.network
        }

        guard let http = response as? HTTPURLResponse else { throw OAuthError.malformedResponse }

        guard (200..<300).contains(http.statusCode) else {
            // OAuth2 error body: {"error": "invalid_grant", ...}. A dead/rotated
            // refresh chain is `invalid_grant`.
            if let err = try? JSONDecoder().decode(TokenErrorDTO.self, from: data),
               err.error == "invalid_grant" {
                throw OAuthError.invalidGrant
            }
            throw OAuthError.server(status: http.statusCode)
        }

        guard let dto = try? JSONDecoder().decode(TokenResponseDTO.self, from: data),
              let accessToken = dto.access_token
        else { throw OAuthError.malformedResponse }

        return RawTokens(
            accessToken: accessToken,
            refreshToken: dto.refresh_token,
            expiresIn: dto.expires_in
        )
    }

    /// `application/x-www-form-urlencoded` body. Percent-encode each key/value so
    /// nothing outside the unreserved set leaks a `&`/`=`/`+` into the body.
    static func formEncode(_ params: [String: String]) -> Data {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        let pairs = params.map { key, value in
            let k = key.addingPercentEncoding(withAllowedCharacters: allowed) ?? key
            let v = value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
            return "\(k)=\(v)"
        }
        return Data(pairs.joined(separator: "&").utf8)
    }

    private struct TokenResponseDTO: Decodable {
        let access_token: String?
        let refresh_token: String?
        let expires_in: Int?
    }

    private struct TokenErrorDTO: Decodable {
        let error: String?
    }
}
