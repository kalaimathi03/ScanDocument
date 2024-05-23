//
//  UIViewController.swift
//  ScanflowDocumentCapture
//
//  Created by Mac-OBS-46 on 12/05/23.
//

import Foundation
import UIKit
import PDFKit


extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}


public class DocumentScaningProgress {

    static public let shared = DocumentScaningProgress()
    public var delegate: DocumentScaningDelegate?

    open func showDocumentScaning(themeColor: UIColor = .appThemeColor, docuemntFlow: DocumentScaningFlow, license: String) -> UIViewController? {
        switch docuemntFlow {

            case .capturedDocumentListWithCapture:
                SFDocumentHelper.shared.appThemeColor = themeColor
                let bundle = Bundle(identifier: "com.ScanflowDocumentCapture")
                let storyBoard : UIStoryboard = UIStoryboard(name: "DocumentCapture", bundle:bundle)
                let nextViewController = storyBoard.instantiateViewController(withIdentifier: "DocumentHomeViewController") as! DocumentHomeViewController
                nextViewController.authKey = license
                return nextViewController
            case .captureDocument:
                SFDocumentHelper.shared.appThemeColor = themeColor
                let bundle = Bundle(identifier: "com.ScanflowDocumentCapture")
                let storyBoard : UIStoryboard = UIStoryboard(name: "DocumentCapture", bundle:bundle)
                let nextViewController = storyBoard.instantiateViewController(withIdentifier: "DocumentScaningViewController") as! DocumentScaningViewController
                nextViewController.scaningFlow = .captureDocument
                nextViewController.authKey = license
                nextViewController.delegate = self
                return nextViewController
            case .capturedDocumentList:
                let files = CoreDataManager.shared.fetch()
                let names = files?.compactMap({ $0.name})
                captutredDocuemnt(list: names ?? [])
                return nil
        }

    }

    public func convertToPdf(data: Data) -> Data? {
        let pdfDoc = PDFDocument()

        let arrarOfImage = CoreDataManager.shared.imagesFromCoreData(object: data)

        if let documentImages = arrarOfImage {
            for (index,image) in documentImages.enumerated() {
                let page = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4, 72 dpi
                let resized = resizeImage(image: image, targetSize: page.size) ?? UIImage()
                if let pdfPage = PDFPage(image: resized) {
                    pdfPage.setBounds(page, for: .mediaBox)
                    pdfDoc.insert(pdfPage, at: index)
                }
            }
        }


        return pdfDoc.dataRepresentation()
    }

    public func  converToImages(data: Data) -> [UIImage]?{
        return CoreDataManager.shared.imagesFromCoreData(object: data)
    }

    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage? {
        let size = image.size
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        var newSize: CGSize

        if (widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }

        // Calculate the centerX and centerY
        let centerX = (targetSize.width - newSize.width) / 2.0
        let centerY = (targetSize.height - newSize.height) / 2.0

        // The rect of the image should be based on the center calculations
        let rect = CGRect(x: centerX,
                          y: centerY,
                          width: newSize.width,
                          height: newSize.height)

        // The graphics context should be created with the page dimensions
        UIGraphicsBeginImageContextWithOptions(targetSize, true, image.scale)

        // The rest remains the same
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }

}


extension DocumentScaningProgress : DocumentScaningDelegate {
    public func capturedImage(data: Data, text: NSAttributedString) {
        delegate?.capturedImage(data: data, text: text)
    }

    public func failureOnCreatingPdf(error: String) {
        delegate?.failureOnCreatingPdf(error: error)
    }

    public func captutredDocuemnt(list: [String]) {
        delegate?.captutredDocuemnt(list: list)
    }

}
