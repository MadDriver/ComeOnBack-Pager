<<<<<<< HEAD
//
//  OnPositionCellView.swift
//  ComeOnBack
//
//  Created by Calvin Shultz on 3/24/23.
//

import SwiftUI

struct OnPositionCellView: View {
    
=======
import SwiftUI
import OSLog

struct OnPositionCellView: View {
>>>>>>> pullrequests/lunoho/main
    @EnvironmentObject var pagingVM: PagingViewModel
    var controller: Controller
    
    var body: some View {
<<<<<<< HEAD
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
            pagingVM.onBreakControllers.append(controller)
            pagingVM.onPosition.remove(at: index)
        }
    }
    
=======
        ZStack { // ZStack for a tapGesture for the entire row
            HStack {
                Text("") // To get the underline all the way across the row
                Spacer()
                Text(controller.initials)
                Spacer()
                Image(systemName: "arrowshape.right")
            }
            .padding()
        }
        .onTapGesture {
            Task {
                do {
                    try await pagingVM.moveControllerToOnBreak(controller)
                } catch {
                    Logger(subsystem: Logger.subsystem, category: "OnPositionCellView").error("With controller \(controller): \(error)")
                }
            }
        }
    }
>>>>>>> pullrequests/lunoho/main
}

struct OnPositionCellView_Previews: PreviewProvider {
    static var previews: some View {
<<<<<<< HEAD
        OnPositionCellView(controller: MockData.controller)
=======
        VStack {
            OnPositionCellView(controller: Controller.mock_data[0])
            OnPositionCellView(controller: Controller.mock_data[1])
            OnPositionCellView(controller: Controller.mock_data[2])
        }
>>>>>>> pullrequests/lunoho/main
    }
}
