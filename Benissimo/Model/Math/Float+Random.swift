//
//  Float+Random.swift
//  Benissimo
//
//  Created by IC on 20.02.2018.
//  Copyright © 2018 Greasy Bowels. All rights reserved.
//

import Foundation
import CoreGraphics

extension Float {
    static func random() -> Float {
        return Float(arc4random()) / Float(RAND_MAX)
    }
}

extension Double {
    static func random() -> Double {
        return Double(arc4random()) / Double(RAND_MAX)
    }
}

extension CGFloat {
    static func random() -> CGFloat {
        return CGFloat(arc4random()) / CGFloat(RAND_MAX)
    }
}

