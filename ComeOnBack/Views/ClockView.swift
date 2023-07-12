//
//  ClockView.swift
//  ComeOnBack
//
//  Created by Calvin Shultz on 7/11/23.
//

import SwiftUI

struct ClockView: View {
    
    // minutes start at 30 since the numbers start at the 6 o'clock position.  Probably an easy fix but I don't know it.
    let minutes = [30, 35, 40, 45, 50, 55, 0, 5, 10, 15, 20, 25]
    @State var selectedMinutes: Int?
    
    var body: some View {
        ZStack {
            ForEach(1...60, id: \.self) { index in
                Rectangle()
                    .fill(index % 5 == 0 ? .black : .gray)
                    .frame(width: 2, height: index % 5 == 0 ? 15 : 5)
                    .offset(y: (200 - 60))
                    .rotationEffect(.init(degrees: Double(index) * 6))
                
            }
            
            ForEach(minutes.indices, id: \.self) { index in
                Text("\(minutes[index])")
                    .frame(width: 100, height: 100)
                    .background(selectedMinutes == minutes[index] ? .blue: .clear)
                    .font(.system(size: 30))
                    .font(.caption.bold())
                    .foregroundColor(.black)
                    .clipShape(Circle())
                    .rotationEffect(.init(degrees: Double(index) * -30))
                    .offset(y: (450-30) / 2)
                    .rotationEffect(.init(degrees: Double(index) * 30))
                    .onTapGesture {
                        
                        if selectedMinutes == minutes[index] {
                            selectedMinutes = nil
                        } else {
                            selectedMinutes = minutes[index]
                            print(String(minutes[index]))
                        }
                        
                    }
            }
            
        }
    }
}

struct ClockView_Previews: PreviewProvider {
    static var previews: some View {
        ClockView()
    }
}
