// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "JetSet",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v10_10), .iOS(.v11), .tvOS(.v9), .watchOS(.v3)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "JetSet",
            targets: ["JetSet"]),
        
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        //.package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "5.0.0"),
        .package(name: "SwiftyJSON", url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "5.0.0"),
    ],
    
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "JetSet",
            dependencies: ["SwiftyJSON"]),
        //.target(name: "SwiftyJSON", dependencies: ["SwiftyJSON"]),
        .testTarget(
            name: "JetSetTests",
            dependencies: ["JetSet"]),
    ]
)
