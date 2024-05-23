//
//  ExportFormatsTableViewCell.swift
//  ScanflowDocumentCapture
//
//  Created by Mac-OBS-46 on 02/08/23.
//

import UIKit



class ExportFormatsTableViewCell: UITableViewCell {

    @IBOutlet weak var exportFormat: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func updateCell(title: String) {
        exportFormat.text = title
    }
}
