// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "SwiftDOF",
  defaultLocalization: "en",
  platforms: [.macOS(.v26), .iOS(.v26), .watchOS(.v26), .tvOS(.v26), .visionOS(.v26)],
  products: [
    // Products define the executables and libraries a package produces, making them visible to other packages.
    .library(
      name: "SwiftDOF",
      targets: ["SwiftDOF"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.7.0"),
    .package(url: "https://github.com/swiftlang/swift-docc-plugin.git", from: "1.4.3"),
    .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.20"),
    .package(url: "https://github.com/jkandzi/Progress.swift", from: "0.4.0")
  ],
  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .target(
      name: "SwiftDOF",
      resources: [.process("Resources")]
    ),
    .testTarget(
      name: "SwiftDOFTests",
      dependencies: ["SwiftDOF"]
    ),
    .executableTarget(
      name: "SwiftDOF_E2E",
      dependencies: [
        "SwiftDOF",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        .product(name: "ZIPFoundation", package: "ZIPFoundation"),
        .product(name: "Progress", package: "Progress.swift")
      ]
    )
  ],
  swiftLanguageModes: [.v5, .v6]
)
