//
//  MainCoordinator.swift
//  Benissimo
//
//  Created by Igor Chertenkov on 12/6/22.
//

import Foundation
import UIKit

protocol MainCoordinatorActionDelegate: AnyObject {
    func mainCoordinatorDidRequestToggleSideMenu(_ sender: MainCoordinator)
}

class MainCoordinator: Coordinator {
    
    weak var actionDelegate: MainCoordinatorActionDelegate?
    
    var rootViewController: UIViewController {
        return rootNavigationController
    }
    
    private var rootNavigationController: UINavigationController
    
    private(set) var parentCoordinator: Coordinator?
    private var cameraViewController: CameraViewController
    
    init(parentCoordinator: Coordinator) {
        self.parentCoordinator = parentCoordinator
        self.cameraViewController = CameraViewController.instantiate()
        self.cameraViewController.viewModel = CameraViewModel()
        self.rootNavigationController = UINavigationController(rootViewController: cameraViewController)

        self.cameraViewController.viewModel.actionDelegate = self
    }
}

extension MainCoordinator: CameraViewModelActionDelegate {
    func cameraViewModelDidRequestToggleSideMenu(_ sender: CameraViewModel) {
        self.actionDelegate?.mainCoordinatorDidRequestToggleSideMenu(self)
    }
}
