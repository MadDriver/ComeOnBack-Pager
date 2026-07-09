//
//  PKCE.swift
//  ComeOnBack Pager
//
//  Proof Key for Code Exchange (RFC 7636, S256) generated with CryptoKit — the
//  reason we can use the built-in `ASWebAuthenticationSession` instead of pulling
//  in AppAuth-iOS as the app's first dependency: PKCE is a few lines here, not a
//  library. Ported near-verbatim from the iOS app's auth core.
//

import CryptoKit
import Foundation

/// A PKCE verifier/challenge pair. The verifier is kept in memory for the token
/// exchange; only the S256 challenge leaves the device on the authorize request.
struct PKCE: Equatable {
    let verifier: String
    let challenge: String

    /// Fresh pair: a 43-char base64url verifier (32 random bytes, RFC 7636 allows
    /// 43–128 chars) and its S256 challenge.
    static func generate() -> PKCE {
        let verifier = randomVerifier()
        return PKCE(verifier: verifier, challenge: challenge(for: verifier))
    }

    /// `code_challenge = base64url(SHA256(code_verifier))` — the S256 method. The
    /// hash is over the verifier's ASCII bytes.
    static func challenge(for verifier: String) -> String {
        let digest = SHA256.hash(data: Data(verifier.utf8))
        return Data(digest).base64URLEncodedString()
    }

    private static func randomVerifier() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        if status != errSecSuccess {
            // SecRandom should never fail; fall back to a still-unpredictable source
            // rather than crashing the login flow.
            bytes = (0..<32).map { _ in UInt8.random(in: .min ... .max) }
        }
        return Data(bytes).base64URLEncodedString()
    }
}

/// A random `state`, validated on the redirect to defend the code exchange against
/// CSRF / code injection.
enum OAuthState {
    static func random() -> String {
        var bytes = [UInt8](repeating: 0, count: 16)
        if SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes) != errSecSuccess {
            bytes = (0..<16).map { _ in UInt8.random(in: .min ... .max) }
        }
        return Data(bytes).base64URLEncodedString()
    }
}
