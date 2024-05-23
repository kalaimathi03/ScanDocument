//
//  CircleButton.swift
//  ScanflowDocumentCapture
//
//  Created by Mac-OBS-46 on 11/05/23.
//

import UIKit

class CircleButton: UIButton {

    override func awakeFromNib() {
            super.awakeFromNib()
            // Customize the button's appearance
        self.backgroundColor = SFDocumentHelper.shared.appThemeColor
        self.tintColor = SFDocumentHelper.shared.appThemeColor
        self.layer.cornerRadius = self.frame.width/2
            self.setTitleColor(UIColor.white, for: .normal)
        
        self.setTitle("", for: .normal)
        }
    
    func setRoundButton() {
        self.clipsToBounds = true
        self.layer.cornerRadius = self.frame.width/2
        self.tintColor = SFDocumentHelper.shared.appThemeColor
        self.backgroundColor = SFDocumentHelper.shared.appThemeColor
        self.setTitleColor(UIColor.white, for: .normal)
        self.setTitle("", for: .normal)
        self.titleLabel?.sizeToFit()
    }

}
