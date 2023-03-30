//
//  SignInView.swift
//  ComeOnBack
//
//  Created by Calvin Shultz on 3/24/23.
//

import SwiftUI

struct SignInView: View {
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var pagingVM: PagingViewModel
    @State var sortedControllerList: [Controller] = []
    let columns = Array(repeating: GridItem(.flexible()), count: 5)
    
    var body: some View {
        VStack {
            ScrollView {
                LazyVGrid(columns: columns) {
                    ForEach(sortedControllerList) { controller in
                        Text("\(controller.firstName) \(controller.lastName) - \(controller.initials)")
                            .frame(width: 250, height: 50)
                            .background(Color.black.opacity(0.2))
                            .onTapGesture {
                                pagingVM.onBreakControllers.append(controller)
                                dismiss()
                            }
                    }
                }
            }
            
            Button("CANCEL", action: dismissSignInSheet)
                .buttonStyle(.borderedProminent)
            
        }
        .onAppear {
            sortedControllerList = pagingVM.totalControllerList.sorted(by: {
                $0.lastName < $1.lastName
            })
        }
    }
    
    func dismissSignInSheet() {
        dismiss()
    }
    
}

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView()
    }
}
