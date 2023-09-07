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
    @Binding var facilityID: String?
//    @AppStorage("facilityID") var facilityID: String?
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
            
            
        } // VStack
        
    }
    
    func registerFacilityID()  {
        // make API call to register the facility
        Task {
            do {
                API.facilityName = inputedFacility
                try await API().registerPager()
                facilityID = inputedFacility
            } catch APIError.invalidFacilityName {
                logger.error("No facility found that was entered")
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
