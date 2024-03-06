//
//  PagingView.swift
//  ComeOnBack
//
//  Created by Calvin Shultz on 3/11/23.
//

import SwiftUI
import OSLog

enum TimeASAPPicker: CaseIterable, Identifiable {
    case normal
    case asap
    
    var id: Self { self }
    
    var description: String {
        switch self {
        case .normal:
            return "Normal"
        case .asap:
            return "ASAP"
        }
    }
}

struct PagingView: View {
    private let logger = Logger(subsystem: Logger.subsystem, category: "PagingView")
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var pagingVM: PagingViewModel
    
    // The current selected time/position
    @State var beBackTimeString: String?
    @State var beBackPosition: String?
    
    // Handle the two sources of user input
    @State var clockBeBackMinutes: Int?
    @State var selectedBeBackMinutes: String?
    @State var timePicker: TimeASAPPicker = .normal
    
    @State var buttonIsDisabled: Bool = true
    
    var controller: Controller
    var isSubmittable: Bool { beBackTimeString != nil }
    var beBackText: String {
        let verb = controller.registered ? "Page" : "Assign"
        if beBackTimeString == nil { return "\(verb) \(controller.initials)" }
        if beBackPosition == nil { return "\(verb) \(controller.initials) at \(beBackTimeString ?? "  ")" }
        return "\(verb) \(controller.initials) at \(beBackTimeString ?? "  ") for \(beBackPosition ?? "  ")"
    }
    
    var body: some View {
        VStack {
            HStack {
                VStack {
                    Text("\(beBackText)")
                        .font(.title).bold()
                        .padding(.bottom)
                    leftSideOfHStack
                }
                VStack {
                    Picker("Time Picker type", selection: $timePicker) {
                        ForEach(TimeASAPPicker.allCases) { option in
                            Text(option.description)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 200)
                                        
                    switch timePicker {
                    case .normal:
                        rightClockView
                    case .asap:
                        asapView
                    }
                } // VStack
                .frame(height: 500)
                
            } // HStack
            
            Button(action: pageBack) {
                Text(controller.registered ? "PAGE" : "ASSIGN")
                    .foregroundColor(isSubmittable ? .black : .black.opacity(0.4))
                    .frame(width: 500, height: 100)
                    .font(.title).bold()
                    .background(isSubmittable ? Color.blue.opacity(0.8) : Color.gray)
                    .cornerRadius(20)
                    .padding()
            }
            .disabled(!isSubmittable)
            
            if !controller.registered {
                HStack {
                    Image(systemName: "phone")
                        .foregroundColor(.red).bold()
                    Text("\(controller.initials) is not registered. You must page them via the phone system.")
                    Image(systemName: "phone")
                        .foregroundColor(.red).bold()
                }
            }
        } // VStack
        .frame(maxHeight: .infinity)
        .padding()
        .navigationBarBackButtonHidden()
        .background(Color.black.opacity(0.1))
        .onChange(of: timePicker) { picker in
            switch timePicker {
            case .normal:
                newMinuteSelected(minute: controller.beBack?.atTime?.minutes)
            case .asap:
                beBackTimeString = "ASAP"
            }
        }
        .onAppear {
            beBackTimeString = controller.beBack?.stringValue
            beBackPosition = controller.beBack?.forPosition
            if beBackTimeString == "ASAP" {
                timePicker = .asap
            } else {
                clockBeBackMinutes = controller.beBack?.atTime?.minutes
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if (controller.status == .PAGED_BACK) {
                Button(role: .destructive, action: cancelPage) {
                    Label("Cancel Page", systemImage: "trash")
                }
                .padding()
            }
        }
        .overlay(alignment: .topTrailing) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "x.circle")
                    .font(.system(size: 48))
                    .padding()
                
            }
            .buttonStyle(.plain)
        }
    } // body
    
    @ViewBuilder
    private var asapView: some View {
        ZStack {
            Circle()
                .fill(.red)
            Text("ASAP")
                .font(.title).bold()
        }
        .padding()
    }
    
    @ViewBuilder
    private var rightClockView: some View {
        ClockView(selectedMinute: clockBeBackMinutes, onMinuteSelected: newMinuteSelected)
            .frame(width: 400, height: 400)
        
        HStack {
            ForEach(pagingVM.beBackMinutes, id: \.self) { minute in
                Text("\(minute) mins")
                    .fontWeight(.bold)
                    .frame(width: 100, height: 50)
                    .background(selectedBeBackMinutes == minute ? Color.yellow : Color.blue.opacity(0.5))
                    .border(Color.red, width: selectedBeBackMinutes == minute ? 2.5 : 0)
                    .onTapGesture {
                        guard let minutesAsInt = Int(minute) else { return }
                        newMinuteSelected(minute: pagingVM.roundUpToNext5Minutes(minutes: minutesAsInt))
                        self.selectedBeBackMinutes = minute
                    }
            }
        }
        .padding()
    }
    
    @ViewBuilder
    private var leftSideOfHStack: some View {
        if let facility = pagingVM.facility,
           let area = facility.getArea(forController: controller)
        {
            VStack {
                LazyHGrid(rows: pagingVM.positionRows, spacing: 20) {
                    ForEach(area.positions, id: \.self) { position in
                        if let position = position {
                            Text(position)
                                .font(.system(size: 20, weight: .bold))
                                .frame(width: 100, height: 50)
                                .background(beBackPosition == position ? Color.yellow : Color.red.opacity(0.5))
                                .border(Color.blue, width: beBackPosition == position ? 2.5 : 0)
                                .onTapGesture {
                                    if beBackPosition == position {
                                        beBackPosition = nil
                                    } else {
                                        beBackPosition = position
                                    }
                                }
                        } else {
                            // Position is nil, placeholder text box.
                            Text("")
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height:250)
                
                
            } // VStack
            .padding(.top)
        } // if let facility, area
    }
}

// MARK: Functions

extension PagingView {
    
    func newMinuteSelected(minute: Int?) {
        logger.debug("newTimeSelected \(String(describing:minute))")
        if let minutes = minute,
           let newDate = Calendar.current.date(bySetting: .minute, value: minutes, of: Date()) {
            let beBackTime = BasicTime(fromDate: newDate)
            self.clockBeBackMinutes = minutes
            self.selectedBeBackMinutes = nil
            self.beBackTimeString = beBackTime?.stringValue
        } else {
            self.clockBeBackMinutes = nil
            self.selectedBeBackMinutes = nil
            self.beBackTimeString = nil
        }
    }
    
    func cancelPage() {
        Task {
            do {
                try await pagingVM.removeBeBack(forController: controller)
            } catch {
                Logger(subsystem: Logger.subsystem, category: "PagingView").error("With controller: \(controller): \(error)")
            }
            await MainActor.run {
                dismiss()
            }
        }
        
    }
    
    func pageBack() {
        guard let beBackTime = beBackTimeString else {
            logger.error("beBackTimeString must be defined before calling submitBeBack()")
            return
        }
        
        Task {
            do {
                let beBack = try BeBack(timeString: beBackTime, forPosition: beBackPosition)
                try await pagingVM.submitBeBack(beBack, forController: controller)
                await MainActor.run { dismiss() }
            } catch APIError.invalidParameters {
                logger.error("Invalid parameters in pageBack()")
            } catch APIError.invalidServerResponse {
                logger.error("Invalid server response in pageBack()")
            } catch BeBackError.initializationError {
                logger.error("Could not create BeBack with timeString\(beBackTime)")
            } catch {
                logger.error("Unexpected error in pageBack(): \(error)")
            }
        }
    }
    
    
}

struct PagingView_Previews: PreviewProvider {
    static var previews: some View {
        PagingView(controller: Controller.mock_data[0])
            .environmentObject(PagingViewModel())
            .previewInterfaceOrientation(.landscapeLeft)
            .previewDevice("iPad (10th generation)")
        PagingView(controller: Controller.mock_data[1])
            .environmentObject(PagingViewModel())
            .previewInterfaceOrientation(.landscapeLeft)
            .previewDevice("iPad (10th generation)")
            .previewDisplayName("Not Registered")
        PagingView(controller: Controller.mock_data[2])
            .environmentObject(PagingViewModel())
            .previewInterfaceOrientation(.landscapeLeft)
            .previewDevice("iPad (10th generation)")
            .previewDisplayName("Not Registered")
    }
}
