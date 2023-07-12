//
//  ClockView.swift
//  ComeOnBack
//
//  Created by Calvin Shultz on 7/11/23.
//

import SwiftUI

struct ClockView: View {
    
    let borderWidth: CGFloat = 20
    
    var body: some View {
        GeometryReader { geometry in
            let radius = geometry.size.width / 4
            let innerRadius = radius - borderWidth
            
            let centerX = geometry.size.width / 2
            let centerY = geometry.size.height / 2
            
            let center = CGPoint(x: centerX, y: centerY)
            
            Circle()
                .foregroundColor(.red)
            Circle()
                .foregroundColor(.white)
                .padding(borderWidth)
            
            Path { path in
                
                for index in 0..<60 {
                    let radian = Angle(degrees: CGFloat(index) * 5).radians
                    
                    let lineHeight = index % 5 == 0 ? 25 : 10
                    
                    let x1  = center
                    
                }
                
            }
            
        }
        .aspectRatio(1, contentMode: .fit)
        .padding(30)
    }
}

struct ClockView_Previews: PreviewProvider {
    static var previews: some View {
        ClockView()
    }
}
