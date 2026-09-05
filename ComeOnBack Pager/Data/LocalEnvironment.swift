//
//  LocalEnvironment.swift
//  ComeOnBack Pager
//
//  Debug-only reader for the server URLs that `Configs/Debug.xcconfig` bakes into the
//  generated Info.plist. It lets a device build point at a dev stack on the LAN — set
//  the IP in a gitignored `Configs/Local.xcconfig` — with no edit to Swift source.
//
//  Compile-time rather than an environment variable on purpose: env vars only exist
//  when Xcode launches the app, so they do not survive a home-screen relaunch of an
//  installed build, which is exactly the case device testing needs.
//

import Foundation

#if DEBUG
enum LocalEnvironment {
    /// The Info.plist string for `key`, or nil when the key is missing or blank.
    /// An xcconfig variable that is never assigned expands to the empty string, so
    /// blank has to count as absent for the callers' fallbacks to fire.
    static func url(forInfoDictionaryKey key: String) -> URL? {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: key) as? String else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        return URL(string: trimmed)
    }
}
#endif
