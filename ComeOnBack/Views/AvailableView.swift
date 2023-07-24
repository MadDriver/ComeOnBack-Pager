//
//  AvailableView.swift
//  ComeOnBack
//
//  Created by user on 7/4/23.
//

import SwiftUI

struct AvailableView: View {
    var controllerList: [Controller]
    let columns = [GridItem(.flexible())]
    var body: some View {
        
        
        VStack {

            List {
                ForEach(controllerList) { controller in
                    NavigationLink {
                        PagingView(controller: controller)
                    } label: {
                        AvailableCellView(controller: controller)

                    }
                    .buttonStyle(PlainButtonStyle())
                }
            } // List
        }
    }
}

struct AvailableView_Previews: PreviewProvider {
    
    static var previews: some View {
        AvailableView(controllerList: Controller.mock_data)
    }
}
