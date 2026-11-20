import Foundation

final class ConfigStore {
    private enum Key {
        static let appID = "discordAppID"
        static let enabled = "presenceEnabled"
        static let fileHiderMode = "fileHiderMode"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            Key.enabled: true,
            Key.fileHiderMode: true
        ])
    }

    var appID: String {
        get { defaults.string(forKey: Key.appID) ?? "" }
        set { defaults.set(newValue.trimmingCharacters(in: .whitespacesAndNewlines), forKey: Key.appID) }
    }

    var isFileHiderModeEnabled: Bool {
        get { defaults.bool(forKey: Key.fileHiderMode) }
        set { defaults.set(newValue, forKey: Key.fileHiderMode) }
    }

    var isEnabled: Bool {
        get { defaults.bool(forKey: Key.enabled) }
        set { defaults.set(newValue, forKey: Key.enabled) }
    }
}
