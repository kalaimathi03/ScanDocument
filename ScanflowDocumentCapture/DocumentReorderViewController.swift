//
//  DocumentReorderViewController.swift
//  ScanflowDocumentCapture
//
//  Created by Mac-OBS-46 on 15/05/23.
//

import UIKit

protocol DocumentReorderViewControllerDelegate: AnyObject {
    func reOrdered(document:[DocumentDetails])
}
class DocumentReorderViewController: UIViewController {
    
    @IBOutlet weak var documentCollectionView: UICollectionView!
    
    @IBOutlet weak var doneButton: SFButton!
    let bundle = Bundle(identifier: "com.ScanflowDocumentCapture")
    
    var capturedDocument:[DocumentDetails]? {
        didSet {
            if documentCollectionView != nil {
                // documentCollectionView.reloadData()
            }
        }
    }
    weak var delegate: DocumentReorderViewControllerDelegate?
    override func viewDidLoad() {
        super.viewDidLoad()
        doneButton.setTitle("Done", for: .normal)
        documentCollectionView.backgroundColor = .white
        documentCollectionView.delegate = self
        documentCollectionView.dataSource = self
        
        documentCollectionView.register(UINib(nibName: "DocumentPreviewCollectionViewCell", bundle: bundle), forCellWithReuseIdentifier: "DocumentPreviewCollectionViewCell")
        
        let longPressGesture = UILongPressGestureRecognizer(
            target: self,
            action: #selector(handleLongPressGesture)
        )
        documentCollectionView.addGestureRecognizer(longPressGesture)
        
    }
    
    @IBAction func backButtionTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func doneButtonTapped(_ sender: Any) {
        if let document = capturedDocument {
            delegate?.reOrdered(document: document)
        }
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc private func handleLongPressGesture(_ gesture: UILongPressGestureRecognizer) {
        let gestureLocation = gesture.location(in: documentCollectionView)
        switch gesture.state {
        case .began:
            guard let targetIndexPath = documentCollectionView.indexPathForItem(at: gestureLocation) else {
                return
            }
            documentCollectionView.beginInteractiveMovementForItem(at: targetIndexPath)
        case .changed:
            documentCollectionView.updateInteractiveMovementTargetPosition(gestureLocation)
        case .ended:
            documentCollectionView.endInteractiveMovement()
        default:
            documentCollectionView.cancelInteractiveMovement()
        }
    }
    
    private func refreshData() {
            self.documentCollectionView.reloadData()
    }
    
}

extension DocumentReorderViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        capturedDocument?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        print("cell refresed")
        if let documentCell = collectionView.dequeueReusableCell(withReuseIdentifier: "DocumentPreviewCollectionViewCell", for: indexPath) as? DocumentPreviewCollectionViewCell {
            if let documentDetails = capturedDocument?[indexPath.row] {
                documentCell.updateDocument(image: SFDocumentHelper.shared.showImageFrom(document: documentDetails, forPreview: true, compressionQuality: 0.7)!, count: "\(indexPath.row + 1)")
            }
            return documentCell
        }
        return UICollectionViewCell()
    }
    
    
}

extension DocumentReorderViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: (collectionView.frame.width / 3), height: collectionView.frame.height / 4)
    }
}

extension DocumentReorderViewController:  UICollectionViewDropDelegate {
    
    
    
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        
    }
    
    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        print("change started")
        let changeIteml = (capturedDocument?.remove(at: sourceIndexPath.row))!
        capturedDocument?.insert(changeIteml, at: destinationIndexPath.row)
        collectionView.reloadSections(IndexSet(integer: sourceIndexPath.section))
    }
    
    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
}
