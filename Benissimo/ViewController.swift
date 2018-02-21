//
//  ViewController.swift
//  Benissimo
//
//  Created by IC on 19.02.2018.
//  Copyright © 2018 Greasy Bowels. All rights reserved.
//

import UIKit
import Vision

let kFilterQ : CGFloat = 0.5

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, FrameExtractorDelegate {

    @IBOutlet var image: UIImageView?
    @IBOutlet var overlayImage: UIImageView?
    @IBOutlet var sideBenisesContainer: UIView?
    var mouthLayer : CAShapeLayer?
    
    var extractor: FrameExtractor?
    var processing: Bool = false
    var canProcess : Bool = true
    var shouldStopUpdating: Bool = false
    
    var leftBenises : [CALayer] = []
    var rightBenises : [CALayer] = []
    var flyingBenises : [CALayer] = []
    
    var targetGap: (CGPoint, CGPoint) = (CGPoint.zero, CGPoint.zero)
    
    var maxCrossRatio : CGFloat = 0
    var maxArea : CGFloat = 0
    var filteredArea: CGFloat = 0
    var filteredCrossratio: CGFloat = 0

    @IBOutlet var stats : UILabel?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.extractor = FrameExtractor()
        extractor?.delegate = self
        

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.createBenises()
    }
    
    //MARK: setup
    
    func createBenises() {
        
        let benisCount = 15
        leftBenises = self.createAnimatedBenises(benisCount: benisCount, baseTransform: CATransform3DIdentity, basePosition: CGPoint(x: 0, y: image!.frame.height))
        rightBenises = self.createAnimatedBenises(benisCount: benisCount, baseTransform: CATransform3DMakeScale(-1.0, 1.0, 1.0), basePosition: CGPoint(x: image!.frame.width, y: image!.frame.height))

        for benis in leftBenises {
            self.sideBenisesContainer?.layer.addSublayer(benis)
        }

        for benis in rightBenises {
            self.sideBenisesContainer?.layer.addSublayer(benis)
        }
        
    }
    
    func createAnimatedBenises(benisCount: Int, baseTransform: CATransform3D, basePosition: CGPoint) -> [CALayer] {
        guard let benisImage = UIImage.init(named: "benis") else {
            return []
        }

        var benises : [CALayer] = []
        
        for i in 1..<benisCount {
            let benis = CALayer.init()
            benis.frame = CGRect.init(origin: CGPoint.zero, size: benisImage.size)
            benis.contents = benisImage.cgImage
            benis.anchorPoint = CGPoint(x: 0.25, y: 0.6)
            benis.position = basePosition
            let scale = CGFloat.random() * 0.4 * (CGFloat(benisCount - i) / CGFloat(benisCount)) + 0.8
            
            let transform = CATransform3DScale(baseTransform, scale, scale, 1.0)
            benis.transform = CATransform3DRotate(transform, -CGFloat.pi * CGFloat(arc4random_uniform(90)) / 180.0, 0, 0, 1)
            self.animateBenisRandomly(benisToAnimate: benis)
            
            benises.append(benis)
        }
        return benises
    }
    
    func animateBenisRandomly(benisToAnimate: CALayer) {
        let rotationValue = benisToAnimate.value(forKeyPath: "transform.rotation") as? Double
        guard let baseRotation = rotationValue else {
            return
        }
        
        let animation = CAKeyframeAnimation.init(keyPath: "transform.rotation")
        animation.values = [baseRotation, baseRotation + Double(arc4random_uniform(100)) / 100.0, baseRotation]
        animation.timingFunctions = [CAMediaTimingFunction.init(name: kCAMediaTimingFunctionEaseInEaseOut),
                                     CAMediaTimingFunction.init(name: kCAMediaTimingFunctionEaseInEaseOut),
                                     CAMediaTimingFunction.init(name: kCAMediaTimingFunctionEaseInEaseOut),
                                     CAMediaTimingFunction.init(name: kCAMediaTimingFunctionEaseInEaseOut)]
        animation.duration = CFTimeInterval(arc4random_uniform(100)) / 100.0 + 1.5
        animation.repeatCount = HUGE
        
        benisToAnimate.add(animation, forKey: "benis_vibration")
            
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: actions
    @IBAction func reset() {
        for layer in flyingBenises {
            layer.removeFromSuperlayer()
        }
        
        flyingBenises = []
        
        self.maxArea = 0
        self.maxCrossRatio = 0
        self.filteredArea = 0
        self.filteredCrossratio = 0
        
        self.shouldStopUpdating = false
        self.canProcess = true
        self.processing = false
        
        self.overlayImage?.image = nil
        self.extractor?.start()
    }
    
    //MARK: capture and frame processing
    
    func captured(image: UIImage) {
        
        if (!self.processing) {
            self.processImage(image)
        }
        
        if (!self.shouldStopUpdating) {
            self.image?.image = image
        }
    }
    
    
    func fixOrientation(img: UIImage?) -> UIImage? {
        guard let img = img else {
            return nil
        }
        
        if (img.imageOrientation == .up) {
            return img
        }
        
        UIGraphicsBeginImageContextWithOptions(img.size, false, img.scale)
        let rect = CGRect(x: 0, y: 0, width: img.size.width, height: img.size.height)
        img.draw(in: rect)
        
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return normalizedImage
    }
    
    
    func processImage(_ image: UIImage) {
        let frame = self.image?.frame ?? CGRect.zero
        
        let detectFaceRequest = VNDetectFaceLandmarksRequest { (request, error) in
            if let results = request.results as? [VNFaceObservation] {
                for faceObservation in results {
                    guard let landmarks = faceObservation.landmarks else {
                        continue
                    }

                    var landmarkRegions: [VNFaceLandmarkRegion2D] = []
                    if let faceContour = landmarks.faceContour {
                        landmarkRegions.append(faceContour)
                    }
                    
                    if let innerLips = landmarks.innerLips, let outerLips = landmarks.outerLips {
                        
                        let transform = CGAffineTransform.init(scaleX: 1.0, y: -1).translatedBy(x: 0, y: -frame.size.height)

                        let path = CGMutablePath()
                        let innerPoints = innerLips.pointsInImage(imageSize: frame.size)
                        let outerPoints = outerLips.pointsInImage(imageSize: frame.size)

                        //suppose in outer lips the 1st point is always left corner and so on
                        var contour : [CGPoint] = []
                        contour.append(outerPoints.last!)
                        contour.append(contentsOf: innerPoints.prefix(through: 2))
                        contour.append(outerPoints[5])
                        contour.append(contentsOf: innerPoints.suffix(3))

                        path.move(to: contour[0], transform: transform)
                        path.addLines(between: contour, transform: transform)
                        path.closeSubpath()
                        
                        
                        
                        
                        let layer = CAShapeLayer()
                        layer.frame = CGRect.init(origin: CGPoint.zero, size: frame.size)
                        layer.path = path
                        layer.lineWidth = 2
                        layer.strokeColor = UIColor.red.cgColor
                        layer.fillRule = kCAFillRuleEvenOdd
                        

                        
                        
                        DispatchQueue.main.async {

                            
                            let area = MathUtils.polygonArea(points: contour)
                            let crossratio = MathUtils.ratio(points: contour)
                            let statsText = String(format: "Area: %4.0f %4.0f %4.0f\r\nCrossRatio: %0.3f %0.3f %0.3f", area, self.filteredArea, self.maxArea, crossratio, self.filteredCrossratio, self.maxCrossRatio)
                            self.stats?.text = statsText
                            
                            if (crossratio > self.maxCrossRatio && fabs(1.0 - crossratio / self.filteredCrossratio) < 0.1) {
                                self.maxCrossRatio = crossratio
                            }

                            if (area > self.maxArea && fabs(1.0 - area / self.filteredArea) < 0.1) {
                                self.maxArea = area
                            }

                            let launch : ()->() = {
                                NSLog("LAUCH DICK MISSILES!")
                                self.extractor?.stop()
                                self.shouldStopUpdating = true
                                self.stats?.textColor = UIColor.red
                                
                                //restore original image
                                self.image?.image = image
                                
                                self.animateBenisAssault(mouth: contour, median: landmarks.medianLine!.pointsInImage(imageSize: frame.size))
                            }
                            
                            if (fabs(1.0 - area / self.filteredArea) < 0.95 && area / self.maxArea < 0.9) {
                                if (area > 400 && crossratio > 0.1) {
                                    launch()
                                }
                                
                            } else if (area > 1000 || (self.filteredArea > 400 && self.filteredCrossratio > 0.1)) {
                               launch()
                            }
                            
                            self.filteredArea = self.filteredArea * kFilterQ + area * (1.0 - kFilterQ)
                            self.filteredCrossratio = self.filteredCrossratio * kFilterQ + crossratio * (1.0 - kFilterQ)
                            
                            if (crossratio < 0.1 || area < 100) {
                                self.stats?.textColor = UIColor.black
                            }
                            self.processing = false
                        }
                    }
                }
            }
            self.processing = false
        }

        DispatchQueue.global(qos: .default).async {
            if let cgimage = image.cgImage {
                self.processing = true
                let vnImage = VNImageRequestHandler(cgImage: cgimage, options: [:])
                
                do {
                    try vnImage.perform([detectFaceRequest])
                } catch (_) {
                    self.processing = false
                }
            }
        }
    }
    
    //MARK: benises assault
    
    func animateBenisAssault(mouth: [CGPoint], median: [CGPoint]) {
        
        //####### CREATE CLIPPING CONTOUR FOR THE IMAGE ########
    
        var crosspoints : [CGPoint] = []
        for point in mouth {
            if median.contains(point) {
                crosspoints.append(point)
            }
        }
        
        if (crosspoints.count < 2) {
            NSLog("Benis assault failed yolo")
            return
        }
        
        var halfContour : [CGPoint] = []
        let side = 0//Int(arc4random() % 2)
        let startingPoint = crosspoints[side]
        guard let startIndex = mouth.index(of: startingPoint) else {
            return
            
        }
        
        var i = (startIndex + 1)
        halfContour.append(startingPoint)
        while (crosspoints.contains(mouth[i % mouth.count]) == false) {
            halfContour.append(mouth[i % mouth.count])
            i += 1
        }
        halfContour.append(mouth[i % mouth.count])
        
        let transform = CGAffineTransform.init(scaleX: 1.0, y: -1.0).translatedBy(x: 0, y: -image!.frame.height)
        self.targetGap = (halfContour.first!.applying(transform), halfContour.last!.applying(transform))
        
        var start : CGPoint = CGPoint.zero
        var end : CGPoint = CGPoint.zero
        if (halfContour.first!.y > halfContour.last!.y) {
            start = CGPoint(x: halfContour.first!.x, y: self.image!.frame.size.height)
            end = CGPoint(x: halfContour.last!.x, y: 0.0)
        } else {
            start = CGPoint(x: halfContour.last!.x, y: self.image!.frame.size.height)
            end = CGPoint(x: halfContour.first!.x, y: 0.0)
        }
        halfContour.insert(start, at: 0)
        halfContour.append(end)
        
        if (side == 0) { //finalize clipping contour
            halfContour.insert(CGPoint(x: image!.frame.size.width, y: image!.frame.size.height), at: 0)
            halfContour.append(CGPoint(x: image!.frame.size.width, y: 0))
        } /*else {
            halfContour.insert(CGPoint(x: 0, y: image!.frame.size.height), at: 0)
            halfContour.append(CGPoint.zero)
        }*/
        
        //####### CLIP THE IMAGE ########
        
        UIGraphicsBeginImageContextWithOptions(self.image!.frame.size, false, self.image!.image!.scale)
        let ctx = UIGraphicsGetCurrentContext()
        ctx?.scaleBy(x: 1.0, y: -1.0)
        ctx?.translateBy(x:0, y: -self.image!.frame.height)
        ctx?.move(to: halfContour[0])
        ctx?.addLines(between: halfContour)
        ctx?.closePath()
        ctx?.clip()
        
        ctx?.draw(self.image!.image!.cgImage!, in: self.image!.bounds)
        let clippedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        self.overlayImage?.image = clippedImage
        
        //####### AIM AT TARGET GAP AND SHOOT #######
        
        for _ in 0..<5 {
            let flyingBenis = randomBenisFlyingTo(gap: targetGap)
            self.overlayImage?.layer.addSublayer(flyingBenis.0)
            self.image?.layer.addSublayer(flyingBenis.1)
            flyingBenises.append(flyingBenis.0)
            flyingBenises.append(flyingBenis.1)
        }

        
    }
    
    func randomBenisFlyingTo(gap: (CGPoint, CGPoint)) -> (CALayer, CALayer) {
        let flyingBenis = CALayer()
        let benisBase = CALayer()
        let benisBaseThickness : CGFloat = 24.0
        let gapWidth = abs(gap.0.y - gap.1.y)
        
        flyingBenis.frame = CGRect.init(origin: CGPoint.zero, size: #imageLiteral(resourceName: "benis").size)
        benisBase.frame = flyingBenis.frame
        
        flyingBenis.contents = #imageLiteral(resourceName: "benis").cgImage
        benisBase.contents = #imageLiteral(resourceName: "benis_base").cgImage
        
        let scale = (gapWidth / benisBaseThickness) * (0.5 * CGFloat.random() + 0.5)
        let realBenisThickness = benisBaseThickness * scale
        let maxVerticalShift = gapWidth - realBenisThickness
        let verticalShift = CGFloat.random() * maxVerticalShift
        
        let relativeCenterPosition = (realBenisThickness / 2 + verticalShift) / gapWidth
        
        let targetPoint = CGPoint(x: gap.0.x + (gap.1.x - gap.0.x) * relativeCenterPosition /*+ CGFloat.random() * maxVerticalShift*/,
                                  y: gap.0.y + (gap.1.y - gap.0.y) * relativeCenterPosition)
        
        flyingBenis.anchorPoint = CGPoint(x: 0.35, y: 0.4)
        benisBase.anchorPoint = flyingBenis.anchorPoint
        
        flyingBenis.transform = CATransform3DMakeScale(scale, scale, 1.0)
        benisBase.transform = flyingBenis.transform
        
        flyingBenis.position = CGPoint(x: -(CGFloat.random() * 100.0 + 130.0), y: (targetGap.0.y + targetGap.1.y) / 2 + (CGFloat.random() - 0.5) * 100.0)
        benisBase.position = flyingBenis.position
        
        let benisAnimation = CABasicAnimation.init(keyPath: "position")
        benisAnimation.toValue = targetPoint
        benisAnimation.timingFunction = CAMediaTimingFunction.init(name: kCAMediaTimingFunctionEaseIn)
        benisAnimation.duration = 0.5 + Double.random()
        benisAnimation.isRemovedOnCompletion = false
        benisAnimation.fillMode = kCAFillModeForwards
        
        flyingBenis.add(benisAnimation, forKey: "benis_assault")
        benisBase.add(benisAnimation, forKey: "benis_assault")
        
        return (benisBase, flyingBenis)
    }
}

