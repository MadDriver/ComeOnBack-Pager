//
//  HomeScreen.swift
//  ComeOnBack Pager
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
    @EnvironmentObject var sessionStore: SessionStore
    @StateObject private var pagingVM: PagingViewModel
    @StateObject private var displaySettings = DisplaySettings()

    @AppStorage("user_theme") private var userTheme: Theme = .dark

    @State private var signInViewIsActive = false
    @State private var signOutViewIsActive = false
    @State private var messagesViewIsActive = false
    @State private var pairTeamViewIsActive = false
    @State private var planViewIsActive = false
    @State private var changeTheme = false
    @State private var screenBrightness = 1.0

    init(api: APIClient) {
        _pagingVM = StateObject(wrappedValue: PagingViewModel(api: api))
    }

    private var showingError: Binding<Bool> {
        Binding(
            get: { pagingVM.errorMessage != nil },
            set: { if !$0 { pagingVM.errorMessage = nil } }
        )
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .topLeading) {
                VStack {
                    HeaderView()
                    GeometryReader { geometry in
                        HStack(spacing: 0) {
                            OnPositionView(items: pagingVM.onPositionItems)
                                .frame(width: geometry.size.width * 0.33)
                            AvailableView()
                                .frame(width: geometry.size.width * 0.67)
                        } // HStack
                    } // GeoReader
                } // VStack

                HStack {
                    Button("SIGN IN") { signInViewIsActive = true }
                        .buttonStyle(.borderedProminent)

                    Button("MESSAGES") { messagesViewIsActive = true }
                        .buttonStyle(.bordered)
                    Button("TEAMS") { pairTeamViewIsActive = true }
                        .buttonStyle(.bordered)
                    Button("PLAN") { planViewIsActive = true }
                        .buttonStyle(.bordered)

                    Spacer()

                    Image(systemName: "moonphase.last.quarter.inverse")
                        .frame(width: 50, height: 50)
                        .onTapGesture { changeTheme.toggle() }

                    Button("SIGN OUT") { signOutViewIsActive = true }
                        .buttonStyle(.borderedProminent)
                }
                .padding()
            } // ZStack
        } // NavStack
        .preferredColorScheme(userTheme.colorScheme)
        .fullScreenCover(isPresented: $signInViewIsActive) {
            SignInScreen()
        }
        .fullScreenCover(isPresented: $signOutViewIsActive) {
            SignOutScreen()
        }
        .fullScreenCover(isPresented: $messagesViewIsActive) {
            MessagesView()
        }
        .fullScreenCover(isPresented: $pairTeamViewIsActive) {
            PairTeamView()
        }
        .fullScreenCover(isPresented: $planViewIsActive) {
            PlanView()
        }
        .sheet(isPresented: $changeTheme) {
            if #available(iOS 16.4, *) {
                themeSheet
                    .presentationDetents([.height(560)])
                    .presentationBackground(.clear)
            } else {
                themeSheet
                    .presentationDetents([.height(560)])
            }
        }
        .environmentObject(pagingVM)
        .environmentObject(displaySettings)
        .task {
            // Single ~4s ETag-conditional poll of the whole board; auto-cancelled when
            // this screen is torn down (logout / revoke).
            await pagingVM.poll()
        }
        .refreshable {
            await pagingVM.refresh()
        }
        .alert("Connection issue", isPresented: showingError) {
            Button("OK", role: .cancel) { pagingVM.errorMessage = nil }
        } message: {
            Text(pagingVM.errorMessage ?? "")
        }
        .onChange(of: screenBrightness) { newValue in
            UIScreen.main.brightness = CGFloat(newValue)
        }
    } // body

    private var themeSheet: some View {
        ThemeChangerScreen(screenBrightness: $screenBrightness) {
            changeTheme = false
            Task { await sessionStore.logout() }
        }
    }
}
