//
//  AutoLoadable.swift
//  Benissimo
//
//  Created by Igor Chertenkov on 12/6/22.
//

import Foundation
import UIKit

protocol AutoLoadable {
    static func instantiate() -> Self
    static func instantiate(from storyboardName: String) -> Self
}

extension AutoLoadable where Self: UIViewController {
    static func instantiate() -> Self {
        return instantiate(from: "Main")
    }
    
    static func instantiate(from storyboardName: String) -> Self {
        let fullName = NSStringFromClass(self)
        let className = fullName.components(separatedBy: ".")[1]

        let storyboard = UIStoryboard(name: storyboardName, bundle: Bundle.main)
        return storyboard.instantiateViewController(withIdentifier: className) as! Self
    }
}
