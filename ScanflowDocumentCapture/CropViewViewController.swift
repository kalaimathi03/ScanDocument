//
//  CropViewViewController.swift
//  ScanflowDocumentCapture
//
//  Created by Mac-OBS-46 on 12/05/23.
//

import UIKit
import Vision
import ScanflowCore
import CoreGraphics
import Accelerate

public enum movingPoint {
    
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
    case all
    
}

public enum showPoints {
    
    case leftMagnifier
    case rightMagnifier
    
}

protocol cropViewControllerDelegate: AnyObject {
    func updateDocuemnt(details: [DocumentDetails])
    func deleteButtonTapped()
}

class CropViewViewController: UIViewController {
    
    @IBOutlet weak var mainImageView: UIImageView!
    
    @IBOutlet weak var magniView: UIView!
    @IBOutlet weak var rightMagniMarker: UIImageView!
    
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var leftMagniView: UIView!
    @IBOutlet weak var leftMagniMarker: UIImageView!
    
    var topLeftCornerView: CornerPointView!
    var topRightCornerView: CornerPointView!
    var bottomLeftCornerView: CornerPointView!
    var bottomRightCornerView: CornerPointView!
    let bundle = Bundle(identifier: "com.ScanflowDocumentCapture")

    weak var delegate: cropViewControllerDelegate?
    @IBOutlet weak var doneButton: SFButton!
    var documentDetails: [DocumentDetails]? = []
    let path = UIBezierPath()
    let cropPath = UIBezierPath()
    var shapeLayer = CAShapeLayer()
    var cropLayer = CAShapeLayer()
    var currentDocuemnt:Int = 0
    var widthRatio: Double = 0
    var heightRatio: Double = 0
    var magTempView: UIView?
    var isFromScanningScreen:Bool = false
    var showLeftView: Bool = false {
        didSet {
            leftMagniView.isHidden = !showLeftView
            leftMagniMarker.isHidden = !showLeftView
        }
    }
    
    var showRightView: Bool = false {
        didSet {
            rightMagniMarker.isHidden = !showRightView
            magniView.isHidden = !showRightView
        }
    }
    var multipleSelected: Bool = true
    var scaningFlow: DocumentScaningFlow = .capturedDocumentListWithCapture
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if UIDevice.current.hasNotch == false {
            let tempFrame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.mainImageView.frame.height - 112)
            mainImageView.frame = tempFrame
        }
        magniView.layer.cornerRadius =  magniView.frame.width / 2
        magniView.clipsToBounds = true
        magniView.layer.borderColor = UIColor.white.cgColor
        magniView.layer.borderWidth = 2.0
        
        leftMagniView.layer.cornerRadius =  magniView.frame.width / 2
        leftMagniView.clipsToBounds = true
        leftMagniView.layer.borderColor = UIColor.white.cgColor
        leftMagniView.layer.borderWidth = 2.0
        
        mainImageView.image = documentDetails?[currentDocuemnt].originalImage ?? UIImage()
        
        magniView.layer.shadowColor = UIColor.black.cgColor
        magniView.layer.shadowOpacity = 0.8
        magniView.layer.shadowOffset = CGSize(width: 5, height: 5)
        magniView.layer.shadowRadius = 10
        
        widthRatio = mainImageView.image!.size.width / mainImageView.frame.width
        heightRatio = mainImageView.image!.size.height / mainImageView.frame.height
        
        if let documentBoundingRect = documentDetails?[currentDocuemnt].boundingRect {
            let boundRect = SFDocumentHelper.shared.calculateRect(path: documentBoundingRect, originalSize: mainImageView.image!.size, processingSize: mainImageView.frame.size)
            let boundData = boundRect
          let roundView1 = UIView()
            roundView1.backgroundColor = .white
            topLeftCornerView = CornerPointView(frame: CGRect(x: boundData.first!.x - 10, y:boundData.first!.y - 10, width: 70, height: 70))
            roundView1.frame = CGRect(x: 0, y:0, width: 20, height: 20)
            roundView1.layer.cornerRadius = 10
            topLeftCornerView.backgroundColor = .clear
            topLeftCornerView.addSubview(roundView1)
            
            let roundView2 = UIView()
              roundView2.backgroundColor = .white
            topRightCornerView = CornerPointView(frame: CGRect(x: boundData[2].x - 10, y: boundData[2].y - 10, width: 70, height: 70))
            roundView2.frame = CGRect(x: 0, y:0, width: 20, height: 20)
            roundView2.layer.cornerRadius = 10
            topRightCornerView.backgroundColor = .clear
            topRightCornerView.addSubview(roundView2)
            
            let roundView3 = UIView()
              roundView3.backgroundColor = .white
            bottomLeftCornerView = CornerPointView(frame: CGRect(x: boundData[1].x - 10, y: boundData[1].y - 10, width: 70, height: 70))
            roundView3.frame = CGRect(x: 0, y:0, width: 20, height: 20)
            roundView3.layer.cornerRadius = 10
            bottomLeftCornerView.backgroundColor = .clear
            bottomLeftCornerView.addSubview(roundView3)
            
            let roundView4 = UIView()
              roundView4.backgroundColor = .white
            bottomRightCornerView = CornerPointView(frame: CGRect(x: boundData[3].x - 10, y: boundData[3].y - 10, width: 70, height: 70))
            roundView4.frame = CGRect(x: 0, y:0, width: 20, height: 20)
            roundView4.layer.cornerRadius = 10
            bottomRightCornerView.backgroundColor = .clear
            bottomRightCornerView.addSubview(roundView4)
            
        } else {
            let width = self.bgView.frame.width
            let height = self.bgView.frame.height
            
            topLeftCornerView = CornerPointView(frame: CGRect(x: ((width/2) + 100), y: ((height/2) + 100), width: 20, height: 20))
            topRightCornerView = CornerPointView(frame: CGRect(x: ((width/2) - 100), y: ((height/2) - 100), width: 20, height: 20))
            bottomLeftCornerView = CornerPointView(frame: CGRect(x: ((width/2) + 100), y: ((height/2) - 100), width: 20, height: 20))
            bottomRightCornerView = CornerPointView(frame: CGRect(x: ((width/2) - 100), y: ((height/2) + 100), width: 20, height: 20))
        }
        //mainImageView.addSubview(cropView!)
        //self.view.bringSubviewToFront(cropView!)
        bgView.addSubview(topLeftCornerView)
        bgView.addSubview(topRightCornerView)
        bgView.addSubview(bottomLeftCornerView)
        bgView.addSubview(bottomRightCornerView)
        
        let topLeftDragCompletionHandler: () -> Void = {
            // Update overlay based on new corner point positions

            self.showLeftView = false
            self.showRightView = true
            if self.topLeftCornerView.gestureRecognizers?.first?.state == .ended {
                self.showLeftView = false
                self.showRightView = false
            }
            self.updateOverlay(point: .topLeft)
        }
        
        let topRightDragCompletionHandler: () -> Void = {
            // Update overlay based on new corner point positions
            self.showLeftView = true
            self.showRightView = false
            if self.topRightCornerView.gestureRecognizers?.first?.state == .ended {
                self.showLeftView = false
                self.showRightView = false
            }
            self.updateOverlay(point: .topRight)
        }
        let bottomLeftDragCompletionHandler: () -> Void = {
            // Update overlay based on new corner point positions
            self.showLeftView = true
            self.showRightView = false
            if self.bottomLeftCornerView.gestureRecognizers?.first?.state == .ended {
                self.showLeftView = false
                self.showRightView = false
            }
            self.updateOverlay(point: .bottomLeft)
        }
        let bottomRighDragCompletionHandler: () -> Void = {
            // Update overlay based on new corner point positions
            self.showLeftView = false
            self.showRightView = true
            if self.bottomRightCornerView.gestureRecognizers?.first?.state == .ended {
                self.showLeftView = false
                self.showRightView = false
            }
            self.updateOverlay(point: .bottomRight)
        }
        
        // Set completion handler for corner point drag events
        topLeftCornerView.completionHandler = topLeftDragCompletionHandler
        topRightCornerView.completionHandler = topRightDragCompletionHandler
        bottomLeftCornerView.completionHandler = bottomLeftDragCompletionHandler
        bottomRightCornerView.completionHandler = bottomRighDragCompletionHandler
        
        bgView.layer.addSublayer(shapeLayer)
        updateOverlay(point: .all)
    }
    
    func updateOverlay(point: movingPoint) {
        print("👉🏼\(point)")
        path.removeAllPoints()
        cropPath.removeAllPoints()
        // Define the four points
        let point1 = CGPoint(x: topLeftCornerView.frame.minX + 10 , y: topLeftCornerView.frame.minY + 10)
        let point2 = CGPoint(x: topRightCornerView.frame.minX + 10, y: topRightCornerView.frame.minY + 10)
        let point3 = CGPoint(x: bottomLeftCornerView.frame.minX + 10, y: bottomLeftCornerView.frame.minY + 10)
        let point4 = CGPoint(x: bottomRightCornerView.frame.minX + 10, y: bottomRightCornerView.frame.minY + 10)
        // Move to the first point
        path.move(to: point4)
        
        // Draw lines to the remaining points
        path.addLine(to: point2)
        path.addLine(to: point3)
        path.addLine(to: point1)
        // Close the path
        path.close()
        
        // Create a shape layer to display the path
        shapeLayer.path = path.cgPath
        shapeLayer.strokeColor = UIColor.white.cgColor
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.masksToBounds = false
        shapeLayer.shadowColor = UIColor.black.cgColor
        shapeLayer.shadowOpacity = 0.2
        shapeLayer.shadowOffset = .zero
        shapeLayer.shadowRadius = 3
        shapeLayer.lineWidth = 2.0
        
        switch point {
            
        case .topLeft:
            UpdatingMagnifierView(tappedPoint: point1, viewPosition: .rightMagnifier)
        case .topRight:
            UpdatingMagnifierView(tappedPoint: point2, viewPosition: .leftMagnifier)
        case .bottomLeft:
            UpdatingMagnifierView(tappedPoint: point3, viewPosition: .leftMagnifier)
        case .bottomRight:
            UpdatingMagnifierView(tappedPoint: point4, viewPosition: .rightMagnifier)
        case .all:
            break
        }
        
    }
    
    @IBAction func backButtonTapped(_ sender: Any) {
        if isFromScanningScreen == true {
            documentDetails?.removeLast()
            delegate?.updateDocuemnt(details: self.documentDetails ?? [])
        }
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func doneButtonTapped(_ sender: Any) {
        if let originalImage = documentDetails?[currentDocuemnt].originalImage {
            cropPath.move(to: CGPoint(x: ((bottomRightCornerView.frame.minX + 10.0) * widthRatio), y: ((bottomRightCornerView.frame.minY + 10.0) * heightRatio)))
            cropPath.addLine(to: CGPoint(x: ((topRightCornerView.frame.minX + 10.0) * widthRatio), y: ((topRightCornerView.frame.minY + 10.0) * heightRatio)))
            cropPath.addLine(to: CGPoint(x: ((bottomLeftCornerView.frame.minX + 10.0) * widthRatio), y: ((bottomLeftCornerView.frame.minY + 10.0) * heightRatio)))
            cropPath.addLine(to: CGPoint(x: ((topLeftCornerView.frame.minX + 10.0) * widthRatio) , y: ((topLeftCornerView.frame.minY + 10.0) * heightRatio)))
            cropPath.close()
            print("Stared crop im")

            if let newCropppedImage = originalImage.imageByApplyingClippingBezierPath(cropPath, tempView: UIView()) {
                let page = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4, 72 dpi
                    
                    let ratio = newCropppedImage.size.width / page.width
                    let newWidth = (newCropppedImage.size.width / ratio).rounded(.down)
                    let newHeight = (newCropppedImage.size.height / ratio).rounded(.down)
                    let newDimension = CGSize(width: newWidth, height: newHeight)
                    
                    let tempData = newCropppedImage.resize(toSize: newDimension, path: cropPath)
                     documentDetails?[currentDocuemnt].croppedImage = tempData!
                    delegate?.updateDocuemnt(details: documentDetails!)
                
            }
            
        }
        if multipleSelected == true {
            self.navigationController?.popViewController(animated: true)
        } else {
            let storyBoard : UIStoryboard = UIStoryboard(name: "DocumentCapture", bundle:bundle)
            
            if let vc = storyBoard.instantiateViewController(withIdentifier: "DocumentPreviewViewController")  as? DocumentPreviewViewController {
                vc.multipleDocuemnt = multipleSelected
                vc.capturedDocument = documentDetails
                vc.scaningFlow = scaningFlow
                vc.delegate = self
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
     func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size

        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height

        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }

        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: targetSize.width, height: targetSize.height)

        //resizing the rect using the ImageContext
        UIGraphicsBeginImageContextWithOptions(targetSize, true, 0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage!
    }
    
    func resizeImage(image: UIImage, newSize: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: newSize)
           let resizedImage = renderer.image { context in
               image.draw(in: CGRect(origin: .zero, size: newSize))
           }
           
        return resizedImage
    }
    
    func resizeCGImage(image: CGImage, newSize: CGSize) -> CGImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        guard let context = CGContext(data: nil, width: Int(newSize.width), height: Int(newSize.height), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            return nil
        }
        
        context.interpolationQuality = .high
        context.draw(image, in: CGRect(origin: .zero, size: newSize))
        
        return context.makeImage()
    }
    
    func cutImage(fromPath path: UIBezierPath, originalImage: UIImage) -> UIImage? {
        // Create a graphics context based on the size of the original image
        UIGraphicsBeginImageContextWithOptions(originalImage.size, false, 1.0)
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
        
        let maskedImage = clippedImage!.cgImage
        let da = clippedImage!.crop(to: path.bounds, from: CGPoint(x: path.bounds.minX, y: path.bounds.minY))
        let croppedImage = UIImage(cgImage: maskedImage!.cropping(to: path.bounds)!)
        
        return croppedImage
    }
    
    func resizeImage(_ image: UIImage, newSize: CGSize) -> UIImage? {
//        let newData = CGSize(width: (image.size.width / newSize.width), height: (image.size.height / newSize.height))
//        let changedOne = CGSize(width: (image.size.width / newData.width), height: (image.size.height / newData.height))
        
        let ratio = image.size.width / newSize.width
        let newWidth = image.size.width / ratio
        let newHeight = image.size.height / ratio
        let newDimension = CGSize(width: newWidth, height: newHeight)
        
        UIGraphicsBeginImageContextWithOptions(newDimension, true, 0.0)
        defer { UIGraphicsEndImageContext() }
        
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        
        return resizedImage
    }
    
    func getMaskedImage(path: CGPath, picture: UIImage) -> UIImage? {
        let imageLayer = CALayer()
        imageLayer.frame = cropPath.bounds
        imageLayer.contents = picture.cgImage
        let maskLayer = CAShapeLayer()
        //let maskPath = path.resized(to: CGRect(origin: .zero, size: picture.size))
        maskLayer.path = path
        maskLayer.fillRule = .evenOdd
        imageLayer.mask = maskLayer
        UIGraphicsBeginImageContext(picture.size)
        defer { UIGraphicsEndImageContext() }

        if let context = UIGraphicsGetCurrentContext() {
            imageLayer.render(in: context)
            
            let newImage = UIGraphicsGetImageFromCurrentImageContext()

            return newImage
        }
        return nil
    }

    func cropImageWithBezierPath2(image: UIImage, bezierPath: UIBezierPath) -> UIImage? {
        // Create a shape layer with the bezier path
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = bezierPath.cgPath
                
        // Create a new image view with the original image
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFill
        
        // Apply the shape layer as a mask to the image view
        imageView.layer.mask = shapeLayer
        
        // Render the masked image view into a new image
        UIGraphicsBeginImageContextWithOptions(image.size, false, 0.0)
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
//        imageView.path
        imageView.layer.render(in: context)
        let croppedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return croppedImage
    }
    func cropImageWithBezierPath3(originalImage: UIImage, bezierPath: UIBezierPath) -> UIImage? {
        // Create a shape layer with the bezier path
   
        UIGraphicsBeginImageContextWithOptions(originalImage.size, false, originalImage.scale)
        let context = UIGraphicsGetCurrentContext()


        bezierPath.addClip()


        originalImage.draw(at: .zero)


        let croppedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        //Crop Image using *CGRect*
        return croppedImage
    }
    

    private func UpdatingMagnifierView(tappedPoint: CGPoint, viewPosition: showPoints) {
        let magnificationFrame = CGRect(x: ((tappedPoint.x * widthRatio) - 75) , y: ((tappedPoint.y * heightRatio) - 75), width: 150, height: 150)
        magTempView = UIView(frame: magnificationFrame)

        
        let magnificationContent = UIImageView(frame: magTempView?.bounds ?? CGRect.zero)
        magTempView?.backgroundColor = UIColor.white.withAlphaComponent(0.8)

        magnificationContent.contentMode = .scaleToFill
        magnificationContent.clipsToBounds = true
        let tempImage = resizeImage(mainImageView.image!, newSize: mainImageView.frame.size)
        let tempTect = CGRect(origin: CGPoint(x: ((magnificationFrame.minX - 10) * widthRatio), y: ((magnificationFrame.minY+10) * heightRatio)), size: magnificationFrame.size)
        let asd = cropImageData1(image: mainImageView.image!, cropRect: magnificationFrame)
        let asdsdd =  resizeImage(asd!, newSize: magnificationFrame.size)
        magnificationContent.image = asdsdd
        magnificationContent.tag = 999
        if viewPosition == .leftMagnifier {
            if let vieData = leftMagniView.viewWithTag(999) {
                vieData.removeFromSuperview()
            }
            leftMagniView?.addSubview(magnificationContent)
        } else {
            if let vieData = magniView.viewWithTag(999) {
                vieData.removeFromSuperview()
            }
            magniView?.addSubview(magnificationContent)
        }
    }
     

    func cropImage(image: UIImage, cropRect: CGRect) -> UIImage? {
        guard let cgImage = image.cgImage else {
            return nil
        }
        
        let croppedCGImage = cgImage.cropping(to: cropRect)
        let croppedImage = UIImage(cgImage: croppedCGImage!)
        
        return croppedImage
    }

    func imageCrop(originalImage: UIImage) -> UIImage? {
        if originalImage.imageOrientation != .up {
            UIGraphicsBeginImageContextWithOptions(originalImage.size, false, originalImage.scale)
            originalImage.draw(in: CGRect(origin: .zero, size: originalImage.size))
            let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            // Use the normalizedImage for cropping
            // Update the originalImage variable with normalizedImage
        return normalizedImage
        }
        return nil
    }

    

    func cropImageWithBezierPath(image: UIImage, bezierPath: UIBezierPath) -> UIImage? {
        // Create a CGRect representing the bounds of the bezier path
        let bounds = bezierPath.bounds
        
        // Scale the bounds to match the image's scale
        let scale = image.scale
        let scaledBounds = CGRect(x: bounds.origin.x * scale, y: bounds.origin.y * scale, width: bounds.size.width * scale, height: bounds.size.height * scale)
        
        // Create a new context with the cropped size
        UIGraphicsBeginImageContextWithOptions(scaledBounds.size, true, scale)
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        
        // Apply a translation transform to the context to align the bezier path at (0, 0)
        context.translateBy(x: -scaledBounds.origin.x, y: -scaledBounds.origin.y)
        
        // Add the bezier path to the context as a clipping path
        bezierPath.addClip()
        
        // Draw the image within the context
        image.draw(at: .zero)
        
        // Retrieve the cropped image from the context
        let croppedImage = UIGraphicsGetImageFromCurrentImageContext()
        
        // End the image context
        UIGraphicsEndImageContext()
        
        return croppedImage
    }

    func clipImageWithBezierPath(image: UIImage, bezierPath: UIBezierPath) -> UIImage? {
        // Create a new graphics context with the same size as the image
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        defer { UIGraphicsEndImageContext() }
        
        // Create a path for the image bounds
        let imageRect = CGRect(origin: .zero, size: image.size)
        let path = UIBezierPath(rect: imageRect)
        
        // Apply the clipping path
        path.append(bezierPath)
        path.addClip()
        
        // Draw the image within the clipped context
        image.draw(in: imageRect)
        
        // Get the clipped image from the current graphics context
        let clippedImage = UIGraphicsGetImageFromCurrentImageContext()
        
        return clippedImage
    }


    func cropImageData(image: UIImage, cropRect: CGRect) -> UIImage? {
        // Scale cropRect based on the image's scale
        let scaledCropRect = CGRect(x: cropRect.origin.x * image.scale,
                                    y: cropRect.origin.y * image.scale,
                                    width: cropRect.size.width * image.scale,
                                    height: cropRect.size.height * image.scale)
        
        // Create a new graphics context with the desired size
        UIGraphicsBeginImageContextWithOptions(scaledCropRect.size, false, image.scale)
        
        // Clear the context with a transparent background
        UIColor.clear.setFill()
        UIRectFill(CGRect(origin: .zero, size: scaledCropRect.size))
        
        // Perform the crop by drawing the image in the graphics context
        image.draw(at: CGPoint(x: -scaledCropRect.origin.x, y: -scaledCropRect.origin.y))
        
        // Get the cropped image from the graphics context
        let croppedImage = UIGraphicsGetImageFromCurrentImageContext()
        
        // End the graphics context
        UIGraphicsEndImageContext()
        
        return croppedImage
    }

    
    func cropImageWithBezierPath1(image: UIImage, bezierPath: UIBezierPath) -> UIImage? {
        let outputSize = CGRect(origin: .zero, size: image.size)
        
        let renderer = UIGraphicsImageRenderer(bounds: outputSize, format: UIGraphicsImageRendererFormat())
        
        let croppedImage = renderer.image { context in
            // Set the current context to clip to the bezier path
            context.cgContext.addPath(bezierPath.cgPath)
            context.cgContext.clip()
            
            // Draw the image within the bezier path bounds
            image.draw(in: outputSize)
        }
        
        return croppedImage
    }

    func cropImageData1(image: UIImage, cropRect: CGRect) -> UIImage? {
        // Scale cropRect based on the image's scale
        let scaledCropRect = CGRect(x: cropRect.origin.x * image.scale,
                                    y: cropRect.origin.y * image.scale,
                                    width: cropRect.size.width * image.scale,
                                    height: cropRect.size.height * image.scale)
        
        // Create a new graphics context with the desired size
        UIGraphicsBeginImageContextWithOptions(scaledCropRect.size, false, image.scale)
        
        // Perform the crop by drawing the image in the graphics context
        image.draw(at: CGPoint(x: -scaledCropRect.origin.x, y: -scaledCropRect.origin.y))
        
        // Get the cropped image from the graphics context
        let croppedImage = UIGraphicsGetImageFromCurrentImageContext()
        
        // End the graphics context
        UIGraphicsEndImageContext()
        
        return croppedImage
    }


}


extension UIImage {
    func crop(to rect: CGRect, from point: CGPoint) -> CGRect? {
        let scaledRect = CGRect(x: point.x * scale, y: point.y * scale, width: rect.width * scale, height: rect.height * scale)
        
       
        return scaledRect
    }
}

extension UIImage {
    func resize(toSize size: CGSize, path: UIBezierPath) -> UIImage? {

        let rect = CGRect(origin: .zero, size: size)
        
        UIGraphicsBeginImageContextWithOptions(size, true, 0.0)
        draw(in: rect)
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        let page = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4, 72 dpi
        let tempView = UIView(frame: page)
        tempView.backgroundColor = .white
            let imView = UIImageView(image: resizedImage)
            imView.frame = CGRect(x: 0, y: 0, width: page.width, height: page.height)
        imView.contentMode = .scaleAspectFit
        tempView.addSubview(imView)
            let convertedImage = tempView.convertToImage()
        return convertedImage
    }
}

extension CropViewViewController: DocumentPreviewViewControllerDelegate {
    func deleteButtonTapped() {
        delegate?.deleteButtonTapped()
    }
    
    
    func updateDocuemnt(details: [DocumentDetails]) {
        delegate?.updateDocuemnt(details: details)
    }
   
    
}

extension UIDevice {
    var hasNotch: Bool {
        let bottom = UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0
        return bottom > 0
    }
}
