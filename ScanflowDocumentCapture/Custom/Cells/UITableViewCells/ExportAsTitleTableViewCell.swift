//
//  ExportAsTitleTableViewCell.swift
//  ScanflowDocumentCapture
//
//  Created by Mac-OBS-46 on 02/08/23.
//

import UIKit

class ExportAsTitleTableViewCell: UITableViewCell {

    @IBOutlet weak var fileNameTitle: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func updateTitle(name:String) {
        fileNameTitle.text = "Share \(name) as"
    }

}
