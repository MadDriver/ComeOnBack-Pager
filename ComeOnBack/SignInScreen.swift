//
//  SignInView.swift
//  ComeOnBack
//
//  Created by Calvin Shultz on 3/24/23.
//

import SwiftUI

struct SignInScreen: View {
    
    @State var controllerInitials = ""
    
    var body: some View {
        VStack {
            TextField("Enter Controller Initials", text: $controllerInitials)
                
        }
        .frame(width: 300)
    }
}

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignInScreen()
    }
}
