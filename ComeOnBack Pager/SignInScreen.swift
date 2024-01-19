import SwiftUI
import OSLog

struct SignInScreen: View {
    private let logger = Logger(subsystem: Logger.subsystem, category: "SignInScreen")
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var pagingVM: PagingViewModel
    @State var controllersToSignIn: [Controller] = []
    @State private var searchInitials = ""
    //    let columns = Array(repeating: GridItem(.adaptive(minimum: 175)), count: 1)
    let columns = [
        GridItem(.adaptive(minimum: 175))
    ]
    
    var body: some View {
        NavigationStack {  // I believe to make it "searchable" it needs to be in a nav stack.  More research needed
            VStack {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(searchResult) { controller in
                            Text("\(controller.initials)")
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(isControllerInSignInArray(controller: controller) ? Color.red :  Color.primary.opacity(0.2))
                                .cornerRadius(20)
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
                    }  // LazyVGrid
                } // Scrollview
                
                HStack(spacing: 200) {
                    Button("CANCEL", role: .cancel, action: dismissSignInSheet)
                        .buttonStyle(.bordered)
                    Button("SIGN IN", action: signInControllers)
                        .buttonStyle(.borderedProminent)
                }
            } // V Stack
            .padding(.top)
        } // Nav Stack
        .searchable(text: $searchInitials)
    }
    
    private var searchResult: [Controller] {
        if searchInitials.isEmpty {
            return pagingVM.notSignedIn.sorted(by: { $0.initials < $1.initials })
        } else {
            return pagingVM.notSignedIn.filter { $0.initials.contains(searchInitials.uppercased()) }
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
