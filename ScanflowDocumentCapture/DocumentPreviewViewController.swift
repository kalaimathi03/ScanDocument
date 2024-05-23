//
//  DocumentPreviewViewController.swift
//  ScanflowDocumentCapture
//
//  Created by Mac-OBS-46 on 12/05/23.
//

import Foundation
import UIKit
import PDFKit
import ScanflowCore
import opencv2
import CoreGraphics
import PDFKit
import ScanflowCore
import CommonCrypto

protocol DocumentPreviewViewControllerDelegate: AnyObject {
    func deleteButtonTapped()
    func updateDocuemnt(details: [DocumentDetails])

}


class DocumentPreviewViewController: UIViewController {
    
    
    @IBOutlet weak var rotateButton: SFButton!
    
    @IBOutlet weak var saveButton: SFButton!
    
    @IBOutlet weak var addImageButton: SFButton!
    
    @IBOutlet weak var documentCollectionView: UICollectionView!
    
    @IBOutlet weak var cropButton: SFButton!
    var pdfDocument = PDFDocument()
    var isEditeFlow: Bool = false
    var docuemntId: Int?
    private let activityIndicator = UIActivityIndicatorView(style: .gray)

    var cameraManager: ScanflowCameraManager?
    
    let bundle = Bundle(identifier: "com.ScanflowDocumentCapture")
    
    var capturedImage: [UIImage]?
    var documentTitle: String?
    var capturedDocument: [DocumentDetails]?
    weak var delegate: DocumentPreviewViewControllerDelegate?
    weak var documentDelegate: DocumentScaningDelegate?
    var pdfData: Data?
    var multipleDocuemnt: Bool = true
    var scaningFlow: DocumentScaningFlow = .capturedDocumentListWithCapture
    var currentDocument: Documents?
    var compressRatio:[CGFloat] = [1.0, 0.80, 0.50, 0.25]

    override func viewDidLoad() {
        super.viewDidLoad()
        saveButton.setTitle("Save", for: .normal)
        documentCollectionView.isPagingEnabled = true
        
        documentCollectionView.delegate = self
        documentCollectionView.dataSource = self
        
        documentCollectionView.register(UINib(nibName: "DocumentPreviewCollectionViewCell", bundle: bundle), forCellWithReuseIdentifier: "DocumentPreviewCollectionViewCell")
        if let id = docuemntId {
            currentDocument = CoreDataManager.shared.fetch(documentID: id)?.first
        }
    }
    
    @IBAction func cropButtonTapped(_ sender: Any) {
        let storyBoard : UIStoryboard = UIStoryboard(name: "DocumentCapture", bundle:bundle)
        if let vc = storyBoard.instantiateViewController(withIdentifier: "CropViewViewController")  as? CropViewViewController {
            vc.documentDetails = capturedDocument
            vc.currentDocuemnt = getCurrentRow()
            vc.delegate = self
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @IBAction func filterButtonTapped(_ sender: Any) {
        let storyBoard : UIStoryboard = UIStoryboard(name: "DocumentCapture", bundle:bundle)
        if let vc = storyBoard.instantiateViewController(withIdentifier: "DocumentFilterViewController")  as? DocumentFilterViewController {
            vc.capturedDocuments = capturedDocument
            vc.currentDocuemntAddress = getCurrentRow()
            vc.delegate = self
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

    func resizeImage(_ image: UIImage, newSize: CGSize) -> UIImage? {
        let newData = CGSize(width: (image.size.width / newSize.width), height: (image.size.height / newSize.height))
        let changedOne = CGSize(width: (image.size.width / newData.width), height: (image.size.height / newData.height))
        UIGraphicsBeginImageContextWithOptions(changedOne, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        
        return resizedImage
    }
    
    @IBAction func saveButtonTapped(_ sender: Any) {

        showLoadingIndicator(status: true)
        var captureImage:[UIImage] = []
        let fileManager = FileManager.default

        let _ = capturedDocument?.filter({
            if $0.isFilterApplied == true {
                captureImage.append($0.filteredImage)
            } else {
                captureImage.append($0.croppedImage)
            }
            
            return true
        })
        self.capturedImage = captureImage

        if let imagesData = CoreDataManager.shared.coreDataObjectFromImages(images: captureImage) {
//Save button flow
//            if let encryptedData = try? cameraManager?.encrypt(data: imagesData, keyData: AESconfig.key.rawValue, ivData: AESconfig.once.rawValue) {
                if isEditeFlow == false {
                    CoreDataManager.shared.createDocument(name: randomFilenameGeneration(), Data: imagesData, date: Date(), jpegSize: dataSize(type: .jpg), pngSize: dataSize(type: .png), pdfSize: dataSize(type: .pdf))
                }
//            }

        }
        pdfDocument =  makePDF(images: captureImage)!
        if isEditeFlow == true {
            if let imageFilteData = currentDocument?.fileData {
//                let imagesData = decryptFile(key: AESconfig.key.rawValue, nonce: AESconfig.once.rawValue, data: imageFilteData)
                var images =  CoreDataManager.shared.imagesFromCoreData(object: imageFilteData) ?? []

                    images.append(contentsOf: captureImage)
                self.capturedImage = images
                if let imageData = CoreDataManager.shared.coreDataObjectFromImages(images: images) {
                    do {
//                        let enryptedData = try? cameraManager?.encrypt(data: imageData, keyData: AESconfig.key.rawValue, ivData: AESconfig.once.rawValue)

                        CoreDataManager.shared.updateDocuemnt(id: docuemntId ?? 0, imagedata: imageData, pdfSize: dataSize(type: .pdf), jpgSize: dataSize(type: .jpg), pngSize: dataSize(type: .png))
                        print("✅ Document saved succesfuly")

                    } catch let error {
                        print("❌ Failed to create Person: \(error.localizedDescription)")
                    }


                }
            }
            if let viewControllerToRemove = navigationController?.viewControllers.first(where: { $0 is DocumentViewViewController }) {
                // Pop the identified view controller from the navigation stack
                navigationController?.popToViewController(viewControllerToRemove, animated: true)
            }
        } else {
            //Save button FLow
            switch scaningFlow {
                case .captureDocument:
                    if let imageData = CoreDataManager.shared.coreDataObjectFromImages(images: captureImage) {
                        documentDelegate?.capturedImage(data: imageData, text: readFromPDF())
                    }
                    navigationController?.popToRootViewController(animated: true)

                case .capturedDocumentListWithCapture:
                    if let viewControllerToRemove = navigationController?.viewControllers.first(where: { $0 is DocumentHomeViewController }) {
                        // Pop the identified view controller from the navigation stack
                        navigationController?.popToViewController(viewControllerToRemove, animated: true)
                    }
                case .capturedDocumentList:
                    break
            }
        }

        showLoadingIndicator(status: false)

    }

    private func dataSize(type: exportType) -> String {
        var tempSize:[String] = []
        for compres in compressRatio {
            print(tempSize)
            switch type {
                case .pdf:
                    let pdfDoc = PDFDocument()
                    if let images = capturedImage?.map({UIImage(data: $0.jpegData(compressionQuality: compres)!)!}) {


                        for (index,image) in images.enumerated() {
                            let page = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4, 72 dpi
                            let resized = resizeImage(image: image, targetSize: page.size) ?? UIImage()
                            if let pdfPage = PDFPage(image: resized) {
                                pdfPage.setBounds(page, for: .mediaBox)
                                pdfDoc.insert(pdfPage, at: index)
                            }
                        }
                        let dataSize =  round(Double(pdfDoc.dataRepresentation()?.count ?? 0) / 1024.0)
                            if dataSize <= 1024 {
                                tempSize.append("\(dataSize) KB")
                            } else {
                                tempSize.append("\(dataSize / 1024.0) MB")
                            }

                    }
                case .jpg:
                    print(capturedImage)
                    if let a = capturedImage?.map({$0.jpegData(compressionQuality: compres)!}) {
                        print(a)

                        var tempDataSize:Int = 0
                        let _ = a.map({ tempDataSize += $0.count})

                        let dataSize = round(((Double(tempDataSize) / 1024.0) * 10)) / 10
                        if dataSize <= 1024 {
                            tempSize.append("\(dataSize) KB")
                        } else {
                            tempSize.append("\(round(((dataSize / 1024.0) * 10)) / 10 ) MB")
                        }
                    }
                case .png:
                    print(capturedImage)
                    if let a = capturedImage?.map({UIImage(data: $0.jpegData(compressionQuality: compres)!)!.pngData()!}) {
                        print(a)

                        var tempDataSize:Int = 0
                        let _ = a.map({ tempDataSize += $0.count})
                        print(tempDataSize)
                        let dataSize = round(((Double(tempDataSize) / 1024.0) * 10)) / 10
                        if dataSize <= 1024 {
                            tempSize.append("\(dataSize) KB")
                        } else {
                            tempSize.append("\(round(((dataSize / 1024.0) * 10)) / 10 ) MB")
                        }
                    }
            }

        }

        let result = tempSize.joined(separator: ",")
        return result
    }

    func sizeOfArray<T>(_ array: [T]) -> Double {
        let totalBytes = array.reduce(0) { $0 + MemoryLayout.size(ofValue: $1) }
        print(totalBytes)
        return Double(totalBytes)

    }

    private func compressedImage(_ originalImage: UIImage, compressionQuality: CGFloat = 1) -> UIImage {
        guard let imageData = originalImage.jpegData(compressionQuality: compressionQuality),
              let reloadedImage = UIImage(data: imageData) else {
            return originalImage
        }
        return   reloadedImage
    }

    func decryptFile(key: String, nonce: String, data: Data) -> Data? {
        let keyData = Data(hexString: key)!
        let ivData = Data(hexString: nonce)!
        let decryptedData = data
        var decryptedDataCopy = decryptedData
        var decryptedDataLength: Int = 0

        let status = keyData.withUnsafeBytes { keyBytes in
            ivData.withUnsafeBytes { ivBytes in
                data.withUnsafeBytes { dataBytes in
                    decryptedDataCopy.withUnsafeMutableBytes { decryptedDataBytes in
                        CCCrypt(
                            CCOperation(kCCDecrypt),
                            CCAlgorithm(kCCAlgorithmAES),
                            CCOptions(kCCOptionPKCS7Padding),
                            keyBytes.baseAddress, kCCKeySizeAES128,
                            ivBytes.baseAddress,
                            dataBytes.baseAddress, data.count,
                            decryptedDataBytes.baseAddress, decryptedData.count,
                            &decryptedDataLength
                        )
                    }
                }
            }
        }

        if status == kCCSuccess {
            decryptedDataCopy.removeSubrange(decryptedDataLength..<decryptedData.count)
            return decryptedDataCopy
        } else {
            return nil
        }
    }

    private func documentScaningFlow() {
        let fileManager = FileManager.default
        let documentsUrl = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        
        
        let docURL = documentsUrl.appendingPathComponent("Scanflow")
        
        do {
            try fileManager.createDirectory(at: docURL, withIntermediateDirectories: true, attributes: nil)
            
        } catch (let error) {
            documentDelegate?.failureOnCreatingPdf(error: error.localizedDescription)
            print("error is \(error.localizedDescription)")
        }
        let destination = docURL.appendingPathComponent(randomFilenameGeneration())
        var pdfData:Data = Data()
        do {
            if pdfDocument.write(to: destination) {
                documentDelegate?.capturedImage(data: pdfDocument.dataRepresentation() ?? Data(), text: readFromPDF())
            }
        } catch (let error) {
            documentDelegate?.failureOnCreatingPdf(error: error.localizedDescription)
            print("error is \(error.localizedDescription)")
        }
        navigationController?.popToRootViewController(animated: true)
    }
    
    private func readFromPDF() -> NSAttributedString {
        let pageCount = pdfDocument.pageCount
        let documentContent = NSMutableAttributedString()

        for i in 0 ..< pageCount {
            guard let page = pdfDocument.page(at: i) else { continue }
            guard let pageContent = page.attributedString else { continue }
            documentContent.append(pageContent)
        }
        return documentContent
    }

    func showLoadingIndicator(status: Bool) {
        if status == true {
                self.activityIndicator.center = self.view.center
                self.view.addSubview(self.activityIndicator)
                self.activityIndicator.startAnimating()
        } else {
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                self.activityIndicator.removeFromSuperview()
            }
        }
    }
    
    func makePDF(images: [UIImage])-> PDFDocument? {
        let pdfDoc = PDFDocument()
        for (index,image) in images.enumerated() {
            if let pdfPage = PDFPage(image: image) {
                let page = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4, 72 dpi
                pdfPage.setBounds(page, for: .mediaBox)
                pdfDoc.insert(pdfPage, at: index)
            }
            
        }
        return pdfDoc
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
    
   
    func createPDFWithAspectFitImages(images: [UIImage], outputURL: URL) {
        let pdfDocument = PDFDocument()
        
        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4 page size in points (72 points per inch)
        
        for image in images {
            let pdfPage = PDFPage()
            
            UIGraphicsBeginPDFPageWithInfo(pageRect, nil)
            
            let imageSize = image.size
            
            let scaleX = pageRect.width / imageSize.width
            let scaleY = pageRect.height / imageSize.height
            let scale = min(scaleX, scaleY)
            
            let scaledImageSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
            let translationX = (pageRect.width - scaledImageSize.width) / 2
            let translationY = (pageRect.height - scaledImageSize.height) / 2
            
            let scaledImageRect = CGRect(x: translationX, y: translationY, width: scaledImageSize.width, height: scaledImageSize.height)
            
            image.draw(in: scaledImageRect)
            
            pdfPage.draw(with: .mediaBox, to: UIGraphicsGetCurrentContext()!)
            //pdfPage.draw(with: <#T##PDFDisplayBox#>, to: <#T##CGContext#>)
            pdfDocument.insert(pdfPage, at: pdfDocument.pageCount)
        }
        
        pdfDocument.write(to: outputURL)
    }
    
    @IBAction func deleteButtonTapped(_ sender: Any) {
        let alertController = UIAlertController(title: "Delete", message: "Delete all images?", preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "NO", style: .default) { (_) in
            //do nothing
    
        }
        alertController.addAction(okAction)
        
        let cancelAction = UIAlertAction(title: "YES", style: .cancel) { (_) in
            // Handle cancel button action
            self.delegate?.deleteButtonTapped()
            if self.multipleDocuemnt == true {
                self.navigationController?.popViewController(animated: true)
            } else {
                if let viewControllerToRemove = self.navigationController?.viewControllers.first(where: { $0 is DocumentScaningViewController }) {
                    // Pop the identified view controller from the navigation stack
                    self.navigationController?.popToViewController(viewControllerToRemove, animated: true)
                }
            }
        }
        alertController.addAction(cancelAction)
        
        // Add additional actions if needed
        
        // Present the alert controller
        if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
            rootViewController.present(alertController, animated: true, completion: nil)
        }
        
    }
    
    @IBAction func rorateButtonTapped(_ sender: Any) {
        // Load the image from a file or from an existing UIImage object
        var documentImage: UIImage?
        if capturedDocument?[getCurrentRow()].isFilterApplied == true {
            documentImage = capturedDocument?[getCurrentRow()].filteredImage
        } else {
            documentImage = capturedDocument?[getCurrentRow()].croppedImage
        }
        if let originalImage = documentImage {
            let roratedImage = originalImage.rotate(radians: .pi/2)
            if capturedDocument?[getCurrentRow()].isFilterApplied == true {
                capturedDocument?[getCurrentRow()].filteredImage = roratedImage
            } else {
                capturedDocument?[getCurrentRow()].croppedImage = roratedImage
            }
        }
        documentCollectionView.reloadItems(at: [IndexPath(row: getCurrentRow(), section: 0)])

    }
    
    @IBAction func addimageButtontapped(_ sender: Any) {
        backButtonTapped(addImageButton)
    }
    
    @IBAction func reOrderButtonTapped(_ sender: Any) {
        
        let storyBoard : UIStoryboard = UIStoryboard(name: "DocumentCapture", bundle:bundle)
        
        if let vc = storyBoard.instantiateViewController(withIdentifier: "DocumentReorderViewController")  as? DocumentReorderViewController {
            vc.capturedDocument = capturedDocument
            vc.delegate = self
            self.navigationController?.pushViewController(vc, animated: true)
        }
        
    }
    
    private func randomFilenameGeneration() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        let timestampString = dateFormatter.string(from: Date())
        let temp = "\(timestampString)"
        
        return "SF\(temp.replacingOccurrences(of: "-", with: "").replacingOccurrences(of: ":", with: "").replacingOccurrences(of: " ", with: ""))"
    }

    
    private func saveDocument() {
        print("saveDocument")
        let fileManager = FileManager.default
        let documentsUrl = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        
        let docURL = documentsUrl.appendingPathComponent("Scanflow")
        
        do {
            try fileManager.createDirectory(at: docURL, withIntermediateDirectories: true, attributes: nil)
            
        } catch (let error) {
            documentDelegate?.failureOnCreatingPdf(error: error.localizedDescription)
            print("error is \(error.localizedDescription)")
        }
        
        let destination = docURL.appendingPathComponent(randomFilenameGeneration())
        
            do {
                 pdfDocument.write(to: destination)
               // try fileManager.createFile(atPath: destination, contents: pdfData)
                showLoadingIndicator(status: false)
                switch scaningFlow {
                    case .captureDocument:
                        navigationController?.popToRootViewController(animated: true)
                    case .capturedDocumentListWithCapture:
                        if let viewControllerToRemove = navigationController?.viewControllers.first(where: { $0 is DocumentHomeViewController }) {
                            // Pop the identified view controller from the navigation stack
                            navigationController?.popToViewController(viewControllerToRemove, animated: true)
                        }
                    case .capturedDocumentList:
                        break
                }
                
            } catch(let error) {
                print("error")
                showLoadingIndicator(status: false)
                showToast(message: error.localizedDescription, font: .boldSystemFont(ofSize: 13.0), width: (self.view.frame.width * 0.7), duration: .now() + 3, height: 70)
                print("error is \(error.localizedDescription)")
                documentDelegate?.failureOnCreatingPdf(error: error.localizedDescription)
            }
    
    }
    
    private func getCurrentRow() -> Int {
        let visibleRect = CGRect(origin: documentCollectionView.contentOffset, size: documentCollectionView.bounds.size)
        let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
        let visibleIndexPath = documentCollectionView.indexPathForItem(at: visiblePoint)
        return visibleIndexPath?.row ?? 0
    }
    
    @IBAction func backButtonTapped(_ sender: Any) {
        delegate?.updateDocuemnt(details: capturedDocument!)
        if multipleDocuemnt == true {
            self.navigationController?.popViewController(animated: true)
        } else {
            if let viewControllerToRemove = navigationController?.viewControllers.first(where: { $0 is DocumentScaningViewController }) {
                // Pop the identified view controller from the navigation stack
                navigationController?.popToViewController(viewControllerToRemove, animated: true)
            }
        }
    }
        
}

extension DocumentPreviewViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return capturedDocument?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let documentCell = collectionView.dequeueReusableCell(withReuseIdentifier: "DocumentPreviewCollectionViewCell", for: indexPath) as? DocumentPreviewCollectionViewCell {
            if let documentDetails = capturedDocument?[indexPath.row] {
                documentCell.updateDocument(image: SFDocumentHelper.shared.showImageFrom(document: documentDetails)!, count: "Page \(indexPath.row + 1 ) of \(capturedDocument?.count ?? 0)")
            }
            return documentCell
        }
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: (collectionView.frame.width ), height: (collectionView.frame.height ))
    }
    
}

extension DocumentPreviewViewController : cropViewControllerDelegate {
    
    func deleteButtonTapped() {
        
    }
    
    
    func updateDocuemnt(details: [DocumentDetails]) {
        capturedDocument = details
        documentCollectionView.reloadItems(at: [IndexPath(row: getCurrentRow(), section: 0)])
    }
    
}


extension DocumentPreviewViewController: DocumentReorderViewControllerDelegate {
    
    func reOrdered(document: [DocumentDetails]) {
        capturedDocument = document
        documentCollectionView.reloadData()
    }
    
}

extension UIImage {
    
    func scalePreservingAspectRatio(targetSize: CGSize) -> UIImage {
        // Determine the scale factor that preserves aspect ratio
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        
        let scaleFactor = min(widthRatio, heightRatio)
        
        // Compute the new image size that preserves aspect ratio
        let scaledImageSize = CGSize(
            width: size.width * scaleFactor,
            height: size.height * scaleFactor
        )
        
        // Draw and return the resized UIImage
        let renderer = UIGraphicsImageRenderer(
            size: scaledImageSize
        )
        
        let scaledImage = renderer.image { _ in
            self.draw(in: CGRect(
                origin: .zero,
                size: scaledImageSize
            ))
        }
        
        return scaledImage
    }
    
    func imageBlackAndWhite() -> UIImage? {
        let filter = CIFilter(name: "CIColorMonochrome")
        filter?.setValue(self.ciImage, forKey: "inputImage")
        
        // set a gray value for the tint color
        filter?.setValue(CIColor(red: 0.7, green: 0.7, blue: 0.7), forKey: "inputColor")
        
        filter?.setValue(1.0, forKey: "inputIntensity")
        guard let outputImage = filter?.outputImage else { return nil}
        
        let context = CIContext()
        filter?.outputImage?.applyingFilter("")
        if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
            let processedImage = UIImage(cgImage: cgimg)
            return processedImage
            print(processedImage.size)
        }
        return nil
    }
    
    func applyBlackAndWhiteFilter() -> UIImage? {
        guard let ciImage = CIImage(image: self) else {
            return nil
        }
        
        let filter = CIFilter(name: "CIColorControls")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(0.0, forKey: kCIInputSaturationKey)
        
        if let outputCIImage = filter?.outputImage,
            let outputCGImage = CIContext().createCGImage(outputCIImage, from: outputCIImage.extent) {
            let processedImage = UIImage(cgImage: outputCGImage)
            return processedImage
        } else {
            return nil
        }
    }
    
}

extension DocumentPreviewViewController: DocumentFilterViewControllerDelegate {
    
    func applyFilter(document: [DocumentDetails]) {
        capturedDocument = document
        documentCollectionView.reloadData()
    }
    
}


extension UIViewController {
    
    func showToast(message : String, font: UIFont, width: CGFloat = 150, duration: DispatchTime = .now() + 1, height: CGFloat = 35) {
        
        var toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width/2 - (width/2), y: self.view.frame.size.height-180, width: width, height: height))
        
        toastLabel.backgroundColor = UIColor.black
        toastLabel.textColor = UIColor.white
        toastLabel.font = font
        toastLabel.textAlignment = .center;
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.numberOfLines = 3
        
        toastLabel.layer.cornerRadius = 10;
        toastLabel.clipsToBounds  =  true
        self.view.addSubview(toastLabel)
        
        DispatchQueue.main.asyncAfter(deadline: duration) {
            toastLabel.removeFromSuperview()
        }

    }
    
}

extension CGSize {
    func aspectFit(within boundingSize: CGSize) -> CGSize {
        let aspectRatio = self.width / self.height
        let boundingAspectRatio = boundingSize.width / boundingSize.height
        
        var newSize = boundingSize
        if aspectRatio > boundingAspectRatio {
            newSize.height = boundingSize.width / aspectRatio
        } else {
            newSize.width = boundingSize.height * aspectRatio
        }
        
        return newSize
    }
}

extension UIImage {
    func resizeImageWith(newSize: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(newSize, true, 0)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: newSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
