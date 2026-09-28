import ServiceManagement
import SwiftUI

struct SettingsView: View {
    let calendars: [CalendarInfo]

    @AppStorage(PrefKey.leadMinutes) private var leadMinutes = 2
    @AppStorage(PrefKey.workStartMinutes) private var workStart = 9 * 60
    @AppStorage(PrefKey.workEndMinutes) private var workEnd = 18 * 60
    @AppStorage(PrefKey.workDaysMask) private var workDays = 0b0111110
    @AppStorage(PrefKey.excludedCalendars) private var excluded = ""
    @AppStorage(PrefKey.playSound) private var playSound = true
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var loginError: String?

    var body: some View {
        Form {
            Section("Alert") {
                Stepper("Interrupt \(leadMinutes) min before start", value: $leadMinutes, in: 0...15)
                Toggle("Play sound", isOn: $playSound)
            }

            Section("Workday") {
                HStack {
                    ForEach(orderedWeekdays, id: \.self) { weekday in
                        Toggle(Calendar.current.shortWeekdaySymbols[weekday - 1], isOn: dayBinding(weekday))
                            .toggleStyle(.button)
                    }
                }
                DatePicker("Start", selection: timeBinding($workStart), displayedComponents: .hourAndMinute)
                DatePicker("End", selection: timeBinding($workEnd), displayedComponents: .hourAndMinute)
            }

            Section("Calendars") {
                if calendars.isEmpty {
                    Text("Calendar access not granted.").foregroundStyle(.secondary)
                }
                ForEach(calendars) { cal in
                    Toggle(isOn: calendarBinding(cal.id)) {
                        HStack {
                            Circle().fill(Color(nsColor: cal.color)).frame(width: 10, height: 10)
                            Text(cal.title)
                            Text(cal.source).foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, enabled in
                        do {
                            if enabled {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                            loginError = nil
                        } catch {
                            loginError = error.localizedDescription
                        }
                    }
                if let loginError {
                    Text(loginError).foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 480, height: 600)
    }

    private var orderedWeekdays: [Int] {
        let first = Calendar.current.firstWeekday
        return (0..<7).map { (first - 1 + $0) % 7 + 1 }
    }

    private func dayBinding(_ weekday: Int) -> Binding<Bool> {
        let bit = 1 << (weekday - 1)
        return Binding(
            get: { workDays & bit != 0 },
            set: { workDays = $0 ? workDays | bit : workDays & ~bit }
        )
    }

    private func timeBinding(_ minutes: Binding<Int>) -> Binding<Date> {
        Binding(
            get: { Calendar.current.date(bySettingHour: minutes.wrappedValue / 60, minute: minutes.wrappedValue % 60, second: 0, of: .now)! },
            set: {
                let c = Calendar.current.dateComponents([.hour, .minute], from: $0)
                minutes.wrappedValue = c.hour! * 60 + c.minute!
            }
        )
    }

    private func calendarBinding(_ id: String) -> Binding<Bool> {
        Binding(
            get: { !excluded.split(separator: "\n").contains(Substring(id)) },
            set: { include in
                var ids = Set(excluded.split(separator: "\n").map(String.init))
                if include { ids.remove(id) } else { ids.insert(id) }
                excluded = ids.sorted().joined(separator: "\n")
            }
        )
    }
}
