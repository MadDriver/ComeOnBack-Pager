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
            VStack(spacing: 0) {
                topBar
                Divider()
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        OnPositionView(items: pagingVM.onPositionItems)
                            .frame(width: geometry.size.width * 0.33)
                        Divider()
                        AvailableView()
                            .frame(maxWidth: .infinity)
                    } // HStack
                } // GeoReader
            } // VStack
            .toolbar(.hidden, for: .navigationBar)
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
            ThemeChangerScreen(screenBrightness: $screenBrightness)
                .presentationDetents([.medium, .large])
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

    /// The console top bar: board identity + clock on the leading edge, the three peer
    /// actions and the sign in/out controls trailing, and an overflow menu for
    /// appearance + the destructive device re-enroll (P1, P8, P11).
    private var topBar: some View {
        HStack(spacing: Spacing.md) {
            if let name = pagingVM.facility?.name, !name.isEmpty {
                Text(name)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            HeaderView()

            Spacer()

            Button { messagesViewIsActive = true } label: {
                Label("Messages", systemImage: "message")
            }
            .buttonStyle(.bordered)
            Button { pairTeamViewIsActive = true } label: {
                Label("Teams", systemImage: "person.2")
            }
            .buttonStyle(.bordered)
            Button { planViewIsActive = true } label: {
                Label("Plan", systemImage: "calendar.badge.clock")
            }
            .buttonStyle(.bordered)

            Divider().frame(height: 28)

            Button { signOutViewIsActive = true } label: {
                Label("Sign out", systemImage: "arrow.right.square")
            }
            .buttonStyle(.bordered)
            Button { signInViewIsActive = true } label: {
                Label("Sign in", systemImage: "person.badge.plus")
            }
            .buttonStyle(.borderedProminent)

            Menu {
                Button { changeTheme = true } label: {
                    Label("Appearance", systemImage: "circle.lefthalf.filled")
                }
                Divider()
                Button(role: .destructive) {
                    Task { await sessionStore.logout() }
                } label: {
                    Label("Sign out / re-enroll device", systemImage: "rectangle.portrait.and.arrow.right")
                }
            } label: {
                Image(systemName: "ellipsis.circle").font(.title2)
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
    }
}
