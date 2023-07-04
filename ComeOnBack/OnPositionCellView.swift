//
//  OnPositionCellView.swift
//  ComeOnBack
//
//  Created by Calvin Shultz on 3/24/23.
//

import SwiftUI

struct OnPositionCellView: View {
    
    @EnvironmentObject var pagingVM: PagingViewModel
    var controller: Controller
    
    var body: some View {
        HStack {
            Text(controller.initials)
            Spacer()
            ZStack {
                Button {
                    withAnimation {
                        putControllerOnBreakList()
                    }
                    
                } label: {
                    Image(systemName: "arrow.right")
                    
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
        .frame(width: 200)
        //        .background(Color.red)
    }
    
    func putControllerOnBreakList() {
        if let index = pagingVM.onPosition.firstIndex(of: controller) {
            pagingVM.onBreak.append(controller)
            pagingVM.onPosition.remove(at: index)
        }
    }
    
}

struct OnPositionCellView_Previews: PreviewProvider {
    static var previews: some View {
        OnPositionCellView(controller:
                            Controller(initials: "TT",
                                       area: "",
                                       isDev: false,
                                       status: .AVAILABLE
                                      ))
    }
}
