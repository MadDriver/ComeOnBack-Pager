//
//  AvailableCellBeta.swift
//  ComeOnBack
//
//  Created by Calvin Shultz on 7/16/23.
//

import SwiftUI

struct AvailableCellBeta: View {
    
    let controller: Controller
    @Binding var isSelected: Bool
    
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

        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isSelected ? Color.red.opacity(0.2) : Color.black.opacity(0.2))
        .padding(.horizontal)
        
    }
}

struct AvailableCellBeta_Previews: PreviewProvider {
    static var previews: some View {
        AvailableCellBeta(controller: Controller.mock_data[2], isSelected: .constant(false))
    }
}
