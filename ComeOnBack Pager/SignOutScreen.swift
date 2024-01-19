//
//  SignOutView.swift
//  ComeOnBack
//
//  Created by Calvin Shultz on 7/9/23.
//

import SwiftUI
import OSLog

struct SignOutScreen: View {
    
    private let logger = Logger(subsystem: Logger.subsystem, category: "SignOutScreen")
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var pagingVM: PagingViewModel
    let columns = Array(repeating: GridItem(.flexible()), count: 2)
    @State var controllersToSignOut: [Controller] = []
    
    var body: some View {
        VStack {
            ScrollView {
                LazyVGrid(columns: columns) {
                    ForEach(pagingVM.onBreak) { controller in
                        Text("\(controller.initials)")
                            .frame(width: 250, height: 50)
                            .background(controllerIsInSignOutArray(controller: controller) ? Color.red : Color.primary.opacity(0.5))
                            .onTapGesture {
                                if controllerIsInSignOutArray(controller: controller) {
                                    if let index = controllersToSignOut.firstIndex(of: controller) {
                                        controllersToSignOut.remove(at: index)
                                    }
                                } else {
                                    controllersToSignOut.append(controller)
                                    logger.info("Signing out (\(controllersToSignOut) ")
                                }
                            }
                    }
                }
            }
            
            HStack(spacing: 200) {
                Button("CANCEL", role: .cancel, action: dismissSignOutSheet)
                    .buttonStyle(.bordered)
                Button("SIGN OUT", action: signOutControllers)
                    .buttonStyle(.borderedProminent)
            }
            
        } // VStack
    } // Body
    
    func dismissSignOutSheet() {
        dismiss()
    }
    
    func signOutControllers() {
        Task {
            do {
                try await pagingVM.signOut(controllers: controllersToSignOut)
            } catch {
                logger.error("\(error)")
            }
        }
        
        dismiss()
    }
    
    func controllerIsInSignOutArray(controller: Controller) -> Bool {
        controllersToSignOut.contains(controller)
    }
    
}

struct SignOutView_Previews: PreviewProvider {
    static var previews: some View {
        SignOutScreen()
    }
}
