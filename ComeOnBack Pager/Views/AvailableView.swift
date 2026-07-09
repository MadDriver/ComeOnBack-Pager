//
//  AvailableView.swift
//  ComeOnBack
//
//  Created by user on 7/4/23.
//
//  The AVAILABLE (right) side: the interleaved callup queue + available roster from
//  `PagingViewModel.availableItems` — lone controllers, training teams, and unassigned
//  planned-position holes. Tapping a controller/team opens the page modal; tapping a
//  hole opens the assign modal.
//

import SwiftUI

struct AvailableView: View {
    @EnvironmentObject var pagingVM: PagingViewModel

    var body: some View {
        VStack {
            Text("AVAILABLE")
                .fontWeight(.heavy)
            if pagingVM.availableItems.isEmpty {
                EmptyControllerView()
            }
            List {
                ForEach(pagingVM.availableItems) { item in
                    switch item {
                    case .single(let controller, let plan):
                        NavigationLink {
                            PagingView(target: .controller(controller))
                        } label: {
                            AvailableCellView(controller: controller, plan: plan)
                        }
                    case .team(let unit, let plan):
                        NavigationLink {
                            PagingView(target: .team(unit))
                        } label: {
                            TeamCellView(unit: unit, plan: plan)
                        }
                    case .hole(let plan):
                        NavigationLink {
                            AssignPlanView(plan: plan)
                        } label: {
                            HoleCellView(plan: plan)
                        }
                    }
                }
            } // List
        }
    }
}

struct AvailableView_Previews: PreviewProvider {
    static var previews: some View {
        AvailableView()
            .environmentObject(PagingViewModel.preview)
    }
}
