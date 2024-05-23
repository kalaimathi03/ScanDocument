//
//  PdfView.swift
//  ScanflowDocumentCapture
//
//  Created by Mac-OBS-46 on 11/05/23.
//

import Foundation
import PDFKit

class SFPDFView: PDFView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .white
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
