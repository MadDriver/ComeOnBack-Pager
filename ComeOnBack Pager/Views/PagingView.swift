//
//  PagingView.swift
//  ComeOnBack
//
//  Created by Calvin Shultz on 3/11/23.
//

import SwiftUI
import OSLog

struct PagingView: View {
    private let logger = Logger(subsystem: Logger.subsystem, category: "PagingView")
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var pagingVM: PagingViewModel
    @State var beBackPosition: String?
    @State var beBackTime: String?
    @State var customBeBackTime: Int?
    @State var selectedBeBackTime: String?
    @State private var selectedDev: Controller?
    @State var buttonIsDisabled: Bool = true
    
    var controller: Controller
    var isSubmittable: Bool {
        if let controllerIsRegistered = controller.registered {
            if controllerIsRegistered {
                return beBackTime != nil
            } else {
                return beBackPosition != nil
            }
        }
        
        return false
    }
    var beBackText: String {
        let verb = controller.registered ?? false ? "Page" : "Assign"
        if beBackTime == nil { return "\(verb) \(controller.initials)" }
        if beBackPosition == nil { return "\(verb) back \(controller.initials) at \(beBackTime ?? "  ")" }
        return "\(verb) \(controller.initials) at \(beBackTime ?? "  ") for \(beBackPosition ?? "  ")"
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
                    if let registered = controller.registered, registered {
                        VStack {
                            ClockView(selectedMinutes: $customBeBackTime)
                                .frame(width: 400, height: 400)
                            
                            
                            HStack {
                                ForEach(pagingVM.beBackTimes, id: \.self) { time in
                                    Text(time + " mins")
                                        .fontWeight(.bold)
                                        .frame(width: 100, height: 50)
                                        .background(selectedBeBackTime == time ? Color.yellow : Color.blue.opacity(0.5))
                                        .border(Color.red, width: selectedBeBackTime == time ? 2.5 : 0)
                                        .onTapGesture {
                                            selectedBeBackTime = time
                                            self.beBackTime = pagingVM.getBeBackTime(minute: time)
                                        }
                                }
                            }
                            .padding()
                        }
                    } else {
                        // Controller bot registered
                        Text("\(controller.initials) not registered")
                        Spacer()
                    }
                    
                } // HStack
                
                Button(action: pageBack) {
                    Text(controller.registered ?? false ? "PAGE" : "ASSIGN")
                        .foregroundColor(isSubmittable ? .black : .black.opacity(0.4))
                        .frame(width: 500, height: 100)
                        .font(.title).bold()
                        .background(isSubmittable ? Color.blue.opacity(0.8) : Color.gray)
                        .cornerRadius(20)
                        .padding()
                    
                }
                .disabled(!isSubmittable)
                
            } // VStack
            .padding()
            .navigationBarBackButtonHidden()
            .background(Color.black.opacity(0.1))
            .onChange(of: customBeBackTime) { time in
                selectedBeBackTime = nil
                beBackTime = nil
                if let time = time {
                    beBackTime = pagingVM.customBeBackTimeChanged(time: time)
                }
            }
            .onAppear {
                beBackTime = controller.beBack?.time.stringValue
                beBackPosition = controller.beBack?.forPosition
                
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
    
    
}

// MARK: Functions

extension PagingView {
    
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
        guard let beBackTime = beBackTime else {
            logger.error("beBackTime must be defined before calling submitBeBack()")
            return
        }
        
        Task {
            do {
                let time = try Time(beBackTime)
                try await pagingVM.createAndSubmitBeBack(forController: controller, time: time, forPosition: beBackPosition)
                await MainActor.run { dismiss() }
            } catch APIError.invalidParameters {
                logger.error("Invalid parameters in pageBack()")
            } catch APIError.invalidServerResponse {
                logger.error("Invalid server response in pageBack()")
            } catch {
                logger.error("Unexpected error in pageBack(): \(error)")
            }
        }
    }
    
    @ViewBuilder
    private var leftSideOfHStack: some View {
        VStack {
            
            var positions: [String] {
                if controller.area == "Departure" {
                    return pagingVM.DRpositions + pagingVM.commonPositions
                } else {
                    return pagingVM.ARPositions + pagingVM.commonPositions
                }
            }
            
            LazyHGrid(rows: pagingVM.positionRows, spacing: 20) {
                ForEach(positions, id: \.self) { position in
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
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height:250)
                        
            
        } // VStack
        .padding(.top)
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
    }
}
