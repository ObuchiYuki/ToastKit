// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ToastKit",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(name: "ToastKit", targets: ["ToastKit"]),
    ],
    targets: [
        .target(name: "ToastKit"),
        .testTarget(name: "ToastKitTests", dependencies: ["ToastKit"]),
    ]
)
