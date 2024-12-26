import SwiftUI
import OSLog

struct SignInScreen: View {
    private let logger = Logger(subsystem: Logger.subsystem, category: "SignInScreen")
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var pagingVM: PagingViewModel
    @State var controllersToSignIn: [Controller] = []
    @State private var searchInitials = ""
    @State private var filteredArea: Area? = nil
    let columns = [
        GridItem(.adaptive(minimum: 175))
    ]
    
    private func areaFilter(_ controller: Controller) -> Bool {
        guard let filteredArea = filteredArea else {
            // If filteredArea is nil, include all
            return true
        }
        return controller.areaString == filteredArea.name
    }
    
    private func searchFilter(_ controller: Controller) -> Bool {
        if searchInitials == "" {
            return true
        }
        return controller.initials.contains(searchInitials.uppercased())
    }
    
    private var controllers: [Controller] {
        return pagingVM.notSignedIn
            .filter(searchFilter)
            .filter(areaFilter)
            .sorted(by: { $0.initials < $1.initials })
    }
    
    var body: some View {
        NavigationStack {  // I believe to make it "searchable" it needs to be in a nav stack.  More research needed
            VStack {
                if let facility = pagingVM.facility {
                    if facility.areas.count > 1 {
                        HStack {
                            Picker("Select Area", selection: $filteredArea) {
                                ForEach(facility.areas) { area in
                                    Text("\(area.name)")
                                        .tag(area as Area?)
                                }
                            }
                            .pickerStyle(.segmented)
                            
                            Button("Clear") { filteredArea = nil }
                        } //HStack
                    } // if facility.areas.count > 1
                } // facility = pagingVM.facility
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(controllers) { controller in
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
        .task {
            try? await pagingVM.updateAllControllers()
        }
    }
    
    func signInControllers() {
        Task {
            do {
                // Remove any controllers that are in controllersToSignIn
                // but are not visible due to another filter
                controllersToSignIn = controllersToSignIn.filter { controller in
                    controllers.contains { $0 == controller }
                }
                
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
