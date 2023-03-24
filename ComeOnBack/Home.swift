//
//  Home.swift
//  ComeOnBack
//
//  Created by Calvin Shultz on 3/9/23.
//

import SwiftUI

struct Home: View {
    
    @ObservedObject var pagingVM = PagingViewModel()
    
    var body: some View {
        
        NavigationStack {
            List {
                ForEach($pagingVM.onBreakControllers) { $controller in
                    
                    NavigationLink {
                        PagingView(controller: $controller)
                    } label: {
                        StripView(controller: controller)
                    }

                }
            }
        }
        .environmentObject(pagingVM)
    }
}


struct Home_Previews: PreviewProvider {
    static var previews: some View {
        Home()
            .previewInterfaceOrientation(.landscapeLeft)
    }
}
