//
//  PlannedPosition.swift
//  ComeOnBack Pager
//
//  A scheduled position assignment, from `GET /api/v3/{fac}`'s `plannedPositions`.
//  Decoded for R1; the board renders / assigns / creates these in R2.
//

import Foundation

struct PlannedPosition: Identifiable, Hashable, Decodable {
    let id: Int
    let position: String
    /// `HH:MM` or a sentinel — rendered as-is (parse leniently in R2).
    let time: String
    /// `planned` | `paged`.
    let status: String
    let controllerInitials: String?
    let teamId: Int?
}
