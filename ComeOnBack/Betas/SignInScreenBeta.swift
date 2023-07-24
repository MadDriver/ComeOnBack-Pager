//
//  SignInScreenBeta.swift
//  ComeOnBack
//
//  Created by Calvin Shultz on 7/16/23.
//

import SwiftUI

struct SignInScreenBeta: View {
    
    @Environment(\.dismiss) var dismiss
    let controllers: [Controller]
    
    var body: some View {
        
        VStack {
            ForEach(controllers) { controller in
                Text(controller.initials)
            }
            
            Button("DISMISS") {
                dismiss()
            }
        }
    }
}

struct SignInScreenBeta_Previews: PreviewProvider {
    static var previews: some View {
        SignInScreenBeta(controllers: Controller.mock_data)
    }
}
