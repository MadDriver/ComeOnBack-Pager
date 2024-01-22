//
//  SignOutView.swift
//  ComeOnBack
//
//  Created by Calvin Shultz on 7/9/23.
//

import SwiftUI
import OSLog

struct SignOutScreen: View {
    
    enum SignOutFilterOptions: String, CaseIterable, Identifiable {
        case all = "All Controllers"
        case onBreak = "On Break Only"
        var id: Self { self }
    }
    
    enum SignOutSortOptions: String, CaseIterable, Identifiable {
        case alpha = "A-Z"
        case time = "Sign On Time"
        var id: Self { self }
        
    }
    
    private let logger = Logger(subsystem: Logger.subsystem, category: "SignOutScreen")
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var pagingVM: PagingViewModel
    @State var controllersToSignOut: [Controller] = []
    
    @State var selectedSignOutFilterOption: SignOutFilterOptions = .all
    @State var selectedSignOutSortOption: SignOutSortOptions = .time
    
    private func sortedBySignIn(lhs: Controller, rhs: Controller) -> Bool {
        guard let lhsTime = lhs.signInTime, let rhsTime = rhs.signInTime else {
            logger.error("Could not sort controllers without signInTime")
            return false
        }
        return lhsTime < rhsTime
    }
    
    private func sortedByInitials(lhs: Controller, rhs: Controller) -> Bool {
        return lhs.initials < rhs.initials
    }
    
    private var selectedSortingMethod: (Controller, Controller) -> Bool {
        switch selectedSignOutSortOption {
        case .alpha:
            return sortedByInitials
        case .time:
            return sortedBySignIn
        }
    }
    
    var controllers: [Controller] {
        switch selectedSignOutFilterOption {
        case .all:
            return pagingVM.signedIn.sorted(by: selectedSortingMethod)
        case .onBreak:
            return (pagingVM.onBreak + pagingVM.newelySignedIn).sorted(by: selectedSortingMethod)
        }
    }
    
    
    var body: some View {
        VStack {
            Picker("", selection: $selectedSignOutFilterOption) {
                ForEach (SignOutFilterOptions.allCases) { option in
                    Text("\(option.rawValue)")
                }
            }.pickerStyle(.segmented)
            
            Picker("", selection: $selectedSignOutSortOption) {
                ForEach (SignOutSortOptions.allCases) { option in
                    Text("\(option.rawValue)")
                }
            }.pickerStyle(.segmented)
            
            HStack {
                Spacer()
                Button("Select All") {
                    controllersToSignOut = controllers
                }
                Spacer()
                Button("Select None") {
                    controllersToSignOut = []
                }
                Spacer()
            } // HStack
            
            ScrollView {
                ForEach(controllers) { controller in
                    let signInTime = controller.signInTime?.relative() ?? ""
                    Text("\(controller.initials) - \(signInTime)")
                        .frame(width: 250, height: 50)
                        .background(controllerIsInSignOutArray(controller: controller) ? Color.red : Color.primary.opacity(0.5))
                        .onTapGesture {
                            if controllerIsInSignOutArray(controller: controller) {
                                controllersToSignOut.removeAll { $0.initials == controller.initials }
                            } else {
                                controllersToSignOut.append(controller)
                            }
                        }
                    } // forEach
            } // ScrollView
            
            HStack(spacing: 200) {
                Button("CANCEL", role: .cancel, action: dismissSignOutSheet)
                    .buttonStyle(.bordered)
                Button("SIGN OUT", action: signOutControllers)
                    .buttonStyle(.borderedProminent)
            } //HStack
        } // VStack
    } // Body
    
    func dismissSignOutSheet() {
        dismiss()
    }
    
    func signOutControllers() {
        Task {
            do {
                // Remove any controllers that are in controllersToSignOut
                // but are not visible due to another filter
                controllersToSignOut = controllersToSignOut.filter { controller in
                    controllers.contains { $0 == controller }
                }
                
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
