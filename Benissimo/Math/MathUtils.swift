//
//  MathUtils.swift
//  Benissimo
//
//  Created by IC on 20.02.2018.
//  Copyright © 2018 Greasy Bowels. All rights reserved.
//

import Foundation
import CoreGraphics


class MathUtils {
    
    static func segmentArea(_ point1 : CGPoint, _ point2: CGPoint) -> CGFloat {
        let width = point2.x - point1.x
        let height = (point1.y + point2.y) / 2
        return height * width
    }
    
    static func polygonArea(points: [CGPoint]) -> CGFloat {
        if (points.count < 2) {
            return 0
        }
        
        var area = CGFloat(0)
        for i in 0..<points.count - 1 {
            let point1 = points[i]
            let point2 = points[i + 1]
            area += self.segmentArea(point1, point2)
        }
        
        area += self.segmentArea(points.last!, points.first!)
        
        return fabs(area)
    }
    
    static func ratio(points: [CGPoint]) -> CGFloat {
        var leftmost = CGPoint.init(x: 1000000.0, y: 0)
        var rightmost = CGPoint.zero
        
        for point in points {
            if (point.x > rightmost.x) {
                rightmost = point
            }
            
            if (point.x < leftmost.x) {
                leftmost = point
            }
        }
            
        let length = sqrt(pow(leftmost.x - rightmost.x, 2) + pow(leftmost.y - rightmost.y, 2))
        var topdist = CGFloat(0)
        var bottomdist = CGFloat(0)
        for point in points {
            if (point != leftmost && point != rightmost) {
                let length = self.distance(p1: point, p2: leftmost)
                let distance = sin(angle(a: point, o: leftmost, b: rightmost)) * length
                
                if (sideof(point: point, relativeToLineOf: leftmost, p2: rightmost) == 1) {
                    if (distance > topdist) {
                        topdist = distance
                    }
                } else {
                    if (distance > bottomdist) {
                        bottomdist = distance
                    }
                }
            }
        }

        let crosssection = topdist + bottomdist
        let ratio = crosssection / length

        return ratio
    }
    
    //determines if a point lies above (+1) or below (-1) a line defined by points p1,p2. If the point belongs the line, func returns 0
    static func sideof(point: CGPoint, relativeToLineOf p1: CGPoint, p2: CGPoint ) -> Int {
        if (p1.x == p2.x) { //vertical line
            if (point.x < p1.x) {
                return -1
            } else if (point.x > p1.x) {
                return 1
            } else {
                return 0
            }
        }
        
        let a = (p2.y - p1.y) / (p2.x - p1.x)
        let b = p1.y - a * p1.x
        
        let val = a * point.x + b;
        if (val == point.y) {
            return 0
        } else if (val > point.y) {
            return -1
        } else {
            return 1
        }
    }
    
    static func distance(p1: CGPoint, p2: CGPoint) -> CGFloat {
        return sqrt(pow(p2.x-p1.x, 2) + pow(p2.y-p1.y, 2))
    }
    
    static func angle(a: CGPoint, o : CGPoint, b: CGPoint) -> CGFloat {
        let v1 = CGPoint(x: a.x - o.x, y: a.y - o.y)
        let v2 = CGPoint(x: b.x - o.x, y: b.y - o.y)
        
        let scalar = v1.x * v2.x + v1.y * v2.y
        let modules = sqrt(v1.x*v1.x + v1.y*v1.y) * sqrt(v2.x*v2.x + v2.y*v2.y)
        
        let cosine = scalar / modules
        
        return acos(cosine)
    }
}
