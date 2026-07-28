import Foundation

final class VimDetector {
    func currentActivity() -> VimActivity {
        guard let processID = vimProcessID() else {
            return VimActivity(isVimRunning: false, filename: "Unknown File", processID: nil, processStart: nil)
        }

        return VimActivity(
            isVimRunning: true,
            filename: currentFilename(),
            processID: processID,
            processStart: processStart(for: processID)
        )
    }

    private func vimProcessID() -> Int32? {
        let output = run("/usr/bin/pgrep", arguments: ["-x", "vim"])
        return output
            .split(separator: "\n")
            .compactMap { Int32($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
            .last
    }

    private func currentFilename() -> String {
        let output = run("/usr/sbin/lsof", arguments: ["-c", "vim"])
        let swapPath = output
            .split(separator: "\n")
            .compactMap(parseOpenRegularFile)
            .filter { $0.hasSuffix(".swp") }
            .last

        guard let swapPath else {
            return "Unknown File"
        }

        return filename(fromSwapPath: swapPath)
    }

    private func parseOpenRegularFile(_ line: Substring) -> String? {
        let columns = line.split(omittingEmptySubsequences: true, whereSeparator: { $0 == " " || $0 == "\t" })
        guard columns.count >= 9, columns.contains("REG") else {
            return nil
        }

        return columns[8...].joined(separator: " ")
    }

    private func filename(fromSwapPath path: String) -> String {
        var basename = URL(fileURLWithPath: path).lastPathComponent

        if basename.hasPrefix(".") {
            basename.removeFirst()
        }

        if basename.hasSuffix(".swp") {
            basename.removeLast(4)
        }

        return basename.isEmpty ? "Unknown File" : basename
    }

    private func processStart(for processID: Int32) -> Int? {
        let output = run("/bin/ps", arguments: ["-p", String(processID), "-o", "etime="])
        guard let elapsedSeconds = elapsedTime(from: output.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return nil
        }

        return Int(Date().timeIntervalSince1970) - elapsedSeconds
    }

    private func elapsedTime(from value: String) -> Int? {
        let dayParts = value.split(separator: "-", maxSplits: 1).map(String.init)
        let days: Int
        let clock: String

        if dayParts.count == 2 {
            days = Int(dayParts[0]) ?? 0
            clock = dayParts[1]
        } else {
            days = 0
            clock = value
        }

        let clockParts = clock.split(separator: ":").compactMap { Int($0) }
        guard clockParts.count == 2 || clockParts.count == 3 else {
            return nil
        }

        let hours = clockParts.count == 3 ? clockParts[0] : 0
        let minutes = clockParts.count == 3 ? clockParts[1] : clockParts[0]
        let seconds = clockParts.count == 3 ? clockParts[2] : clockParts[1]

        return days * 86_400 + hours * 3_600 + minutes * 60 + seconds
    }

    private func run(_ executable: String, arguments: [String]) -> String {
        let process = Process()
        let pipe = Pipe()

        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            return ""
        }
    }
}
