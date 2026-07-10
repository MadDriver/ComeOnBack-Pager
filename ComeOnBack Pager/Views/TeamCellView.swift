//
//  TeamCellView.swift
//  ComeOnBack Pager
//
//  A training-team row on the AVAILABLE (right) side: the paired OJTI + trainee shown
//  as one unit, with the shared be-back (time / for-position / acknowledged) and any
//  planned position it fills. Tapping the row (via its NavigationLink) opens the team
//  page modal. Mirrors the web console's team row in `BoardRow.svelte`.
//

import SwiftUI

struct TeamCellView: View {
    var unit: TeamUnit
    /// The planned position this team's be-back fills, if any.
    var plan: PlannedPosition? = nil

    var body: some View {
        HStack(spacing: BoardColumns.spacing) {
            Color.clear.frame(width: BoardColumns.action)

            HStack(spacing: Spacing.sm) {
                TeamBadge()
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(unit.ojti.initials).fontWeight(.semibold)
                    Text("OJTI").font(.caption2).foregroundColor(.secondary).baselineOffset(4)
                    Text("+").foregroundColor(.secondary)
                    Text(unit.trainee.initials).fontWeight(.semibold)
                    Text("TRN").font(.caption2).foregroundColor(.secondary).baselineOffset(4)
                }
                .lineLimit(1).minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Group {
                if let beBack = unit.beBack { Text(displayTime(beBack.stringValue)) }
            }
            .font(.body.monospacedDigit())
            .frame(width: BoardColumns.time)

            Group {
                if let forPosition = unit.beBack?.forPosition { Text(forPosition) }
            }
            .frame(width: BoardColumns.position)

            Group {
                if let plan { PlanBadge(position: plan.position) }
            }
            .frame(width: BoardColumns.plan, alignment: .leading)

            Group {
                if let beBack = unit.beBack { AckIcon(acknowledged: beBack.acknowledged) }
            }
            .frame(width: BoardColumns.status)
        }
        .frame(height: BoardColumns.rowHeight)
    }
}

struct TeamCellView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            TeamCellView(unit: TeamUnit(
                team: TrainingTeam(id: 1, ojti: "AA", trainee: "BB"),
                ojti: Controller.mock_data[0],
                trainee: Controller.mock_data[1]
            ))
        }
    }
}
