//
//  CGPoint+Utils.swift
//  ScanflowDocumentCapture
//
//  Created by Mac-OBS-46 on 06/06/23.
//

import Foundation

extension CGPoint {
    
    /// Returns a rectangle of a given size surounding the point.
    ///
    /// - Parameters:
    ///   - size: The size of the rectangle that should surround the points.
    /// - Returns: A `CGRect` instance that surrounds this instance of `CGpoint`.
    func surroundingSquare(withSize size: CGFloat) -> CGRect {
        return CGRect(x: x - size / 2.0, y: y - size / 2.0, width: size, height: size)
    }
    
    /// Checks wether this point is within a given distance of another point.
    ///
    /// - Parameters:
    ///   - delta: The minimum distance to meet for this distance to return true.
    ///   - point: The second point to compare this instance with.
    /// - Returns: True if the given `CGPoint` is within the given distance of this instance of `CGPoint`.
    func isWithin(delta: CGFloat, ofPoint point: CGPoint) -> Bool {
        return (abs(x - point.x) <= delta) && (abs(y - point.y) <= delta)
    }
    
    /// Returns the same `CGPoint` in the cartesian coordinate system.
    ///
    /// - Parameters:
    ///   - height: The height of the bounds this points belong to, in the current coordinate system.
    /// - Returns: The same point in the cartesian coordinate system.
    func cartesian(withHeight height: CGFloat) -> CGPoint {
        return CGPoint(x: x, y: height - y)
    }
    
    /// Returns the distance between two points
    func distanceTo(point: CGPoint) -> CGFloat {
        return hypot((self.x - point.x), (self.y - point.y))
    }
    
    /// Returns the closest corner from the point
    func closestCornerFrom(rect: Rectangle) -> CornerPosition {
        var smallestDistance = distanceTo(point: rect.topLeft)
        var closestCorner = CornerPosition.topLeft
        
        if distanceTo(point: rect.topRight) < smallestDistance {
            smallestDistance = distanceTo(point: rect.topRight)
            closestCorner = .topRight
        }
        
        if distanceTo(point: rect.bottomRight) < smallestDistance {
            smallestDistance = distanceTo(point: rect.bottomRight)
            closestCorner = .bottomRight
        }
        
        if distanceTo(point: rect.bottomLeft) < smallestDistance {
            smallestDistance = distanceTo(point: rect.bottomLeft)
            closestCorner = .bottomLeft
        }
        
        return closestCorner
    }
}
