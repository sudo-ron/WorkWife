import AppKit
import SwiftUI

final class FirstClickHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}

@MainActor
final class OverlayController {
    private var panels: [NSPanel] = []
    private var meetings: [Meeting] = []
    private var chime: NSSound?
    private var loop: NSSound?
    private var loopTimer: Timer?
    var onSnooze: (([Meeting]) -> Void)?

    func present(_ new: [Meeting]) {
        for m in new where !meetings.contains(where: { $0.id == m.id }) {
            meetings.append(m)
        }
        meetings.sort { $0.start < $1.start }
        render()

        if Prefs.playSound && chime == nil && loop == nil {
            let chime = NSSound(contentsOf: Bundle.main.url(forResource: "tindeck_1", withExtension: "mp3")!, byReference: true)!
            chime.play()
            self.chime = chime
            guard !Microphone.inUseByCallApp() else { return }
            loopTimer = Timer.scheduledTimer(withTimeInterval: chime.duration, repeats: false) { [weak self] _ in
                MainActor.assumeIsolated { self?.startLoop() }
            }
        }
    }

    private func render() {
        closePanels()

        for screen in NSScreen.screens {
            let panel = NSPanel(contentRect: screen.frame, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
            panel.setFrame(screen.frame, display: false)
            panel.level = .screenSaver
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
            panel.sharingType = .none
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.hidesOnDeactivate = false
            panel.isReleasedWhenClosed = false
            panel.appearance = NSAppearance(named: .darkAqua)

            let blur = NSVisualEffectView(frame: NSRect(origin: .zero, size: screen.frame.size))
            blur.material = .fullScreenUI
            blur.blendingMode = .behindWindow
            blur.state = .active
            blur.autoresizingMask = [.width, .height]

            let host = FirstClickHostingView(rootView: OverlayView(
                meetings: meetings,
                join: { [weak self] m in self?.join(m) },
                snooze: { [weak self] in
                    guard let self else { return }
                    self.onSnooze?(self.meetings)
                    self.dismiss()
                },
                dismiss: { [weak self] in self?.dismiss() }
            ))
            host.frame = blur.bounds
            host.autoresizingMask = [.width, .height]
            blur.addSubview(host)
            panel.contentView = blur
            panels.append(panel)
        }

        for panel in panels { panel.orderFrontRegardless() }
    }

    private func join(_ meeting: Meeting) {
        NSWorkspace.shared.open(meeting.joinURL!)
        meetings.removeAll { $0.id == meeting.id }
        if meetings.isEmpty { dismiss() } else { render() }
    }

    private func startLoop() {
        chime = nil
        loop = NSSound(named: "Submarine")!.copy() as? NSSound
        loop!.loops = true
        loop!.play()
    }

    private func dismiss() {
        loopTimer?.invalidate()
        loopTimer = nil
        chime?.stop()
        chime = nil
        loop?.stop()
        loop = nil
        meetings = []
        closePanels()
    }

    private func closePanels() {
        for panel in panels { panel.close() }
        panels = []
    }
}

struct OverlayView: View {
    let meetings: [Meeting]
    let join: (Meeting) -> Void
    let snooze: () -> Void
    let dismiss: () -> Void

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            VStack(spacing: 48) {
                Text(context.date, format: .dateTime.hour().minute())
                    .font(.system(size: 32, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)

                ForEach(meetings) { m in
                    VStack(spacing: 14) {
                        HStack(spacing: 10) {
                            Circle().fill(Color(nsColor: m.calendarColor)).frame(width: 14, height: 14)
                            Text(m.calendarTitle).font(.title3).foregroundStyle(.secondary)
                        }
                        Text(m.title)
                            .font(.system(size: 64, weight: .bold))
                            .multilineTextAlignment(.center)
                        Text(countdown(to: m.start, now: context.date))
                            .font(.system(size: 30, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(m.start > context.date ? Color.orange : Color.red)
                        Text("\(m.start.formatted(date: .omitted, time: .shortened)) – \(m.end.formatted(date: .omitted, time: .shortened))")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        if let location = m.location {
                            Text(location).font(.title3).foregroundStyle(.secondary).lineLimit(2)
                        }
                        if m.joinURL != nil {
                            Button("Join \(m.joinURL!.host ?? "")") { join(m) }
                                .buttonStyle(.borderedProminent)
                                .tint(.orange)
                                .controlSize(.extraLarge)
                        }
                    }
                }

                HStack(spacing: 20) {
                    Button("Snooze 1 min", action: snooze).controlSize(.extraLarge)
                    Button(meetings.count > 1 ? "Dismiss all" : "Dismiss", action: dismiss).controlSize(.extraLarge)
                }
            }
            .padding(60)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.35))
        }
    }

    private func countdown(to start: Date, now: Date) -> String {
        let seconds = Int(start.timeIntervalSince(now).rounded())
        let clock = String(format: "%d:%02d", abs(seconds) / 60, abs(seconds) % 60)
        return seconds > 0 ? "Starts in \(clock)" : "Started \(clock) ago"
    }
}
