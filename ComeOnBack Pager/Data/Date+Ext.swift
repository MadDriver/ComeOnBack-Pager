import Foundation

let ONEDAY = 60 * 60 * 12
let ONEHOUR = 60 * 60
let ONEMINUTE = 60

extension Date {
    func secondsUntil(laterDate: Date) -> Int? {
        return Calendar.current.dateComponents([.second], from: self, to: laterDate).second
    }
    
    func from(hours: Int, minutes: Int) -> Date? {
        var dateComps = Calendar.current.dateComponents([.day, .month, .year, .hour, .minute], from: Date())
        dateComps.hour = hours
        dateComps.minute = minutes
        return Calendar.current.date(from: dateComps)
    }
    
    func relative() -> String {
        let delta = Int(self.timeIntervalSinceNow) * -1
        let days = delta / ONEDAY
        let hours = delta / ONEHOUR
        let minutes = (delta - (hours * ONEHOUR)) / 60

        if days > 0 {
            return ("\(days)d \(hours)h")
        }

        if hours > 0 {
            return ("\(hours)h \(minutes)m")
        }

        if minutes > 0 {
            return ("\(minutes)m")
        }

        if delta >= 0 {
            return ("<1m")
        }
        
        return ("Unknown")

    }
}
