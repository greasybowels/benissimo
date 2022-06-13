//
//  RootCoordinator.swift
//  Benissimo
//
//  Created by Igor Chertenkov on 12/6/22.
//

import Foundation
import SideMenu

class RootCoordinator: Coordinator {
    var rootViewController: UIViewController {
        return self.mainCoordinator.rootViewController
    }
    
    private(set) var parentCoordinator: Coordinator?
    
    var sideMenuRootController: SideMenuNavigationController
    var sideMenuViewController: SideMenuViewController

    lazy var mainCoordinator: MainCoordinator = {
        let main = MainCoordinator(parentCoordinator: self)
        main.actionDelegate = self
        return main
    }()
    
    init() {
        self.sideMenuViewController = SideMenuViewController.instantiate()
        self.sideMenuViewController.viewModel = SideMenuViewModel()
        self.sideMenuRootController = SideMenuNavigationController(rootViewController: sideMenuViewController)
        
        sideMenuRootController.leftSide = true
    }
}

extension RootCoordinator: MainCoordinatorActionDelegate {
    func mainCoordinatorDidRequestToggleSideMenu(_ sender: MainCoordinator) {
        if (self.rootViewController.presentedViewController != nil) {
            self.rootViewController.dismiss(animated: true)
        } else {
            self.rootViewController.present(sideMenuRootController, animated: true)
        }
    }
}
