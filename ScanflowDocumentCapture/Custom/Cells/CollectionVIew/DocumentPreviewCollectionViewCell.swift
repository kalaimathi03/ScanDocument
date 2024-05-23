//
//  DocumentPreviewCollectionViewCell.swift
//  ScanflowDocumentCapture
//
//  Created by Mac-OBS-46 on 12/05/23.
//

import UIKit
import CoreImage

class DocumentPreviewCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var documentImageView: UIImageView!
    @IBOutlet weak var countLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        documentImageView.contentMode = .scaleAspectFit
        // Initialization code
    }

    func updateDocument(image: UIImage, count: String) {
        documentImageView.image = image
        countLabel.text = count
    }

}
