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
    @State var isShowingCustomPicker = false
    @State var customBeBackTime = 0
    var controller: Controller
    
    var isSubmittable: Bool { beBackTime != nil }
    
    var beBackText: String {
        if beBackTime == nil { return "" }
        if beBackPosition == nil { return "Page back \(controller.initials) at \(beBackTime ?? "  ")" }
        return "Page back \(controller.initials) at \(beBackTime ?? "  ") for \(beBackPosition ?? "  ")"
    }
    
    var body: some View {
        VStack {
            Text("Page \(controller.initials)")
                .font(.title).bold()
                .padding(.bottom)
            
            HStack {
                ForEach(pagingVM.beBackTimes, id: \.self) { time in
                    Text(time + " mins")
                        .frame(width: 100, height: 50)
                        .background(Color.blue.opacity(0.5))
                        .onTapGesture {
                            self.beBackTime = pagingVM.getBeBackTime(minute: time)
                        }
                }
            }
            
            Button("SELECT TIME", action: toggleCustomPicker)
                .sheet(isPresented: $isShowingCustomPicker) {
                    CustomPickerView(customBeBackTime: $customBeBackTime)
                }
                .padding(.vertical)

            Spacer()
            LazyHGrid(rows: pagingVM.positionRows, spacing: 20) {
                ForEach(pagingVM.positions, id: \.self) { position in
                    Text(position)
                        .font(.system(size: 20, weight: .bold))
                        .frame(width: 100, height: 50)
                        .background(Color.red).opacity(0.5)
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
            
            Text(beBackText)
                .padding(.vertical)
                        
            Button("PAGE", action: pageBack)
                .font(.title).bold()
                .background(.green)
                .buttonStyle(.borderedProminent)
                .disabled(!isSubmittable)
            
            Spacer()
            
            HStack(spacing: 75) {
                if (controller.status == .PAGED_BACK) {
                    Button("CANCEL PAGE", role: .cancel, action: cancelPage)
                        .buttonStyle(.bordered)
                }
                
                Button("RESET", role: .cancel, action: reset)
                    .buttonStyle(.bordered)
            }
            
            
            Spacer()
        }
        .padding(.top)
        .navigationBarBackButtonHidden()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.1))
        .onChange(of: customBeBackTime) { time in
            beBackTime = pagingVM.customBeBackTimeChanged(time: time)
        }
        
    }
    
    func toggleCustomPicker() {
        isShowingCustomPicker.toggle()
    }
    
    func cancelPage() {
        pagingVM.removeBeBack(forController: controller)
        dismiss()
    }
    
    func pageBack() {
        logger.info("In pageBack()")
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
    
    func reset() {
        // TODO: Impl
    }
}

struct PagingView_Previews: PreviewProvider {
    static var previews: some View {
        PagingView(controller: Controller.mock_data.first!)
            .environmentObject(PagingViewModel())
            .previewInterfaceOrientation(.landscapeLeft)
    }
}

enum AssignedPosition {
    case DR1, DR2, DR3, DR4, AR1, AR2, AR3, AR4, FR1, FR2, FR3, FR4, MO1, MO2, MO3, GJT, PUB, CI, FDCD
}

