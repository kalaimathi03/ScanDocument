//
//  SelectFilterTableViewCell.swift
//  ScanflowDocumentCapture
//
//  Created by Mac-OBS-46 on 15/05/23.
//

import UIKit

class SelectFilterTableViewCell: UITableViewCell {

    @IBOutlet weak var filterLabel: UILabel!
    @IBOutlet weak var tickImageView: UIImageView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
    func update(title: String, isSelected: Bool) {
        filterLabel.text = title
        tickImageView.isHidden = !isSelected
    }
    
}
