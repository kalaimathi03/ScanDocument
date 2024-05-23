//
//  HomeViewController.swift
//  ScanflowDocumentCapture
//
//  Created by Mac-OBS-46 on 11/05/23.
//

import UIKit
import PDFKit
import Vision
import AVFoundation
import ScanflowCore

public enum ImageFilters {
    
    case noFilter
    case blackAndWhite
    case auto
    
}

public enum DocumentScaningFlow {

    case capturedDocumentList
    case capturedDocumentListWithCapture
    case captureDocument
    
}



public struct DocumentDetails {
    public var originalImage: UIImage
    public var croppedImage: UIImage
    public var boundingRect: Rectangle?
    public var appliedFilter: ImageFilters
    public var isFilterApplied: Bool
    public var filteredImage: UIImage
    
    public init(originalImage: UIImage, croppedImage: UIImage, boundingRect: Rectangle?, appliedFilter: ImageFilters, isFilterApplied:Bool, filteredImage: UIImage) {
        self.originalImage = originalImage
        self.croppedImage = croppedImage
        self.boundingRect = boundingRect
        self.appliedFilter = appliedFilter
        self.isFilterApplied = isFilterApplied
        self.filteredImage = filteredImage
    }
    
}

public class DocumentHomeViewController: UIViewController {
    
    @IBOutlet var navBar: SFNavBarView!
    @IBOutlet weak var cameraButton: CircleButton!
    
    @IBOutlet weak var documentTableView: UITableView!
    
    @IBOutlet weak var applyButton: SFButton!
    @IBOutlet var bottomView: SFNavBarView!
    @IBOutlet weak var noFilesImageView: UIImageView!
    @IBOutlet weak var getInTouchButton: SFButton!
    
    let bundle = Bundle(identifier: "com.ScanflowDocumentCapture")
    var appPath: URL?

    var selectedImages: [URL]?
    var popoverController: UIPopoverPresentationController?
    var currentSeletedIndexpath: Int = 0
    var selectedcellButtion:SFButton?
    var authKey: String = ""
    let fileManager = FileManager.default
    public weak var delegate: DocumentScaningDelegate?
    private var pdfFiles: [Documents] = []

    var cameraManager: ScanflowCameraManager?

    public override func viewDidLoad() {
        super.viewDidLoad()
        noFilesImageView.tintColor = SFDocumentHelper.shared.appThemeColor
        navBar.updateBackgroundColor()
        getInTouchButton.setTitle("GET IN TOUCH", for: .normal)
        getInTouchButton.setTitleColor(.white, for: .normal)
        
        applyButton.setTitle("ABOUT", for: .normal)
        applyButton.setTitleColor(.white, for: .normal)
        
        tableViewConfig()
        hideKeyboardWhenTappedAround()
        //searchBgView
        cameraButton.setRoundButton()
        
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        
        view.addGestureRecognizer(tap)
        
    }
    
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchPdfFiles()
    }
    
    //Calls this function when the tap is recognized.
    @objc override func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
        dismiss(animated: true)
    }
    
    private func tableViewConfig() {
        //register nib
        documentTableView.register(UINib(nibName: "DocumentListTableViewCell", bundle: bundle), forCellReuseIdentifier: "DocumentListTableViewCell")
        
        //configure delegates
        documentTableView.delegate = self
        documentTableView.dataSource = self
    }
    
    open func showDocumentScaning(themeColor: UIColor = .appThemeColor, docuemntFlow: DocumentScaningFlow) -> UIViewController? {
        switch docuemntFlow {
            
            case .capturedDocumentListWithCapture:
                SFDocumentHelper.shared.appThemeColor = themeColor
                let bundle = Bundle(identifier: "com.ScanflowDocumentCapture")
                let storyBoard : UIStoryboard = UIStoryboard(name: "DocumentCapture", bundle:bundle)
                let nextViewController = storyBoard.instantiateViewController(withIdentifier: "DocumentHomeViewController") as! DocumentHomeViewController
                return nextViewController
            case .captureDocument:
                SFDocumentHelper.shared.appThemeColor = themeColor
                let bundle = Bundle(identifier: "com.ScanflowDocumentCapture")
                let storyBoard : UIStoryboard = UIStoryboard(name: "DocumentCapture", bundle:bundle)
                let nextViewController = storyBoard.instantiateViewController(withIdentifier: "DocumentScaningViewController") as! DocumentScaningViewController
                nextViewController.scaningFlow = .captureDocument
                nextViewController.authKey = authKey
                return nextViewController
            case .capturedDocumentList:
                let documentsUrl = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!

                let docURL = documentsUrl.appendingPathComponent("Scanflow")
                appPath = docURL
                do {
                    try FileManager.default.createDirectory(at: docURL, withIntermediateDirectories: false, attributes: nil)
                } catch (let error) {
                    print("error is \(error.localizedDescription)")
                }
                var files: [URL] = []
                do {
                    files = try fileManager.contentsOfDirectory(at: docURL, includingPropertiesForKeys: nil)

                } catch {
                    print("error is \(error.localizedDescription)")

                }
                #warning("have to check below delegate")
//                pdfFilesName = files.map({ return $0.lastPathComponent})
//                delegate?.captutredDocuemnt(list: pdfFiles ?? [])
                return nil
        }
        
    }
    
    @IBAction func aboutButtonTapped(_ sender: Any) {
        if let url = URL(string: "https://www.scanflow.ai/about/") {
            UIApplication.shared.open(url)
        }
    }
    
    @IBAction func getInTouchButtonTappeed(_ sender: Any) {
        if let url = URL(string: "https://www.scanflow.ai/get-in-touch/") {
            UIApplication.shared.open(url)
        }
    }
    
    @IBAction func cameraButtonTapped(_ sender: Any) {
        let storyBoard : UIStoryboard = UIStoryboard(name: "DocumentCapture", bundle:bundle)
        let nextViewController = storyBoard.instantiateViewController(withIdentifier: "DocumentScaningViewController") as! DocumentScaningViewController
        self.navigationController?.pushViewController(nextViewController, animated: true)
    }
    
    @IBAction func backButtonTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    private func fetchPdfFiles() {
        if let fetchedDocuemnt = CoreDataManager.shared.fetch() {
            pdfFiles = fetchedDocuemnt.sorted(by: { $0.createdAt! > $1.createdAt!})
            if pdfFiles.count == 0 {
                documentTableView.isHidden = true
            } else {
                documentTableView.isHidden = false
            }
            documentTableView.reloadData()
        } else {
            documentTableView.isHidden = true
        }
    }

    private func dispalyDateFormat(createDate: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy - hh:mm a"
        let formattedDate = dateFormatter.string(from: createDate)
        return formattedDate
    }

    private func deleteFile(at path: String) {
        
        do {
            try fileManager.removeItem(atPath: path)
            print("File deleted successfully.")
            documentTableView.reloadData()
        } catch {
            print("Error deleting file: \(error)")
        }
    }    
    
}


extension DocumentHomeViewController: UITableViewDelegate, UITableViewDataSource {
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return pdfFiles.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let docuemntCell = tableView.dequeueReusableCell(withIdentifier: "DocumentListTableViewCell", for: indexPath) as? DocumentListTableViewCell {
            if let name = pdfFiles[indexPath.row].name, let date = pdfFiles[indexPath.row].createdAt {
                docuemntCell.updateFile(name: name, createdAt: dispalyDateFormat(createDate: date))
                docuemntCell.currentIndexPath = indexPath
                docuemntCell.delegate = self
                return docuemntCell
            }
        }
        return UITableViewCell()
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("selected index\(indexPath.row)")
    }
}


extension DocumentHomeViewController: DocumentListTableViewCellDelegate {

    
    func shareButtonTapped(indexPath: IndexPath, sender: SFButton) {
        selectedcellButtion = sender

        let storyBoard : UIStoryboard = UIStoryboard(name: "DocumentCapture", bundle:bundle)
        let nextViewController = storyBoard.instantiateViewController(withIdentifier: "EditDocuemntViewController") as! EditDocuemntViewController
        nextViewController.documentId = Int(pdfFiles[indexPath.row].id)
        nextViewController.modalPresentationStyle = .formSheet
        self.navigationController?.present(nextViewController, animated: true)
    }
        func moreOptionsButtonTapped(indexPath: IndexPath, sender: SFButton) {
            selectedcellButtion = sender
            let storyBoard : UIStoryboard = UIStoryboard(name: "DocumentCapture", bundle:bundle)

            currentSeletedIndexpath = Int(pdfFiles[indexPath.row].id)
            if let contentVC = storyBoard.instantiateViewController(withIdentifier: "PopoverViewController")  as? PopoverViewController  {
                contentVC.modalPresentationStyle = .popover
                contentVC.preferredContentSize = CGSize(width: 80, height: 50)
                contentVC.delegate = self
                popoverController = contentVC.popoverPresentationController
                popoverController?.permittedArrowDirections = .any
                popoverController?.delegate = self
                popoverController?.sourceView = sender as? UIButton

                present(contentVC, animated: true)
            }
        }

        func cellTapped(indexpath: IndexPath) {

            let storyBoard : UIStoryboard = UIStoryboard(name: "DocumentCapture", bundle:bundle)

            if let vc = storyBoard.instantiateViewController(withIdentifier: "DocumentViewViewController")  as? DocumentViewViewController {
                vc.camaraManager = cameraManager
                vc.pageTitle = pdfFiles[indexpath.row].name
                vc.documentId = Int(pdfFiles[indexpath.row].id)
                self.navigationController?.pushViewController(vc, animated: true)
            }

        }


}

extension DocumentHomeViewController: UIPopoverPresentationControllerDelegate {
    
    public func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }

}


extension DocumentHomeViewController : PopoverViewControllerDelegate {
    
    func deleteButtonTapped() {
        dismiss(animated: true)
        let alertController = UIAlertController(title: "Delete", message: "Are you sure you want delete this?", preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "NO", style: .default) { (_) in
            //do nothing
            
        }
        alertController.addAction(okAction)
        
        let cancelAction = UIAlertAction(title: "YES", style: .cancel) { (_) in
            CoreDataManager.shared.deleteDocument(id: self.currentSeletedIndexpath)
            self.fetchPdfFiles()
            
        }
        alertController.addAction(cancelAction)
        
        // Add additional actions if needed
        
        // Present the alert controller
        if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
            rootViewController.present(alertController, animated: true, completion: nil)
        }
        
    }
    
}


