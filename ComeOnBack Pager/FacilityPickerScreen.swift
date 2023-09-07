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
    @Binding var facility: String
    @State var inputedFacility = ""
    var body: some View {
        VStack {
            Spacer()
            Form {
                TextField("Facility", text: $inputedFacility)
            }
            .padding()
            Spacer()
        } // VStack
        .frame(height: 300, alignment: .center)
        .onChange(of: inputedFacility) { _ in
            // Make an API call to register the facility
        }
    }
}

struct FacilityPickerScreen_Previews: PreviewProvider {
    static var previews: some View {
        FacilityPickerScreen(facility: .constant(""))
    }
}
