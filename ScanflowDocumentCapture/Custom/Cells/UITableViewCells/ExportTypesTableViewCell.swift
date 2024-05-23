//
//  ExportTypesTableViewCell.swift
//  ScanflowDocumentCapture
//
//  Created by Mac-OBS-46 on 17/08/23.
//

import UIKit


protocol ExportTypesTableViewCellDelegate: AnyObject {
    func selectedExport(type: exportType)
}

class ExportTypesTableViewCell: UITableViewCell {

    @IBOutlet weak var pngButton: UIButton!
    @IBOutlet weak var jpegButton: UIButton!
    @IBOutlet weak var pdfButton: UIButton!

    weak var delegate: ExportTypesTableViewCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        pngButton.layer.borderColor = SFDocumentHelper.shared.appThemeColor.cgColor
        pngButton.layer.borderWidth = 1

        jpegButton.layer.borderColor = SFDocumentHelper.shared.appThemeColor.cgColor
        jpegButton.layer.borderWidth = 1

        pdfButton.layer.borderColor = SFDocumentHelper.shared.appThemeColor.cgColor
        pdfButton.layer.borderWidth = 1

        pdfButton.setTitleColor(SFDocumentHelper.shared.appThemeColor, for: .normal)
        jpegButton.setTitleColor(SFDocumentHelper.shared.appThemeColor, for: .normal)
        pngButton.setTitleColor(SFDocumentHelper.shared.appThemeColor, for: .normal)

        pdfButton.backgroundColor = SFDocumentHelper.shared.appThemeColor.withAlphaComponent(0.3)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func pdfButtonTapped(_ sender: Any) {
        delegate?.selectedExport(type: .pdf)
        pdfButton.backgroundColor = SFDocumentHelper.shared.appThemeColor.withAlphaComponent(0.3)
        jpegButton.backgroundColor = .white
        pngButton.backgroundColor = .white
    }

    @IBAction func jpegButtonTaped(_ sender: Any) {
        delegate?.selectedExport(type: .jpg)
        pdfButton.backgroundColor = .white
        jpegButton.backgroundColor = SFDocumentHelper.shared.appThemeColor.withAlphaComponent(0.3)
        pngButton.backgroundColor = .white
    }

    @IBAction func pngImageTapped(_ sender: Any) {
        delegate?.selectedExport(type: .png)
        pdfButton.backgroundColor = .white
        jpegButton.backgroundColor = .white
        pngButton.backgroundColor = SFDocumentHelper.shared.appThemeColor.withAlphaComponent(0.3)
    }


}
