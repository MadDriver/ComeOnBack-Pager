//
//  APIError.swift
//  ComeOnBack Pager
//
//  The typed v3 error envelope + the terminal, app-wide lock state — the two things
//  the `APIClient` choke point produces from a non-2xx response.
//
//  Every non-2xx on `/api/v3` is `{"error": {"code": "<machine_code>", "message":
//  "<human text>"}}` (contract §5). Behaviour is driven by `code`; `message` is
//  server-built and display-safe. Replaces the v1 stringly `APIError`.
//

import Foundation

/// Typed failure surfaced from `APIClient`. 401 refresh-retry is handled inside the
/// client (never surfaced as a case a caller retries). 410 raises the terminal
/// `AppLockState.upgradeRequired`; a 403 (console role revoked — the kill switch)
/// forces a re-enroll before the `.forbidden` case is thrown.
enum APIError: Error, Equatable {
    /// Unrecoverable 401 (bad/absent token, or a failed refresh) — force re-enroll.
    case unauthorized
    /// 403 — the console role was revoked (or facility mismatch); terminal. The
    /// client has already cleared the session (drop to the enrollment screen).
    case forbidden(code: String?, message: String?)
    /// 404 — resource gone (e.g. acknowledging a cancelled be-back); refetch state.
    case notFound(message: String?)
    /// 409 — server truth wins; refetch state.
    case conflict(code: String?, message: String?)
    /// 410 — this build is past the sunset; the blocking upgrade screen is shown.
    case upgradeRequired
    /// Any other non-2xx (incl. 5xx).
    case server(status: Int, code: String?, message: String?)
    /// A transient connectivity failure carrying a user-facing message (from a failed
    /// refresh); the action can be retried later.
    case transient(String)
    /// A low-level transport failure (URLSession threw / no HTTP response).
    case transport
    /// A 2xx body that could not be decoded into the expected type.
    case decoding
}

/// The `{"error": {code, message}}` envelope. Decoded best-effort — a non-envelope /
/// unparseable error body maps to a status-only error, never a throw.
struct APIErrorEnvelope: Decodable, Equatable {
    struct Body: Decodable, Equatable {
        let code: String?
        let message: String?
    }
    let error: Body?

    /// Parse an error body, tolerating a missing/blank/non-JSON payload.
    static func body(from data: Data) -> Body? {
        guard !data.isEmpty,
              let envelope = try? JSONDecoder().decode(APIErrorEnvelope.self, from: data)
        else { return nil }
        return envelope.error
    }

    static func code(from data: Data) -> String? { body(from: data)?.code }
}

/// Terminal, app-wide blocking state raised by the network choke point. `.none` is
/// the normal, unlocked app. Unlike the mobile app there is no `notRostered` lock:
/// a revoked console (403) simply clears the session and drops to enrollment.
enum AppLockState: Equatable {
    case none
    /// 410 sunset — a full-screen "this workstation needs an update" block.
    case upgradeRequired
}
