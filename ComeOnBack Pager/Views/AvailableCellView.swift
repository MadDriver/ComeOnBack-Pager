import SwiftUI
import OSLog

struct AvailableCellView: View {
    private let logger = Logger(subsystem: Logger.subsystem, category: "AvailableCellView")
    @EnvironmentObject var pagingVM: PagingViewModel
    @State private var movingController: Bool = false
    @State private var processingPhoneTap = false
    
    var controller: Controller
    
    private var phoneColor: Color {
        if let beBack = controller.beBack {
            return beBack.acknowledged ? .green : .red
        }
        return .gray
    }
    
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
                    if let beBack = controller.beBack, controller.registered {
                        if beBack.acknowledged == true {
                            Image(systemName: "checkmark.square")
                                .foregroundColor(.green).bold()
                        } else {
                            Image(systemName: "xmark")
                                .foregroundColor(.red).bold()
                        }
                    }
                    
                }
                .frame(width: 50)
                
                ZStack {
                    if !controller.registered {
                        if processingPhoneTap {
                            ProgressView()
                        } else {
                            Image(systemName: "phone")
                                .foregroundColor(phoneColor).bold()
                                .onTapGesture {
                                    if controller.beBack != nil {
                                        processingPhoneTap = true
                                        Task {
                                            do {
                                                logger.debug("Processing phone tap ack")
                                                try await pagingVM.ackBeBack(forController: controller)
                                                processingPhoneTap = false
                                            } catch {
                                                processingPhoneTap = false
                                                logger.error("Error ackBeBack \(error)")
                                            }
                                        }
                                    }
                                } // onTapGesture
                        } // "phone" Image
                    }
                }
                .frame(width: 50)
            }
        } // VStack
        .frame(height: 40)
    } // body
}

struct StripView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            AvailableCellView(controller: Controller.mock_data[0])
            AvailableCellView(controller: Controller.mock_data[1])
//            AvailableCellView(controller: Controller.mock_data[2])
        }
    }
}
