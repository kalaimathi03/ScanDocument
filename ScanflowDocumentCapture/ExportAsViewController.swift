//
//  ExportAsViewController.swift
//  ScanflowDocumentCapture
//
//  Created by Mac-OBS-46 on 02/08/23.
//

import UIKit
import CommonCrypto
import PDFKit
import VisionKit
import Vision
import CoreImage
import CoreText

enum exportFormats: String {
    case pdf = "PDF"
    case png = "PNG"
    case jpg = "JPG"
}



class ExportAsViewController: UIViewController {
    @IBOutlet weak var tableBackgroundView: UIView!

    @IBOutlet weak var cancelButtonView: UIView!
    @IBOutlet weak var exportFormatTableView: UITableView!

    @IBOutlet weak var smartTextView: UITextView!
    var isShareMode: Bool = true
    var currentImage: UIImage?
    private let exportFormat: [String] = ["PDF","PNG","JPG"]
    var curretDocuemnt: Documents?
    var documentImages:[UIImage]?
    var documentId: Int?
    private let activityIndicator = UIActivityIndicatorView(style: .gray)

    override func viewDidLoad() {
        super.viewDidLoad()
        if isShareMode == true {
            exportFormatTableView.delegate = self
            exportFormatTableView.dataSource = self

            tableBackgroundView.clipsToBounds = true
            tableBackgroundView.layer.masksToBounds = true

            tableBackgroundView.layer.cornerRadius = 10

            cancelButtonView.clipsToBounds = true
            cancelButtonView.layer.masksToBounds = true

            cancelButtonView.layer.cornerRadius = 5

            if let id = documentId {
                curretDocuemnt = CoreDataManager.shared.fetch(documentID: id)?.first
            }

            if let imageFilteData = curretDocuemnt?.fileData {
                let imagesData = decryptFile(key: AESconfig.key.rawValue, nonce: AESconfig.once.rawValue, data: imageFilteData)
                self.documentImages =  CoreDataManager.shared.imagesFromCoreData(object: imagesData) ?? []
            }
        } else {
            exportFormatTableView.isHidden = true
            showLoadingIndicator(status: true)
            if let image = currentImage {
                guard let cgImage = image.cgImage else {return}

                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

                if #available(iOS 13.0, *) {
                    let request = VNRecognizeTextRequest { request, error in
                        guard let observations = request.results as? [VNRecognizedTextObservation],
                              error == nil else {return}
                        let text = observations.compactMap({
                            $0.topCandidates(1).first?.string
                        })
                        let a = observations.compactMap( {$0.topCandidates(1).first?.string} )
                        for singleLine in text {
                            self.showLoadingIndicator(status: false)
                            self.smartTextView.text += singleLine + "\n" // text we get from image
                        }
                    }
                    request.recognitionLevel = .accurate
                    do {
                        try handler.perform([request])
                    } catch {

                    }
                } else {
                    guard let cgImage = image.cgImage else { return }

                    let ciImage = CIImage(cgImage: cgImage)


                    let context = CIContext(options: nil)
                    let textDetector = CIDetector(ofType: CIDetectorTypeText, context: context, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])

                    if let textFeatures = textDetector?.features(in: ciImage) as? [CITextFeature] {
                        for textFeature in textFeatures {
                            let detectedText = ""
                            print("Detected Text: \(detectedText)")
                        }
                    }

                }
            }
        }
    }

    @IBAction func cancelButtonTapped(_ sender: Any) {
        dismiss(animated: true)
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



}

extension ExportAsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
          exportFormat.count + 1

    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            if let formatsCell = tableView.dequeueReusableCell(withIdentifier: "ExportAsTitleTableViewCell", for: indexPath) as? ExportAsTitleTableViewCell {
                formatsCell.updateTitle(name: curretDocuemnt?.name ?? "")
                return formatsCell
            }
        } else  {
            if let formatsCell = tableView.dequeueReusableCell(withIdentifier: "ExportFormatsTableViewCell", for: indexPath) as? ExportFormatsTableViewCell {
                formatsCell.updateCell(title: exportFormat[indexPath.row - 1])
                return formatsCell
            }
        }
        return UITableViewCell()
    }


    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return exportFormatTableView.frame.height * 0.3
        } else {
            return exportFormatTableView.frame.height * 0.17
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

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        showLoadingIndicator(status: true)
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.row {
            case 1:
                
                let pdfDoc = PDFDocument()
                if let documentImages = documentImages {
                    for (index,image) in documentImages.enumerated() {
                        let page = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4, 72 dpi
                        let resized = resizeImage(image: image, targetSize: page.size) ?? UIImage()
                        if let pdfPage = PDFPage(image: resized) {
                            pdfPage.setBounds(page, for: .mediaBox)
                            pdfDoc.insert(pdfPage, at: index)
                        }
                    }
                }

                if let pdf = pdfDoc.dataRepresentation() {
                    let items = [pdf]
                    let ac = UIActivityViewController(activityItems: items, applicationActivities: nil)
                    ac.popoverPresentationController?.sourceView = tableView.cellForRow(at: indexPath)
                    present(ac, animated: true)
                }

            case 2://PNG
                if let images = documentImages {
                    let ac = UIActivityViewController(activityItems: images, applicationActivities: nil)
                    ac.popoverPresentationController?.sourceView = tableView.cellForRow(at: indexPath)
                    present(ac, animated: true)
                }
            case 3://JPG
                var jpegData: [Data] = []
                if let documentImages = documentImages {
                    for image in documentImages {
                        jpegData.append(image.jpegData(compressionQuality: 1.0)!)
                    }
                }

                    var activityItems: [UIImage] = []
                            for data in jpegData {
                                activityItems.append(UIImage(data: data)!)
                            }

                    let ac = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
                    ac.popoverPresentationController?.sourceView = tableView.cellForRow(at: indexPath)
                    present(ac, animated: true)

            case 4:
                break
            default:
                break
        }
        showLoadingIndicator(status: false)

    }
}
