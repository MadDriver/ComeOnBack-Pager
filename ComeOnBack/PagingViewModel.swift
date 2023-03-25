//
//  PagingViewModel.swift
//  ComeOnBack
//
//  Created by Calvin Shultz on 3/11/23.
//

import SwiftUI

final class PagingViewModel: ObservableObject {
    
    @Published var onBreakControllers: [Controller] = [
        Controller(initials: "RR", isPagedBack: false),
        Controller(initials: "MJ", isPagedBack: false),
        Controller(initials: "KT", isPagedBack: false),
        Controller(initials: "GM", isPagedBack: false),
        Controller(initials: "PZ", isPagedBack: false),
        Controller(initials: "SW", isPagedBack: false),
        Controller(initials: "KW", isPagedBack: false),
        Controller(initials: "GC", isPagedBack: false),
        Controller(initials: "TO", isPagedBack: false),
        Controller(initials: "AA", isPagedBack: false),
        Controller(initials: "BB", isPagedBack: false),
        Controller(initials: "CC", isPagedBack: false),
        Controller(initials: "DD", isPagedBack: false),
        Controller(initials: "EE", isPagedBack: false),
        Controller(initials: "EG", isPagedBack: false),
        Controller(initials: "PL", isPagedBack: false),
        Controller(initials: "FF", isPagedBack: false),
        Controller(initials: "GG", isPagedBack: false)
    ]
    @Published var date = Date()
    @Published var onPosition: [Controller] = [
        Controller(initials: "YY", isPagedBack: false),
        Controller(initials: "XX", isPagedBack: false),
        Controller(initials: "PP", isPagedBack: false),
        Controller(initials: "RB", isPagedBack: false),
        Controller(initials: "BR", isPagedBack: false),
        Controller(initials: "YT", isPagedBack: false),
        Controller(initials: "VM", isPagedBack: false)
    ]
    let positions = [
        "DR1", "DR2", "DR3", "DR4", "AR1", "AR2", "AR3", "AR4", "FR1", "FR2", "FR3", "FR4", "SR1", "SR2", "SR4", "FDCD", "MO1", "MO2", "MO3", "CI", "GJT", "PUB", "TBD"
    
    ]
    let beBackTimes = [
        "10", "15", "30", "45"
    ]
    let positionRows = [
        GridItem(), GridItem(), GridItem(), GridItem()
    ]
    let beBackTimeRows = [
        GridItem(), GridItem()
    ]
    
    var timeFormat: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm:ss a"
        return formatter
    }
    
    var beBackTimeFormat: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }
    
    func getBeBackTime(minute: String) -> String {
        
        let calendar = Calendar.current
        let timeToAdd = Int(minute)!
        let dateToEdit = calendar.date(byAdding: .minute, value: timeToAdd, to: date)!
        let m = calendar.component(.minute, from: dateToEdit)
        
        if m % 5 != 0 {
            let r = 5 - (m % 5)
            let minuteToAdd = timeToAdd + r
            let actualDate = calendar.date(byAdding: .minute, value: minuteToAdd, to: date)!
            return beBackTimeFormat.string(from: actualDate)
        } else {
            return beBackTimeFormat.string(from: dateToEdit)
        }
        
    }
    
    func timeString(date: Date) -> String {
        let time = timeFormat.string(from: date)
        return time
    }
    
    var updateTimer: Timer {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in
            self.date = Date()
        })
    }
    
    func customBeBackTimeChanged(time: Int) -> String {
        let calendar = Calendar.current
        let dateOne = calendar.date(bySetting: .minute, value: time, of: date)!
        let dateString = beBackTimeFormat.string(from: dateOne)
        return dateString
    }
    
}
