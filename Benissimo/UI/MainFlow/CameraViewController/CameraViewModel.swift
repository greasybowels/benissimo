//
//  CameraViewModel.swift
//  Benissimo
//
//  Created by Igor Chertenkov on 12/6/22.
//

import Foundation
import AVFoundation
import Vision

protocol CameraViewModelActionDelegate: AnyObject {
    func cameraViewModelDidRequestToggleSideMenu(_ sender: CameraViewModel)
}

protocol CameraViewModelDisplayDelegate: AnyObject {
    func didUpdateFrame(image: CVPixelBuffer)
    func didUpdateDebugContour(points: [CGPoint])
}

class CameraViewModel {
    weak var actionDelegate: CameraViewModelActionDelegate?
    weak var displayDelegate: CameraViewModelDisplayDelegate?
    
    private var cameraService: CameraService
    
    private var recentFrameSize: CGSize?
    
    var previewSession: AVCaptureSession {
        return self.cameraService.captureSession
    }
    
    init() {
        self.cameraService = CameraService()
        self.cameraService.delegate = self
        self.cameraService.start()
    }

    func userDidTapMenu() {
        self.actionDelegate?.cameraViewModelDidRequestToggleSideMenu(self)
    }
    
    func userDidTapChangeCamera() {
        
    }
}

extension CameraViewModel: CameraServiceDelegate {
    func cameraService(_ service: CameraService, didProcessFrame frame: CVPixelBuffer) {
        self.recentFrameSize = CGSize(width: CVPixelBufferGetWidth(frame),
                                      height: CVPixelBufferGetHeight(frame))
        self.displayDelegate?.didUpdateFrame(image: frame)
    }
    
    func cameraService(_ service: CameraService, didFoundSuitableMouth mouth: VNFaceLandmarkRegion2D) {
        if let size = self.recentFrameSize {
            self.displayDelegate?.didUpdateDebugContour(points: mouth.pointsInImage(imageSize: size))
        }
    }
}
