//
//  WebAuthLoginService.swift
//  ComeOnBack Pager
//
//  Drives the OAuth2 authorization-code + PKCE enrollment through the built-in
//  `ASWebAuthenticationSession` (the platform primitive that lets us avoid
//  AppAuth-iOS as a dependency). atcauth's own pages handle the "Enroll with a code"
//  entry; the bridge redirects back to `comeonback-console://callback`. We own only
//  PKCE, `state`, and URL construction.
//

import AuthenticationServices
import Foundation

/// A successful redirect: the authorization code plus the PKCE verifier that must be
/// presented at the token exchange.
struct AuthorizationGrant {
    let code: String
    let verifier: String
}

enum WebAuthError: Error {
    /// The user dismissed the browser sheet — not an error to surface loudly.
    case cancelled
    /// The redirect was missing a code, or its `state` did not match (possible CSRF).
    case invalidCallback
    case presentationFailed
}

@MainActor
final class WebAuthLoginService: NSObject, ASWebAuthenticationPresentationContextProviding {

    /// Present the authorize page and resolve to the captured code + PKCE verifier.
    /// Throws `WebAuthError.cancelled` if the user dismisses the sheet.
    func requestAuthorization() async throws -> AuthorizationGrant {
        let pkce = PKCE.generate()
        let state = OAuthState.random()
        let url = authorizeURL(challenge: pkce.challenge, state: state)

        let callbackURL: URL = try await withCheckedThrowingContinuation { continuation in
            let session = makeSession(url: url) { result in
                continuation.resume(with: result)
            }
            session.presentationContextProvider = self
            // Keep the atcauth SSO cookie so a re-enroll doesn't re-prompt credentials.
            session.prefersEphemeralWebBrowserSession = false
            if !session.start() {
                continuation.resume(throwing: WebAuthError.presentationFailed)
            }
        }

        let code = try parseCallback(callbackURL, expectedState: state)
        return AuthorizationGrant(code: code, verifier: pkce.verifier)
    }

    // MARK: - URL construction

    private func authorizeURL(challenge: String, state: String) -> URL {
        var components = URLComponents(url: OAuthConfig.authorizationEndpoint,
                                       resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: OAuthConfig.clientID),
            URLQueryItem(name: "redirect_uri", value: OAuthConfig.redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: OAuthConfig.scope),
            URLQueryItem(name: "code_challenge", value: challenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "state", value: state),
        ]
        return components.url!
    }

    private func parseCallback(_ url: URL, expectedState: String) throws -> String {
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        let returnedState = items.first { $0.name == "state" }?.value
        guard returnedState == expectedState else { throw WebAuthError.invalidCallback }
        guard let code = items.first(where: { $0.name == "code" })?.value, !code.isEmpty else {
            throw WebAuthError.invalidCallback
        }
        return code
    }

    // MARK: - Session factory (splits the iOS 17.4 callback API from the older one)

    private func makeSession(
        url: URL,
        completion: @escaping (Result<URL, Error>) -> Void
    ) -> ASWebAuthenticationSession {
        let handler: ASWebAuthenticationSession.CompletionHandler = { callbackURL, error in
            if let error {
                let code = (error as? ASWebAuthenticationSessionError)?.code
                completion(.failure(code == .canceledLogin ? WebAuthError.cancelled : error))
            } else if let callbackURL {
                completion(.success(callbackURL))
            } else {
                completion(.failure(WebAuthError.invalidCallback))
            }
        }

        if #available(iOS 17.4, *) {
            return ASWebAuthenticationSession(
                url: url,
                callback: .customScheme(OAuthConfig.callbackScheme),
                completionHandler: handler
            )
        } else {
            return ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: OAuthConfig.callbackScheme,
                completionHandler: handler
            )
        }
    }

    // MARK: - ASWebAuthenticationPresentationContextProviding

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        return scene?.keyWindow
            ?? scene?.windows.first
            ?? ASPresentationAnchor()
    }
}
