//
//  ExportPreviewViewController.swift
//  ScanflowDocumentCapture
//
//  Created by Mac-OBS-46 on 23/08/23.
//

import UIKit

class ExportPreviewViewController: UIViewController {

    private let shareOptions: [String] = ["Other Apps", "Email", "Files"]
    private let shareOptionImages: [String] = ["more", "mail", "folder"]

    @IBOutlet weak var documentType: UILabel!
    @IBOutlet weak var tableView: UITableView!

    private let bundle = Bundle(identifier: "com.ScanflowDocumentCapture")

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    private func setDelegate() {
        tableView.dataSource = self
        tableView.delegate = self
    }

    private func registerCell() {
        tableView.register(UINib(nibName: "SetPasswordTableViewCell", bundle: bundle), forCellReuseIdentifier: "SetPasswordTableViewCell")
    }


}

extension ExportPreviewViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        shareOptions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "SetPasswordTableViewCell", for: indexPath) as? SetPasswordTableViewCell {
            cell.update(img: UIImage(named: shareOptionImages[indexPath.row]), title: shareOptions[indexPath.row])
            return cell
        }
        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }

}
