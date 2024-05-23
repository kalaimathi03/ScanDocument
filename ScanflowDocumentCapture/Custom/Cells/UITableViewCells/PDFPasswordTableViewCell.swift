//
//  PDFPasswordTableViewCell.swift
//  ScanflowDocumentCapture
//
//  Created by Mac-OBS-46 on 24/08/23.
//

import UIKit

protocol PDFPasswordTableViewCellDelegate: AnyObject {
    func setPassword()
    func clearPassword()
}
class PDFPasswordTableViewCell: UITableViewCell {
    @IBOutlet weak var passwordButton: UIButton!
    @IBOutlet weak var clearButton: UIButton!

    weak var delegate: PDFPasswordTableViewCellDelegate?


    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    @IBAction func setPasswordTapped(_ sender: Any) {
        delegate?.setPassword()
    }

    @IBAction func clearPassword(_ sender: Any) {
        delegate?.clearPassword()
    }

    func update(password: String = "Set Password") {
        passwordButton.setTitle(password, for: .normal)
        if password != "Set Password" {
            clearButton.isHidden = false
        } else {
            clearButton.isHidden = true
        }
    }
    
}
