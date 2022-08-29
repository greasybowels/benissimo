//
//  CameraViewController.swift
//  Benissimo
//
//  Created by Igor Chertenkov on 12/6/22.
//

import UIKit

class CameraViewController: UIViewController, AutoLoadable {

    var viewModel: CameraViewModel!

    @IBOutlet var image: UIImageView?
    @IBOutlet var overlayImage: UIImageView?
    @IBOutlet var sideBenisesContainer: UIView!
    @IBOutlet var stats : UILabel?
    
    @IBOutlet var preview: CameraPreviewView?

    // BENISES :DDD
    var leftBenises : [CALayer] = []
    var rightBenises : [CALayer] = []


    override func viewDidLoad() {
        super.viewDidLoad()
        self.viewModel.displayDelegate = self
        setupBenisesAnimation()
        //preview?.videoPreviewLayer.session = self.viewModel.previewSession
    }
        
    func setupBenisesAnimation() {
        let benisCount = 15
        leftBenises = self.createAnimatedBenises(benisCount: benisCount, baseTransform: CATransform3DIdentity, basePosition: CGPoint(x: 0, y: sideBenisesContainer.bounds.height))
        rightBenises = self.createAnimatedBenises(benisCount: benisCount, baseTransform: CATransform3DMakeScale(-1.0, 1.0, 1.0), basePosition: CGPoint(x: sideBenisesContainer.bounds.width, y: sideBenisesContainer.bounds.height))

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
        animation.repeatCount = .greatestFiniteMagnitude
        
        benisToAnimate.add(animation, forKey: "benis_vibration")
            
    }
    
    @IBAction func userDidTapMenu(_ sender: AnyObject?) {
        self.viewModel.userDidTapMenu()
    }

    @IBAction func userDidTapChangeCamera(_ sender: AnyObject?) {
        self.viewModel.userDidTapChangeCamera()
    }
}

extension CameraViewController: CameraViewModelDisplayDelegate {
    func didUpdateFrame(image: CVPixelBuffer) {
        DispatchQueue.main.async {
            self.preview?.layer.contents = image
        }
    }
    
    func didUpdateDebugContour(points: [CGPoint]) {
        
    }
}
