//
//  HoleCellView.swift
//  ComeOnBack Pager
//
//  An unassigned planned-position "hole" on the AVAILABLE (right) side —
//  "LC2 @ 09:40 — unassigned". Tapping (via its NavigationLink) opens the assign
//  modal. Mirrors the dashed warning row in the web console's `BoardRow.svelte`.
//

import SwiftUI

struct HoleCellView: View {
    var plan: PlannedPosition

    var body: some View {
        HStack(spacing: BoardColumns.spacing) {
            Image(systemName: "calendar.badge.clock")
                .foregroundColor(.pendingOrange)
                .frame(width: BoardColumns.action)

            Text(plan.position)
                .font(.title3).bold()
                .lineLimit(1).minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(displayTime(plan.time))
                .font(.body.monospacedDigit())
                .frame(width: BoardColumns.time)

            Text("UNASSIGNED")
                .font(.caption).bold()
                .foregroundColor(.pendingOrange)
                .padding(.horizontal, Spacing.sm).padding(.vertical, 3)
                .overlay(Capsule().stroke(Color.pendingOrange, lineWidth: 1))
                .frame(width: BoardColumns.position + BoardColumns.plan + BoardColumns.status + BoardColumns.spacing * 2,
                       alignment: .trailing)
        }
        .frame(height: BoardColumns.rowHeight)
    }
}

struct HoleCellView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            HoleCellView(plan: PlannedPosition(
                id: 1, position: "LC2", time: "09:40",
                status: "planned", controllerInitials: nil, teamId: nil
            ))
        }
    }
}
