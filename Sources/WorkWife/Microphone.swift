import CoreAudio

enum Microphone {
    private static let callAppBundlePrefixes = [
        "us.zoom.xos",
        "com.microsoft.teams2",
        "com.google.Chrome",
        "com.brave.Browser",
        "com.microsoft.edgemac",
        "company.thebrowser.Browser",
        "org.mozilla.firefox",
        "com.apple.WebKit",
        "com.apple.FaceTime",
        "com.cisco.webexmeetingsapp",
        "Cisco-Systems.Spark",
        "com.tinyspeck.slackmacgap",
    ]

    static func inUseByCallApp() -> Bool {
        processObjects().contains { process in
            guard isRunningInput(process) else { return false }
            let id = bundleID(process)
            return callAppBundlePrefixes.contains { id.hasPrefix($0) }
        }
    }

    private static func processObjects() -> [AudioObjectID] {
        var address = address(kAudioHardwarePropertyProcessObjectList)
        var size: UInt32 = 0
        AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size)
        var objects = [AudioObjectID](repeating: 0, count: Int(size) / MemoryLayout<AudioObjectID>.size)
        AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &objects)
        return objects
    }

    private static func address(_ selector: AudioObjectPropertySelector) -> AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(mSelector: selector, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
    }

    private static func isRunningInput(_ process: AudioObjectID) -> Bool {
        var address = address(kAudioProcessPropertyIsRunningInput)
        var running: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        AudioObjectGetPropertyData(process, &address, 0, nil, &size, &running)
        return running != 0
    }

    private static func bundleID(_ process: AudioObjectID) -> String {
        var address = address(kAudioProcessPropertyBundleID)
        var value: Unmanaged<CFString>?
        var size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        AudioObjectGetPropertyData(process, &address, 0, nil, &size, &value)
        return value?.takeRetainedValue() as String? ?? ""
    }
}
