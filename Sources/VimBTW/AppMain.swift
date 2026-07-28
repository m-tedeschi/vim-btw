import AppKit
import Darwin

@main
enum AppMain {
    static func main() {
        signal(SIGPIPE, SIG_IGN)

        let app = NSApplication.shared
        let delegate = MenuBarApp()

        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }
}
