//
//  TrainingTeam.swift
//  ComeOnBack Pager
//
//  A paired OJTI + trainee, from `GET /api/v3/{fac}`'s `trainingTeams`. Decoded for
//  R1; the board pairs/splits/pages teams in R2.
//

import Foundation

struct TrainingTeam: Identifiable, Hashable, Decodable {
    let id: Int
    /// OJTI's initials.
    let ojti: String
    /// Trainee's initials.
    let trainee: String
}
