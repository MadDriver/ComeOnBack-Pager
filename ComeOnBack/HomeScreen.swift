//
//  Home.swift
//  ComeOnBack
//
//  Created by Calvin Shultz on 3/9/23.
//

import SwiftUI
import OSLog

struct HomeScreen: View {
    private let logger = Logger(subsystem: Logger.subsystem, category: "Home View")
    @ObservedObject var pagingVM = PagingViewModel()
    @State var signInViewIsActive = false
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack {
                HeaderView()
                
                NavigationStack {
                    VStack {
                        GeometryReader { geometry in
                            HStack(spacing: 0) {
                                OnPositionView(controllers: pagingVM.onPosition)
                                    .frame(width: geometry.size.width * 0.33)
                                AvailableView(controllerList: pagingVM.rightHandList)
                                    .frame(width: geometry.size.width * 0.67)
                            }
                        }
                    }
                } // Nav Stack
            } // V Stack
            
            Button("SIGN IN/OUT", action: signInController)
                .buttonStyle(.borderedProminent)
                .padding()
            
        } // Z Stack
        .environmentObject(pagingVM)
        .sheet(isPresented: $signInViewIsActive) {
            Text("DFADFDSAFSFS")
        }
        .task{
            do {
                pagingVM.allControllers = try await API().getControllerList()
            } catch {
                logger.error("Error getting controller list: \(error)")
            }
            
            do {
                try await pagingVM.shortPoll()
            } catch {
                logger.error("\(error)")
            }
            
        }
    }// body
    
    func signInController() {
        signInViewIsActive = true
    }
}

struct Home_Previews: PreviewProvider {
    static var previews: some View {
        HomeScreen()
            .previewInterfaceOrientation(.landscapeLeft)
            .previewDevice(PreviewDevice(rawValue: "iPad (10th generation)"))
    }
}
