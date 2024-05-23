//
//  SFDocumentHelper.swift
//  ScanflowDocumentCapture
//
//  Created by Mac-OBS-46 on 12/05/23.
//

import Foundation
import Vision
import UIKit
import AVFoundation

public enum AESconfig: String {
    case key = "d5a423f64b6072"
    case once = "131348c0987c7eece60fc0bc"

}
public class SFDocumentHelper {
    
    static public let shared = SFDocumentHelper()
    
    public var appThemeColor: UIColor = .appThemeColor
    
    func calculateRect(path: Rectangle, originalSize: CGSize, processingSize: CGSize, wantEnlarge: Bool = false)  -> [CGPoint]{
        
        let widthRatio = originalSize.width / processingSize.width
        let heightRatio = originalSize.height / processingSize.height
        
        let leftTop = CGPoint(x: (path.topLeft.x / widthRatio), y: (path.topLeft.y / heightRatio))
        let rightTop = CGPoint(x: (path.topRight.x / widthRatio), y: (path.topRight.y / heightRatio))
        let bottomRight = CGPoint(x: (path.bottomRight.x / widthRatio), y: (path.bottomRight.y / heightRatio))
        let bottomLeft = CGPoint(x: (path.bottomLeft.x / widthRatio), y: (path.bottomLeft.y / heightRatio))
        
        return [leftTop, rightTop, bottomRight, bottomLeft]
        
    }
    
    public func calculateCropRectData(ponits:[CGPoint]) -> [CGPoint]{
        let transformImage = CGAffineTransform.identity
                .scaledBy(x: 1, y: -1)
        
        let topLeft = ponits.first?.applying(transformImage) ?? .zero
        let topRight = ponits[1].applying(transformImage)
        let bottomRight = ponits[2].applying(transformImage)
        let bottomLeft = ponits[3].applying(transformImage)
        
        return [topLeft, topRight, bottomRight, bottomLeft]
        
    }
    
    func cutImage(fromPath path: UIBezierPath, originalImage: UIImage) -> UIImage? {
        // Create a graphics context based on the size of the original image
        UIGraphicsBeginImageContextWithOptions(originalImage.size, true, 1.0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        // Clip the context to the specified path
        context.addPath(path.cgPath)
        context.clip()
        
        // Draw the original image within the clipped context
        originalImage.draw(at: .zero)
        
        // Retrieve the image from the graphics context
        let clippedImage = UIGraphicsGetImageFromCurrentImageContext()
        
        // End the graphics context
        UIGraphicsEndImageContext()
        
        return clippedImage
    }
    
    func showImageFrom(document: DocumentDetails, forPreview: Bool = true, compressionQuality: CGFloat? = nil) -> UIImage? {
        var imageData = UIImage()
        if forPreview == true {
            if document.isFilterApplied {
                imageData = document.filteredImage
            } else {
                imageData = document.croppedImage
            }
        } else {
            if document.isFilterApplied {
                imageData = document.filteredImage
            } else {
                imageData = document.originalImage
            }
        }
        if let compressionQuality = compressionQuality {
            return compressedImage(imageData, compressionQuality: compressionQuality)
            
        } else {
            return imageData
        }
        
    }
    
  
    
    func compressedImage(_ originalImage: UIImage, compressionQuality: CGFloat = 1) -> UIImage {
        let targetSize = CGSize(width: 595, height: 842)
        guard let imageData = originalImage.jpegData(compressionQuality: compressionQuality),
              let reloadedImage = UIImage(data: imageData) else {
            return originalImage
        }
        return   reloadedImage
    }
    
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage? {
        let size = image.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }
        newSize = CGSize(width: size.width * widthRatio, height: size.height * heightRatio)
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(origin: .zero, size: newSize)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        //igview.image = newImage
        return newImage
    }
    
}
