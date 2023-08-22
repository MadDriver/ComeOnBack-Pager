import SwiftUI
import OSLog

struct AvailableCellView: View {
    
    @EnvironmentObject var pagingVM: PagingViewModel
    @Binding var controller: Controller
    
    var body: some View {
        VStack {
            //            Rectangle()
            //                .frame(width: 500, height: 5)
            
            HStack(spacing: 30) {
                Text("")
                ZStack {
                    Button {
                        Task {
                            do {
                                try await pagingVM.moveControllerToOnPosition(controller)
                            } catch {
                                Logger(subsystem: Logger.subsystem, category: "AvailableCellView").error("With controller \(controller): \(error)")
                            }
                        }
                        
                    } label: {
                        Image(systemName: "arrowshape.left")
                    }
                    
                }
                .buttonStyle(PlainButtonStyle())
//                .frame(width: 50)
                .zIndex(1)
                
                ZStack {
                    Text(controller.initials)
                        .bold()
                }
                .frame(width: 50)
                
                
                ZStack {
                    if let beBack = controller.beBack {
                        Text("\(beBack.time.description)")
                    }
                }
                .frame(width: 50)
                
                ZStack {
                    if let beBack = controller.beBack,
                       let forPosition = beBack.forPosition {
                        Text(forPosition)
                    }
                }
                .frame(width: 50)
                
                ZStack {
                    if controller.beBack != nil {
                        Image(systemName: "checkmark.square")
                            .foregroundColor(.green).bold()
                    }
                }
                .frame(width: 50)
            }
        }
    }
<<<<<<<< HEAD:ComeOnBack/Views/StripView.swift
    
    func moveControllerToOnPosition() {
        if let index = pagingVM.onBreakControllers.firstIndex(of: controller) {
            controller.beBackTime = nil
            controller.positionAssigned = nil
            controller.isPagedBack = false
            pagingVM.onPosition.append(controller)
            pagingVM.onBreakControllers.remove(at: index)
        }
    }
    
========
>>>>>>>> pullrequests/lunoho/main:ComeOnBack/Views/AvailableCellView.swift
}

struct StripView_Previews: PreviewProvider {
    static var previews: some View {
<<<<<<<< HEAD:ComeOnBack/Views/StripView.swift
        StripView(controller: .constant(Controller(firstName: "Calvin", lastName: "Shultz", initials: "RR", isPagedBack: false)))
========
        List {
            AvailableCellView(controller: Controller.mock_data[0])
            AvailableCellView(controller: Controller.mock_data[1])
            AvailableCellView(controller: Controller.mock_data[2])
        }
>>>>>>>> pullrequests/lunoho/main:ComeOnBack/Views/AvailableCellView.swift
    }
}
