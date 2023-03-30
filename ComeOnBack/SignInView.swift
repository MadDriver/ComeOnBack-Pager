//
//  SignInView.swift
//  ComeOnBack
//
//  Created by Calvin Shultz on 3/24/23.
//

import SwiftUI

struct SignInView: View {
    
    @EnvironmentObject var pagingVM: PagingViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            List {
                ForEach(pagingVM.totalControllerList) { controller in
                    Text("\(controller.firstName) \(controller.lastName) - \(controller.initials)")
                        .onTapGesture {
                            pagingVM.onBreakControllers.append(controller)
                            dismiss()
                        }
                }
            }
                
        }
        .frame(width: 300)
    }
}

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView()
    }
}
