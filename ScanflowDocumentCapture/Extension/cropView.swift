//
//  cropView.swift
//  ScanflowDocumentCapture
//
//  Created by Mac-OBS-46 on 12/05/23.
//

import UIKit

class CornerPointView: UIView {
    
    var dragGestureRecognizer: UIPanGestureRecognizer!
    var completionHandler: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        layer.borderWidth = 2
        layer.borderColor = UIColor.clear.cgColor
        layer.cornerRadius = 10
        layer.masksToBounds = true
        layer.shadowColor = UIColor.clear.cgColor
        layer.shadowOpacity = 0.2
        layer.shadowOffset = .zero
        layer.shadowRadius = 3
        dragGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(dragged(_:)))
        addGestureRecognizer(dragGestureRecognizer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        let path = UIBezierPath(ovalIn: rect)
        UIColor.clear.setFill()
        path.fill()
    }
    
    @objc func dragged(_ gestureRecognizer: UIPanGestureRecognizer) {
        switch gestureRecognizer.state {
        case .began, .changed:
            let translation = gestureRecognizer.translation(in: superview)
            center = CGPoint(x: center.x + translation.x, y: center.y + translation.y)
            gestureRecognizer.setTranslation(CGPoint.zero, in: superview)
            completionHandler?()
        case .ended:
            completionHandler?()
        default:
            break
        }
    }
}
