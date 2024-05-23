//
//  UIView.swift
//  ScanflowDocumentCapture
//
//  Created by Mac-OBS-46 on 11/05/23.
//

import Foundation
import UIKit

class backgroundView : UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .white
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

class SFView : UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .white
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setCornerRadius(value: CGFloat) {
        layer.masksToBounds = true
        layer.cornerRadius = value
    }
    
}

class SFNavBarView : UIView {
    

    override func awakeFromNib() {
       super.awakeFromNib()
        self.backgroundColor = SFDocumentHelper.shared.appThemeColor
    }

    
    func setCornerRadius(value: CGFloat) {
        layer.masksToBounds = true
        layer.cornerRadius = value
    }
    
    func updateBackgroundColor() {
        self.backgroundColor = SFDocumentHelper.shared.appThemeColor
    }
}


