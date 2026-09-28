import AppKit
import SwiftUI

@main
struct WorkWifeMain {
    @MainActor static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let scheduler = Scheduler()
    private let overlay = OverlayController()
    private var statusItem: NSStatusItem!
    private var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        Prefs.register()

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "bell.and.waves.left.and.right", accessibilityDescription: "WorkWife")
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu

        scheduler.onDue = { [weak self] in self?.overlay.present($0) }
        overlay.onSnooze = { [weak self] in self?.scheduler.snooze($0, minutes: 1) }
        scheduler.start()
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        if !scheduler.authorized {
            menu.addItem(disabled: "Calendar access not granted")
            menu.addItem("Open Privacy Settings…", action: #selector(openPrivacySettings), key: "", target: self)
        } else if let next = scheduler.nextMeeting() {
            menu.addItem(disabled: "Next: \(next.title)")
            menu.addItem(disabled: next.start.formatted(date: .abbreviated, time: .shortened))
        } else {
            menu.addItem(disabled: "No meetings in the next 24 hours")
        }

        let joinable = scheduler.joinableMeetings()
        if !joinable.isEmpty {
            menu.addItem(.separator())
            for m in joinable {
                let item = NSMenuItem(title: "Join \(m.title)", action: #selector(openJoinURL(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = m.joinURL
                menu.addItem(item)
            }
        }

        menu.addItem(.separator())
        menu.addItem("Test Alert", action: #selector(testAlert), key: "t", target: self)
        menu.addItem("Settings…", action: #selector(openSettings), key: ",", target: self)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit WorkWife", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }

    @objc private func testAlert() {
        let start = Date().addingTimeInterval(TimeInterval(Prefs.leadMinutes * 60))
        overlay.present([Meeting(
            id: "test-\(UUID().uuidString)",
            title: "Test Meeting",
            start: start,
            end: start.addingTimeInterval(30 * 60),
            calendarTitle: "WorkWife",
            calendarColor: .systemOrange,
            location: nil,
            joinURL: nil
        )])
    }

    @objc private func openSettings() {
        if settingsWindow == nil {
            let window = NSWindow(contentRect: .zero, styleMask: [.titled, .closable], backing: .buffered, defer: false)
            window.title = "WorkWife Settings"
            window.isReleasedWhenClosed = false
            settingsWindow = window
        }
        settingsWindow!.contentViewController = NSHostingController(rootView: SettingsView(calendars: scheduler.calendarInfos()))
        settingsWindow!.center()
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow!.makeKeyAndOrderFront(nil)
    }

    @objc private func openJoinURL(_ sender: NSMenuItem) {
        NSWorkspace.shared.open(sender.representedObject as! URL)
    }

    @objc private func openPrivacySettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars")!)
    }
}

private extension NSMenu {
    func addItem(disabled title: String) {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        addItem(item)
    }

    func addItem(_ title: String, action: Selector, key: String, target: AnyObject) {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = target
        addItem(item)
    }
}
