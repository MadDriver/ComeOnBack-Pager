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
    
    @AppStorage("user_theme") private var userTheme: Theme = .dark
//    @AppStorage("isDarkMode") private var isDarkMode: Bool = true
    
    @State var signInViewIsActive = false
    @State var signOutViewIsActive = false
    @State var isLoading = false
    
    @State private var fetchError: APIError = .invalidServerResponse
    @State private var isShowingAlert = false
    @State private var changeTheme: Bool = false
    
    @State private var screenBrightness = 1.0
        
    let timer = Timer.publish(every: 30.0, on: .main, in: .common).autoconnect()
        
    var body: some View {
        if #available(iOS 17.0, *) {
            NavigationStack {
                ZStack(alignment: .topLeading) {
                    VStack {
                        HeaderView()
                        GeometryReader { geometry in
                            HStack(spacing: 0) {
                                OnPositionView(controllers: pagingVM.onPosition)
                                    .frame(width: geometry.size.width * 0.33)
                                AvailableView()
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
                                                                        
                        Image(systemName: "moonphase.last.quarter.inverse")
                            .frame(width: 50, height: 50)
                            .onTapGesture {
                                changeTheme.toggle()
                            }
                        
                        Button("SIGN OUT", action: signOutControllers)
                            .buttonStyle(.borderedProminent)
                            .padding()
                            .disabled(isLoading)
                    }
                } // Z Stack
                
                
                
            } // Nav Stack
            .preferredColorScheme(userTheme.colorScheme)
            .fullScreenCover(isPresented: $signInViewIsActive) {
                SignInScreen()
            }
            .fullScreenCover(isPresented: $signOutViewIsActive) {
                SignOutScreen()
            }
            .sheet(isPresented: $changeTheme, content: {
                if #available(iOS 16.4, *) {
                    ThemeChangerScreen(screenBrightness: $screenBrightness)
                        .presentationDetents([.height(500)])
                        .presentationBackground(.clear)
                } else {
                    ThemeChangerScreen(screenBrightness: $screenBrightness)
                        .presentationDetents([.height(500)])
                }
            })
            .environmentObject(pagingVM)
            .environmentObject(displaySettings)
            .onReceive(timer) { _ in
                Task {
                    do {
                        try await pagingVM.shortPoll()
                    } catch {
                        fetchError = .invalidServerResponse
                        isShowingAlert = true
                        logger.error("\(error)")
                    }
                }
            }
            .task{
                do {
                    try await pagingVM.updateAllControllers()
                    await MainActor.run {
                        isLoading = false
                    }
                } catch {
                    fetchError = .invalidServerResponse
                    isShowingAlert = true
                    logger.error("Error getting controller list: \(error)")
                }
                
                do {
                    try await pagingVM.shortPoll()
                } catch {
                    fetchError = .invalidServerResponse
                    isShowingAlert = true
                    logger.error("\(error)")
                }
                
            }
            .refreshable {
                Task {
                    try? await pagingVM.shortPoll()
                }
            }
            .alert(isPresented: $isShowingAlert, error: fetchError) { fetchError in
                // Default
            } message: { fetchError in
                Text(fetchError.failureReason)
            }
            .onChange(of: screenBrightness) {
                UIScreen.main.brightness = CGFloat(screenBrightness)
            }
        } else {
            
        }

    }// body
    
    func signInControllers() {
        signInViewIsActive = true
    }
    
    func signOutControllers() {
        signOutViewIsActive = true
    }
    
//    var darkModeToggle: some View {
//        Toggle("Dark Mode", systemImage: "moonphase.last.quarter.inverse", isOn: $isDarkMode)
//            .toggleStyle(.button)
//            .labelStyle(.iconOnly)
//    }
}


//struct Home_Previews: PreviewProvider {
//    static var previews: some View {
//        HomeScreen()
//            .previewInterfaceOrientation(.landscapeLeft)
//            .previewDevice(PreviewDevice(rawValue: "iPad (10th generation)"))
//    }
//}
