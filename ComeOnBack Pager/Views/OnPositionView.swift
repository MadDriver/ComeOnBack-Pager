//
//  OnPositionView.swift
//  ComeOnBack
//
//  Created by user on 7/4/23.
//

import SwiftUI

struct OnPositionView: View {
    var controllers: [Controller]
    var body: some View {
        VStack {
            
            List {
                ForEach(controllers) { controller in
                    OnPositionCellView(controller: controller)
                }
            }
        }
    }
}

struct OnPositionView_Previews: PreviewProvider {
    static var previews: some View {
        OnPositionView(controllers: Controller.mock_data)
    }
}
