//
//  StripView.swift
//  ComeOnBack
//
//  Created by Calvin Shultz on 3/10/23.
//

import SwiftUI

struct StripView: View {
    
    var controller: Controller
    
    var body: some View {
        VStack {
            Rectangle()
                .frame(width: 500, height: 5)
            
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
                        print(controller.initials)
                    } label: {
                        Image(systemName: "pencil")
                    }
                        
                }
                .buttonStyle(PlainButtonStyle())
                .frame(width: 50)
                .zIndex(1)
                
               
                
                
            }
            
            Rectangle()
                .frame(width: 500, height: 5)
        }
    }
}

struct StripView_Previews: PreviewProvider {
    static var previews: some View {
        StripView(controller: Controller(initials: "RR", beBackTime: "35", isPagedBack: true))
    }
}
