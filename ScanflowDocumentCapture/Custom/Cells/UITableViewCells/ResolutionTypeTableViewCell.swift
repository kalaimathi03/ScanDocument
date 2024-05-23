//
//  ResolutionTypeTableViewCell.swift
//  ScanflowDocumentCapture
//
//  Created by Mac-OBS-46 on 17/08/23.
//

import UIKit

class ResolutionTypeTableViewCell: UITableViewCell {

    @IBOutlet weak var resolutionType: UILabel!
    @IBOutlet weak var resolutionSize: UILabel!
    @IBOutlet weak var selectedIndicator: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()

    }

    func updateResolution(type: qualityCompression, size: String, isSelected:Bool = false) {
        switch type {
            case .actual:
                resolutionType.text = "Actual"
            case .large:
                resolutionType.text = "Large"
            case .medium:
                resolutionType.text = "Medium"
            case .small:
                resolutionType.text = "Small"

        }
        resolutionSize.text = size
        selectedIndicator.isHidden = !isSelected

    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)


    }

}
