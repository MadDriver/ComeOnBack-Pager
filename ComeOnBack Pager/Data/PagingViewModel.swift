//
//  PagingViewModel.swift
//  ComeOnBack Pager
//
//  The board view-model. A single ~4s ETag-conditional poll of `GET /api/v3/{fac}`
//  (web-console cadence) replaces v1's split `updateAllControllers` (facility) +
//  `shortPoll` (signed-in) and the 30s / 5-min timers. One payload carries the whole
//  roster nested in `areas[].controllers`; the board lists are derived from each
//  controller's `status`. Writes go through the console `APIClient`, then trigger an
//  immediate refetch.
//

import SwiftUI
import OSLog

@MainActor
final class PagingViewModel: ObservableObject {
    private let logger = Logger(subsystem: Logger.subsystem, category: "PagingViewModel")

    @Published var facility: Facility? = nil
    /// Non-nil after a transient poll/write failure; surfaced as a board alert.
    @Published var errorMessage: String? = nil

    private let api: APIClient
    /// Last strong validator; sent as `If-None-Match` so an unchanged tick is a cheap 304.
    private var etag: String? = nil
    /// Set on a terminal condition (410 upgrade / 403 revoked / unrecoverable 401) so
    /// the poll loop stops promptly — the session/lock flip tears this screen down too.
    private var terminated = false

    init(api: APIClient) {
        self.api = api
    }

    // MARK: - Polling

    /// Poll the board every `APIConfig.pollInterval`s until the driving `.task` is
    /// cancelled (view torn down) or a terminal error stops it.
    func poll() async {
        while !Task.isCancelled && !terminated {
            await refresh()
            if terminated { break }
            try? await Task.sleep(nanoseconds: UInt64(APIConfig.pollInterval * 1_000_000_000))
        }
    }

    /// One conditional fetch: 200 → swap the board + ETag; 304 → keep it. Terminal
    /// errors have already flipped the session/lock at the choke point; transient ones
    /// surface a message and leave the last board in place.
    func refresh() async {
        do {
            switch try await api.getStatus(etag: etag) {
            case .modified(let facility, let newEtag):
                self.facility = facility
                self.etag = newEtag
            case .notModified:
                break
            }
            errorMessage = nil
        } catch APIError.upgradeRequired, APIError.forbidden, APIError.unauthorized {
            terminated = true
        } catch {
            errorMessage = "Unable to reach the server. Retrying…"
            logger.error("status poll failed: \(error)")
        }
    }

    // MARK: - Derived board lists

    private var allControllers: [Controller] {
        facility?.allControllers ?? []
    }

    /// A controller is "signed in" for anything but NOT_SIGNED_IN (an `.unknown`
    /// status is treated as neither signed-in nor not-signed-in, so a garbage record
    /// stays invisible rather than miscategorized).
    var signedIn: [Controller] {
        allControllers.filter { c in
            switch c.status {
            case .AVAILABLE, .PAGED_BACK, .ON_POSITION, .OTHER_DUTIES, .SIGNED_IN: return true
            case .NOT_SIGNED_IN, .unknown: return false
            }
        }
    }

    var notSignedIn: [Controller] {
        allControllers.filter { $0.status == .NOT_SIGNED_IN }
    }

    var pagedBack: [Controller] {
        signedIn
            .filter { $0.status == .PAGED_BACK }
            .sorted { lhs, rhs in
                guard let lhsBeBack = lhs.beBack, let rhsBeBack = rhs.beBack else {
                    logger.error("Trying to sort controllers without beBacks defined. \(lhs)-\(rhs)")
                    return false
                }
                return lhsBeBack < rhsBeBack
            }
    }

    /// Effectively empty under v3 (the API signs controllers in as AVAILABLE, so they
    /// surface under `onBreak`/AVAILABLE); kept for the "Signed In" board section in
    /// case the server ever emits it.
    var newlySignedIn: [Controller] {
        signedIn.filter { $0.status == .SIGNED_IN }.sorted()
    }

    var onBreak: [Controller] {
        pagedBack + signedIn.filter { $0.status == .AVAILABLE }.sorted()
    }

    var onPosition: [Controller] {
        signedIn.filter { $0.status == .ON_POSITION }.sorted()
    }

    // MARK: - Lookups + writes (each write refetches so the board reflects server truth)

    func getController(withInitials initials: String) -> Controller? {
        allControllers.first { $0.initials == initials }
    }

    func signIn(controllers: [Controller]) async throws {
        try await api.signIn(initials: controllers.map { $0.initials })
        await refresh()
    }

    func signOut(controllers: [Controller]) async throws {
        try await api.signOut(initials: controllers.map { $0.initials })
        await refresh()
    }

    func submitBeBack(_ beBack: BeBack, forController controller: Controller) async throws {
        try await api.submitBeBack(
            initials: controller.initials,
            time: beBack.stringValue,
            forPosition: beBack.forPosition
        )
        await refresh()
    }

    func moveControllerToOnPosition(_ controller: Controller) async throws {
        try await api.moveOnPosition(initials: controller.initials, position: nil)
        await refresh()
    }

    func moveControllerToOnBreak(_ controller: Controller) async throws {
        try await api.moveOffPosition(initials: controller.initials)
        await refresh()
    }

    func removeBeBack(forController controller: Controller) async throws {
        try await api.removeBeBack(initials: controller.initials)
        await refresh()
    }

    func ackBeBack(forController controller: Controller) async throws {
        try await api.ackBeBack(initials: controller.initials)
        await refresh()
    }

    // MARK: - Utility

    func roundUpToNext5Minutes(minutes: Int) -> Int? {
        let calendar = Calendar.current
        let dateToEdit = calendar.date(byAdding: .minute, value: minutes, to: Date())!
        let currentMinutes = calendar.component(.minute, from: dateToEdit)

        if currentMinutes % 5 != 0 {
            let r = 5 - (currentMinutes % 5)
            let minuteToAdd = minutes + r
            let actualDate = calendar.date(byAdding: .minute, value: minuteToAdd, to: Date())!
            return calendar.component(.minute, from: actualDate)
        } else {
            return calendar.component(.minute, from: dateToEdit)
        }
    }
}

#if DEBUG
extension PagingViewModel {
    /// A view-model backed by a no-token API client — for SwiftUI previews only
    /// (no network is ever reached).
    static var preview: PagingViewModel {
        PagingViewModel(api: APIClient(auth: PreviewTokenProvider()))
    }
}

private struct PreviewTokenProvider: AccessTokenProviding {
    func currentAccessToken() async -> String? { nil }
    func validAccessToken(previous: String?) async -> TokenRefreshResult { .loggedOut }
}
#endif
