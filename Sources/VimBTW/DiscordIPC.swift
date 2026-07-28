import Darwin
import Foundation

enum DiscordIPCError: Error, CustomStringConvertible {
    case socketNotFound
    case connectFailed(String)
    case disconnected
    case invalidPayload

    var description: String {
        switch self {
        case .socketNotFound:
            return "Discord IPC socket not found"
        case .connectFailed(let message):
            return "Discord IPC connection failed: \(message)"
        case .disconnected:
            return "Discord IPC disconnected"
        case .invalidPayload:
            return "Discord IPC payload could not be encoded"
        }
    }
}

final class DiscordIPCClient {
    private enum Opcode: UInt32 {
        case handshake = 0
        case frame = 1
    }

    private let clientID: String
    private var fd: Int32 = -1

    init(clientID: String) {
        self.clientID = clientID
    }

    deinit {
        disconnect()
    }

    var isConnected: Bool {
        fd >= 0
    }

    func connect() throws {
        disconnect()

        let path = try Self.findSocketPath()
        let socketFD = Darwin.socket(AF_UNIX, SOCK_STREAM, 0)
        guard socketFD >= 0 else {
            throw DiscordIPCError.connectFailed(String(cString: strerror(errno)))
        }

        var address = sockaddr_un()
        address.sun_family = sa_family_t(AF_UNIX)

        let maxLength = MemoryLayout.size(ofValue: address.sun_path)
        guard path.utf8.count < maxLength else {
            Darwin.close(socketFD)
            throw DiscordIPCError.connectFailed("socket path is too long")
        }

        withUnsafeMutablePointer(to: &address.sun_path) { pointer in
            pointer.withMemoryRebound(to: CChar.self, capacity: maxLength) { cString in
                _ = path.withCString { source in
                    strncpy(cString, source, maxLength)
                }
            }
        }

        let addressLength = socklen_t(MemoryLayout<sa_family_t>.size + path.utf8.count + 1)
        let result = withUnsafePointer(to: &address) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                Darwin.connect(socketFD, $0, addressLength)
            }
        }

        guard result == 0 else {
            let message = String(cString: strerror(errno))
            Darwin.close(socketFD)
            throw DiscordIPCError.connectFailed(message)
        }

        fd = socketFD
        try send(opcode: .handshake, payload: [
            "v": 1,
            "client_id": clientID
        ])
    }

    func disconnect() {
        if fd >= 0 {
            Darwin.close(fd)
            fd = -1
        }
    }

    func setActivity(_ presence: PresenceState, processID: Int32 = getpid()) throws {
        let payload: [String: Any] = [
            "cmd": "SET_ACTIVITY",
            "args": [
                "pid": Int(processID),
                "activity": [
                    "details": presence.details,
                    "state": presence.state,
                    "timestamps": [
                        "start": presence.sessionStart
                    ],
                    "assets": [
                        "large_image": "terminal",
                        "large_text": "macOS Terminal"
                    ]
                ]
            ],
            "nonce": UUID().uuidString
        ]

        try send(opcode: .frame, payload: payload)
    }

    func clearActivity(processID: Int32 = getpid()) throws {
        let payload: [String: Any] = [
            "cmd": "SET_ACTIVITY",
            "args": [
                "pid": Int(processID),
                "activity": NSNull()
            ],
            "nonce": UUID().uuidString
        ]

        try send(opcode: .frame, payload: payload)
    }

    private func send(opcode: Opcode, payload: Any) throws {
        guard fd >= 0 else {
            throw DiscordIPCError.disconnected
        }

        guard JSONSerialization.isValidJSONObject(payload) else {
            throw DiscordIPCError.invalidPayload
        }

        let json = try JSONSerialization.data(withJSONObject: payload)
        var packet = Data()
        packet.append(UInt32(opcode.rawValue).littleEndianData)
        packet.append(UInt32(json.count).littleEndianData)
        packet.append(json)

        try packet.withUnsafeBytes { bytes in
            guard let baseAddress = bytes.baseAddress else { return }

            var sent = 0
            while sent < packet.count {
                let result = Darwin.write(fd, baseAddress.advanced(by: sent), packet.count - sent)
                guard result > 0 else {
                    disconnect()
                    throw DiscordIPCError.disconnected
                }
                sent += result
            }
        }
    }

    private static func findSocketPath() throws -> String {
        let environment = ProcessInfo.processInfo.environment
        let candidates = [
            environment["TMPDIR"],
            environment["XDG_RUNTIME_DIR"],
            "/tmp",
            "/var/tmp",
            "/usr/tmp"
        ].compactMap { $0 }

        for directory in candidates {
            for index in 0...9 {
                let path = URL(fileURLWithPath: directory)
                    .appendingPathComponent("discord-ipc-\(index)")
                    .path

                if FileManager.default.fileExists(atPath: path) {
                    return path
                }
            }
        }

        throw DiscordIPCError.socketNotFound
    }
}

private extension UInt32 {
    var littleEndianData: Data {
        var value = littleEndian
        return Data(bytes: &value, count: MemoryLayout<UInt32>.size)
    }
}
