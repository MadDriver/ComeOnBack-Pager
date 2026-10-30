//
//  OnPositionView.swift
//  ComeOnBack
//
//  Created by user on 7/4/23.
//
//  The ON POSITION (left) side: current reality only. Lone controllers tap straight
//  to "move off"; a team plugged in together (both members ON_POSITION) collapses to
//  one row that opens the team modal (move off / split).
//

import SwiftUI

struct OnPositionView: View {
    var items: [OnPositionRow]
    var body: some View {
        VStack(spacing: Spacing.sm) {
            BoardSectionTitle(title: "On position", count: items.count)

            if items.isEmpty {
                EmptyControllerView(message: "No one on position")
            } else {
                List {
                    ForEach(items) { item in
                        Group {
                            switch item {
                            case .single(let controller):
                                OnPositionCellView(controller: controller)
                            case .team(let unit):
                                NavigationLink {
                                    PagingView(target: .team(unit))
                                } label: {
                                    OnPositionTeamCellView(unit: unit)
                                }
                            }
                        }
                        .boardRowCard()
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

/// A team plugged in together, shown as one on-position row: the pair leading, time on
/// position under it, and the move-off affordance trailing — the same shape as a lone
/// controller's row.
struct OnPositionTeamCellView: View {
    var unit: TeamUnit
    var body: some View {
        HStack(spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: Spacing.sm) {
                    Text(unit.label).font(.title3.weight(.bold))
                        .lineLimit(1).minimumScaleFactor(0.6)
                    TeamBadge()
                }
                Text(unit.ojti.atTime?.relative() ?? "")
                    .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
            }
            Spacer(minLength: Spacing.xs)
            Image(systemName: "arrowshape.right")
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, Spacing.md)
        .frame(height: BoardColumns.rowHeight)
    }
}

#if DEBUG
struct OnPositionView_Previews: PreviewProvider {
    static var previews: some View {
        OnPositionView(items: Controller.mock_data.map { .single($0) })
            .environmentObject(PagingViewModel.preview)
    }
}
#endif
