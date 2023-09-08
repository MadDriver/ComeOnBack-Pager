//
//  FacilityPickerScreen.swift
//  ComeOnBack Pager
//
//  Created by user on 9/7/23.
//

import SwiftUI
import OSLog

struct FacilityPickerScreen: View {
    private let logger = Logger(subsystem: Logger.subsystem, category: "FacilityPickerScreen")
    @State var inputedFacility = ""
    @State var showErrorField = false
    @Binding var facilityID: String?
    var body: some View {
        
        VStack {
            
            Text("Enter Facility ID")
                .font(.title.bold())
                .foregroundColor(.primary)
            
            
            TextField("Facility", text: $inputedFacility)
                .frame(width: 100, height: 55)
                .textFieldStyle(PlainTextFieldStyle())
                .textInputAutocapitalization(.characters)
//                .background(Color.gray.opacity(0.2).cornerRadius(10))
                .multilineTextAlignment(.center)
                .padding([.horizontal], 4)
                .overlay {
                    RoundedRectangle(cornerRadius: 16).stroke(Color.primary)
                }
                .padding([.horizontal], 20)
                
            
            Button("ENTER") {
                registerFacilityID( )
            }
            .buttonStyle(.borderedProminent)
            .padding()
            
            if showErrorField {
                Text("Invalid Facility ID")
                    .foregroundColor(.red).bold()
            }
            
        } // VStack
        
    }
    
    func registerFacilityID()  {
        Task {
            do {
                try await API().registerPager(forFacilityID: inputedFacility)
                await MainActor.run {
                    facilityID = inputedFacility
                }
            } catch APIError.invalidFacilityID {
                await MainActor.run {
                    showErrorField = true
                }
            } catch {
                logger.error("\(error.localizedDescription)")
            }
        }
    }
    
}

struct FacilityPickerScreen_Previews: PreviewProvider {
    static var previews: some View {
        FacilityPickerScreen(facilityID: .constant(""))
    }
}
