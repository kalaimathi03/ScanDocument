//
//  SetPasswordTableViewCell.swift
//  ScanflowDocumentCapture
//
//  Created by Mac-OBS-46 on 18/08/23.
//

import UIKit

class SetPasswordTableViewCell: UITableViewCell {

    @IBOutlet weak var faviImage: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func update(img: UIImage?, title: String) {
        faviImage.image = img
        nameLabel.text = title
    }
}
