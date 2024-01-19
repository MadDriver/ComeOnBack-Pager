//
//  AvailableView.swift
//  ComeOnBack
//
//  Created by user on 7/4/23.
//

import SwiftUI

struct AvailableView: View {
    var newlySignedIn: [Controller]
    var onBreak: [Controller]
    
    
    var body: some View {
        
        VStack {
            
            if !newlySignedIn.isEmpty {
                Text("Signed In")
                    .fontWeight(.heavy)
                List {
                    ForEach(newlySignedIn) { controller in
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
            if onBreak.isEmpty && newlySignedIn.isEmpty {
                EmptyControllerView()
            }
            List {
                ForEach(onBreak) { controller in
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
        AvailableView( newlySignedIn: [], onBreak: Controller.mock_data)
    }
}
