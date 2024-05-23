//
//  DocumentListTableViewCell.swift
//  ScanflowDocumentCapture
//
//  Created by Mac-OBS-46 on 11/05/23.
//

import UIKit

protocol DocumentListTableViewCellDelegate: AnyObject {
    func cellTapped(indexpath: IndexPath)
    func shareButtonTapped(indexPath: IndexPath, sender: SFButton)
    func moreOptionsButtonTapped(indexPath: IndexPath, sender: SFButton)
}
class DocumentListTableViewCell: UITableViewCell {

    @IBOutlet weak var documentTitle: UILabel!
    @IBOutlet weak var moreOptionButton: SFButton!
    @IBOutlet weak var createdDate: UILabel!
    @IBOutlet weak var bgView: UIView!
    
    
    weak var delegate: DocumentListTableViewCellDelegate?
    var currentIndexPath: IndexPath?
    let bundle = Bundle(identifier: "com.ScanflowDocumentCapture")
    var popoverController: UIPopoverPresentationController?

    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
        self.contentView.backgroundColor = .white
        self.backgroundColor = .white
        bgView.layer.cornerRadius = 6
        
        bgView.layer.shadowColor = UIColor.black.withAlphaComponent(0.08).cgColor
        bgView.layer.shadowOffset = CGSize(width: 0, height: 3)
        bgView.layer.shadowOpacity = 0.5
        bgView.layer.shadowRadius = 6
        
    }
    

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func moreButtonTapped(_ sender: SFButton) {
        delegate?.moreOptionsButtonTapped(indexPath: currentIndexPath!, sender: sender)
    }
    
    @IBAction func shareButtionTapped(_ sender: SFButton) {
        delegate?.shareButtonTapped(indexPath: currentIndexPath!, sender: sender)
    }

    @IBAction func cellTapped(_ sender: Any) {
        delegate?.cellTapped(indexpath: currentIndexPath!)

    }

    func updateFile(name: String, createdAt: String) {
        documentTitle.text = name
        createdDate.text = createdAt
    }

}


extension DocumentListTableViewCell: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}
