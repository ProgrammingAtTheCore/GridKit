//  swift-tools-version: 6.1
//
//  Created by ProgrammingAtTheCore on 11/02/2025.
//

import PackageDescription

let package = Package(
    name: "GridKit",
    platforms: [
        .iOS(.v17), // version: 17
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "GridKit",
            targets: ["GridKit"]
        ),
    ],
    targets: [
        .target(
            name: "GridKit",
            dependencies: []
        )
    ]
)
