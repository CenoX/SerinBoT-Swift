// swift-tools-version:3.1

import PackageDescription

let package = Package(
    name: "Serin",
    dependencies: [
        .Package(url: "https://github.com/Azoy/Sword", majorVersion: 0, minor: 7),
        .Package(url: "https://github.com/mattgallagher/CwlUtils.git", majorVersion: 1),
        .Package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", versions: Version(1, 0, 0)..<Version(3, .max, .max)),
        .Package(url: "https://github.com/tid-kijyun/Kanna.git", majorVersion: 2),
        .Package(url: "https://github.com/devxoul/Then", majorVersion: 2)
    ]
)
