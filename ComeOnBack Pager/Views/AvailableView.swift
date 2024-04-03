//
//  AvailableView.swift
//  ComeOnBack
//
//  Created by user on 7/4/23.
//

import SwiftUI

struct AvailableView: View {
    @EnvironmentObject var pagingVM: PagingViewModel
    
    var body: some View {
        VStack {
            if !pagingVM.newlySignedIn.isEmpty {
                Text("Signed In")
                    .fontWeight(.heavy)
                List {
                    ForEach(pagingVM.newlySignedIn) { controller in
                        NavigationLink {
                            PagingView(controller: controller)
                        } label: {
                            AvailableCellView(controller: controller)
                        }
                    }
                } // List
            }
            
            Text("AVAILABLE")
                .fontWeight(.heavy)
            if pagingVM.onBreak.isEmpty && pagingVM.newlySignedIn.isEmpty {
                EmptyControllerView()
            }
            List {
                ForEach(pagingVM.onBreak, id: \.id) { controller in
                    NavigationLink {
                        PagingView(controller: controller)
                    } label: {
                        AvailableCellView(controller: controller)
                    }
                }
            } // List
        }
    }
}

struct AvailableView_Previews: PreviewProvider {
    static var previews: some View {
        AvailableView()
    }
}
