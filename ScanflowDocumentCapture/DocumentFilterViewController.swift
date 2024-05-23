//
//  DocumentFilterViewController.swift
//  ScanflowDocumentCapture
//
//  Created by Mac-OBS-46 on 15/05/23.
//

import UIKit
import Vision
import VisionKit

protocol DocumentFilterViewControllerDelegate: AnyObject {
    func applyFilter(document: [DocumentDetails])
}

class DocumentFilterViewController: UIViewController {
    
    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var typesOfFilterTableVIew: UITableView!
    @IBOutlet weak var applChangesView: UIView!
    
    @IBOutlet weak var filterListBgView: UIView!
    @IBOutlet weak var doneButton: SFButton!
    @IBOutlet weak var applyChangesButton: UISwitch!
    let bundle = Bundle(identifier: "com.ScanflowDocumentCapture")
    
    let filters:[String] = ["Normal", "Black and White", "Auto"]
    var selectedIndexPath: Int = 0
    var currentDocuemntAddress: Int = 0
    var capturedDocuments:[DocumentDetails]?
    weak var delegate: DocumentFilterViewControllerDelegate?
    private var currenlyApplied: ImageFilters = .noFilter
    private let activityIndicator = UIActivityIndicatorView(style: .gray)

    override func viewDidLoad() {
        super.viewDidLoad()
       
        if capturedDocuments?[currentDocuemntAddress].isFilterApplied == true {
            switch capturedDocuments?[currentDocuemntAddress].appliedFilter {
            case .auto:
                selectedIndexPath = 2
            case .blackAndWhite:
                selectedIndexPath = 1
            case .noFilter:
                selectedIndexPath = 0
            case .none:
                selectedIndexPath = 0
            }
        } else {
            selectedIndexPath = 0
        }
        let temp = capturedDocuments?.filter({ $0.isFilterApplied == false})
        if temp?.isEmpty == true {
            applyChangesButton.isOn = true
        } else {
            applyChangesButton.isOn = false
        }
        doneButton.setTitle("Done", for: .normal)
        filterListBgView.backgroundColor = .clear
        filterListBgView.layer.masksToBounds = true
        filterListBgView.layer.cornerRadius = 10
        
        applChangesView.backgroundColor = .white
        applChangesView.layer.masksToBounds = true
        applChangesView.layer.cornerRadius = 10
        
        typesOfFilterTableVIew.backgroundColor = .white
        typesOfFilterTableVIew.backgroundView?.backgroundColor = .white
        previewImageView.image = SFDocumentHelper.shared.showImageFrom(document: capturedDocuments![currentDocuemntAddress], compressionQuality: 0.6)
        typesOfFilterTableVIew.separatorStyle = .singleLine
        //applychangesBgView.setCornerRadius(value: 10)
        typesOfFilterTableVIew.delegate = self
        typesOfFilterTableVIew.dataSource = self
        typesOfFilterTableVIew.register(UINib(nibName: "SelectFilterTableViewCell", bundle: bundle), forCellReuseIdentifier: "SelectFilterTableViewCell")
    }
    
    @IBAction func doneButtionTapped(_ sender: Any) {
        delegate?.applyFilter(document: capturedDocuments!)
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func applychangesButtonTapped(_ sender: UISwitch) {
        showLoadingIndicator(status: true)
        DispatchQueue.main.async {
            if let totalDocument: Int = self.capturedDocuments?.count {
                if sender.isOn {
                    for  i in 0..<(totalDocument) {
                        self.capturedDocuments?[i].isFilterApplied = true
                        self.capturedDocuments?[i].appliedFilter = self.currenlyApplied
                        if let currentImage = self.capturedDocuments?[i] {
                            switch self.currenlyApplied {
                            case .noFilter:
                                self.capturedDocuments?[i].filteredImage = currentImage.croppedImage
                            case .blackAndWhite:
                                self.capturedDocuments?[i].filteredImage = currentImage.croppedImage.applyBlackAndWhiteFilter()!
                            case .auto:
                                if let cropImage = self.capturedDocuments?[i].croppedImage {
                                    let page = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4, 72 dpi
                                    
                                    if let dataThings = cropImage.autoEnhancementApply().cgImage, let resizedData = self.resizeCGImage(image: dataThings, newSize: page.size) {
                                        let datass = UIImage(cgImage: resizedData)
                                        self.capturedDocuments?[i].filteredImage = datass
                                        
                                    }
                                    
                                }
                            }
                        }
                    }
                } else {
                    for  i in 0..<(totalDocument) {
                        self.capturedDocuments?[i].isFilterApplied = false
                        
                    }
                    
                }
            }
            
            switch self.currenlyApplied {
            case .noFilter:
                self.selectedIndexPath = 0
            case .blackAndWhite:
                self.selectedIndexPath = 1
            case .auto:
                self.selectedIndexPath = 2
            }
            self.previewImageView.image = SFDocumentHelper.shared.showImageFrom(document: self.capturedDocuments![self.currentDocuemntAddress], compressionQuality: 0.7)
            DispatchQueue.main.async {
                self.typesOfFilterTableVIew.reloadData()
            }
            self.showLoadingIndicator(status: false)
        }
    }
    
    @IBAction func backButtonTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    func convertToGrayScale(image: UIImage) -> UIImage {
        
        // Create image rectangle with current image width/height
        let imageRect:CGRect = CGRect(x:0, y:0, width:image.size.width, height: image.size.height)
        
        // Grayscale color space
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let width = image.size.width
        let height = image.size.height
        
        // Create bitmap content with current image size and grayscale colorspace
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
        
        // Draw image into current context, with specified rectangle
        // using previously defined context (with grayscale colorspace)
        let context = CGContext(data: nil, width: Int(width), height: Int(height), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)
        context?.draw(image.cgImage!, in: imageRect)
        let imageRef = context!.makeImage()
        
        // Create a new UIImage object
        let newImage = UIImage(cgImage: imageRef!)
        
        return newImage
    }
    
}


extension DocumentFilterViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filters.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let filterCell = tableView.dequeueReusableCell(withIdentifier: "SelectFilterTableViewCell", for: indexPath) as? SelectFilterTableViewCell {
            filterCell.update(title: filters[indexPath.row], isSelected: selectedIndexPath == indexPath.row)
            return filterCell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.row == 0 {
            self.currenlyApplied = .noFilter
        } else if indexPath.row == 1 {
            self.currenlyApplied = .blackAndWhite
        } else {
            self.currenlyApplied = .auto
        }
        if applyChangesButton.isOn {
                self.applychangesButtonTapped(self.applyChangesButton)
        } else {
            showLoadingIndicator(status: true)
            tableView.reloadData()
            
            DispatchQueue.global().async {
                self.selectedIndexPath = indexPath.row
                if indexPath.row == 0 {
                    self.currenlyApplied = .noFilter
                        self.capturedDocuments?[self.currentDocuemntAddress].isFilterApplied = false
                        self.capturedDocuments?[self.currentDocuemntAddress].appliedFilter = .noFilter
                        self.currenlyApplied = .noFilter
                        if let cropImage = self.capturedDocuments?[self.currentDocuemntAddress].croppedImage {
                            self.capturedDocuments?[self.currentDocuemntAddress].filteredImage = cropImage
                            DispatchQueue.main.async {
                                self.previewImageView.image = SFDocumentHelper.shared.showImageFrom(document: self.capturedDocuments![self.currentDocuemntAddress], compressionQuality: 0.6)
                            }
                            self.showLoadingIndicator(status: false)
                        }
                } else if indexPath.row == 1{
                    self.currenlyApplied = .auto
                        self.capturedDocuments?[self.currentDocuemntAddress].isFilterApplied = true
                        self.currenlyApplied = .blackAndWhite
                        self.capturedDocuments?[self.currentDocuemntAddress].appliedFilter = .blackAndWhite
                    
                        if let cropImage = self.capturedDocuments?[self.currentDocuemntAddress].croppedImage {
                            let page = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4, 72 dpi

                            if let dataThings = cropImage.applyBlackAndWhiteFilter()!.cgImage, let resizedData = self.resizeCGImage(image: dataThings, newSize: page.size) {
                                let datass = UIImage(cgImage: resizedData)
                                self.capturedDocuments?[self.currentDocuemntAddress].filteredImage = UIImage(cgImage: resizedData)
                                
                            }
                            
                            DispatchQueue.main.async {
                                self.previewImageView.image = SFDocumentHelper.shared.showImageFrom(document: self.capturedDocuments![self.currentDocuemntAddress], compressionQuality: 0.6)
                            }
                            self.showLoadingIndicator(status: false)
                        }
                } else {
                    self.currenlyApplied = .auto
                        self.capturedDocuments?[self.currentDocuemntAddress].isFilterApplied = true
                        self.currenlyApplied = .auto
                        self.capturedDocuments?[self.currentDocuemntAddress].appliedFilter = .auto
                        if let cropImage = self.capturedDocuments?[self.currentDocuemntAddress].croppedImage {
                            let page = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4, 72 dpi
                            
                            if let dataThings = cropImage.autoEnhancementApply().cgImage, let resizedData = self.resizeCGImage(image: dataThings, newSize: page.size) {
                                let datass = UIImage(cgImage: resizedData)
                                self.capturedDocuments?[self.currentDocuemntAddress].filteredImage = UIImage(cgImage: resizedData)
                            }
                            DispatchQueue.main.async {
                                self.previewImageView.image = SFDocumentHelper.shared.showImageFrom(document: self.capturedDocuments![self.currentDocuemntAddress], compressionQuality: 0.6)
                            }
                            self.showLoadingIndicator(status: false)
                        }
                }
            }
        }
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
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
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
    
}
