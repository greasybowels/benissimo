//
//  RecognitionService.swift
//  Benissimo
//
//  Created by Igor Chertenkov on 7/7/22.
//

import Foundation
import Vision

class RecognitionService {
    enum RecognitionError: Error {
        case cantRegisterHandler(underlying: Error)
    }
    
    var handler: VNSequenceRequestHandler
    
    init() {
        handler = VNSequenceRequestHandler()
    }
    
    func processImage(pixelBuffer: CVPixelBuffer, completion: @escaping (Result<[VNObservation]?, Error>) -> Void) {
        
        let request = VNDetectFaceLandmarksRequest { request, error in
            if error != nil {
                completion(.failure(error!))
            } else {
                completion(.success(request.results))
            }
        }

        do {
            try handler.perform([request], on: pixelBuffer, orientation: .upMirrored)
        } catch (let error) {
            completion(.failure(RecognitionError.cantRegisterHandler(underlying: error)))
        }
    }
}
