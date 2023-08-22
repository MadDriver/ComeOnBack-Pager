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
               
                List {
                    ForEach(controllers) { controller in
                        AvailableCellBeta(controller: controller)
                            .overlay {
                                if isSelected(controller: controller) {
                                    Color.red.opacity(0.2)
                                }
                            }
                            .onTapGesture {
                                if isSelected(controller: controller) {
                                    if let index = selectedControllers.firstIndex(of: controller) {
                                        selectedControllers.remove(at: index)
                                    }
                                    
                                } else {
                                    selectedControllers.append(controller)
                                }
                            }
                    }
                } // List
                .frame(maxWidth: .infinity)

                
                Button("SUBMIT") {
                    signInScreenActive = true
                }
                .buttonBorderShape(.capsule)
                .buttonStyle(.borderedProminent)
                
                
            } // VStack
//            .fullScreenCover(isPresented: $signInScreenActive) {
//                SignInScreenBeta(controllers: selectedControllers)
//            }
        
        
        
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


