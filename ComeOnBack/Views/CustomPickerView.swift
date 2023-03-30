//
//  CustomPickerView.swift
//  ComeOnBack
//
//  Created by Calvin Shultz on 3/12/23.
//

import SwiftUI

struct CustomPickerView: View {
    
    @Binding var customBeBackTime: Int
    @Environment(\.dismiss) var dismiss
    
    let availableTimes = Array(stride(from: 5, through: 55, by: 5))
    
    var body: some View {
        ZStack {
            VStack {
                List {
                    ForEach(availableTimes, id: \.self) { num in
                        Button {
                            customBeBackTime = num
                            dismiss()
                        } label: {
                            Text("\(num)")
                        }
                        
                    }
                }
                .background(Color.black.opacity(0.1))
                .scrollContentBackground(.hidden)
                .scrollDisabled(true)
                
                HStack {
                    Button("CANCEL", action: cancel)
                        .buttonStyle(.borderedProminent)
                }
                
                
            }
            .cornerRadius(30)
        }
        .frame(width: 300, height: 600)
    }
    
    func cancel() {
        dismiss()
    }
    
}

struct CustomPickerView_Previews: PreviewProvider {
    static var previews: some View {
        CustomPickerView(customBeBackTime: .constant(5))
    }
}
