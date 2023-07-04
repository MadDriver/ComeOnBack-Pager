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
    @Binding var controller: Controller
    @State var beBackPosition: String?
    @State var beBackTime: String?
    @State var isShowingCustomPicker = false
    @State var customBeBackTime = 0
    
    var isSubmittable: Bool { beBackTime != nil }
    
    var beBackText: String {
        if beBackTime == nil {
            return ""
        }
        if beBackPosition == nil {
            return "Page back \(controller.initials) at \(beBackTime ?? "  ")"
            
        }
        return "Page back \(controller.initials) at \(beBackTime ?? "  ") for \(beBackPosition ?? "  ")"
    }
    
    var body: some View {
        VStack {
                        
            Text("Page \(controller.initials)?")
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
                        .onTapGesture {
                            beBackPosition = position
                        }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height:250)
            
            Text(beBackText)
                .padding(.vertical)
                        
            
            HStack(spacing: 75) {
                
                Button("CANCEL", role: .cancel, action: cancelPage)
                    .buttonStyle(.bordered)
                
                Button("RESET", role: .cancel, action: reset)
                    .buttonStyle(.bordered)
                
                Button("PAGE", action: pageBack)
                    .buttonStyle(.borderedProminent)
                    .disabled(!isSubmittable)
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
        dismiss()
    }
    
    func pageBack() {
        Task {
            do {
                try await submitBeBack()
            } catch is APIError {
                logger.error("APIError in pageBack()")
            } catch {
                logger.error("Unexpected error in pageBack(): \(error)")
            }
        }
    }
    
    func reset() {
        // TODO: Impl
    }
    
    func submitBeBack() async throws {
        logger.info("In submitBeBack()")
        guard let beBackTime = beBackTime else {
            logger.error("beBackTime must be defined before calling submitBeBack()")
            return
        }
        let beBack = try await API().submitBeBack(initials: controller.initials,
                                     time: beBackTime,
                                     forPosition: beBackPosition)
        DispatchQueue.main.async {
            self.controller.status = .PAGED_BACK
            self.controller.beBack = beBack
            dismiss()
        }
    }
    
}

struct PagingView_Previews: PreviewProvider {
    static var previews: some View {
        let beBack = BeBack(initials: "RR", time: "10:00", forPosition: "FR1")
        PagingView(controller:
                .constant(Controller(initials: "RR",
                                     area: "",
                                     isDev: false,
                                     status: .PAGED_BACK,
                                     beBack: beBack
                                    )
                ))
            .environmentObject(PagingViewModel())
            .previewInterfaceOrientation(.landscapeLeft)
    }
}

enum AssignedPosition {
    case DR1, DR2, DR3, DR4, AR1, AR2, AR3, AR4, FR1, FR2, FR3, FR4, MO1, MO2, MO3, GJT, PUB, CI, FDCD
}

