//
//  BoardColumns.swift
//  ComeOnBack Pager
//
//  One set of column metrics for the AVAILABLE board so the three row types
//  (lone controller / training team / unassigned hole) line up under a single header,
//  instead of each hand-rolling its own widths and spacing.
//
//  The controller column is capped rather than flexing to fill the row, so the
//  be-back / pos / plan / ack columns sit next to the name instead of being pushed to
//  the far edge of a 13" landscape screen.
//

import SwiftUI

enum BoardColumns {
    static let action: CGFloat = 40      // leading move affordance
    static let controllerMin: CGFloat = 120
    static let controllerMax: CGFloat = 240
    static let time: CGFloat = 84        // be-back / planned time (monospaced)
    static let position: CGFloat = 64    // for-position
    static let plan: CGFloat = 110       // "plan: XX" badge
    static let status: CGFloat = 44      // ack / phone
    static let rowHeight: CGFloat = 56
    static let spacing = Spacing.md
    /// Vertical gap between row cards.
    static let rowGap: CGFloat = 3
}

extension View {
    /// The controller column's frame, shared by the header and every row type.
    func controllerColumn() -> some View {
        frame(minWidth: BoardColumns.controllerMin, maxWidth: BoardColumns.controllerMax,
              alignment: .leading)
    }

    /// Lays a board row out as a card inside a plain `List`: no separator, the neutral
    /// tile fill, and a small gap to the next row. Replaces hairline separators, which
    /// disappear on a dark kiosk screen viewed from across the room.
    func boardRowCard() -> some View {
        listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: BoardColumns.rowGap, leading: Spacing.md,
                                      bottom: BoardColumns.rowGap, trailing: Spacing.md))
            .listRowBackground(
                RoundedRectangle(cornerRadius: Radius.card)
                    .fill(Color.tileFill)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, BoardColumns.rowGap)
            )
    }
}

/// A board side's title row: the section label plus a live count.
struct BoardSectionTitle: View {
    let title: String
    let count: Int

    var body: some View {
        HStack(spacing: Spacing.sm) {
            SectionHeader(title)
            Text("\(count)")
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(.secondary)
                .padding(.horizontal, Spacing.sm).padding(.vertical, 1)
                .background(Color.tileFill, in: Capsule())
            Spacer()
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.md)
    }
}

/// The column header shown once above the AVAILABLE list.
struct BoardColumnHeader: View {
    var body: some View {
        HStack(spacing: BoardColumns.spacing) {
            // Height pinned: a bare `Color` is vertically flexible and would stretch this
            // header to fill the column, pushing the list to the bottom of the screen.
            Color.clear.frame(width: BoardColumns.action, height: 1)
            SectionHeader("Controller").controllerColumn()
            SectionHeader("Be-back").frame(width: BoardColumns.time)
            SectionHeader("Pos").frame(width: BoardColumns.position)
            SectionHeader("Plan").frame(width: BoardColumns.plan, alignment: .leading)
            SectionHeader("Ack").frame(width: BoardColumns.status)
            Spacer(minLength: 0)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        // Row content starts at the list inset (md) plus the card's own padding (md).
        .padding(.horizontal, Spacing.md * 2)
    }
}

/// Initials over the controller's full name, sized for reading across a room.
/// The name line is omitted when the payload doesn't carry one.
struct ControllerLabel: View {
    let initials: String
    let name: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(initials)
                .font(.title3.weight(.bold))
            if let name, !name.isEmpty {
                Text(name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.7)
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
