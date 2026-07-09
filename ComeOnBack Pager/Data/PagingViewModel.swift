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

    // MARK: - Training teams + interleaved board items (R2)

    var trainingTeams: [TrainingTeam] { facility?.trainingTeams ?? [] }
    var plannedPositions: [PlannedPosition] { facility?.plannedPositions ?? [] }

    private var controllersByInitials: [String: Controller] {
        Dictionary(allControllers.map { ($0.initials, $0) }, uniquingKeysWith: { first, _ in first })
    }

    /// Team units keyed by *each* member's initials (both point at the same unit).
    /// A team whose members aren't both on the current roster is skipped (tolerate the
    /// momentary roster/team skew a poll can expose — mirrors `board.ts:buildTeamUnits`).
    private var unitsByMember: [String: TeamUnit] {
        let byInitials = controllersByInitials
        var map: [String: TeamUnit] = [:]
        for team in trainingTeams {
            guard let ojti = byInitials[team.ojti], let trainee = byInitials[team.trainee] else { continue }
            let unit = TeamUnit(team: team, ojti: ojti, trainee: trainee)
            map[team.ojti] = unit
            map[team.trainee] = unit
        }
        return map
    }

    /// One resolved unit per team (for the pairing UI's "already teamed" filtering).
    var teamUnits: [TeamUnit] {
        var seen = Set<Int>()
        return unitsByMember.values.filter { seen.insert($0.team.id).inserted }
    }

    /// The team a controller belongs to (by initials), if any.
    func team(forInitials initials: String) -> TrainingTeam? {
        trainingTeams.first { $0.ojti == initials || $0.trainee == initials }
    }

    /// The AVAILABLE (right) side: the paged callup queue (singles/teams + unassigned
    /// plan holes, interleaved ASAP→SOON→HH:MM) followed by the not-paged available
    /// controllers/teams by sign-on time. Ports `board.ts:buildQueue`+`buildAvailable`,
    /// merged into the pager's single AVAILABLE list.
    var availableItems: [AvailableRow] {
        let units = unitsByMember
        var planByInitials: [String: PlannedPosition] = [:]
        var planByTeam: [Int: PlannedPosition] = [:]
        var holes: [PlannedPosition] = []
        for plan in plannedPositions {
            if let initials = plan.controllerInitials { planByInitials[initials] = plan }
            else if let teamId = plan.teamId { planByTeam[teamId] = plan }
            else { holes.append(plan) }
        }

        // Callup queue: paged singles/teams (carrying any assigned plan) + holes.
        var queue: [AvailableRow] = []
        var seenTeams = Set<Int>()
        for controller in allControllers where controller.status == .PAGED_BACK && controller.beBack != nil {
            if let unit = units[controller.initials] {
                guard seenTeams.insert(unit.team.id).inserted else { continue }
                queue.append(.team(unit, plan: planByTeam[unit.team.id]))
            } else {
                queue.append(.single(controller, plan: planByInitials[controller.initials]))
            }
        }
        queue.append(contentsOf: holes.map { AvailableRow.hole($0) })
        queue.sort { timeRank($0.queueTime) < timeRank($1.queueTime) }

        // Available: not paged, not on position. A team shows only when both members
        // are available (else its members appear as singles).
        var available: [AvailableRow] = []
        seenTeams.removeAll()
        for controller in allControllers where controller.status == .AVAILABLE || controller.status == .SIGNED_IN {
            if let unit = units[controller.initials] {
                guard seenTeams.insert(unit.team.id).inserted else { continue }
                let partner = unit.ojti.initials == controller.initials ? unit.trainee : unit.ojti
                guard partner.status == .AVAILABLE || partner.status == .SIGNED_IN else {
                    seenTeams.remove(unit.team.id)  // let the partner-less member fall through as a single
                    available.append(.single(controller, plan: nil))
                    continue
                }
                available.append(.team(unit, plan: nil))
            } else {
                available.append(.single(controller, plan: nil))
            }
        }
        available.sort { ($0.atTime ?? .distantFuture) < ($1.atTime ?? .distantFuture) }

        return queue + available
    }

    /// The ON POSITION (left) side: current reality only. A team plugged in together
    /// (both ON_POSITION) collapses to one row; otherwise members show individually.
    var onPositionItems: [OnPositionRow] {
        let units = unitsByMember
        var items: [OnPositionRow] = []
        var seenTeams = Set<Int>()
        for controller in onPosition {
            if let unit = units[controller.initials],
               unit.ojti.status == .ON_POSITION, unit.trainee.status == .ON_POSITION {
                guard seenTeams.insert(unit.team.id).inserted else { continue }
                items.append(.team(unit))
            } else {
                items.append(.single(controller))
            }
        }
        return items
    }

    /// An unassigned plan whose position matches a just-created direct page — the
    /// reconciliation prompt (design spec §9.2). At most one plan per position, so the
    /// match is unambiguous.
    func matchingUnassignedPlan(forPosition: String?) -> PlannedPosition? {
        guard let forPosition else { return nil }
        return plannedPositions.first { plan in
            plan.status == "planned" && plan.controllerInitials == nil && plan.teamId == nil
                && plan.position.uppercased() == forPosition.uppercased()
        }
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

    // MARK: - Team writes (R2)

    func createTeam(ojti: Controller, trainee: Controller) async throws {
        try await api.createTeam(ojti: ojti.initials, trainee: trainee.initials)
        await refresh()
    }

    func splitTeam(_ unit: TeamUnit) async throws {
        try await api.splitTeam(id: unit.team.id)
        await refresh()
    }

    func pageTeam(_ unit: TeamUnit, beBack: BeBack) async throws {
        try await api.pageTeam(id: unit.team.id, time: beBack.stringValue, forPosition: beBack.forPosition)
        await refresh()
    }

    func cancelTeamPage(_ unit: TeamUnit) async throws {
        try await api.cancelTeamPage(id: unit.team.id)
        await refresh()
    }

    func moveTeamOnPosition(_ unit: TeamUnit, position: String?) async throws {
        try await api.moveTeamOnPosition(id: unit.team.id, position: position)
        await refresh()
    }

    func moveTeamOffPosition(_ unit: TeamUnit) async throws {
        try await api.moveTeamOffPosition(id: unit.team.id)
        await refresh()
    }

    // MARK: - Planned-position writes (R2)

    /// Create a plan; a `.conflict` throw means one already exists for the position
    /// (the caller offers "Overwrite?" and retries with `overwrite: true`).
    func createPlanned(position: String, time: String, overwrite: Bool) async throws {
        try await api.createPlanned(position: position, time: time, overwrite: overwrite)
        await refresh()
    }

    func assignPlanned(
        _ plan: PlannedPosition, controllerInitials: String? = nil, teamId: Int? = nil,
        adoptExistingBeBack: Bool = false
    ) async throws {
        try await api.assignPlanned(
            id: plan.id, controllerInitials: controllerInitials, teamId: teamId,
            adoptExistingBeBack: adoptExistingBeBack
        )
        await refresh()
    }

    func cancelPlanned(_ plan: PlannedPosition) async throws {
        try await api.cancelPlanned(id: plan.id)
        await refresh()
    }

    // MARK: - Canned messages (R2)

    func listMessages() async throws -> [CannedMessage] {
        try await api.listMessages()
    }

    /// Send a canned message; refetch so the board reflects any resulting state, and
    /// return the per-recipient outcomes for the result screen.
    func sendMessage(messageId: Int, initials: [String]) async throws -> [SendResult] {
        let results = try await api.sendMessage(messageId: messageId, initials: initials)
        await refresh()
        return results
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
