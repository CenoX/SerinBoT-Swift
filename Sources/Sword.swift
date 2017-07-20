//
//  Sword.swift
//  Serin
//
//  Created by CenoX on 2017. 7. 20..
//
//

import Foundation
import Sword

extension Sword {
    func deadline(of seconds: Double) -> DispatchTime {
        return DispatchTime.now() + Double(Int64(seconds * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
    }
}
