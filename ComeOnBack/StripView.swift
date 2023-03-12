//
//  StripView.swift
//  ComeOnBack
//
//  Created by Calvin Shultz on 3/10/23.
//

import SwiftUI

struct StripView: View {
    
    var controller: Controller
    @Binding var isPagingViewShowing: Bool
    @Binding var controllerToEdit: Controller
    
    var body: some View {
        VStack {
            Rectangle()
                .frame(width: 300, height: 5)
            
            HStack(spacing: 30) {
                
                Button {
                    isPagingViewShowing = true
                    controllerToEdit = controller
                } label: {
                    Text("PAGE")
                }
                .buttonStyle(.borderedProminent)

                
                Text(controller.initials)
                    .bold()
                
                Text("\(controller.beBackTime)")
                
                Text(controller.positionAssigned ?? "    ")
                
                if controller.isPagedBack {
                    Image(systemName: "checkmark.square")
                        .foregroundColor(.green).bold()
                }
                
                
            }
            
            Rectangle()
                .frame(width: 300, height: 5)
        }
    }
    
}

struct StripView_Previews: PreviewProvider {
    static var previews: some View {
        StripView(controller: Controller(initials: "RR", beBackTime: 35, isPagedBack: true), isPagingViewShowing: .constant(false), controllerToEdit: .constant(Controller(initials: "RR", beBackTime: 35, isPagedBack: true)))
    }
}
