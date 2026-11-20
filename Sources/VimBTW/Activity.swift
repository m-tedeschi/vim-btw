import Foundation

struct VimActivity: Equatable {
    let isVimRunning: Bool
    let filename: String
    let processID: Int32?
    let processStart: Int?
}

struct PresenceState: Equatable {
    let activity: VimActivity
    let sessionStart: Int
    var hideFilename = false

    var details: String {
        activity.isVimRunning ? "Editing in Vim" : "Using Terminal"
    }

    var state: String? {
        activity.isVimRunning ? (hideFilename ? nil : activity.filename) : "Idle"
    }
}
