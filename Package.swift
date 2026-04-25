// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "NotchAgent",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "NotchAgent",
            linkerSettings: [.linkedFramework("AVFoundation")]
        )
    ]
)
