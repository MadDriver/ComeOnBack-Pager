//
//  ClockViewGeometry.swift
//  ComeOnBack
//
//  Created by Calvin Shultz on 7/13/23.
//

import SwiftUI

struct ClockViewGeometry: View {
    
    let minutes = [30, 35, 40, 45, 50, 55, 0, 5, 10, 15, 20, 25]
    
    
    var body: some View {
        GeometryReader { proxy in
            
            let width = proxy.size.width
            
            ZStack(alignment: .center) {
                
                ForEach(1...60, id: \.self) { index in
                    Rectangle()
                        .fill(.primary)
                        .frame(width: 2, height: index % 5 == 0 ? 15 : 5)
                        .offset(y: width/3)
                        .rotationEffect(Angle(degrees: Double(index) * 6))
                }
                
                ForEach(minutes.indices, id: \.self) { index in
                    Text("\(minutes[index])")
                        .frame(width: 75, height: 75)
                        .rotationEffect(.init(degrees: Double(index) * -30))
                        .offset(y: width / 2.5)
                        .rotationEffect(.init(degrees: Double(index) * 30))
                }
                
                Rectangle() // Minute hand
                    .fill(.primary)
                    .frame(width: width / 3, height: 2)
                    .rotationEffect(Angle(degrees: 0), anchor: .leading)
                    .offset(x: (width / 3) / 2)
                
            } // ZStack
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
        }
    }
}

struct ClockViewGeometry_Previews: PreviewProvider {
    static var previews: some View {
        ClockViewGeometry()
    }
}
