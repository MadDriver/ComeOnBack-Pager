//
//  TokenStore.swift
//  ComeOnBack Pager
//
//  Secure persistence for the OAuth token pair. The seam is a protocol so the
//  rotation / single-flight logic in `AuthManager` can be exercised against an
//  in-memory fake in unit tests (Keychain access is unreliable in the test host),
//  while the app uses the real Keychain implementation.
//

import Foundation
import Security

/// The persisted token pair. Access and refresh are stored as two separate Keychain
/// items; the access-token expiry is not stored — it is derived from the JWT `exp`
/// claim (`JWTDecoder`), so there is no third item to keep in sync.
struct StoredTokens: Equatable {
    let accessToken: String
    let refreshToken: String
}

protocol TokenStoring: Sendable {
    /// Both items, or nil if either is absent / unreadable.
    func load() throws -> StoredTokens?
    func save(_ tokens: StoredTokens) throws
    func clear() throws
}

/// Keychain-backed store: two `kSecClassGenericPassword` items (access + refresh)
/// under this app's **own** service string. Unlike the iOS app there is no shared
/// access group — the pager has no widget/extension reading the token, so the items
/// stay private to the app. Accessibility is `AfterFirstUnlock` so a backgrounded /
/// locked kiosk can still refresh in place.
final class KeychainTokenStore: TokenStoring, @unchecked Sendable {
    private let service = "co.amalgamated.ComeOnBackPager.auth"
    private let accessTokenAccount = "access_token"
    private let refreshTokenAccount = "refresh_token"

    func load() throws -> StoredTokens? {
        guard let access = try read(account: accessTokenAccount),
              let refresh = try read(account: refreshTokenAccount)
        else { return nil }
        return StoredTokens(accessToken: access, refreshToken: refresh)
    }

    func save(_ tokens: StoredTokens) throws {
        try write(tokens.accessToken, account: accessTokenAccount)
        try write(tokens.refreshToken, account: refreshTokenAccount)
    }

    func clear() throws {
        try delete(account: accessTokenAccount)
        try delete(account: refreshTokenAccount)
    }

    // MARK: - SecItem plumbing

    private func baseQuery(account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }

    private func read(account: String) throws -> String? {
        var query = baseQuery(account: account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        switch status {
        case errSecSuccess:
            guard let data = item as? Data, let string = String(data: data, encoding: .utf8) else {
                return nil
            }
            return string
        case errSecItemNotFound:
            return nil
        default:
            throw KeychainError.unexpectedStatus(status)
        }
    }

    /// Upsert: update in place if present, else add. `AfterFirstUnlock` accessibility
    /// is set on add so the value is readable while the device is locked.
    private func write(_ value: String, account: String) throws {
        let data = Data(value.utf8)
        let update: [String: Any] = [kSecValueData as String: data]
        let updateStatus = SecItemUpdate(baseQuery(account: account) as CFDictionary,
                                         update as CFDictionary)
        if updateStatus == errSecSuccess { return }
        guard updateStatus == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(updateStatus)
        }

        var addQuery = baseQuery(account: account)
        addQuery[kSecValueData as String] = data
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        guard addStatus == errSecSuccess else { throw KeychainError.unexpectedStatus(addStatus) }
    }

    private func delete(account: String) throws {
        let status = SecItemDelete(baseQuery(account: account) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
}

enum KeychainError: Error, Equatable {
    case unexpectedStatus(OSStatus)
}
