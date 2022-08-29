//
//  CameraService.swift
//  Benissimo
//
//  Created by Igor Chertenkov on 13/6/22.
//

import Foundation
import AVFoundation
import Vision

protocol CameraServiceDelegate: AnyObject {
    func cameraService(_ service: CameraService, didFoundSuitableMouth mouth: VNFaceLandmarkRegion2D)
    func cameraService(_ service: CameraService, didProcessFrame frame: CVPixelBuffer)
}

class CameraService: NSObject {
    
    private (set) var captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "session queue")
    private let mlQueue = DispatchQueue(label: "ml queue")

    private var cameraPosition: AVCaptureDevice.Position = .front
    private var videoDataOutput: AVCaptureVideoDataOutput?
    
    private var recognitionService = RecognitionService()
    
    weak var delegate: CameraServiceDelegate?
    
    override init() {
        super.init()
        configure()
    }
    
    func configure() {
        captureSession.beginConfiguration()
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                  for: .video,
                                                        position: cameraPosition) else {
            return
        }
        
        guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
              captureSession.canAddInput(videoDeviceInput) else {
            return
        }
        
        captureSession.sessionPreset = .hd1280x720
        captureSession.addInput(videoDeviceInput)
        
        
        
        // Adding output to ML
        let output = AVCaptureVideoDataOutput()
        if captureSession.canAddOutput(output) {
            captureSession.addOutput(output)
            // Add a video data output
            output.alwaysDiscardsLateVideoFrames = true
            output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
            output.setSampleBufferDelegate(self, queue: mlQueue)
            self.videoDataOutput = output
        } else {
            print("Could not add video data output to the session")
        }
        
        captureSession.commitConfiguration()
    }
    
    func start() {
        captureSession.startRunning()
    }
    
    func stop() {
        captureSession.stopRunning()
    }
}

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {

        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        var size = CGSize(width: CVPixelBufferGetWidth(pixelBuffer),
                          height: CVPixelBufferGetHeight(pixelBuffer))

        recognitionService.processImage(pixelBuffer: pixelBuffer) { result in
            self.delegate?.cameraService(self, didProcessFrame: pixelBuffer)
            switch result {
            case .success(let observations):
                if let observations = observations,
                   observations.count > 0 {
                    let result = FeaturesAnalyzer().analyzeFeatures(observations: observations, inImageOfSize: size)
                    switch result {
                    case .success(let observation):
                        self.delegate?.cameraService(self, didFoundSuitableMouth: observation)
                    case .failure:
                        break
                    }
                }
            case .failure(let error):
                print(error)
            }
        }
    }
}
