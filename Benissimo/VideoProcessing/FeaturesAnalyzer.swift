//
//  FeaturesAnalyzer.swift
//  Benissimo
//
//  Created by Igor Chertenkov on 7/7/22.
//

import Foundation
import Vision

class FeaturesAnalyzer {
    
    enum AnalyzerError: Error {
        case notFound
        case notReady
    }
    
    /// Analyzes features inside an image. We use image size because "ellipticalness" of lips opening depends on image aspect ratio.
    ///  This is the reason we can't use normalized points here
    func analyzeFeatures(observations: [VNObservation], inImageOfSize size: CGSize) -> Result<VNFaceLandmarkRegion2D, Error> {
        let innerLipsArray = observations.compactMap({($0 as? VNFaceObservation)?.landmarks?.innerLips})
        
        guard let observation = innerLipsArray.first else {
            return .failure(AnalyzerError.notFound)
        }
        
        var points = observation.pointsInImage(imageSize: size)
        
        return .success(observation)
    }
}
