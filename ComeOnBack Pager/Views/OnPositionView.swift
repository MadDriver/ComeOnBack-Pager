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
        VStack {
            Text("ON POSITION")
                .fontWeight(.heavy)
            List {
                if items.isEmpty {
                    EmptyControllerView()
                }
                ForEach(items) { item in
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
            }
        }
    }
}

/// A team plugged in together, shown as one on-position row. The left column is
/// narrow (33% of the board), so the label scales down rather than truncating.
struct OnPositionTeamCellView: View {
    var unit: TeamUnit
    var body: some View {
        HStack(spacing: 8) {
            Text(unit.ojti.atTime?.relative() ?? "")
                .font(.caption).foregroundColor(.secondary)
            Text("TEAM").font(.caption2).bold()
                .padding(.horizontal, 5).padding(.vertical, 1)
                .background(Color.accentColor.opacity(0.25)).cornerRadius(4)
            Text(unit.label).bold()
                .lineLimit(1).minimumScaleFactor(0.6)
            Spacer(minLength: 4)
            Image(systemName: "arrowshape.right")
        }
        .padding()
        .frame(height: 40)
    }
}

struct OnPositionView_Previews: PreviewProvider {
    static var previews: some View {
        OnPositionView(items: Controller.mock_data.map { .single($0) })
            .environmentObject(PagingViewModel.preview)
    }
}
