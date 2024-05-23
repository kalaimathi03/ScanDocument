//
//  DocumentScaningViewController.swift
//  ScanflowDocumentCapture
//
//  Created by Mac-OBS-46 on 11/05/23.
//

import UIKit
import ScanflowCore
import Vision
import AVFoundation
import CoreMotion
import CoreImage


public protocol DocumentScaningDelegate: AnyObject {
    
    func capturedImage(data: Data, text: NSAttributedString)
    func failureOnCreatingPdf(error: String)
    func captutredDocuemnt(list: [String])

}

class DocumentScaningViewController: UIViewController {

    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var flashButton: SFButton!
    @IBOutlet weak var countlabelBgView: UIView!
    
    @IBOutlet weak var cancelButton: SFButton!
    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var flashImageView: UIImageView!
    @IBOutlet weak var mulipleImageView: UIImageView!
    @IBOutlet weak var multipleButton: SFButton!
    @IBOutlet weak var multipleImagesButton: SFButton!
    @IBOutlet weak var selectedimageView: UIImageView!
    
    @IBOutlet weak var selecletedImagePreviewView: UIView!
    private var displayedRectangleResult: RectangleDetectorResult?
    var authKey: String = ""
    let bundle = Bundle(identifier: "com.ScanflowDocumentCapture")
    private var prepOverlayView: UIView!
    var isEditMode:Bool = false
    var docuemntId: Int?

    private var refBounding: CGRect = .zero
    var scaningFlow: DocumentScaningFlow = .capturedDocumentListWithCapture
    public weak var delegate: DocumentScaningDelegate?
    
    var multipleSelected: Bool = true {
        didSet {
            if multipleSelected == true {
                mulipleImageView.tintColor = .appThemeColor
            } else {
                mulipleImageView.tintColor = .lightGray
            }
        }
    }
    
    var currentImage: UIImage?
    var selectedImage: [UIImage] = []
    let detectRectanglesRequest = VNDetectRectanglesRequest()
    var previewWidth: Double?
    var previewheight: Double?
    var imageWidth: Double?
    var imageHeight: Double?
    var startCapture:Bool = false
    var boundView: UIView?
    var widthRatio: CGFloat = 0
    var heightRatio: CGFloat = 0
    private var previousRect: Rectangle?
    
    var capturedImages: [DocumentDetails] = []
    private var cameraManager: ScanflowCameraManager?
    private var isDetecting = true
    
    /// The number of times no rectangles have been found in a row.
    private var noRectangleCount = 0
    
    /// The minimum number of time required by `noRectangleCount` to validate that no rectangles have been found.
    private let noRectangleThreshold = 10
    private let rectangleFunnel = RectangleFeaturesFunnel()

    var isFlashOn: Bool = false {
        didSet {
            if isFlashOn == true {
                flashImageView.tintColor = .appThemeColor
            } else {
                flashImageView.tintColor = .lightGray
            }
        }
    }
    
    deinit {
        
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cameraManager?.stopSession()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
            cameraManager?.startSession()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()

        let frameData = CGRect(x: 0, y: 0, width: cameraView.frame.width, height: cameraView.frame.height)
        cameraView.frame = frameData
        cameraManager = ScanflowCameraManager(previewView: cameraView, scannerMode: .docuementScaning, overlayApperance: .hide, overCropNeed: false)
        cameraManager?.toBeSendInDelegate = false
        cameraManager?.captureDelegate = self
        cameraManager?.validateLicense(authKey: authKey, productType: .textCapture)
        widthRatio = 1080.0 / cameraView.frame.width
        heightRatio = 1920.0 / cameraView.frame.height
//        delegate = self
        updatePreviewImageView()
        cancelButton.setTitle("Cancel", for: .normal)
        mulipleImageView.tintColor = .appThemeColor
        cancelButton.setTitleColor(.white, for: .normal)
        countlabelBgView.layer.masksToBounds = true
        countlabelBgView.layer.cornerRadius =  (countlabelBgView.frame.width / 2)
        
        previewWidth = cameraView.frame.width
        previewheight = cameraView.frame.height
        
        detectRectanglesRequest.minimumAspectRatio = VNAspectRatio(0.2)
        detectRectanglesRequest.maximumAspectRatio = VNAspectRatio(0.8)
        detectRectanglesRequest.minimumSize = Float(0.4)
        detectRectanglesRequest.maximumObservations = 1
        detectRectanglesRequest.minimumConfidence = 0.8
        

        boundView?.backgroundColor = .black
        
        selectedimageView.layer.cornerRadius = 5
        selectedimageView.layer.masksToBounds = true
        selectedimageView.contentMode = .scaleToFill
        cameraManager?.updateWaterMarkLabel()
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isFlashOn == true {
            flashButtonTapped(flashButton)
        }
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        previewWidth = cameraView.frame.width
        previewheight = cameraView.frame.height
    }
    
    @IBAction func flashButtonTapped(_ sender: SFButton) {
        
        isFlashOn = !isFlashOn
        DispatchQueue.main.async {
            self.cameraManager?.flashLight(enable: self.isFlashOn)

        }
        
    }
    
    @IBAction func multipleButtonTapped(_ sender: Any) {
        multipleSelected = !multipleSelected
    }
    
    @IBAction func cancelButttonTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func imagesTapped(_ sender: Any) {
        let storyBoard : UIStoryboard = UIStoryboard(name: "DocumentCapture", bundle:bundle)
        
        if let vc = storyBoard.instantiateViewController(withIdentifier: "DocumentPreviewViewController")  as? DocumentPreviewViewController {
            vc.capturedDocument = capturedImages
            vc.cameraManager = cameraManager
            vc.isEditeFlow = isEditMode
            vc.docuemntId = docuemntId
            vc.scaningFlow = scaningFlow
            vc.documentDelegate = self
            vc.delegate = self
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @IBAction func captureButtonTapped(_ sender: Any) {
        startCapture = true
    }
    
    
    private func calculateRect(observation: VNRectangleObservation, referenceViewWidth: Double, referenceViewHeight: Double) {
        
        let transformImage = CGAffineTransform.identity
            .scaledBy(x: 1, y: -1)
            .translatedBy(x: 0, y: -referenceViewHeight)
            .scaledBy(x: referenceViewWidth, y: referenceViewHeight)
        
        let bottomLeft = observation.bottomLeft.applying(transformImage)
        let topLeft = observation.topLeft.applying(transformImage)
        let bottomRight = observation.topRight.applying(transformImage)
        let topRight = observation.bottomRight.applying(transformImage)
        
        DispatchQueue.main.async {
            self.cameraManager?.drawPath(boundRect: [topLeft, bottomRight, topRight, bottomLeft])
        }
        
    }
    
    private func updatePreviewImageView() {
        selecletedImagePreviewView.isHidden = capturedImages.isEmpty
    }
    
}



extension DocumentScaningViewController : CaptureDelegate {
    
    func scale(rect: CGRect, to imageSize: CGSize) -> CGRect {
        let scaleX = imageSize.width
        let scaleY = imageSize.height
        
        // Scale the coordinates of the rectangle
        let origin = CGPoint(x: rect.origin.x * scaleX, y: rect.origin.y * scaleY)
        let size = CGSize(width: rect.size.width * scaleX, height: rect.size.height * scaleY)
        
        return CGRect(origin: origin, size: size)
    }
    
    
    public func readData(originalframe: CVPixelBuffer, croppedFrame: CVPixelBuffer) {
        let imageSize = CGSize(width: CVPixelBufferGetWidth(originalframe), height: CVPixelBufferGetHeight(originalframe))

        let finalImage = CIImage(cvPixelBuffer: originalframe)
        CIRectangleDetector.rectangle(forImage: finalImage) { (rectangle) in
            self.processRectangle(rectangle: rectangle, imageSize: imageSize, image: originalframe.toImage())
        }
        
    }
    
    private func processRectangle(rectangle: Rectangle?, imageSize: CGSize, image: UIImage) {
        
        let path = UIBezierPath()

        if let rectangle = rectangle {
            
            self.noRectangleCount = 0
            self.rectangleFunnel.add(rectangle, currentlyDisplayedRectangle: self.displayedRectangleResult?.rectangle) {  (result, rectangle) in

                //let shouldAutoScan = (result == .showAndAutoScan)
                let data = displayRectangleResult(rectangleResult: RectangleDetectorResult(rectangle: rectangle, imageSize: imageSize))
                self.previousRect = data

                let leftTop = CGPoint(x: (data.topLeft.x / widthRatio), y: (data.topLeft.y / heightRatio))
                let rightTop = CGPoint(x: (data.topRight.x / widthRatio), y: (data.topRight.y / heightRatio))
                let bottomRight = CGPoint(x: (data.bottomRight.x / widthRatio), y: (data.bottomRight.y / heightRatio))
                let bottomLeft = CGPoint(x: (data.bottomLeft.x / widthRatio), y: (data.bottomLeft.y / heightRatio))
                DispatchQueue.main.async {
                    self.cameraManager?.drawPath(boundRect: [leftTop, rightTop, bottomRight, bottomLeft])
                }
                if startCapture == true {
                    startCapture = false
                    let orifi = image
                    DispatchQueue.main.async {
                        let croppedImage = orifi.imageByApplyingClippingBezierPath(data.path, tempView: UIView())
                        self.capturedImages.append(DocumentDetails(originalImage: image, croppedImage: croppedImage!, boundingRect: data, appliedFilter: .noFilter, isFilterApplied: false, filteredImage: croppedImage!))
                        self.countLabel.text = "\(self.capturedImages.count)"
                        let storyBoard : UIStoryboard = UIStoryboard(name: "DocumentCapture", bundle: self.bundle)
                        if let vc = storyBoard.instantiateViewController(withIdentifier: "CropViewViewController")  as? CropViewViewController {
                            vc.isFromScanningScreen = true
                            vc.multipleSelected = self.multipleSelected
                            vc.documentDetails = self.capturedImages
                            vc.currentDocuemnt = self.capturedImages.count - 1
                            vc.delegate = self
                            self.navigationController?.pushViewController(vc, animated: true)
                        }
                    }
                }
            }
        } else {
            if startCapture == true {
                startCapture = false
                let originalImage = image
                DispatchQueue.main.async {
                    self.capturedImages.append(DocumentDetails(originalImage: originalImage, croppedImage: originalImage, boundingRect: self.previousRect, appliedFilter: .noFilter, isFilterApplied: false, filteredImage: originalImage))
                    self.countLabel.text = "\(self.capturedImages.count)"
                    let storyBoard : UIStoryboard = UIStoryboard(name: "DocumentCapture", bundle: self.bundle)
                    if let vc = storyBoard.instantiateViewController(withIdentifier: "CropViewViewController")  as? CropViewViewController {
                        vc.isFromScanningScreen = true
                        vc.multipleSelected = self.multipleSelected
                        vc.documentDetails = self.capturedImages
                        vc.currentDocuemnt = self.capturedImages.count - 1
                        vc.delegate = self
                        self.navigationController?.pushViewController(vc, animated: true)
                    }
                }

            }
            DispatchQueue.main.async { [weak self] in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.noRectangleCount += 1
                
                if strongSelf.noRectangleCount > strongSelf.noRectangleThreshold {
                    // Reset the currentAutoScanPassCount, so the threshold is restarted the next time a rectangle is found
                    self?.cameraManager?.drawPath(boundRect: [])

                }
            }
            return
            
        }
    }
    
    @discardableResult private func displayRectangleResult(rectangleResult: RectangleDetectorResult) -> Rectangle {
        displayedRectangleResult = rectangleResult
        
        let rect = rectangleResult.rectangle.toCartesian(withHeight: rectangleResult.imageSize.height)
        
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else {
                return
            }
            
        }
        
        return rect
    }
    
}


extension DocumentScaningViewController: DocumentPreviewViewControllerDelegate {
    
    func deleteButtonTapped() {
        capturedImages = []
        self.selectedimageView.image = nil
        self.countLabel.text = "0"
        updatePreviewImageView()
        
    }
    
}



class OverlayView: UIView {
    
    
    override func draw(_ rect: CGRect) {
        // Call super implementation first
        super.draw(rect)
        
        // Get the current graphics context
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        
        // Set the overlay properties (e.g., color, line width)
        context.setFillColor(UIColor.red.withAlphaComponent(0.5).cgColor)
        context.setStrokeColor(UIColor.blue.cgColor)
        context.setLineWidth(2.0)
        
        
        
        // Draw the rectangle overlay
        context.addRect(rect)
        context.drawPath(using: .fillStroke)
    }
}

extension DocumentScaningViewController : cropViewControllerDelegate {
    
    func updateDocuemnt(details: [DocumentDetails]) {
        capturedImages = details
        if details.isEmpty {
            deleteButtonTapped()
        } else {
            selectedimageView.image = SFDocumentHelper.shared.showImageFrom(document: details.last!, compressionQuality: 0.8)
            self.countLabel.text = "\(self.capturedImages.count)"
            updatePreviewImageView()
        }
    }

}



private struct RectangleDetectorResult {
    
    /// The detected rectangle.
    let rectangle: Rectangle
    
    /// The size of the image the rectangle was detected on.
    let imageSize: CGSize
    
}


extension DocumentScaningViewController: DocumentScaningDelegate {

    func capturedImage(data: Data, text: NSAttributedString) {
        delegate?.capturedImage(data: data, text: text)
    }

    func failureOnCreatingPdf(error: String) {
        delegate?.failureOnCreatingPdf(error: error)
    }

    func captutredDocuemnt(list: [String]) {
        delegate?.captutredDocuemnt(list: list)
    }

}
