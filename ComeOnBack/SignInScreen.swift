import SwiftUI
import OSLog

struct SignInScreen: View {
    private let logger = Logger(subsystem: Logger.subsystem, category: "SignInScreen")
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var pagingVM: PagingViewModel
    var controllers: [Controller] = []
    @State var controllersToSignIn: [Controller] = []
    let columns = Array(repeating: GridItem(.flexible()), count: 5)
    
    var body: some View {
        VStack {
            ScrollView {
                LazyVGrid(columns: columns) {
                    ForEach(controllers) { controller in
                        Text("\(controller.initials)")
                            .frame(width: 250, height: 50)
                            .background(isControllerInSignInArray(controller: controller) ? Color.red :  Color.primary.opacity(0.2))
                            .onTapGesture {
                                if isControllerInSignInArray(controller: controller) {
                                    if let index = controllersToSignIn.firstIndex(of: controller) {
                                        controllersToSignIn.remove(at: index)
                                        print(controllersToSignIn)
                                    }
                                } else {
                                    controllersToSignIn.append(controller)
                                    print(controllersToSignIn)
                                }
                               
//                                Task {
//                                    do {
//                                        try await pagingVM.signIn(controller: controller)
//                                    } catch {
//                                        logger.error("\(error)")
//                                    }
//                                }
                            }
                    }
                }
            }
            
            HStack(spacing: 200) {
                Button("CANCEL", role: .cancel, action: dismissSignInSheet)
                    .buttonStyle(.bordered)
                Button("SIGN IN", action: signInControllers)
                    .buttonStyle(.borderedProminent)
            }
            
            
            
        }
    }
    
    func signInControllers() {
        dismiss()
    }
    
    func dismissSignInSheet() {
        dismiss()
    }
    
    func isControllerInSignInArray(controller: Controller) -> Bool {
        controllersToSignIn.contains(controller)
    }
    
}

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignInScreen(controllers: [Controller(initials: "RR", area: "D", isDev: false, status: .AVAILABLE), Controller(initials: "LG", area: "D", isDev: false, status: .AVAILABLE), Controller(initials: "RR", area: "D", isDev: false, status: .AVAILABLE)])
    }
}
