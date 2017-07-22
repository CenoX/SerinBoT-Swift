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
            return Documents.shared.commonHelp
        case .dev:
            return Documents.shared.devHelp
        case .papa:
            return Documents.shared.papaHelp
        default:
            return Documents.shared.readme
        }
    }
}

class Documents {
    static let shared = Texts()
}
