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
        HStack(spacing: 12) {
            Image(systemName: "calendar.badge.clock")
                .foregroundColor(.orange)
            Text(plan.position)
                .font(.title3).bold()
            Text("@ \(displayTime(plan.time))")
            Spacer()
            Text("UNASSIGNED")
                .font(.caption).bold()
                .foregroundColor(.orange)
                .padding(.horizontal, 8).padding(.vertical, 3)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.orange, lineWidth: 1))
        }
        .frame(height: 40)
        .padding(.horizontal, 6)
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
