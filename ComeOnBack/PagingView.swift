//
//  PagingView.swift
//  ComeOnBack
//
//  Created by Calvin Shultz on 3/11/23.
//

import SwiftUI

struct PagingView: View {
    
    @StateObject var pagingVM = PagingViewModel()
    
    
    @State var beBackPosition = "_____"
    @State var beBackTime = "_____"
    @State var isShowingCustomPicker = false
    @State var customBeBackTime = 0
    
    
    
    
    var body: some View {
        VStack {
                        
            Text("Page RR?")
                .font(.title).bold()
                .padding(.bottom)
                
            Text("\(pagingVM.timeString(date: pagingVM.date))")
                .font(.system(size: 32, weight: .bold))
                .onAppear {
                    let _ = pagingVM.updateTimer
                }
            
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
                        .frame(width: 100, height: 50)
                        .background(Color.red).opacity(0.5)
                        .onTapGesture {
                            beBackPosition = position
                        }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height:250)
            
            Text("Page back RR at \(beBackTime) for \(beBackPosition)")
                .padding(.vertical)
                        
            
            HStack(spacing: 75) {
                
                Button("CANCEL", role: .cancel, action: cancelPage)
                    .buttonStyle(.bordered)
                
                Button("PAGE", action: pageBack)
                    .buttonStyle(.borderedProminent)
            }
            
            
            Spacer()
        }
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
        
    }
    
    func pageBack() {
        
    }
    
}

struct PagingView_Previews: PreviewProvider {
    static var previews: some View {
        PagingView()
            .previewInterfaceOrientation(.landscapeLeft)
    }
}

enum AssignedPosition {
    case DR1, DR2, DR3, DR4, AR1, AR2, AR3, AR4, FR1, FR2, FR3, FR4, MO1, MO2, MO3, GJT, PUB, CI, FDCD
}

