import Foundation

@MainActor
protocol PresenceControllerDelegate: AnyObject {
    func presenceControllerDidUpdate(_ controller: PresenceController)
}

@MainActor
final class PresenceController {
    weak var delegate: PresenceControllerDelegate?

    private let config: ConfigStore
    private let detector: VimDetector
    private var client: DiscordIPCClient?
    private var timer: Timer?
    private var lastPresence: PresenceState?
    private var vimSessionStart = Int(Date().timeIntervalSince1970)

    private(set) var statusText = "Not connected"
    private(set) var currentActivity = VimActivity(
        isVimRunning: false,
        filename: "Unknown File",
        processID: nil,
        processStart: nil
    )

    init(config: ConfigStore, detector: VimDetector = VimDetector()) {
        self.config = config
        self.detector = detector
    }

    var isEnabled: Bool {
        config.isEnabled
    }

    var appID: String {
        config.appID
    }

    func start() {
        timer?.invalidate()
        tick()
        timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        clearPresence()
        client?.disconnect()
        client = nil
    }

    func setEnabled(_ enabled: Bool) {
        config.isEnabled = enabled
        if enabled {
            statusText = "Enabled"
            tick()
        } else {
            clearPresence()
            client?.disconnect()
            client = nil
            statusText = "Disabled"
        }
        delegate?.presenceControllerDidUpdate(self)
    }

    func setAppID(_ appID: String) {
        config.appID = appID
        client?.disconnect()
        client = nil
        statusText = appID.isEmpty ? "Missing Discord App ID" : "App ID updated"
        tick()
        delegate?.presenceControllerDidUpdate(self)
    }

    func tick() {
        guard config.isEnabled else {
            statusText = "Disabled"
            delegate?.presenceControllerDidUpdate(self)
            return
        }

        guard !config.appID.isEmpty else {
            statusText = "Missing Discord App ID"
            delegate?.presenceControllerDidUpdate(self)
            return
        }

        let activity = detector.currentActivity()
        updateSessionStart(for: activity)
        currentActivity = activity

        let presence = PresenceState(activity: activity, sessionStart: vimSessionStart)

        do {
            let client = try connectedClient()
            try client.setActivity(presence)
            lastPresence = presence
            statusText = activity.isVimRunning ? "Editing \(activity.filename)" : "Idle"
        } catch {
            client?.disconnect()
            client = nil
            statusText = "\(error)"
        }

        delegate?.presenceControllerDidUpdate(self)
    }

    private func updateSessionStart(for activity: VimActivity) {
        guard activity != currentActivity else {
            return
        }

        if activity.isVimRunning != currentActivity.isVimRunning {
            vimSessionStart = activity.processStart ?? Int(Date().timeIntervalSince1970)
            return
        }
    }

    private func connectedClient() throws -> DiscordIPCClient {
        if let client, client.isConnected {
            return client
        }

        let newClient = DiscordIPCClient(clientID: config.appID)
        try newClient.connect()
        client = newClient
        return newClient
    }

    private func clearPresence() {
        do {
            let client = try connectedClient()
            try client.clearActivity()
        } catch {
            // Clearing is best-effort during shutdown or disable.
        }
        lastPresence = nil
    }
}
