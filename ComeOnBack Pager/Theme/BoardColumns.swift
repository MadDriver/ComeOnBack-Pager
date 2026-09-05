//
//  BoardColumns.swift
//  ComeOnBack Pager
//
//  One set of column metrics for the AVAILABLE board so the three row types
//  (lone controller / training team / unassigned hole) line up under a single header,
//  instead of each hand-rolling its own widths and spacing.
//

import SwiftUI

enum BoardColumns {
    static let action: CGFloat = 34    // leading move affordance
    static let time: CGFloat = 64      // be-back / planned time (monospaced)
    static let position: CGFloat = 52  // for-position
    static let plan: CGFloat = 96      // "plan: XX" badge
    static let status: CGFloat = 40    // ack / phone
    static let rowHeight: CGFloat = 44
    static let spacing = Spacing.md
}

/// The column header shown once above the AVAILABLE list.
struct BoardColumnHeader: View {
    var body: some View {
        HStack(spacing: BoardColumns.spacing) {
            Color.clear.frame(width: BoardColumns.action)
            SectionHeader("Controller").frame(maxWidth: .infinity, alignment: .leading)
            SectionHeader("Be-back").frame(width: BoardColumns.time)
            SectionHeader("Pos").frame(width: BoardColumns.position)
            SectionHeader("Plan").frame(width: BoardColumns.plan, alignment: .leading)
            SectionHeader("Ack").frame(width: BoardColumns.status)
        }
        .padding(.horizontal, Spacing.md)
    }
}

/// The small "TEAM" tag shown on training-team rows (both board sides).
struct TeamBadge: View {
    var body: some View {
        Text("TEAM")
            .font(.caption2).bold()
            .padding(.horizontal, Spacing.sm).padding(.vertical, 2)
            .background(Color.accentColor.opacity(0.22), in: Capsule())
    }
}

/// The orange "plan: XX" badge shared by the controller and team rows.
struct PlanBadge: View {
    let position: String
    var body: some View {
        Text("plan: \(position)")
            .font(.caption).bold()
            .foregroundColor(.pendingOrange)
            .lineLimit(1).minimumScaleFactor(0.7)
    }
}

/// Acknowledgement indicator shared by the controller + team rows: green when the
/// be-back is acknowledged, orange (pending) when it isn't — never red, which is
/// reserved for genuine danger.
struct AckIcon: View {
    let acknowledged: Bool
    var body: some View {
        Image(systemName: acknowledged ? "checkmark.circle.fill" : "clock.fill")
            .foregroundColor(acknowledged ? .ackGreen : .pendingOrange)
            .fontWeight(.semibold)
    }
}
