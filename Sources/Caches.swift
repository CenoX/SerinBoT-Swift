//
//  Caches.swift
//  Serin
//
//  Created by CenoX on 2017. 7. 20..
//
//

import Foundation
import Sword

class Caches {
    
    var isChangingGame = false
    var changeGame: Any? {
        didSet {
            isChangingGame = true
        }
    }
    var changePrefix = false
    var prefixCache: String?
}
