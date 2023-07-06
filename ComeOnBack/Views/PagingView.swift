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
    @State var selectedBeBackTime: String?
    var controller: Controller
    
    var isSubmittable: Bool { beBackTime != nil }
    
    var beBackText: String {
        if beBackTime == nil { return "Page \(controller.initials)" }
        if beBackPosition == nil { return "Page back \(controller.initials) at \(beBackTime ?? "  ")" }
        return "Page back \(controller.initials) at \(beBackTime ?? "  ") for \(beBackPosition ?? "  ")"
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "x.circle")
                        .font(.system(size: 48))
                        .padding()
                    
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                if (controller.status == .PAGED_BACK) {
                    Button(role: .destructive, action: cancelPage) {
                        Label("Cancel Page", systemImage: "trash")
                    }
                    .padding(.horizontal, 30)
                }
            }
        
            
            VStack {
                Text("\(beBackText)")
                    .font(.title).bold()
                    .padding(.bottom)
                
                HStack {
                    ForEach(pagingVM.beBackTimes, id: \.self) { time in
                        Text(time + " mins")
                            .frame(width: 100, height: 50)
                            .background(Color.blue.opacity(0.5))
                            .border(Color.red, width: selectedBeBackTime == time ? 2.5 : 0)
                            .onTapGesture {
                                selectedBeBackTime = time
                                self.beBackTime = pagingVM.getBeBackTime(minute: time)
                            }
                    }
                }
                
                Button("SELECT TIME", action: { isShowingCustomPicker.toggle() })
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
                
                Spacer()
                
                Button(action: pageBack) {
                    Text("PAGE")
                        .foregroundColor(isSubmittable ? .black : .gray)
                        .frame(width: 500, height: 100)
                        .font(.title).bold()
                        .background(Color.blue.opacity(0.8))
                        .cornerRadius(20)
                        
                }
                .disabled(!isSubmittable)
                
                Spacer()
            } // VStack
            .padding(.top)
        } // ZStack
        .navigationBarBackButtonHidden()
        .background(Color.black.opacity(0.1))
        .onChange(of: customBeBackTime) { time in
            selectedBeBackTime = nil
            beBackTime = pagingVM.customBeBackTimeChanged(time: time)
        }
        .onAppear {
            beBackTime = controller.beBack?.time.stringValue
            beBackPosition = controller.beBack?.forPosition
        }
        
    } // body view
    
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
}

struct PagingView_Previews: PreviewProvider {
    static var previews: some View {
        PagingView(controller: Controller.mock_data.first!)
            .environmentObject(PagingViewModel())
            .previewInterfaceOrientation(.landscapeLeft)
    }
}
