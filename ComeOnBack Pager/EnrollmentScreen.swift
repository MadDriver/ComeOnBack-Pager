//
//  EnrollmentScreen.swift
//  ComeOnBack Pager
//
//  Kiosk enrollment: replaces the old free-text `FacilityPickerScreen`. Tapping
//  "Enroll this workstation" opens the atcauth web-auth sheet (`SessionStore.login()`),
//  where an admin-minted one-time code binds this device to a facility console. On
//  success the app gates through to the board; the facility comes from the token.
//

import SwiftUI

struct EnrollmentScreen: View {
    @EnvironmentObject var sessionStore: SessionStore

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "dot.radiowaves.left.and.right")
                .font(.system(size: 72))
                .foregroundStyle(.tint)

            Text("ComeOnBack Pager")
                .font(.largeTitle.bold())

            Text("This workstation isn't enrolled yet.")
                .font(.title3)
                .foregroundStyle(.secondary)

            Button(action: enroll) {
                if sessionStore.isLoggingIn {
                    ProgressView()
                        .frame(width: 320, height: 56)
                } else {
                    Text("Enroll this workstation")
                        .font(.title2.bold())
                        .frame(width: 320, height: 56)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(sessionStore.isLoggingIn)

            Text("Ask a facility admin to mint an enrollment code, then enter it on the sign-in page.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)

            if let error = sessionStore.loginError {
                Text(error)
                    .foregroundColor(.red)
                    .bold()
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 420)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func enroll() {
        Task { await sessionStore.login() }
    }
}

struct EnrollmentScreen_Previews: PreviewProvider {
    static var previews: some View {
        EnrollmentScreen().environmentObject(SessionStore())
    }
}
