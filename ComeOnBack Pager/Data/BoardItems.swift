//
//  BoardItems.swift
//  ComeOnBack Pager
//
//  The R2 board-item model: a training team collapsed into one unit, and the row
//  kinds the two board sides render. Ports the web console's `board.ts` semantics
//  (`TeamUnit`, `buildQueue`/`buildAvailable`, `timeRank`) to the pager's kiosk board.
//
//  Equality/id design follows the frozen-rows rule (see `Controller`): every type
//  here has **full-value** equality (synthesized) so SwiftUI re-renders when the
//  underlying state changes, while `id` is a **stable** key (team id / initials /
//  entry id) used only for `Identifiable` — never derived from mutable state.
//

import Foundation

/// A training team resolved to its two live controllers. Full-value equality (the
/// members carry their own be-back/status) means a member change re-renders the unit;
/// `id` is the stable server team id.
struct TeamUnit: Identifiable, Hashable {
    let team: TrainingTeam
    let ojti: Controller
    let trainee: Controller

    var id: Int { team.id }
    var label: String { "\(ojti.initials) + \(trainee.initials)" }
    /// The be-back the team was paged with (both members share it; read the OJTI's).
    var beBack: BeBack? { ojti.beBack }
    /// The team's board status (both members move in lockstep; read the OJTI's).
    var status: ControllerStatus { ojti.status }
}

/// A row on the AVAILABLE (right) side: a lone controller, a team, or an unassigned
/// planned-position hole. Singles/teams carry the plan they fill (a "plan:" badge);
/// holes are plans with no assignee yet.
enum AvailableRow: Identifiable, Hashable {
    case single(Controller, plan: PlannedPosition?)
    case team(TeamUnit, plan: PlannedPosition?)
    case hole(PlannedPosition)

    var id: String {
        switch self {
        case .single(let c, _): return "single-\(c.initials)"
        case .team(let u, _): return "team-\(u.team.id)"
        case .hole(let p): return "hole-\(p.id)"
        }
    }

    /// The be-back / plan time this row is queued by (paged callup queue ordering).
    var queueTime: String? {
        switch self {
        case .single(let c, _): return c.beBack?.stringValue
        case .team(let u, _): return u.beBack?.stringValue
        case .hole(let p): return p.time
        }
    }

    /// The sign-on `atTime` used to order the available (non-paged) part; nil for holes.
    var atTime: Date? {
        switch self {
        case .single(let c, _): return c.atTime
        case .team(let u, _): return u.ojti.atTime
        case .hole: return nil
        }
    }
}

/// A row on the ON POSITION (left) side: a lone controller or a team plugged in
/// together. The left side is current reality only — no planned entries.
enum OnPositionRow: Identifiable, Hashable {
    case single(Controller)
    case team(TeamUnit)

    var id: String {
        switch self {
        case .single(let c): return "single-\(c.initials)"
        case .team(let u): return "team-\(u.team.id)"
        }
    }
}

/// Callup-queue sort key: ASAP first, then SOON, then `HH:MM` ascending, unknown
/// sentinels last (mirrors `board.ts:timeRank`). Applied to be-back / plan times so
/// paged controllers, teams, and plan holes interleave in one ordered list.
func timeRank(_ time: String?) -> (Int, Int) {
    switch time {
    case "ASAP": return (0, 0)
    case "SOON": return (1, 0)
    default:
        guard let time, let t = try? BasicTime(time) else { return (3, 0) }
        return (2, t.hours * 60 + t.minutes)
    }
}

/// Zero-pad a clock time for display ("9:40" → "09:40"); sentinels pass through
/// unchanged (mirrors `board.ts:displayTime` — plan times aren't pre-padded).
func displayTime(_ time: String) -> String {
    (try? BasicTime(time))?.stringValue ?? time
}
