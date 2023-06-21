//
//  Home.swift
//  ComeOnBack
//
//  Created by Calvin Shultz on 3/9/23.
//

import SwiftUI

struct Home: View {
    
    @ObservedObject var pagingVM = PagingViewModel()
    @State var signInViewIsActive = false
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack {
                HStack {
                    Text("\(pagingVM.timeString(date: pagingVM.date))")
                        .font(.system(size: 32, weight: .bold))
                        .onAppear {
                            let _ = pagingVM.updateTimer
                        }
                    
                    Image(systemName: "pencil")
                        .frame(width: 50, height: 50)
                        .onTapGesture {
                            if pagingVM.timeType == .standard {
                                pagingVM.timeType = .military
                            } else {
                                pagingVM.timeType = .standard
                            }
                        }
                } // H Stack
                
                NavigationStack {
                    VStack {
                        HStack {
                            List {
                                ForEach(pagingVM.onPosition) { controller in
                                    OnPositionCellView(controller: controller)
                                }
                            }
                            
                            List {
                                ForEach($pagingVM.onBreakControllers) { $controller in
                                    
                                    NavigationLink {
                                        PagingView(controller: $controller)
                                    } label: {
                                        StripView(controller: controller)
                                    }
                                    
                                }
                            }
                        }
                    }
                } // Nav Stack
            } // V Stack
            
            Button("SIGN IN/OUT", action: signInController)
                .buttonStyle(.borderedProminent)
                .padding()
            
        } // Z Stack
        .environmentObject(pagingVM)
        .sheet(isPresented: $signInViewIsActive) {
            Text("DFADFDSAFSFS")
        }
    }// body
    
    func signInController() {
        signInViewIsActive = true
    }
}

struct Home_Previews: PreviewProvider {
    static var previews: some View {
        Home()
            .previewInterfaceOrientation(.landscapeLeft)
            .previewDevice(PreviewDevice(rawValue: "iPad (10th generation)"))
    }
}
