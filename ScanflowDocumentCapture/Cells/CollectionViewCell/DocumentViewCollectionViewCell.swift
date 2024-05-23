//
//  DocumentViewCollectionViewCell.swift
//  ScanflowDocumentCapture
//
//  Created by Mac-OBS-46 on 01/08/23.
//

import UIKit

class DocumentViewCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var documentImage: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func updateCell(image: UIImage) {
        documentImage.image = image
    }

}
