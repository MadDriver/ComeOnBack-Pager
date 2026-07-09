//
//  CannedMessage.swift
//  ComeOnBack Pager
//
//  Canned-message definitions (`GET /api/v3/{fac}/messages`) and the per-recipient
//  outcome of a send (`POST /messages/send`). Mirrors the web console's send modal:
//  pick a definition, pick recipients, report `sent` / `no_devices` per initials.
//

import Foundation

/// A canned-message definition. `phoneNumber` is an optional tap-to-call fallback
/// rendered for unregistered recipients (contract: `CannedMessage`).
struct CannedMessage: Identifiable, Hashable, Decodable {
    let id: Int
    let text: String
    let phoneNumber: String?
    let sortOrder: Int
}

/// One recipient's send outcome. `result` is `sent` (a push went out) or `no_devices`
/// (registered nowhere — the OS must alert them by phone). Decoded leniently so an
/// unfamiliar future result value renders verbatim rather than dropping the row.
struct SendResult: Identifiable, Hashable, Decodable {
    var id: String { initials }
    let initials: String
    let result: String

    var delivered: Bool { result == "sent" }
}
