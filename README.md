# WorkWife

A macOS menu-bar app that takes over every screen shortly before a meeting starts, so it cannot be missed while you are heads-down.

WorkWife reads events from the macOS Calendar database through EventKit. Nothing leaves the machine: there is no OAuth client, backend, telemetry, or third-party access to your calendar. Google, iCloud, Exchange, or any other account added under **System Settings → Internet Accounts** is picked up automatically.

> [!NOTE]
> The alert is a window at screen-saver level, not a notification. Focus modes and Do Not Disturb do not suppress it.

## Requirements

| | |
|---|---|
| macOS | 14 or later |
| Toolchain | Xcode with Swift 6 |
| Signing | An Apple Development certificate in the login keychain (a free Apple ID personal team works) |

## Build and install

```bash
./build.sh
```

This produces a signed `build/WorkWife.app`. To replace any copy in `/Applications` and launch it:

```bash
./build.sh install
```

`build.sh` signs with the first `Apple Development` identity it finds. Override it with `SIGN_IDENTITY`:

```bash
SIGN_IDENTITY="Apple Development: Name (TEAMID)" ./build.sh install
```

On first launch macOS asks for calendar access. Grant it, then use **Test Alert** from the menu-bar bell to preview the takeover.

> [!IMPORTANT]
> Calendar permission is bound to the code signature. Keep signing with the same certificate so the grant survives rebuilds. Ad-hoc signing (`--sign -`) changes identity on every build and forces macOS to ask again.

## Behaviour

Every 60 seconds WorkWife checks for events whose start time, minus the configured lead time, has arrived. It asks macOS to sync calendar accounts every 15 minutes and immediately on wake from sleep. An event that started less than 5 minutes ago still triggers, which covers a Mac that was asleep at alert time.

An event triggers an alert only if it is:

- not all-day, not cancelled, and not declined by you
- on an enabled calendar
- starting inside your configured workday

The takeover covers every display and Space, including full-screen apps. It shows the event title, calendar, a live countdown, time range, location, and a **Join** button when a Google Meet, Zoom, Teams, Webex, or Whereby link is found in the event URL, location, or notes. Buttons are click-only so that a stray <kbd>Return</kbd> or <kbd>Esc</kbd> while typing cannot dismiss it.

Sound plays `tindeck_1.mp3` once, then loops the system *Submarine* sound until **Join**, **Snooze 1 min**, or **Dismiss** is clicked.

## Settings

Open **Settings…** from the menu-bar bell.

| Setting | Default |
|---|---|
| Interrupt lead time | 2 minutes (0–15) |
| Play sound until dismissed | On |
| Workdays | Monday–Friday |
| Workday hours | 09:00–18:00 |
| Calendars | All enabled |
| Launch at login | Off |

## Project layout

| Path | Purpose |
|---|---|
| `Sources/WorkWife/App.swift` | Entry point, menu-bar item, settings window |
| `Sources/WorkWife/Scheduler.swift` | EventKit queries, filtering, alert timing, snooze, join-link detection |
| `Sources/WorkWife/Overlay.swift` | Full-screen panels, SwiftUI alert view, sound sequencing |
| `Sources/WorkWife/SettingsView.swift` | Settings UI and launch-at-login |
| `Sources/WorkWife/Prefs.swift` | `UserDefaults` keys, defaults, workday check |
| `Support/Info.plist` | Bundle metadata, `LSUIElement`, calendar usage strings |
| `WorkWife-Apple-Icon-Bundle/` | App icon sources; `macOS/WorkWife.icns` is bundled |
| `tindeck_1.mp3` | Alert chime, stored at 50% of the original level |
| `build.sh` | Builds, assembles, and signs the `.app` bundle |
