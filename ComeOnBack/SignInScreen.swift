//
//  SignInView.swift
//  ComeOnBack
//
//  Created by Calvin Shultz on 3/24/23.
//

import SwiftUI

struct SignInScreen: View {
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var pagingVM: PagingViewModel
    var controllers: [Controller] = []
    let columns = Array(repeating: GridItem(.flexible()), count: 5)
    
    var body: some View {
        VStack {
            ScrollView {
                LazyVGrid(columns: columns) {
                    ForEach(controllers) { controller in
                        Text("\(controller.initials)")
                            .frame(width: 250, height: 50)
                            .background(Color.black.opacity(0.2))
                            .onTapGesture {
                                // TODO: Sign In
                            }
                    }
                }
            }
            
            Button("CANCEL", action: dismissSignInSheet)
                .buttonStyle(.borderedProminent)
            
        }
    }
    
    func dismissSignInSheet() {
        dismiss()
    }
    
}

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignInScreen()
    }
}
