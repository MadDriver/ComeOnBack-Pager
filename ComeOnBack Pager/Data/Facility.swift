//
//  Facility.swift
//  ComeOnBack Pager
//
//  The v3 `GET /api/v3/{facility}` payload: the full roster nested in
//  `areas[].controllers` (not-signed-in controllers included, as `NOT_SIGNED_IN`),
//  plus training teams and planned positions. One fetch replaces v1's split
//  `getFacility()` + `getSignedInControllers()`.
//

import Foundation

struct Facility {
    var name: String
    var lat: Double?
    var lon: Double?
    var areas: [Area]
    /// Parsed for R1; the board consumes these in R2 (canned messages / teams /
    /// planned positions).
    var trainingTeams: [TrainingTeam]
    var plannedPositions: [PlannedPosition]
}

extension Facility: Decodable {
    enum CodingKeys: String, CodingKey {
        case name, lat, lon, areas, trainingTeams, plannedPositions
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = (try? c.decode(String.self, forKey: .name)) ?? ""
        lat = try? c.decode(Double.self, forKey: .lat)
        lon = try? c.decode(Double.self, forKey: .lon)
        areas = (try? c.decode(LossyArray<Area>.self, forKey: .areas))?.elements ?? []
        trainingTeams = (try? c.decode(LossyArray<TrainingTeam>.self, forKey: .trainingTeams))?.elements ?? []
        plannedPositions = (try? c.decode(LossyArray<PlannedPosition>.self, forKey: .plannedPositions))?.elements ?? []
    }
}

extension Facility {
    func getArea(forController controller: Controller) -> Area? {
        return areas.first { area in
            area.name == controller.areaString
        }
    }

    var allControllers: [Controller] {
        return self.areas.flatMap { $0.controllers }
    }
}
