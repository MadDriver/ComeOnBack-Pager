//
//  StripView.swift
//  ComeOnBack
//
//  Created by Calvin Shultz on 3/10/23.
//

import SwiftUI

struct StripView: View {
    
    @EnvironmentObject var pagingVM: PagingViewModel
    var controller: Controller
    
    var body: some View {
        VStack {
//            Rectangle()
//                .frame(width: 500, height: 5)
            
            HStack(spacing: 30) {
                
                ZStack {
                    Text(controller.initials)
                        .bold()
                }
                .frame(width: 50)
                
                
                ZStack {
                    if let beBackTime = controller.beBackTime {
                        Text("\(beBackTime)")
                    }
                }
                .frame(width: 50)
                
                ZStack {
                    if let position = controller.positionAssigned {
                        Text(position)
                    }
                }
                .frame(width: 50)
                
                ZStack {
                    if controller.isPagedBack {
                        Image(systemName: "checkmark.square")
                            .foregroundColor(.green).bold()
                    }
                }
                .frame(width: 50)
                
                ZStack {
                    Button {
                        withAnimation {
                            moveControllerToOnPosition()
                        }
                        
                    } label: {
                        Image(systemName: "rectangle.2.swap")
                    }
                        
                }
                .buttonStyle(PlainButtonStyle())
                .frame(width: 50)
                .zIndex(1)
                
               
                
                
            }
            
//            Rectangle()
//                .frame(width: 500, height: 5)
        }
    }
    
    func moveControllerToOnPosition() {
        if let index = pagingVM.onBreakControllers.firstIndex(of: controller) {
            pagingVM.onPosition.append(controller)
            pagingVM.onBreakControllers.remove(at: index)
        }
    }
    
}

struct StripView_Previews: PreviewProvider {
    static var previews: some View {
        StripView(controller: Controller(initials: "RR", beBackTime: "35", isPagedBack: true))
    }
}
