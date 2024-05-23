//
//  UIImage.swift
//  ScanflowDocumentCapture
//
//  Created by Mac-OBS-46 on 16/05/23.
//

import Foundation
import UIKit
import CoreImage
import ScanflowCore
import opencv2



extension UIImage {
    
    func rotate(radians: CGFloat) -> UIImage {
        let rotatedSize = CGRect(origin: .zero, size: size)
            .applying(CGAffineTransform(rotationAngle: CGFloat(radians)))
            .integral.size
        UIGraphicsBeginImageContext(rotatedSize)
        if let context = UIGraphicsGetCurrentContext() {
            let origin = CGPoint(x: rotatedSize.width / 2.0,
                                 y: rotatedSize.height / 2.0)
            context.translateBy(x: origin.x, y: origin.y)
            context.rotate(by: radians)
            draw(in: CGRect(x: -origin.y, y: -origin.x,
                            width: size.width, height: size.height))
            let rotatedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            return rotatedImage ?? self
        }
        
        return self
    }
    
    func imageByApplyingMaskingBezierPath(_ path: UIBezierPath, _ pathFrame: CGRect) -> UIImage {
        
        UIGraphicsBeginImageContext(self.size)
        let context = UIGraphicsGetCurrentContext()!
        
        context.addPath(path.cgPath)
        context.clip()
        draw(in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
        
        let maskedImage = UIGraphicsGetImageFromCurrentImageContext()!
        
        UIGraphicsEndImageContext()
        
        return maskedImage
    }

    
}

extension UIView {
    func convertToImage() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(bounds.size, isOpaque, 0.0)
        defer { UIGraphicsEndImageContext() }
        
        if let context = UIGraphicsGetCurrentContext() {
            layer.render(in: context)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            return image
        }
        
        return nil
    }
}

extension UIImage {

    func imageByApplyingClippingBezierPath(_ path: UIBezierPath, tempView: UIView) -> UIImage? {
        // Mask image using path

        if let maskedImage = imageByApplyingMaskingBezierPath(path).cgImage {

            // Crop image to frame of path
            let croppedImage = UIImage(cgImage: maskedImage.cropping(to: path.bounds)!)
            tempView.frame = path.bounds
            tempView.backgroundColor = .white
                let imView = UIImageView(image: croppedImage)
                imView.frame = CGRect(x: 0, y: 0, width: path.bounds.width, height: path.bounds.height)
            tempView.addSubview(imView)
                let a = tempView.convertToImage()
                return a
            }
         
        return nil
    }

    
    func imageByApplyingMaskingBezierPath(_ path: UIBezierPath) -> UIImage {
        // Define graphic context (canvas) to paint on
        UIGraphicsBeginImageContext(size)
        let context = UIGraphicsGetCurrentContext()!
        context.saveGState()

        // Set the clipping mask
        path.addClip()
        draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))

        let maskedImage = UIGraphicsGetImageFromCurrentImageContext()!

        // Restore previous drawing context
        context.restoreGState()
        UIGraphicsEndImageContext()

        return maskedImage
    }

  
    
    
    func autoEnhancementApply() -> UIImage {
        print("started enhancement: \(SFManager.shared.getCurrentMillis())")
        let givenImage = self.cgImage
        let matImage = Mat(uiImage: self)
        let convertedMatImage = Mat()
        //pythin 3 chnnael Mat(UIimage:) -> 4 channel
        Imgproc.cvtColor(src: matImage, dst: convertedMatImage, code: .COLOR_RGB2BGR)
        
        return autoEnhancement(image: convertedMatImage)
    }
    
    func autoEnhancement(image: Mat) -> UIImage{

        print("autoEnhancement","Started")
        // Estimate light falloff
        
        let falloffImage = estimateLightFalloff(src: image)
   
        
        //lighten_background
        //enhance_text_color
        //increase_sharpness
        //enhance_colors_gamma
        //dilate_colors

        let lightenBackgroundMat = lightenBackground(src: falloffImage!)
        let enhanceTextMat = enhanceTextColor(src: lightenBackgroundMat)
        let increaseSharpnessMat = increaseSharpness(src: enhanceTextMat)
        let enhanceColorsGammaMat = enhanceColorsGamma(image: increaseSharpnessMat,gamma: 3.0)

        return enhanceColorsGammaMat.toUIImage()
    }
    
    func estimateLightFalloff(src: Mat) -> Mat? {
        // Check if the input image is valid
        if (src.empty() /*|| src.type() != CV_8UC3*/) {
           return src
        }
        // Apply median blur to reduce noise and artifacts
        let median = Mat()
        Imgproc.medianBlur(src: src, dst: median, ksize: Int32(23))

        // Find local maximum using morphology closing operation
        let localMaxKernel = Imgproc.getStructuringElement(shape: .MORPH_RECT, ksize: Size(width: Int32(75.0), height: Int32(75.0)))
        let localMax = Mat()
        Imgproc.morphologyEx(src: median, dst: localMax, op: .MORPH_CLOSE, kernel: localMaxKernel, anchor: Point(x: Int32(-1.0), y: Int32(-1.0)), iterations: Int32(1), borderType: .BORDER_REFLECT_101)

        // Calculate per-pixel gain to make localMax monochromatic 255
        let gain = Mat()
        opencv2.Core.divide(scale: 255.0, src: localMax, dst: gain, dtype: CvType.CV_32FC3)

        let srcFloat = Mat()
        src.convert(to: srcFloat, rtype: CvType.CV_32FC3)
        
        // Apply gain to the source image and clip the values
        var dstFloat = Mat()
        opencv2.Core.multiply(src1: gain, src2: srcFloat, dst: dstFloat)
        
        let scaledMat = Mat()
        opencv2.Core.convertScaleAbs(src: dstFloat, dst: scaledMat)
        let finalDst = Mat()
        scaledMat.convert(to: finalDst, rtype: CvType.CV_8U)
        
        return finalDst
    }
    
    func lightenBackground(src: Mat) -> Mat {
        // Convert image to HSV color space
        var hsv = Mat()
        var arrayMat:[Mat] = []
        Imgproc.cvtColor(src: src, dst: hsv, code: .COLOR_BGR2HSV)
        arrayMat.append(hsv)

        var channels:[Mat] = []
        opencv2.Core.split(m: hsv, mv: &channels)
        let h = channels[0]
        let s = channels[1]
        let v = channels[2]

        // Increase the value (brightness) of the V channel
        opencv2.Core.add(src1: v, srcScalar: Scalar(30.0), dst: v)
        

        // Merge the modified V channel with the original H and S channels
        var hsvLightened = Mat()
        opencv2.Core.merge(mv: [h, s, v], dst: hsvLightened)

        // Convert back to the original color space (BGR)
        var lightened = Mat()
        
        Imgproc.cvtColor(src: hsvLightened, dst: lightened, code: .COLOR_HSV2BGR)

        return lightened
    }
    
    func enhanceTextColor(src: Mat) -> Mat {
        // Convert image to LAB color space
        var lab = Mat()
        Imgproc.cvtColor(src: src, dst: lab, code: .COLOR_BGR2Lab)

        // Split the LAB image into individual channels
        var labChannels:[Mat] = []
        opencv2.Core.split(m: lab, mv: &labChannels)
        

        // Apply histogram equalization to the L channel
        var clahe = Imgproc.createCLAHE(clipLimit: 2.0)
        
        var l = labChannels[0]
        clahe.apply(src: l, dst: l)

        // Merge the enhanced L channel with the original A and B channels
        opencv2.Core.merge(mv: labChannels, dst: lab)
        

        // Convert back to the original color space (BGR)
        var enhanced = Mat()
        Imgproc.cvtColor(src: lab, dst: enhanced, code: .COLOR_Lab2BGR)

        return enhanced
    }
    
    func increaseSharpness(src: Mat) -> Mat {
        // Apply Gaussian blur to the source image
        var blurred = Mat()
        Imgproc.GaussianBlur(src: src, dst: blurred, ksize: Size2i(vals: [0.0, 0.0]), sigmaX: 3.0)

        // Calculate the sharpened image using the unsharp masking technique
        var sharpened = Mat()
        opencv2.Core.addWeighted(src1: src, alpha: 1.7, src2: blurred, beta: -0.5, gamma: 10.0, dst: sharpened)
        return sharpened
    }

    func enhanceColorsGamma(image: Mat, gamma: Double) -> Mat {
        // Convert image to the LAB color space
        var lab = Mat()
        Imgproc.cvtColor(src: image, dst: lab, code: .COLOR_BGR2Lab)
        ///Imgproc.cvtColor(image, lab, Imgproc.COLOR_BGR2Lab)

        // Split LAB channels
        var channels:[Mat] = []
        
        opencv2.Core.split(m: lab, mv: &channels)
        
        var l = channels[0]
        var a = channels[1]
        var b = channels[2]

        // Normalize L channel pixel intensities to the range [0, 1]
        var normalizedL = Mat()
        //l.convert(to: normalizedL, rtype: CvType., alpha: T##Double)
        l.convert(to: normalizedL, rtype: CvType.CV_32FC3, alpha: 1.0 / 255.0)

        // Apply gamma correction to L channel
        var correctedL = Mat()
        opencv2.Core.pow(src: normalizedL, power: gamma, dst: correctedL)
//        Core.pow(normalizedL, gamma, correctedL)

        // Scale L channel pixel intensities back to the range [0, 255]
        var enhancedL = Mat()
        opencv2.Core.multiply(src1: correctedL, srcScalar: Scalar(255.0), dst: enhancedL)
//        Core.multiply(correctedL, Scalar(255.0), enhancedL)
        enhancedL.convert(to: enhancedL, rtype: CvType.CV_8U)
//        enhancedL.convertTo(enhancedL, CV_8U)

        // Merge enhanced L channel with original A and B channels
        var enhancedLab = Mat()
        opencv2.Core.merge(mv: [enhancedL, a, b], dst: enhancedLab)
        

        // Convert image back to the original color space (BGR)
        var enhancedImage = Mat()
        Imgproc.cvtColor(src: enhancedLab, dst: enhancedImage, code: .COLOR_Lab2BGR)

        return enhancedImage
    }

    func dilateColors(image: Mat, colorLower: Scalar, colorUpper: Scalar, kernelSize: Size) -> Mat {
        // Convert image to HSV color space
        var hsv = Mat()
        Imgproc.cvtColor(src: image, dst: hsv, code: .COLOR_BGR2HSV)

        // Create a binary mask for the specified color range
        var mask = Mat()
        opencv2.Core.inRange(src: hsv, lowerb: colorLower, upperb: colorUpper, dst: mask)
        

        // Define a structuring element for dilation
        var kernel = Imgproc.getStructuringElement(shape: .MORPH_RECT, ksize: kernelSize)

        // Perform dilation on the color regions in the mask
        var dilatedMask = Mat()
        Imgproc.dilate(src: mask, dst: dilatedMask, kernel: kernel, anchor: Point(x: Int32(-1.0),y: Int32(-1.0)), iterations: 50)

        // Invert the dilated mask
        var invertedMask = Mat()
        Core.bitwise_not(src: dilatedMask, dst: invertedMask)

        // Apply the dilated mask to the original image
        var dilatedImage = Mat()
        opencv2.Core.bitwise_and(src1: image, src2: image, dst: dilatedImage)
        

        return dilatedImage
    }
    
    
}
