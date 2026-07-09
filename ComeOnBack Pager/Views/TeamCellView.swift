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
        HStack(spacing: 16) {
            Text("TEAM")
                .font(.caption2).bold()
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(Color.accentColor.opacity(0.25))
                .cornerRadius(4)

            HStack(spacing: 4) {
                Text(unit.ojti.initials).bold()
                Text("OJTI").font(.caption2).foregroundColor(.secondary)
                Text("+")
                Text(unit.trainee.initials).bold()
                Text("TRN").font(.caption2).foregroundColor(.secondary)
            }

            if let beBack = unit.beBack {
                Text(displayTime(beBack.stringValue))
                    .frame(width: 55)
                if let forPosition = beBack.forPosition {
                    Text(forPosition).frame(width: 50)
                }
                Image(systemName: beBack.acknowledged ? "checkmark.square" : "xmark")
                    .foregroundColor(beBack.acknowledged ? .green : .red).bold()
            }

            if let plan {
                Text("plan: \(plan.position)")
                    .font(.caption).bold()
                    .foregroundColor(.orange)
            }

            Spacer()
        }
        .frame(height: 40)
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
