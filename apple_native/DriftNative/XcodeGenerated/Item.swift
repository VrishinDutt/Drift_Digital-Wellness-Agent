//
//  Item.swift
//  DriftNative
//
//  Created by Vrishin Dutt on 15/05/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
