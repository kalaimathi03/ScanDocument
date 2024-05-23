//
//  PdfViewViewController.swift
//  ScanflowDocumentCapture
//
//  Created by Mac-OBS-46 on 11/05/23.
//

import UIKit
import PDFKit

class PdfViewViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var presentationView: UIView!
    
    @IBOutlet weak var backButton: SFButton!
    
    var pdfViewloader: SFPDFView?
    var pdfData: PDFDocument?
    var pdfTitle: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        presentationView.backgroundColor = .white
        pdfViewloader = SFPDFView(frame: CGRect(origin: .zero, size: CGSize(width: presentationView.frame.width, height: presentationView.frame.height)))
        titleLabel.text = pdfTitle ?? ""
        loadPdf()
        // Do any additional setup after loading the view.
    }

    
    @IBAction func backButtonTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    


    private func loadPdf() {
        pdfViewloader!.translatesAutoresizingMaskIntoConstraints = false
        
        pdfViewloader!.autoScales = true
        pdfViewloader!.displayMode = .singlePageContinuous
        
        if let data = pdfData {
            pdfViewloader!.document = data
        }
        pdfViewloader?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        presentationView.addSubview(pdfViewloader!)
    }
}


