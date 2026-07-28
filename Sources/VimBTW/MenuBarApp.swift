import AppKit
import Foundation

@MainActor
final class MenuBarApp: NSObject, NSApplicationDelegate, PresenceControllerDelegate {
    private let config = ConfigStore()
    private lazy var presenceController = PresenceController(config: config)

    private var statusItem: NSStatusItem!
    private let menu = NSMenu()
    private let statusMenuItem = NSMenuItem(title: "Starting...", action: nil, keyEquivalent: "")
    private let activityMenuItem = NSMenuItem(title: "Activity: Idle", action: nil, keyEquivalent: "")
    private let toggleMenuItem = NSMenuItem(title: "Disable Presence", action: #selector(togglePresence), keyEquivalent: "")
    private let appIDMenuItem = NSMenuItem(title: "Set Discord App ID...", action: #selector(promptForAppID), keyEquivalent: "")

    func applicationDidFinishLaunching(_ notification: Notification) {
        presenceController.delegate = self
        configureStatusItem()
        configureMenu()
        presenceController.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        presenceController.stop()
    }

    func presenceControllerDidUpdate(_ controller: PresenceController) {
        refreshMenu()
    }

    private func configureStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        guard let button = statusItem.button else {
            return
        }

        button.image = Self.makeStatusIcon()
        button.imagePosition = .imageOnly
        button.toolTip = "Vim BTW"
        statusItem.menu = menu
    }

    private func configureMenu() {
        statusMenuItem.isEnabled = false
        activityMenuItem.isEnabled = false

        menu.addItem(statusMenuItem)
        menu.addItem(activityMenuItem)
        menu.addItem(.separator())
        menu.addItem(toggleMenuItem)
        menu.addItem(appIDMenuItem)
        menu.addItem(NSMenuItem(title: "Refresh Now", action: #selector(refreshNow), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: ""))

        for item in menu.items {
            item.target = self
        }

        refreshMenu()
    }

    private func refreshMenu() {
        statusMenuItem.title = "Status: \(presenceController.statusText)"

        let activity = presenceController.currentActivity
        activityMenuItem.title = activity.isVimRunning
            ? "Activity: Editing \(activity.filename)"
            : "Activity: Idle"

        toggleMenuItem.title = presenceController.isEnabled ? "Disable Presence" : "Enable Presence"

        if presenceController.appID.isEmpty {
            appIDMenuItem.title = "Set Discord App ID..."
        } else {
            appIDMenuItem.title = "Change Discord App ID..."
        }
    }

    @objc private func togglePresence() {
        presenceController.setEnabled(!presenceController.isEnabled)
    }

    @objc private func refreshNow() {
        presenceController.tick()
    }

    @objc private func promptForAppID() {
        let alert = NSAlert()
        alert.messageText = "Discord App ID"
        alert.informativeText = "Enter the Discord application client ID used for Rich Presence."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")

        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 320, height: 24))
        input.stringValue = presenceController.appID
        input.placeholderString = "Application ID"
        alert.accessoryView = input

        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()

        if response == .alertFirstButtonReturn {
            presenceController.setAppID(input.stringValue)
        }
    }

    @objc private func quit() {
        presenceController.stop()
        NSApp.terminate(nil)
    }

    private static func makeStatusIcon() -> NSImage {
        let image = NSImage(size: NSSize(width: 28, height: 18))
        image.lockFocus()

        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .semibold),
            .foregroundColor: NSColor.black
        ]
        let text = "Vim"
        let size = text.size(withAttributes: attrs)
        text.draw(
            at: NSPoint(
                x: (image.size.width - size.width) / 2,
                y: (image.size.height - size.height) / 2 - 1
            ),
            withAttributes: attrs
        )

        image.unlockFocus()
        image.isTemplate = true
        return image
    }
}
