import Foundation

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
}
