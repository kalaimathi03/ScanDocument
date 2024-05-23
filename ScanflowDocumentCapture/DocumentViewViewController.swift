//
//  DocumentViewViewController.swift
//  ScanflowDocumentCapture
//
//  Created by Mac-OBS-46 on 01/08/23.
//

import UIKit
import ScanflowCore
import CommonCrypto
import PDFKit

class DocumentViewViewController: UIViewController {

    @IBOutlet weak var imageCollectionView: UICollectionView!
    @IBOutlet weak var fileName: UILabel!
    @IBOutlet weak var toolBarView: SFNavBarView!

    var camaraManager: ScanflowCameraManager?
    let bundle = Bundle(identifier: "com.ScanflowDocumentCapture")

    private var images: [UIImage] = []
    private var documents: [Documents] = []
    var documentId:Int?
    var pageTitle: String?
    var compressRatio:[CGFloat] = [1.0, 0.80, 0.50, 0.25]

    override func viewDidLoad() {
        super.viewDidLoad()
        toolBarView.backgroundColor = SFDocumentHelper.shared.appThemeColor
        imageCollectionView.delegate = self
        imageCollectionView.dataSource = self
        
        imageCollectionView.register(UINib(nibName: "DocumentPreviewCollectionViewCell", bundle: bundle), forCellWithReuseIdentifier: "DocumentPreviewCollectionViewCell")

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let docId = documentId {
            fetchDocuments(id: docId)
        }
    }
    @IBAction func deleteButtonTapped(_ sender: Any) {
        showDeleteConfirmationMessage()
    }

    @IBAction func editButtonTapped(_ sender: Any) {
        let storyBoard : UIStoryboard = UIStoryboard(name: "DocumentCapture", bundle:bundle)
        let nextViewController = storyBoard.instantiateViewController(withIdentifier: "EditDocuemntViewController") as! EditDocuemntViewController
        nextViewController.documentId = documentId
        nextViewController.modalPresentationStyle = .formSheet
        self.navigationController?.present(nextViewController, animated: true)
    }

    @IBAction func addImagesOnDocument(_ sender: Any) {
        newButtonTapped()
    }

    func newButtonTapped() {
        let storyBoard : UIStoryboard = UIStoryboard(name: "DocumentCapture", bundle:bundle)
        let nextViewController = storyBoard.instantiateViewController(withIdentifier: "DocumentScaningViewController") as! DocumentScaningViewController
        nextViewController.isEditMode = true
        nextViewController.docuemntId = documentId
        self.navigationController?.pushViewController(nextViewController, animated: true)
    }

    @IBAction func renameButtonTapped(_ sender: Any) {
        showFileRenameMessage()
    }

    @IBAction func scanTextButton(_ sender: Any) {
        let storyBoard : UIStoryboard = UIStoryboard(name: "DocumentCapture", bundle:bundle)
        let nextViewController = storyBoard.instantiateViewController(withIdentifier: "ExportAsViewController") as! ExportAsViewController
        nextViewController.curretDocuemnt = documents.first
        nextViewController.currentImage = getCurrentImage()
        nextViewController.isShareMode = false
        nextViewController.modalPresentationStyle = .overCurrentContext
        self.navigationController?.present(nextViewController, animated: true)
    }

    func shareButtonTapped() {
        let storyBoard : UIStoryboard = UIStoryboard(name: "DocumentCapture", bundle:bundle)
        let nextViewController = storyBoard.instantiateViewController(withIdentifier: "ExportAsViewController") as! ExportAsViewController
        nextViewController.curretDocuemnt = documents.first
        nextViewController.modalPresentationStyle = .overCurrentContext
        self.navigationController?.present(nextViewController, animated: true)
    }

    @IBAction func backButtonTapped(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }

    private func showDeleteConfirmationMessage() {
        let alertController = UIAlertController(title: "Delete", message: "Are you sure want to delete this folder?", preferredStyle: .alert)


        // Create actions for the alert controller
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

        let okayAction = UIAlertAction(title: "Delete", style: .default) { _ in
            CoreDataManager.shared.deleteDocument(id: Int(self.documents.first?.id ?? 0))
            self.navigationController?.popViewController(animated: true)
        }

        // Add actions to the alert controller
        alertController.addAction(cancelAction)
        alertController.addAction(okayAction)

        // Present the alert controller
        present(alertController, animated: true, completion: nil)
    }

    private func showFileRenameMessage() {
        let alertController = UIAlertController(title: "Rename", message: "Please enter a new name for the document", preferredStyle: .alert)

        // Add a text field to the alert controller
        alertController.addTextField { textField in
            textField.placeholder = "Enter New Name Here"
        }

        // Create actions for the alert controller
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

        let okayAction = UIAlertAction(title: "Rename", style: .default) { _ in
            if let textField = alertController.textFields?.first {
                if let enteredText = textField.text {
                    CoreDataManager.shared.updateDocuemnt(id: Int(self.documents.first?.id ?? 0), fileName: textField.text, pdfSize: nil, jpgSize: nil, pngSize: nil)
                    self.fileName.text = textField.text
                    self.dismiss(animated: true)

                }
            }
        }

        // Add actions to the alert controller
        alertController.addAction(cancelAction)
        alertController.addAction(okayAction)

        // Present the alert controller
        present(alertController, animated: true, completion: nil)

    }

    private func fetchDocuments(id: Int) {
        documents = CoreDataManager.shared.fetch(documentID: id) ?? []
        fileName.text = documents.first?.name ?? "File"
        for document in documents {
            if let imageFilteData = document.fileData {
//                let imagesData = decryptFile(key: AESconfig.key.rawValue, nonce: AESconfig.once.rawValue, data: imageFilteData)
                self.images =  CoreDataManager.shared.imagesFromCoreData(object: imageFilteData) ?? []

                imageCollectionView.reloadData()
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

    func getCurrentImage() -> UIImage {
        // Assuming collectionView is your UICollectionView instance
            let visibleRect = CGRect(origin: imageCollectionView.contentOffset, size: imageCollectionView.bounds.size)
            let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
            let visibleIndexPath = imageCollectionView.indexPathForItem(at: visiblePoint)
            return images[visibleIndexPath?.row ?? 0]

    }
}

extension DocumentViewViewController: UICollectionViewDelegate, UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        images.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let documentCell = collectionView.dequeueReusableCell(withReuseIdentifier: "DocumentPreviewCollectionViewCell", for: indexPath) as? DocumentPreviewCollectionViewCell {

            documentCell.updateDocument(image: images[indexPath.row], count:  "Page \(indexPath.row + 1 ) of \(images.count )")
            return documentCell
        }
        return UICollectionViewCell()

    }

    
}



extension DocumentViewViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: (collectionView.frame.width ), height: (collectionView.frame.height ))
    }
}


extension Data {
    init?(hexString: String) {
      let len = hexString.count / 2
      var data = Data(capacity: len)
      var startingIndex = hexString.startIndex
      for _ in 0..<len {
        let processingIndex = hexString.index(startingIndex, offsetBy: 2)
        let bytes = hexString[startingIndex..<processingIndex]
        if var num = UInt8(bytes, radix: 16) {
          data.append(&num, count: 1)
        } else {
          return nil
        }
        startingIndex = processingIndex
      }
      self = data
    }
    /// Hexadecimal string representation of `Data` object.
    var hexadecimal: String {
        return map { String(format: "%02x", $0) }
            .joined()
    }
}

