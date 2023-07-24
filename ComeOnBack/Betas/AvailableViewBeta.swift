//
//  AvailableViewBeta.swift
//  ComeOnBack
//
//  Created by Calvin Shultz on 7/15/23.
//

import SwiftUI

struct AvailableViewBeta: View {
    
    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    let controllers: [Controller]
    @State var selectedControllers: [Controller] = []
    @State var signInScreenActive = false
        
    var body: some View {
        
            VStack {
                LazyVGrid(columns: columns) {
                    ForEach(controllers) { controller in
                        Text(controller.initials)
                            .frame(width: 100, height: 100)
                            .background(isSelected(controller: controller) ? Color.blue.opacity(0.2) : Color.red.opacity(0.2))
                            .onTapGesture {
                                if isSelected(controller: controller) {
                                    if let index = selectedControllers.firstIndex(of: controller) {
                                        selectedControllers.remove(at: index)
                                        print(selectedControllers)
                                    }
                                } else {
                                    selectedControllers.append(controller)
                                    print(selectedControllers)
                                }
                            }
                    }
                }
                
                Button("SUBMIT") {
                    signInScreenActive = true
                }
                .buttonBorderShape(.capsule)
                .buttonStyle(.borderedProminent)
                
                
            } // VStack
            .fullScreenCover(isPresented: $signInScreenActive) {
                SignInScreenBeta(controllers: selectedControllers)
            }
        
        
        
    } // Body
    
    func isSelected(controller: Controller) -> Bool {
        
        if selectedControllers.contains(controller) {
            return true
        }
        
        return false
    }
        
}

struct AvailableViewBeta_Previews: PreviewProvider {
    static var previews: some View {
        AvailableViewBeta(controllers: Controller.mock_data)
    }
}


