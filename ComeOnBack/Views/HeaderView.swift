//
//  HeaderView.swift
//  ComeOnBack
//
//  Created by user on 7/4/23.
//

import SwiftUI

struct HeaderView: View {
    @State var now = Date()
    @EnvironmentObject var displaySettings: DisplaySettings
    
    var localTimeFormat: DateFormatter {
        let formatter = DateFormatter()
        if displaySettings.useMilitaryTime {
            formatter.dateFormat = "HH:mm"
        } else {
            formatter.dateFormat = "h:mm a"
        }
        return formatter
    }
    
    var utcFormat: DateFormatter {
        let utcFormatter = DateFormatter()
        utcFormatter.dateFormat = "HH:mm"
        utcFormatter.locale = Locale(identifier: "en_US_POSIX")
        utcFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        return utcFormatter
    }
    
    var localTimeString:String { localTimeFormat.string(from: now) }
    var utcTimeString: String { utcFormat.string(from: now) }
    
    var updateTimer: Timer {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in
            now = Date()
        })
    }
    
    var body: some View {
        HStack {
            Text("\(localTimeString)")
                .font(.system(size: 32, weight: .bold))
                .onTapGesture { displaySettings.useMilitaryTime.toggle() }
            Text(" -- ")
            Text("\(utcTimeString)z")
                .font(.system(size: 32, weight: .bold))
        }
        .onAppear {
            let _ = updateTimer
        }
    }
    

}

struct HeaderView_Previews: PreviewProvider {
    static var previews: some View {
        HeaderView()
    }
}
