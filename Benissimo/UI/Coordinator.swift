//
//  Coordinator.swift
//  Benissimo
//
//  Created by Igor Chertenkov on 12/6/22.
//

import Foundation
import UIKit

protocol Coordinator {
    var rootViewController: UIViewController {get}
    var parentCoordinator: Coordinator? {get}
}
