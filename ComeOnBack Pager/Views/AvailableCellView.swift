import SwiftUI
import OSLog

struct AvailableCellView: View {
    private let logger = Logger(subsystem: Logger.subsystem, category: "AvailableCellView")
    @EnvironmentObject var pagingVM: PagingViewModel
    @State private var movingController: Bool = false
    @State private var phoneColor: Color = .gray
    var controller: Controller
    
    var body: some View {
        VStack {
            HStack(spacing: 30) {
                Text("")
                ZStack {
                    Button {
                        if (movingController) { return }
                        movingController = true
                        Task {
                            do {
                                try await pagingVM.moveControllerToOnPosition(controller)
                                await MainActor.run { movingController = false }
                            } catch {
                                await MainActor.run { movingController = false }
                                logger.error("With controller \(controller): \(error)")
                            }
                        }
                        
                    } label: {
                        if movingController {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        } else {
                            Image(systemName: "arrowshape.left")
                                .disabled(movingController)
                        }
                        
                    }
                    
                }
                .buttonStyle(PlainButtonStyle())
                .zIndex(1)
                
                ZStack {
                    Text(controller.initials)
                        .bold()
                }
                .frame(width: 50)
                
                
                ZStack {
                    if let beBack = controller.beBack {
                        Text("\(beBack.stringValue)")
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
                    if controller.beBack?.acknowledged == true {
                        Image(systemName: "checkmark.square")
                            .foregroundColor(.green).bold()
                    }
                }
                .frame(width: 50)
                
                ZStack {
                    if let registered = controller.registered, !registered {
                        Image(systemName: "phone")
                            .foregroundColor(phoneColor).bold()
                            .onTapGesture {
                                if let beBack = controller.beBack {
                                    logger.debug("Phone tapped!")
                                }
                            }
                    }
                }
                .frame(width: 50)
            }
        } // VStack
        .frame(height: 40)
        .onAppear {
            if let beBack = controller.beBack {
                phoneColor = beBack.acknowledged ? .green : .red
            }
        }
    } // body
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
