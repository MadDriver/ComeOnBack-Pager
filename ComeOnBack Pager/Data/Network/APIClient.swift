//
//  APIClient.swift
//  ComeOnBack Pager
//
//  The v3 **console** network client — one authenticated request choke point over
//  `URLSession` on `{baseURL}/api/v3/{facility}[/…]`, plus the typed console surface
//  (facility status, sign in/out, page, position, acknowledge-on-behalf). Replaces
//  the v1 `API` class (hardcoded host, initials-in-body auth, stringly errors).
//
//  Design mirrors the iOS app's network layer, adapted for the console:
//
//  - **Bearer inject + proactive refresh.** Every request carries
//    `Authorization: Bearer <token>` from `AuthManager`; when the access token is
//    within `proactiveRefreshWindow` of `exp` we rotate first (single-flight) so the
//    request rarely races a 401.
//  - **401 refresh-retry-once.** A 401 whose envelope is `token_expired` (or an
//    unrecognized code) triggers a single-flight `AuthManager` refresh and **one**
//    retry (`allowRetry` guards against a refresh-then-still-401 loop).
//    `token_invalid`/`token_missing`, or a refresh that reports `.loggedOut`, force
//    re-enroll. Refresh itself is NOT reimplemented here.
//  - **Choke point.** Non-401 errors decode the envelope once and map centrally:
//    410 → `.upgradeRequired` (raises `AppLockState.upgradeRequired`); 403 → console
//    revoked (the kill switch) → force re-enroll (mirrors the web console's "a 403
//    won't heal by retrying"); 404/409 → typed refetch errors.
//  - **Conditional status GET.** `getStatus(etag:)` sends `If-None-Match`; a **304
//    is a normal `.notModified` result, not an error**, so a fast poll costs almost
//    nothing.
//  - **Facility from the token.** The `{facility}` segment is the console role's
//    facility, decoded from the JWT — never user input.
//

import Foundation

/// The token surface `APIClient` consumes. A protocol so the client is unit-testable
/// with a lightweight fake, while the app injects the real `AuthManager` actor (whose
/// single-flight rotating refresh already ships and must not be duplicated).
protocol AccessTokenProviding: Sendable {
    /// The stored access token, if any, without refreshing.
    func currentAccessToken() async -> String?
    /// A valid access token, refreshing under single-flight if needed. `previous` is
    /// the token that was found stale/rejected (so a concurrent rotation is detected).
    func validAccessToken(previous: String?) async -> TokenRefreshResult
}

// `AuthManager`'s synchronous `currentAccessToken()` witnesses the async requirement
// (cross-actor access adds the `await`); `validAccessToken(previous:)` matches directly.
extension AuthManager: AccessTokenProviding {}

/// The `{"results": […]}` wrapper the send-message route returns.
private struct SendResultsEnvelope: Decodable {
    let results: [SendResult]
}

/// The result of a conditional facility-status GET.
enum StatusResult {
    /// A 200: the fresh facility payload and its new ETag (nil if the server sent none).
    case modified(Facility, etag: String?)
    /// A 304: nothing changed since the sent ETag — keep the cached board.
    case notModified
}

final class APIClient: @unchecked Sendable {
    private let baseURL: URL
    private let session: URLSession
    private let auth: AccessTokenProviding
    /// Raise a terminal, app-wide lock (410 upgrade). Hops to the main actor in the
    /// app; records in tests.
    private let onLock: @Sendable (AppLockState) -> Void
    /// Force re-enroll on an unrecoverable 401 or a revoked console (403).
    private let onForceLogout: @Sendable () -> Void

    // `@unchecked Sendable` is sound: every stored property is a `let` of a
    // concurrency-safe type (URL, URLSession, the `AuthManager` actor, `@Sendable`
    // closures). Decoding uses a fresh `JSONDecoder` per call.

    init(
        baseURL: URL = APIConfig.baseURL,
        session: URLSession = .shared,
        auth: AccessTokenProviding,
        onLock: @escaping @Sendable (AppLockState) -> Void = { _ in },
        onForceLogout: @escaping @Sendable () -> Void = {}
    ) {
        self.baseURL = baseURL
        self.session = session
        self.auth = auth
        self.onLock = onLock
        self.onForceLogout = onForceLogout
    }

    // MARK: - Console surface (all initials/team-explicit — the token has no identity)

    /// `GET /api/v3/{fac}` with conditional `If-None-Match`. 200 → decode the facility
    /// board; 304 → `.notModified` (not an error).
    func getStatus(etag: String?) async throws -> StatusResult {
        var headers: [String: String] = [:]
        if let etag { headers["If-None-Match"] = etag }
        let (data, http) = try await perform(path: "", method: "GET", extraHeaders: headers)
        if http.statusCode == 304 { return .notModified }
        if (200..<300).contains(http.statusCode) {
            let facility = try decodeFacility(data)
            return .modified(facility, etag: http.value(forHTTPHeaderField: "Etag"))
        }
        throw mapError(status: http.statusCode, data: data)
    }

    /// `POST /controllers/signin {"initials":[…]}` — batch; per-initials results
    /// ignored (the board refetch reflects the truth).
    func signIn(initials: [String]) async throws {
        _ = try await send(path: "controllers/signin", method: "POST", body: ["initials": initials])
    }

    /// `POST /controllers/signout {"initials":[…]}` — batch.
    func signOut(initials: [String]) async throws {
        _ = try await send(path: "controllers/signout", method: "POST", body: ["initials": initials])
    }

    /// `POST /controllers/{initials}/beback {time, forPosition?}` — page (201).
    func submitBeBack(initials: String, time: String, forPosition: String?) async throws {
        var body: [String: Any] = ["time": time]
        if let forPosition { body["forPosition"] = forPosition }
        _ = try await send(path: "controllers/\(pathSafe(initials))/beback", method: "POST", body: body)
    }

    /// `DELETE /controllers/{initials}/beback` — cancel a page.
    func removeBeBack(initials: String) async throws {
        _ = try await send(path: "controllers/\(pathSafe(initials))/beback", method: "DELETE")
    }

    /// `POST /controllers/{initials}/position {position?}` — move on position.
    func moveOnPosition(initials: String, position: String?) async throws {
        let body: [String: Any] = position.map { ["position": $0] } ?? [:]
        _ = try await send(path: "controllers/\(pathSafe(initials))/position", method: "POST", body: body)
    }

    /// `DELETE /controllers/{initials}/position` — move off position.
    func moveOffPosition(initials: String) async throws {
        _ = try await send(path: "controllers/\(pathSafe(initials))/position", method: "DELETE")
    }

    /// `POST /controllers/{initials}/beback/acknowledge` — acknowledge on behalf of an
    /// unregistered controller (M0 console route).
    func ackBeBack(initials: String) async throws {
        _ = try await send(path: "controllers/\(pathSafe(initials))/beback/acknowledge", method: "POST")
    }

    // MARK: - R2 console surface: canned messages

    /// `GET /messages` — the canned-message definitions for the send UI.
    func listMessages() async throws -> [CannedMessage] {
        let data = try await send(path: "messages", method: "GET")
        return try decode([CannedMessage].self, from: data)
    }

    /// `POST /messages/send {"messageId", "initials":[…]}` — fire-and-forget; returns
    /// the per-recipient outcomes (`sent` / `no_devices`).
    func sendMessage(messageId: Int, initials: [String]) async throws -> [SendResult] {
        let data = try await send(
            path: "messages/send", method: "POST",
            body: ["messageId": messageId, "initials": initials]
        )
        return try decode(SendResultsEnvelope.self, from: data).results
    }

    // MARK: - R2 console surface: training teams

    /// `POST /teams {"ojti","trainee"}` — pair a team (201). 409 if either isn't
    /// signed in / already teamed.
    func createTeam(ojti: String, trainee: String) async throws {
        _ = try await send(path: "teams", method: "POST", body: ["ojti": ojti, "trainee": trainee])
    }

    /// `DELETE /teams/{id}` — split; member statuses unchanged.
    func splitTeam(id: Int) async throws {
        _ = try await send(path: "teams/\(id)", method: "DELETE")
    }

    /// `POST /teams/{id}/beback {time, forPosition?}` — page both members (201).
    func pageTeam(id: Int, time: String, forPosition: String?) async throws {
        var body: [String: Any] = ["time": time]
        if let forPosition { body["forPosition"] = forPosition }
        _ = try await send(path: "teams/\(id)/beback", method: "POST", body: body)
    }

    /// `DELETE /teams/{id}/beback` — cancel the team's page.
    func cancelTeamPage(id: Int) async throws {
        _ = try await send(path: "teams/\(id)/beback", method: "DELETE")
    }

    /// `POST /teams/{id}/position {position?}` — move both members on position.
    func moveTeamOnPosition(id: Int, position: String?) async throws {
        let body: [String: Any] = position.map { ["position": $0] } ?? [:]
        _ = try await send(path: "teams/\(id)/position", method: "POST", body: body)
    }

    /// `DELETE /teams/{id}/position` — move both members off position.
    func moveTeamOffPosition(id: Int) async throws {
        _ = try await send(path: "teams/\(id)/position", method: "DELETE")
    }

    // MARK: - R2 console surface: planned positions

    /// `POST /positions/planned {position, time, overwrite?}` — create (201). A 409
    /// (`.conflict`) means one already exists for the position — retry with overwrite.
    func createPlanned(position: String, time: String, overwrite: Bool) async throws {
        var body: [String: Any] = ["position": position, "time": time]
        if overwrite { body["overwrite"] = true }
        _ = try await send(path: "positions/planned", method: "POST", body: body)
    }

    /// `POST /positions/planned/{id}/assign` — assign a controller **or** a team (exactly
    /// one) and page them in one action; `adoptExistingBeBack` reconciles a direct page.
    func assignPlanned(
        id: Int, controllerInitials: String? = nil, teamId: Int? = nil,
        adoptExistingBeBack: Bool = false
    ) async throws {
        var body: [String: Any] = [:]
        if let controllerInitials { body["controllerInitials"] = controllerInitials }
        if let teamId { body["teamId"] = teamId }
        if adoptExistingBeBack { body["adoptExistingBeBack"] = true }
        _ = try await send(path: "positions/planned/\(id)/assign", method: "POST", body: body)
    }

    /// `DELETE /positions/planned/{id}` — cancel the entry (cascades any page it made).
    func cancelPlanned(id: Int) async throws {
        _ = try await send(path: "positions/planned/\(id)", method: "DELETE")
    }

    // MARK: - Authenticated request choke point

    /// The mutation flavor: run through `perform`, return the 2xx body or map the
    /// error. Empty-body POSTs send `{}` (contract §3).
    @discardableResult
    private func send(
        path: String,
        method: String,
        body: [String: Any]? = nil
    ) async throws -> Data {
        let (data, http) = try await perform(path: path, method: method, body: body)
        if (200..<300).contains(http.statusCode) { return data }
        throw mapError(status: http.statusCode, data: data)
    }

    /// Attach the Bearer token, proactively refresh near expiry, resolve the facility
    /// from the token, execute, and on a 401 `token_expired` refresh + retry **once**.
    /// Returns `(data, response)` for any status the caller must interpret (2xx, 304,
    /// 4xx/5xx); only the 401 handshake is resolved here.
    private func perform(
        path: String,
        method: String,
        body: [String: Any]? = nil,
        extraHeaders: [String: String] = [:],
        allowRetry: Bool = true
    ) async throws -> (Data, HTTPURLResponse) {
        guard var token = await auth.currentAccessToken() else {
            onForceLogout()
            throw APIError.unauthorized
        }

        // Proactive refresh: rotate ahead of a near-expiry 401 (single-flight). A
        // transient failure keeps the stale token — the reactive 401 path handles it.
        if let expiry = JWTDecoder.claims(from: token)?.expiry,
           expiry.timeIntervalSinceNow < APIConfig.proactiveRefreshWindow {
            switch await auth.validAccessToken(previous: token) {
            case .refreshed(let fresh): token = fresh
            case .loggedOut: onForceLogout(); throw APIError.unauthorized
            case .failed: break
            }
        }

        guard let facility = facility(from: token) else {
            onForceLogout()
            throw APIError.unauthorized
        }

        let request = buildRequest(
            facility: facility, path: path, method: method,
            body: body, token: token, extraHeaders: extraHeaders
        )

        let data: Data
        let http: HTTPURLResponse
        do {
            let (responseData, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { throw APIError.transport }
            data = responseData
            http = httpResponse
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.transport
        }

        if http.statusCode == 401 {
            let code = APIErrorEnvelope.code(from: data)
            // A structurally bad/absent token never becomes valid by retrying.
            if code == "token_invalid" || code == "token_missing" {
                onForceLogout()
                throw APIError.unauthorized
            }
            guard allowRetry else {
                onForceLogout()
                throw APIError.unauthorized
            }
            switch await auth.validAccessToken(previous: token) {
            case .refreshed:
                return try await perform(
                    path: path, method: method, body: body,
                    extraHeaders: extraHeaders, allowRetry: false
                )
            case .loggedOut:
                onForceLogout()
                throw APIError.unauthorized
            case .failed(let message):
                throw APIError.transient(message)
            }
        }

        return (data, http)
    }

    // MARK: - Choke point

    /// Decode the envelope once, raise any terminal side effect, and return the typed
    /// error. 410 → upgrade lock; 403 → console revoked → force re-enroll.
    private func mapError(status: Int, data: Data) -> APIError {
        let body = APIErrorEnvelope.body(from: data)
        let code = body?.code
        let message = body?.message

        if status == 410 { onLock(.upgradeRequired) }
        if status == 403 { onForceLogout() }

        switch status {
        case 403: return .forbidden(code: code, message: message)
        case 404: return .notFound(message: message)
        case 409: return .conflict(code: code, message: message)
        case 410: return .upgradeRequired
        default: return .server(status: status, code: code, message: message)
        }
    }

    // MARK: - Plumbing

    /// The console role's facility, decoded from the JWT (never user input).
    private func facility(from token: String) -> String? {
        guard let claims = JWTDecoder.claims(from: token) else { return nil }
        return consoleFacility(from: claims)
    }

    private func buildRequest(
        facility: String,
        path: String,
        method: String,
        body: [String: Any]?,
        token: String,
        extraHeaders: [String: String]
    ) -> URLRequest {
        // The status endpoint is `/api/v3/{facility}` with NO trailing slash (Flask
        // 404s the slashed form); sub-resources append `/{path}`.
        let base = "\(baseURL.absoluteString)/api/v3/\(facility)"
        let url = URL(string: path.isEmpty ? base : "\(base)/\(path)")!
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        for (field, value) in extraHeaders {
            request.setValue(value, forHTTPHeaderField: field)
        }
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        } else if method == "POST" {
            // Empty-body POSTs send `{}` (contract §3).
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = Data("{}".utf8)
        }
        return request
    }

    private func decodeFacility(_ data: Data) throws -> Facility {
        try decode(Facility.self, from: data)
    }

    /// Decode a 2xx body into `T`, mapping any failure to `.decoding`. Fresh decoder
    /// per call: `APIClient` is concurrency-safe and a shared `JSONDecoder` is NOT safe
    /// across concurrent `.decode()`. Dates parse leniently inside the models, so no
    /// date strategy is set here.
    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw APIError.decoding
        }
    }

    /// Percent-encode an initials path segment (defensive — initials are A–Z, but a
    /// stray character must not break the path or inject a segment).
    private func pathSafe(_ segment: String) -> String {
        segment.addingPercentEncoding(withAllowedCharacters: .cobURLPathSegment) ?? segment
    }
}

private extension CharacterSet {
    /// Unreserved path-segment characters (percent-encode `/`, `?`, `#`, etc.).
    static let cobURLPathSegment: CharacterSet = {
        var set = CharacterSet.alphanumerics
        set.insert(charactersIn: "-._~")
        return set
    }()
}
