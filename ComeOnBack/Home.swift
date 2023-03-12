//
//  Home.swift
//  ComeOnBack
//
//  Created by Calvin Shultz on 3/9/23.
//

import SwiftUI

struct Home: View {
    
    @State var onBreak: [Controller] = [
        Controller(initials: "RR", beBackTime: 25, isPagedBack: false),
        Controller(initials: "XO", beBackTime: 25, isPagedBack: false),
        Controller(initials: "LG", beBackTime: 25, isPagedBack: false),
        Controller(initials: "PZ", beBackTime: 25, isPagedBack: false),
        Controller(initials: "MG", beBackTime: 25, isPagedBack: false),
        Controller(initials: "DF", beBackTime: 25, isPagedBack: false),
        Controller(initials: "VV", beBackTime: 25, isPagedBack: false),
        
    
    ]
    
    @State var onPosition = [
        "AS", "TR", "HY", "BS", "VM"
    ]
    
    
    var body: some View {
        VStack {
            HStack {
                List {
                    ForEach(onPosition, id: \.self) { initials in
                        Text(initials)
                            
                    }
                }
                
                List {
                    ForEach(onBreak) { controller in
                        StripView(controller: controller)
                    }
                    .listRowSeparator(.hidden)
                }

            } // Hstack
            
            Button {
//                signIn()
            } label: {
                Text("SIGN IN")
            }

            
        }  // Vstack
    }
    
//    func signIn() {
//        let initials = "BB"
//        if onBreak.contains(initials) { return }
//        if onPosition.contains(initials) { return }
//        onBreak.append(initials)
//
//    }
//
//    func swapToOnPosition(initials: String) {
//        if let index = onBreak.firstIndex(of: initials) {
//            onBreak.remove(at: index)
//            onPosition.append(initials)
//        }
//    }
//
//    func swapToOnBreak(initials: String) {
//        if let index = onPosition.firstIndex(of: initials) {
//            onPosition.remove(at: index)
//            onBreak.append(initials)
//        }
//    }
    
}

struct Home_Previews: PreviewProvider {
    static var previews: some View {
        Home()
            .previewInterfaceOrientation(.landscapeLeft)
    }
}
