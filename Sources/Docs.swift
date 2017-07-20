//
//  Docs.swift
//  Serin
//
//  Created by CenoX on 2017. 7. 20..
//
//

import Foundation

enum HelpIndex: String {
    case common = "common"
    case dev = "dev"
    case papa = "papa"
    case unknown = "unknown"
    
    init(rawValue: String) {
        switch rawValue {
        case "common":
            self = .common
        case "dev":
            self = .dev
        case "papa":
            self = .papa
        default:
            self = .unknown
        }
    }
    
    func docs() -> String {
        switch self {
        case .common:
            return Documents.shared.common
        case .dev:
            return Documents.shared.dev
        case .papa:
            return Documents.shared.papa
        default:
            return Documents.shared.readme
        }
    }
}

class Documents {
    
    static let shared = Documents()
    
    let readme = try! String(contentsOf: Bundle.main.url(forResource: "readme", withExtension: "strings", subdirectory: "Docs")!)
    
    let common = try! String(contentsOf: Bundle.main.url(forResource: "commonHelp", withExtension: "strings", subdirectory: "Docs")!)
    
    let dev = try! String(contentsOf: Bundle.main.url(forResource: "devHelp", withExtension: "strings", subdirectory: "Docs")!)
    
    let papa = try! String(contentsOf: Bundle.main.url(forResource: "papaHelp", withExtension: "strings", subdirectory: "Docs")!)
}
