//
//  Home.swift
//  ComeOnBack
//
//  Created by Calvin Shultz on 3/9/23.
//

import SwiftUI
import OSLog

class DisplaySettings: ObservableObject {
    @Published var useMilitaryTime = false
}

struct HomeScreen: View {
    private let logger = Logger(subsystem: Logger.subsystem, category: "Home View")
    @ObservedObject var pagingVM = PagingViewModel()
    
    @ObservedObject var displaySettings = DisplaySettings()
    @State var signInViewIsActive = false
    @State var signOutViewIsActive = false
    @State var isLoading = false
    let timer = Timer.publish(every: 30.0, on: .main, in: .common).autoconnect()
        
    var body: some View {
        NavigationStack {
            ZStack(alignment: .topLeading) {
                VStack {
                    HeaderView()
                    GeometryReader { geometry in
                        HStack(spacing: 0) {
                            OnPositionView(controllers: pagingVM.onPosition)
                                .frame(width: geometry.size.width * 0.33)
                            AvailableView(newlySignedIn: pagingVM.newelySignedIn,
                                          onBreak: pagingVM.onBreak)
                                .frame(width: geometry.size.width * 0.67)
                        } // HStack
                    } // GeoReader
                } // V Stack
                
                HStack {
                    Button("SIGN IN", action: signInControllers)
                        .buttonStyle(.borderedProminent)
                        .padding()
                        .disabled(isLoading)
                    
                    Spacer()
                    
                    Button("SIGN OUT", action: signOutControllers)
                        .buttonStyle(.borderedProminent)
                        .padding()
                        .disabled(isLoading)
                }
            } // Z Stack
            
            
            
        } // Nav Stack
        
        .fullScreenCover(isPresented: $signInViewIsActive) {
            SignInScreen()
        }
        .fullScreenCover(isPresented: $signOutViewIsActive) {
            SignOutScreen()
        }
        .environmentObject(pagingVM)
        .environmentObject(displaySettings)
        .onReceive(timer) { _ in
            Task {
                do {
                    try await pagingVM.shortPoll()
                } catch {
                    logger.error("\(error)")
                }
            }
        }
        .task{
            do {
                pagingVM.allControllers = try await API().getControllerList()
                await MainActor.run {
                    isLoading = false
                }
            } catch {
                logger.error("Error getting controller list: \(error)")
            }
            
            do {
                try await pagingVM.shortPoll()
            } catch {
                logger.error("\(error)")
            }
            
        }
        .refreshable {
            Task {
                try? await pagingVM.shortPoll()
            }
        }
    }// body
    
    func signInControllers() {
        signInViewIsActive = true
    }
    
    func signOutControllers() {
        signOutViewIsActive = true
    }
}

//struct Home_Previews: PreviewProvider {
//    static var previews: some View {
//        HomeScreen()
//            .previewInterfaceOrientation(.landscapeLeft)
//            .previewDevice(PreviewDevice(rawValue: "iPad (10th generation)"))
//    }
//}
