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
    let width = UIScreen.main.bounds.width
    @Binding var selectedMinutes: Int?
    @State var currentTime = TimeClock(sec: 0, min: 0, hour: 0)
    @State var receiver = Timer.publish(every: 1, on: .current, in: .default).autoconnect()

    var body: some View {
        GeometryReader { proxy in
            
            let width = proxy.size.width
            
            ZStack {
                ForEach(1...60, id: \.self) { index in
                    Rectangle()
                        .fill(.primary)
                        .frame(width: 2, height: index % 5 == 0 ? 20 : 5)
                        .offset(y: width / 3)
                        .rotationEffect(.init(degrees: Double(index) * 6))
                    
                }
                
                ForEach(minutes.indices, id: \.self) { index in
                    Text("\(minutes[index])")
                        .frame(width: 60, height: 60)
                        .background(selectedMinutes == minutes[index] ? .blue: .clear)
                        .font(.system(size: 30))
                        .font(.caption.bold())
                        .clipShape(Circle())
                        .rotationEffect(.init(degrees: Double(index) * -30))
                        .offset(y: width / 2.5)
                        .rotationEffect(.init(degrees: Double(index) * 30))
                        .opacity(showNumber(minute: minutes[index]) ? 1 : 0)
                        .onTapGesture {
                            
                            if selectedMinutes == minutes[index] {
                                selectedMinutes = nil
                            } else {
                                selectedMinutes = minutes[index]
                                print(String(minutes[index]))
                            }
                            
                        }
                }
    
                Rectangle() // Minute hand
                    .fill(.primary)
                    .frame(width: width / 2.9, height: 2)
                    .rotationEffect(.init(degrees: ((Double(currentTime.min) * 6) + (Double(currentTime.sec) / 10))  - 90), anchor: .leading)
                    .offset(x: (width / 2.9) / 2)
                
                Rectangle()
                    .fill(.primary)
                    .frame(width: width / 4.5, height: 2)
                    .rotationEffect(Angle(degrees: (Double(currentTime.hour) * 30) + (Double(currentTime.min) * 0.5) - 90), anchor: .leading)
                    .offset(x: (width / 4.5) / 2)
                
                Circle()
                    .fill(.primary)
                    .frame(width: 15, height: 15)
            } // Zstack
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            .onAppear {
                let calendar  = Calendar.current
                let sec = calendar.component(.second, from: Date())
                let min = calendar.component(.minute, from: Date())
                let hour = calendar.component(.hour, from: Date())
                
                self.currentTime = TimeClock(sec: sec, min: min, hour: hour)
                
            }
            .onReceive(receiver) { (_) in
                let calendar  = Calendar.current
                let sec = calendar.component(.second, from: Date())
                let min = calendar.component(.minute, from: Date())
                let hour = calendar.component(.hour, from: Date())
                
                self.currentTime = TimeClock(sec: sec, min: min, hour: hour)
                
            }
        }
    }
    #warning("Doesn't work correctly between 55 and 0")
    func showNumber(minute: Int) -> Bool {
        let negBuffer = 5
        
        if currentTime.min >= (minute - negBuffer) && currentTime.min < (minute + 2) {
            return false
        }
        
        return true
    }
    
}

struct ClockView_Previews: PreviewProvider {
    static var previews: some View {
        ClockView(selectedMinutes: .constant(nil))
    }
}

struct TimeClock: Equatable {
    var sec: Int
    var min: Int
    var hour: Int
    
}
