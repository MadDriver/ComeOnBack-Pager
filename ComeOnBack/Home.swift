//
//  Home.swift
//  ComeOnBack
//
//  Created by Calvin Shultz on 3/9/23.
//

import SwiftUI

struct Home: View {
    
    @StateObject var pagingVM = PagingViewModel()
    
    var body: some View {
        
        NavigationStack(path: $pagingVM.path) {
            VStack {
                HStack {
                    
                    List {
                        ForEach(pagingVM.onPosition) { controller in
                            Text(controller.initials)
                        }
                    }
                    
                    List {
                        ForEach($pagingVM.onBreakControllers) { $controller in
                            
                            NavigationLink(value: controller) {
                                StripView(controller: controller)
                            }
                            .navigationDestination(for: Controller.self) { controller in
                                PagingView(pagingVM: pagingVM, controller: $controller)
                            }
                        }
                    }
                }
                
            }
        }
    }
}


struct Home_Previews: PreviewProvider {
    static var previews: some View {
        Home()
            .previewInterfaceOrientation(.landscapeLeft)
    }
}
