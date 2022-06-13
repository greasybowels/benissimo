//
//  CameraViewModel.swift
//  Benissimo
//
//  Created by Igor Chertenkov on 12/6/22.
//

import Foundation

protocol CameraViewModelActionDelegate: AnyObject {
    func cameraViewModelDidRequestToggleSideMenu(_ sender: CameraViewModel)
}

protocol CameraViewModelDisplayDelegate: AnyObject {
    
}

class CameraViewModel {
    weak var actionDelegate: CameraViewModelActionDelegate?
    weak var displayDelegate: CameraViewModelDisplayDelegate?

    func userDidTapMenu() {
        self.actionDelegate?.cameraViewModelDidRequestToggleSideMenu(self)
    }
    
    func userDidTapChangeCamera() {
        
    }
}
