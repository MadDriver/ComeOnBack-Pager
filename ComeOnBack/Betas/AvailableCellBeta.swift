//
//  AvailableCellBeta.swift
//  ComeOnBack
//
//  Created by Calvin Shultz on 7/16/23.
//

import SwiftUI

struct AvailableCellBeta: View {
    
    let controller: Controller
    
    var body: some View {
        HStack {
            
            Image(systemName: "arrow.backward.circle")
                .resizable()
                .frame(width: 50, height: 50)
                .padding()
            
            Rectangle()
                .frame(width: 5, height: 50)
            
            Text(controller.initials)
                .font(.system(size: 45, weight: .bold))
                .padding()
            
            Text("\(controller.beBack?.time.description ?? " ")")
                .font(.system(size: 45, weight: .bold))

            Text("\(controller.beBack?.forPosition?.description ?? " ")")
                .font(.system(size: 45, weight: .bold))
                .padding(.horizontal)
            
            Spacer()

        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        
    }
}

struct AvailableCellBeta_Previews: PreviewProvider {
    static var previews: some View {
        AvailableCellBeta(controller: Controller.mock_data[2])
    }
}
