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
        if delta > ONEDAY {
            return ("\(delta / ONEDAY)d")
        }

        if delta > ONEHOUR {
            return ("\(delta / ONEHOUR)h \(delta % 60)m")
        }

        if delta > ONEMINUTE {
            return ("\(delta / ONEMINUTE)m")
        }

        if delta >= 0 {
            return ("<1m")
            //return ("\(delta)s")
        }
        
        return ("Unknown")

    }
}
