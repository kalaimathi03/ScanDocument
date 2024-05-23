//
//  EditDocuemntViewController.swift
//  ScanflowDocumentCapture
//
//  Created by Mac-OBS-46 on 16/08/23.
//

import UIKit
import CommonCrypto
import PDFKit

enum exportType {
    case pdf
    case jpg
    case png
}

enum qualityCompression {
    case actual
    case large
    case medium
    case small
}

class EditDocuemntViewController: UIViewController {

    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var exportOptionsTableView: UITableView!

    var documentId: Int?
    var sectionCount: Int = 3
    var passwordForPDF: String?
    private var selectedExportType: exportType = .pdf {
        didSet {

            selectedResolutionType()
        }
    }
    private var selectedResolution: qualityCompression = .actual
    private let exportOption: [String] = ["PDF","JPG","PNG"]
    private let exportResolution: [qualityCompression] = [.actual, .large, .medium, .small]
    private var size:[String] = []
    private let bundle = Bundle(identifier: "com.ScanflowDocumentCapture")
    private var fetchedImages: [UIImage]?
    private var fetchedDocuments: Documents?
    private var sizeOfDocument: [String] = []


    override func viewDidLoad() {
        super.viewDidLoad()
        fetchDocuments(id: documentId ?? 0)
        setDelegates()
        registerCell()
    }

    private func setDelegates() {
        exportOptionsTableView.delegate = self
        exportOptionsTableView.dataSource = self
    }

    private func registerCell() {
        exportOptionsTableView.register(UINib(nibName: "ExportTypesTableViewCell", bundle: bundle), forCellReuseIdentifier: "ExportTypesTableViewCell")
        exportOptionsTableView.register(UINib(nibName: "ResolutionTypeTableViewCell", bundle: bundle), forCellReuseIdentifier: "ResolutionTypeTableViewCell")
        //PDFPasswordTableViewCell
        exportOptionsTableView.register(UINib(nibName: "PDFPasswordTableViewCell", bundle: bundle), forCellReuseIdentifier: "PDFPasswordTableViewCell")

    }

    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        dismiss(animated: true)
    }

    @IBAction func doneButtonTapped(_ sender: Any) {
        var processingImage:[UIImage]?
        switch selectedResolution {
            case .actual:
                processingImage = fetchedImages
            case .large:
                processingImage = fetchedImages?.map({ compressedImage($0, compressionQuality: 0.80) })
            case .medium:
                processingImage = fetchedImages?.map({ compressedImage($0, compressionQuality: 0.50) })
            case .small:
                processingImage = fetchedImages?.map({ compressedImage($0, compressionQuality: 0.25) })
        }

        switch selectedExportType {
            case .pdf:

                if let pdfFiles = convertToPDF(images: processingImage) {
                    sharering(data: [pdfFiles])
                }
            case .jpg:
                if let jpgFiles = processingImage?.map( { $0.jpegData(compressionQuality: 1) } ) {
                    sharering(data: jpgFiles)
                }
                sharering(data: processingImage!)
            case .png:
                if let png = processingImage?.map( { $0.pngData()} ) {
                    sharering(data: png)
                }

        }
    }

    private func sharering(data: [Any]) {
        let activityVC = UIActivityViewController(activityItems: data, applicationActivities: nil)
        activityVC.popoverPresentationController?.sourceView = shareButton
        present(activityVC, animated: true)
    }

    private func selectedResolutionType() {
        if let fetchedDocuments = fetchedDocuments {
            sizeOfDocument.removeAll()
            var tempSize:[Double]?
            switch selectedExportType {
                case .pdf:
                    sizeOfDocument = fetchedDocuments.pdfSize!.components(separatedBy: ",")
                case .jpg:
                    sizeOfDocument = fetchedDocuments.jpgSize!.components(separatedBy: ",")
                case .png:
                    sizeOfDocument = fetchedDocuments.pngSize!.components(separatedBy: ",")
            }

            exportOptionsTableView.reloadData()
        }
    }

    private func compressedImage(_ originalImage: UIImage, compressionQuality: CGFloat = 1) -> UIImage {
        guard let imageData = originalImage.jpegData(compressionQuality: compressionQuality),
              let reloadedImage = UIImage(data: imageData) else {
            return originalImage
        }
        return   reloadedImage
    }

    private func fetchDocuments(id: Int) {
        size.removeAll()
       let documents = CoreDataManager.shared.fetch(documentID: id) ?? []
        fetchedDocuments = documents.first
        selectedResolutionType()
        for document in documents {
            if let imageFilteData = document.fileData {
                let imagesData = decryptFile(key: AESconfig.key.rawValue, nonce: AESconfig.once.rawValue, data: imageFilteData)
                self.fetchedImages =  CoreDataManager.shared.imagesFromCoreData(object: imagesData) ?? []
            }
        }
    }

    private func convertToPDF(images: [UIImage]?) -> Data? {
        let fileManager = FileManager.default
        let documentsUrl = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let docURL = documentsUrl.appendingPathComponent("sf")
        var pdfDoc = PDFDocument()

        do {
            try fileManager.createDirectory(at: docURL, withIntermediateDirectories: true, attributes: nil)

        } catch (let error) {
            print(error)
        }

        if let documentImages = images {
            for (index,image) in documentImages.enumerated() {
                let page = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4, 72 dpi
                let resized = resizeImage(image: image, targetSize: page.size) ?? UIImage()
                if let pdfPage = PDFPage(image: resized) {
                    pdfPage.setBounds(page, for: .mediaBox)
                    pdfDoc.insert(pdfPage, at: index)
                }
            }
        }
        let pdfURL = docURL.appendingPathComponent("name.pdf")
        if let password = passwordForPDF {
            let options: [PDFDocumentWriteOption: Any] = [
                .userPasswordOption: password, .ownerPasswordOption: password
            ]
            if pdfDoc.write(to: pdfURL, withOptions: options) {
                   print("Password protection applied.")
               } else {
                   print("Failed to apply password protection.")
               }
            guard let encryptedPDFDoc = PDFDocument(url: pdfURL) else {
                return nil
            }
            return try? Data(contentsOf: pdfURL)
        }


        return pdfDoc.dataRepresentation()

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


extension EditDocuemntViewController : UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        sectionCount
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else if section == 1{
            return exportResolution.count
        } else {
            return 1
        }

    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "ExportTypesTableViewCell", for: indexPath) as? ExportTypesTableViewCell {
                cell.delegate = self
                return cell
            }
        } else if indexPath.section == 1 {

            if let cell = tableView.dequeueReusableCell(withIdentifier: "ResolutionTypeTableViewCell", for: indexPath) as? ResolutionTypeTableViewCell {

                cell.updateResolution(type: exportResolution[indexPath.row], size: sizeOfDocument[indexPath.row],isSelected: selectedResolution == exportResolution[indexPath.row])
                return cell
            }

        } else {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "PDFPasswordTableViewCell", for: indexPath) as? PDFPasswordTableViewCell {
                cell.update(password: passwordForPDF ?? "Set Password")
                cell.delegate = self
                return cell
            }
        }
        return UITableViewCell()
    }



    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return self.view.frame.height * 0.15
        } else {
            return self.view.frame.height * 0.05
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Export As"
        } else if section == 1 {
            return "Resolution"
        } else  {
            return "Options"
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            switch indexPath.row {
                case 0:
                    selectedResolution = .actual
                case 1:
                    selectedResolution = .large
                case 2:
                    selectedResolution = .medium
                case 3:
                    selectedResolution = .small
                default:
                    selectedResolution = .actual
            }
            tableView.reloadData()
        }
    }

    private func calculateSize(sizeData: Int) {
        size.removeAll()
        var tempSize = (round(Float(sizeData) / 1024.0 ))

        if tempSize <= 1024 {
            size.append("\(tempSize) KB")
        } else {
            size.append("\(round(tempSize / 1024.0 )) MB")
        }

        //second data size
        tempSize = (round((Float(sizeData) / 1024.0 ) * 0.80))
        if tempSize <= 1024 {
            size.append("\(tempSize) KB")
        } else {
            size.append("\(round(tempSize / 1024.0 )) MB")
        }

        tempSize = (round((Float(sizeData) / 1024.0 ) * 0.50))
        if tempSize <= 1024 {
            size.append("\(tempSize) KB")
        } else {
            size.append("\(round(tempSize / 1024.0 )) MB")
        }

        tempSize = (round((Float(sizeData) / 1024.0 ) * 0.25))
        if tempSize <= 1024 {
            size.append("\(tempSize) KB")
        } else {
            size.append("\(round(tempSize / 1024.0 )) MB")
        }

    }
}

extension EditDocuemntViewController: ExportTypesTableViewCellDelegate {
    func selectedExport(type: exportType) {
        switch type {
            case .pdf:
                sectionCount = 3
                selectedExportType = .pdf
            case .jpg:
                sectionCount = 2
                passwordForPDF = nil
                selectedExportType = .jpg
            case .png:
                sectionCount = 2
                passwordForPDF = nil
                selectedExportType = .png
        }

    }

}

extension EditDocuemntViewController: PDFPasswordTableViewCellDelegate {

    func clearPassword() {

        let alertController = UIAlertController(title: "Remove Encryption", message: "Are you sure you want remove pdf encryption?", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "No", style: .cancel) { (_) in
            print("Cancelled")
        }

        let okAction = UIAlertAction(title: "Yes", style: .default) { (_) in
            self.passwordForPDF = nil
            self.exportOptionsTableView.reloadData()
        }

        alertController.addAction(cancelAction)
        alertController.addAction(okAction)

        // Present the alert controller
        self.present(alertController, animated: true, completion: nil)
    }

    func setPassword() {
        let alertController = UIAlertController(title: "Enter Password", message: "Please enter Password", preferredStyle: .alert)

        // Add a text field to the alert controller
        alertController.addTextField { (textField) in
            textField.placeholder = "Password"
        }

        // Create and add actions
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
            print("Cancelled")
        }

        let okAction = UIAlertAction(title: "Set", style: .default) { [weak alertController] (_) in
            guard let textField = alertController?.textFields?[0] else {
                return
            }

            if let text = textField.text {
                if text.isEmpty == false {
                    self.passwordForPDF = text
                } else {
                    self.passwordForPDF = nil
                }
            }
            self.exportOptionsTableView.reloadData()
        }

        alertController.addAction(cancelAction)
        alertController.addAction(okAction)

        // Present the alert controller
        self.present(alertController, animated: true, completion: nil)
    }

}
