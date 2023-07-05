import SwiftUI

struct AvailableCellView: View {
    
    @EnvironmentObject var pagingVM: PagingViewModel
    var controller: Controller
    
    var body: some View {
        VStack {
            //            Rectangle()
            //                .frame(width: 500, height: 5)
            
            HStack(spacing: 30) {
                Text("")
                ZStack {
                    Button {
                        withAnimation {
                            pagingVM.moveControllerToOnPosition(controller)
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
}

struct StripView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            AvailableCellView(controller: Controller.mock_data[0])
            AvailableCellView(controller: Controller.mock_data[1])
            AvailableCellView(controller: Controller.mock_data[2])
        }
    }
}
