import Foundation

enum PrefKey {
    static let leadMinutes = "leadMinutes"
    static let workStartMinutes = "workStartMinutes"
    static let workEndMinutes = "workEndMinutes"
    static let workDaysMask = "workDaysMask"
    static let excludedCalendars = "excludedCalendars"
    static let playSound = "playSound"
}

enum Prefs {
    static func register() {
        UserDefaults.standard.register(defaults: [
            PrefKey.leadMinutes: 2,
            PrefKey.workStartMinutes: 9 * 60,
            PrefKey.workEndMinutes: 18 * 60,
            PrefKey.workDaysMask: 0b0111110,
            PrefKey.excludedCalendars: "",
            PrefKey.playSound: true,
        ])
    }

    static var leadMinutes: Int { UserDefaults.standard.integer(forKey: PrefKey.leadMinutes) }
    static var playSound: Bool { UserDefaults.standard.bool(forKey: PrefKey.playSound) }

    static var excludedCalendars: Set<String> {
        Set(UserDefaults.standard.string(forKey: PrefKey.excludedCalendars)!.split(separator: "\n").map(String.init))
    }

    static func isWorkTime(_ date: Date) -> Bool {
        let d = UserDefaults.standard
        let c = Calendar.current.dateComponents([.weekday, .hour, .minute], from: date)
        guard d.integer(forKey: PrefKey.workDaysMask) & (1 << (c.weekday! - 1)) != 0 else { return false }
        let minute = c.hour! * 60 + c.minute!
        return minute >= d.integer(forKey: PrefKey.workStartMinutes) && minute < d.integer(forKey: PrefKey.workEndMinutes)
    }
}
