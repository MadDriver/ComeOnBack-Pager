import SwiftUI
import OSLog

struct SignInScreen: View {
    private let logger = Logger(subsystem: Logger.subsystem, category: "SignInScreen")
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var pagingVM: PagingViewModel
    @State var controllersToSignIn: [Controller] = []
    let columns = Array(repeating: GridItem(.flexible()), count: 5)
    
    var body: some View {
        VStack {
            ScrollView {
                LazyVGrid(columns: columns) {
                    ForEach(pagingVM.allControllers.sorted(by: { $0.initials < $1.initials })) { controller in
                        Text("\(controller.initials)")
                            .frame(width: 250, height: 50)
                            .background(isControllerInSignInArray(controller: controller) ? Color.red :  Color.primary.opacity(0.2))
                            .onTapGesture {
                                if isControllerInSignInArray(controller: controller) {
                                    if let index = controllersToSignIn.firstIndex(of: controller) {
                                        controllersToSignIn.remove(at: index)
                                        logger.info("Signing in (\(controllersToSignIn) ")
                                    }
                                } else {
                                    controllersToSignIn.append(controller)
                                    logger.info("Signing in (\(controllersToSignIn) ")
                                }
                               
                                
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
        Task {
            do {
                try await pagingVM.signIn(controllers: controllersToSignIn)
            } catch {
                logger.error("\(error)")
            }
        }
        
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
        SignInScreen()
            .environmentObject(PagingViewModel())
    }
}
