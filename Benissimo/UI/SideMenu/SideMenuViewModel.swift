//
//  SideMenuViewModel.swift
//  Benissimo
//
//  Created by Igor Chertenkov on 12/6/22.
//

import Foundation

protocol SideMenuViewModelActionDelegate: AnyObject {
    
}

protocol SideMenuViewModelDisplayDelegate: AnyObject {
    
}

class SideMenuViewModel {
    weak var actionDelegate: SideMenuViewModelActionDelegate?
    weak var displayDelegate: SideMenuViewModelDisplayDelegate?

}
