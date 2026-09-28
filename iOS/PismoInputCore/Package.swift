// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "PismoInputCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "PismoInputCore", targets: ["PismoInputCore"])],
    targets: [
        .target(name: "PismoInputCore"),
        .testTarget(name: "PismoInputCoreTests", dependencies: ["PismoInputCore"])
    ]
)
