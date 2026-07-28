// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "vim-btw",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "vim-btw",
            path: "Sources/VimBTW",
            linkerSettings: [
                .linkedFramework("AppKit")
            ]
        )
    ]
)
