//
//  PopoverViewController.swift
//  ScanflowDocumentCapture
//
//  Created by Mac-OBS-46 on 17/05/23.
//

import Foundation
import UIKit

protocol PopoverViewControllerDelegate: AnyObject {
    func deleteButtonTapped()
}
class PopoverViewController: UIViewController {
    
    
    
    @IBOutlet weak var deleteButton: SFButton!
    
    weak var delegate: PopoverViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        deleteButton.setTitle("Delete", for: .normal)
        deleteButton.setTitleColor(.red, for: .normal)
    }
    
    @IBAction func deleteButtonTapped(_ sender: Any) {
        delegate?.deleteButtonTapped()
    }
    

}
