//
//  UpgradeRequiredScreen.swift
//  ComeOnBack Pager
//
//  The terminal 410 block: this build is past the API sunset. A facility device has
//  no App Store update flow, so the copy points at the admin rather than a store link
//  (distribution is managed out-of-band). Presented above everything by the app root.
//

import SwiftUI

struct UpgradeRequiredScreen: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.arrow.triangle.2.circlepath")
                .font(.system(size: 72))
                .foregroundStyle(.orange)

            Text("Update Required")
                .font(.largeTitle.bold())

            Text("This workstation needs an update — contact your admin.")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 480)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct UpgradeRequiredScreen_Previews: PreviewProvider {
    static var previews: some View {
        UpgradeRequiredScreen()
    }
}
