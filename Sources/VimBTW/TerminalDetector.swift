import Foundation

final class TerminalDetector {
    private let processNames = ["Ghostty", "ghostty", "Terminal"]

    func isTerminalRunning() -> Bool {
        processNames.contains { isProcessRunning(named: $0) }
    }

    private func isProcessRunning(named name: String) -> Bool {
        let process = Process()
        let pipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
        process.arguments = ["-x", name]
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            return !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        } catch {
            return false
        }
    }
}
