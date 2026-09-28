import AppKit
import EventKit

struct Meeting: Identifiable {
    let id: String
    let title: String
    let start: Date
    let end: Date
    let calendarTitle: String
    let calendarColor: NSColor
    let location: String?
    let joinURL: URL?
}

struct CalendarInfo: Identifiable {
    let id: String
    let title: String
    let source: String
    let color: NSColor
}

@MainActor
final class Scheduler {
    private let store = EKEventStore()
    private(set) var authorized = false
    private var alerted: Set<String> = []
    private var snoozed: [String: (until: Date, meeting: Meeting)] = [:]
    private var tickTimer: Timer?
    private var syncTimer: Timer?
    private let lateWindow: TimeInterval = 5 * 60
    private let joinWindow: TimeInterval = 15 * 60
    var onDue: (([Meeting]) -> Void)?

    func start() {
        store.requestFullAccessToEvents { granted, _ in
            Task { @MainActor in
                self.authorized = granted
                self.tick()
            }
        }
        tickTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        syncTimer = Timer.scheduledTimer(withTimeInterval: 15 * 60, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.store.refreshSourcesIfNecessary() }
        }
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.store.refreshSourcesIfNecessary()
                self?.tick()
            }
        }
    }

    func snooze(_ meetings: [Meeting], minutes: Int) {
        let until = Date().addingTimeInterval(TimeInterval(minutes * 60))
        for m in meetings { snoozed[m.id] = (until, m) }
    }

    func tick() {
        let now = Date()
        var due = snoozed.values.filter { $0.until <= now }.map(\.meeting)
        for m in due { snoozed[m.id] = nil }

        if authorized {
            let lead = TimeInterval(Prefs.leadMinutes * 60)
            due += meetings(from: now.addingTimeInterval(-lateWindow), to: now.addingTimeInterval(lead + 1)).filter {
                !alerted.contains($0.id) && snoozed[$0.id] == nil
                    && $0.start.addingTimeInterval(-lead) <= now
                    && now < $0.start.addingTimeInterval(lateWindow)
            }
        }

        guard !due.isEmpty else { return }
        for m in due { alerted.insert(m.id) }
        onDue?(due)
    }

    func nextMeeting() -> Meeting? {
        guard authorized else { return nil }
        let now = Date()
        return meetings(from: now, to: now.addingTimeInterval(24 * 3600)).first { $0.start > now }
    }

    func joinableMeetings() -> [Meeting] {
        guard authorized else { return [] }
        let now = Date()
        return meetings(from: now.addingTimeInterval(-12 * 3600), to: now.addingTimeInterval(joinWindow))
            .filter { $0.joinURL != nil && $0.end > now && $0.start <= now.addingTimeInterval(joinWindow) }
    }

    func calendarInfos() -> [CalendarInfo] {
        guard authorized else { return [] }
        return store.calendars(for: .event)
            .map { CalendarInfo(id: $0.calendarIdentifier, title: $0.title, source: $0.source.title, color: $0.color) }
            .sorted { ($0.source, $0.title) < ($1.source, $1.title) }
    }

    private func meetings(from start: Date, to end: Date) -> [Meeting] {
        let excluded = Prefs.excludedCalendars
        let calendars = store.calendars(for: .event).filter { !excluded.contains($0.calendarIdentifier) }
        guard !calendars.isEmpty else { return [] }
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: calendars)
        return store.events(matching: predicate)
            .filter { e in
                !e.isAllDay
                    && e.status != .canceled
                    && e.startDate >= start
                    && e.attendees?.first(where: \.isCurrentUser)?.participantStatus != .declined
                    && Prefs.isWorkTime(e.startDate)
            }
            .sorted { $0.startDate < $1.startDate }
            .map { e in
                Meeting(
                    id: "\(e.calendarItemIdentifier)@\(e.startDate.timeIntervalSince1970)",
                    title: e.title ?? "Untitled",
                    start: e.startDate,
                    end: e.endDate,
                    calendarTitle: e.calendar.title,
                    calendarColor: e.calendar.color,
                    location: e.location?.isEmpty == false ? e.location : nil,
                    joinURL: Self.joinURL(for: e)
                )
            }
    }

    private static let conferenceHosts = ["meet.google.com", "zoom.us", "teams.microsoft.com", "teams.live.com", "webex.com", "whereby.com"]
    private static let linkDetector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)

    private static func joinURL(for event: EKEvent) -> URL? {
        let text = [event.url?.absoluteString, event.location, event.notes].compactMap { $0 }.joined(separator: "\n")
        return linkDetector.matches(in: text, range: NSRange(text.startIndex..., in: text))
            .compactMap(\.url)
            .first { url in
                guard let host = url.host?.lowercased() else { return false }
                return conferenceHosts.contains { host == $0 || host.hasSuffix("." + $0) }
            }
    }
}
