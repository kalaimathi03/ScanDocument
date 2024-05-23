//
//  RectangleDetector.swift
//  ScanflowDocumentCapture
//
//  Created by Mac-OBS-46 on 06/06/23.
//

import CoreImage
import AVFoundation

/// Class used to detect rectangles from an image.
struct CIRectangleDetector {
    
    static let rectangleDetector = CIDetector(ofType: CIDetectorTypeRectangle,
                                              context: CIContext(options: nil),
                                              options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
    
    /// Detects rectangles from the given image on iOS 10.
    ///
    /// - Parameters:
    ///   - image: The image to detect rectangles on.
    /// - Returns: The biggest detected rectangle on the image.
    static func rectangle(forImage image: CIImage, completion: @escaping ((Rectangle?) -> Void)) {
        let biggestRectangle = rectangle(forImage: image)
        completion(biggestRectangle)
    }
    
    static func rectangle(forImage image: CIImage) -> Rectangle? {
        guard let rectangleFeatures = rectangleDetector?.features(in: image) as? [CIRectangleFeature] else {
            return nil
        }
        
        let rects = rectangleFeatures.map { rectangle in
            return Rectangle(rectangleFeature: rectangle)
        }
        
        return rects.biggest()
    }
}
