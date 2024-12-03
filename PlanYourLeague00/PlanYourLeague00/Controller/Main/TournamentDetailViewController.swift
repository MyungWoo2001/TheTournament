//
//  LeagueDetailViewController.swift
//  PlanYourLeague00
//
//  Created by Myung Woo on 9/11/24.
//

import UIKit
import CoreData
import CloudKit

class TournamentDetailViewController: UIViewController,UITableViewDataSource, UITableViewDelegate {
    
    var league: League!
    var leagues: [CKRecord] = []
    var tournament: CKRecord!
    var onupdate: Bool = false
    var leagueCount: Int = 0
    
    var tournamentAccess: Bool = false
    
    var spinner = UIActivityIndicatorView()
    
    var ondismiss: (()-> Void)!
    var ondismiss1: (()-> Void)!
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.ondismiss?()
    }
   
    @IBOutlet var tableView: UITableView!
    @IBOutlet var accessButton: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        accessButton.image = UIImage(systemName: "square.and.pencil")

        // Do any additional setup after loading the view.
        spinner.style = .medium
        spinner.hidesWhenStopped = true
        view.addSubview(spinner)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate( [ spinner.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 230.0),
                                       spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor)])
        spinner.transform = CGAffineTransform(scaleX: 2.0, y: 2.0) // Phóng to spinner lên 2 lần

        spinner.startAnimating()

        fetchRecordsFromCloud(for: tournament)
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationController?.isNavigationBarHidden = false
        navigationItem.backButtonTitle = ""
        
        tableView.delegate = self
        tableView.dataSource = self
        
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    @objc func fetchRecordsFromCloud(for tournament: CKRecord) {

        leagues.removeAll()
        // Fetch data using Convenience API
        let cloudContainer = CKContainer.default()
        let publicDatabase = cloudContainer.publicCloudDatabase
        var predicate = NSPredicate(value: true)
        predicate = NSPredicate(format: "tournament == %@", tournament)
        let query = CKQuery(recordType: "League", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let queryOperation = CKQueryOperation(query: query)
        queryOperation.desiredKeys = ["name","teamCount","tournament"]
        queryOperation.queuePriority = .veryHigh
        queryOperation.resultsLimit = 50
        queryOperation.recordMatchedBlock = { (recordID, result) -> Void in
            do {
                if let _ = self.leagues.first(where: { $0.recordID == recordID }) {
                    return
                }

                self.leagues.append(try result.get())
            } catch {
                print(error)
            }
        }
        
        queryOperation.queryResultBlock = {
            [unowned self] result in
            switch result {
            case .failure(let error):
                print(error.localizedDescription)
                DispatchQueue.main.async {
                    let alertController = UIAlertController(title: "Error", message: "Can not connect to server! Please check your internet!", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alertController,animated: true, completion: nil)
                }

            case .success:
                print("Successfully retrieve the data from iCloud")
            }
            
            DispatchQueue.main.async {
                self.spinner.stopAnimating()
                self.leagueCount = self.leagues.count
                self.tableView.reloadData()
//                if let refreshControl = self.refreshControl {
//                    if refreshControl.isRefreshing {
//                        refreshControl.endRefreshing()
//                    }
//                }
            }
        }
        publicDatabase.add(queryOperation)
    }
    
    @objc func fetchRecordsFromCloudOnDismiss(for tournament: CKRecord) {

        leagues.removeAll()
        self.spinner.startAnimating()
        // Fetch data using Convenience API
        let cloudContainer = CKContainer.default()
        let publicDatabase = cloudContainer.publicCloudDatabase
        var predicate = NSPredicate(value: true)
        predicate = NSPredicate(format: "tournament == %@", tournament)
        let query = CKQuery(recordType: "League", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let queryOperation = CKQueryOperation(query: query)
        queryOperation.desiredKeys = ["name","teamCount","tournament"]
        queryOperation.queuePriority = .veryHigh
        queryOperation.resultsLimit = 50
        queryOperation.recordMatchedBlock = { (recordID, result) -> Void in
            do {
                if let _ = self.leagues.first(where: { $0.recordID == recordID }) {
                    return
                }

                self.leagues.append(try result.get())
            } catch {
                print(error)
            }
        }
        
        queryOperation.queryResultBlock = {
            [unowned self] result in
            switch result {
            case .failure(let error):
                print(error.localizedDescription)
                DispatchQueue.main.async {
                    let alertController = UIAlertController(title: "Error", message: "Can not connect to server! Please check your internet!", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alertController,animated: true, completion: nil)
                }


            case .success:
                print("Successfully retrieve the data from iCloud")
            }
            
            DispatchQueue.main.async {
                if self.leagueCount != self.leagues.count{
                    self.leagueCount = self.leagues.count
                    self.spinner.stopAnimating()
                } else {
                    self.fetchRecordsFromCloudOnDismiss(for: tournament)
                }
                
                self.tableView.reloadData()
//                if let refreshControl = self.refreshControl {
//                    if refreshControl.isRefreshing {
//                        refreshControl.endRefreshing()
//                    }
//                }
            }
        }
        publicDatabase.add(queryOperation)
    }
    
    func accessRequest() {
        
        let alert = UIAlertController(title: "Access as Admin", message: "Enter Tournament's Access Password!", preferredStyle: .alert)
        
        alert.addTextField{ textField in
            textField.placeholder = "Access Password"
            textField.isSecureTextEntry = true
            
        }
        
        let confirmAction = UIAlertAction(title: "Confirm", style: .default){_ in
            if let accessCode = alert.textFields?.first?.text{
                print("Access code: \(accessCode)")
                if let tournamentAccessPassword = self.tournament.object(forKey: "AccessPassword") as? String{
                    print("Access Password: \(tournamentAccessPassword)",accessCode == tournamentAccessPassword)
                    if accessCode == tournamentAccessPassword {
                        self.tournamentAccess = true
                        self.accessButton.image = UIImage(systemName: "trash")
                    } else {
                        self.showErrorAlert()
                    }
                } else {
                    print("tournament error")
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(confirmAction)
        alert.addAction(cancelAction)
        
        self.present(alert, animated: true)
    }
    
    func showErrorAlert() {
        let errorAlert = UIAlertController(title: "Error",
                                           message: "Access Password is incorrect! Enter",
                                           preferredStyle: .alert)
        errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(errorAlert, animated: true)
    }
    
    @IBAction func accessButtonTapped(sender: UIButton){
        if tournamentAccess {
                
            let publicDatabase = CKContainer.default().publicCloudDatabase
            
            publicDatabase.delete(withRecordID: self.tournament.recordID) { recordID, error in
                DispatchQueue.main.async {
                    if let error = error {
                        // Hiển thị lỗi nếu xóa thất bại
                        let alertController = UIAlertController(
                            title: "Error",
                            message: "Failed to delete record: \(error.localizedDescription)",
                            preferredStyle: .alert
                        )
                        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        self.present(alertController, animated: true, completion: nil)
                    } else {
                        // Hiển thị thông báo thành công nếu xóa thành công
                        let alertController = UIAlertController(
                            title: "Success",
                            message: "Record deleted successfully.",
                            preferredStyle: .alert
                        )
                        let CancelAction  = UIAlertAction(title: "OK", style: .default) {_ in
                            self.ondismiss1?()
                            self.navigationController?.popViewController(animated: true)
                        }
                        alertController.addAction(CancelAction)
                        self.present(alertController, animated: true, completion: nil)
                    }
                }
            }
        } else {
            accessRequest()
        }
    }
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section{
        case 0: return 5
        case 1: return leagues.count
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: LeagueDetailHeaderCell.self), for: indexPath) as! LeagueDetailHeaderCell
                print("table")
                spinner.startAnimating()
                CKContainer.default().publicCloudDatabase.fetch(withRecordID: self.tournament.recordID){ (record, error) in
                    if let error = error {
                        
                        DispatchQueue.main.async{self.spinner.stopAnimating()}
                        print("Error loading image data: \(error.localizedDescription)")
                        let alertController = UIAlertController(title: "Connection is lost", message: "Can not connect to server!", preferredStyle: .alert)
                        let refreshAction = UIAlertAction(title: "Retry", style: .default){_ in
                            self.tableView.reloadData()
                        }
                        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
                        
                        alertController.addAction(refreshAction)
                        alertController.addAction(cancelAction)
                        self.present(alertController,animated: true, completion: nil)
                    } else if let record = record {
                        self.tournament = record
                        DispatchQueue.main.async {
                            self.spinner.stopAnimating()
                            do {
                                if let image = self.tournament.object(forKey: "image"), let imageAsset = image as? CKAsset {
                                    if let fileURL = imageAsset.fileURL {
                                        let imageData = try Data(contentsOf: fileURL)
                                        cell.headerImageView.image = UIImage(data: imageData)
                                    }
                                }
                            } catch {
                                print("Error loading image data: \(error.localizedDescription)")
                                let alertController = UIAlertController(title: "Image is not available now!", message: "Image maybe need more time to upload to server!", preferredStyle: .alert)
                                let refreshAction = UIAlertAction(title: "Retry", style: .default){_ in
                                    self.tableView.reloadData()
                                }
                                let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
                                
                                alertController.addAction(refreshAction)
                                alertController.addAction(cancelAction)
                                self.present(alertController,animated: true, completion: nil)
                            }
                        }
                    }
                }
                           
                return cell
            case 1:
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: LeagueDetailInfoCell.self), for: indexPath) as! LeagueDetailInfoCell
                
                cell.leagueNameLabel.text = tournament.object(forKey: "name") as? String

                return cell
            case 2:
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: LeagueDetailDescriptionCell.self), for: indexPath) as! LeagueDetailDescriptionCell
                
                cell.summaryLabel.text = tournament.object(forKey: "summary") as? String
                
                return cell
            case 3:
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: LeagueDetailManagerCell.self), for: indexPath) as! LeagueDetailManagerCell
                
                cell.leagueManagerNameLabel.text = tournament.object(forKey: "manager") as? String
                cell.leagueManagerPhoneLabel.text = tournament.object(forKey: "phone") as? String
                cell.leagueManagerEmailLabel.text = tournament.object(forKey: "email") as? String
                
                return cell
            case 4:
                let cell = tableView.dequeueReusableCell(withIdentifier: "LeagueDetailCreateNewLeagueCell", for: indexPath) as! LeagueDetailCreateNewLeagueCell
                
                cell.label.text = "Create New League!"
                
                return cell
                
            default:
                fatalError("Failed to instantiate the table cell for detail view controller!!")
            }
            
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TournamentDetailLeagueCell.self), for: indexPath) as! TournamentDetailLeagueCell
            
            cell.leagueNameLabel.text = leagues[indexPath.row].object(forKey: "name") as? String
            
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TournamentDetailLeagueCell.self), for: indexPath) as! TournamentDetailLeagueCell
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard tournamentAccess else {return nil}
        guard indexPath.section == 1 else {
            return nil
        }
        
        // Lấy bản ghi tương ứng với dòng được chọn
        let league = leagues[indexPath.row]
        
        // Hành động xóa
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] action, view, completionHandler in
            guard let self = self else {
                completionHandler(false)
                return
            }
            
            let recordID = league.recordID
            
            // Xóa bản ghi trong CloudKit
            CKContainer.default().publicCloudDatabase.delete(withRecordID: recordID) { _, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("Error deleting record: \(error.localizedDescription)")
                        DispatchQueue.main.async {
                            let alertController = UIAlertController(title: "Error", message: "Can not connect to server! Please check your internet!", preferredStyle: .alert)
                            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                            self.present(alertController,animated: true, completion: nil)
                        }

                        completionHandler(false)
                    } else {
                        print("Record deleted successfully")
                        self.leagues.remove(at: indexPath.row)
                        tableView.deleteRows(at: [indexPath], with: .automatic)
                        completionHandler(true)
                    }
                }
            }
        }
        deleteAction.backgroundColor = .systemRed
        deleteAction.image = UIImage(systemName: "trash")
        
        // Cấu hình hành động vuốt
        let swipeConfiguration = UISwipeActionsConfiguration(actions: [deleteAction])
        return swipeConfiguration
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Chỉ áp dụng cho các cell thuộc section 0
        guard indexPath.section == 0 else { return }
        
        if indexPath.row == 4 {
            if self.tournamentAccess {
                self.performSegue(withIdentifier: "newleaguecreating", sender: nil)
            }
        }
        
        // Lấy nội dung của cell (giả sử là text)
        let cellContent = "Content of cell at row \(indexPath.row)" // Thay thế bằng nội dung thật của cell
        
        // Tạo Alert Controller
        let alertController = UIAlertController(title: "Menu", message: "What you wanna do?", preferredStyle: .actionSheet)
        
        // Hành động 1: Copy nội dung
        let copyPhoneAction = UIAlertAction(title: "Copy phone number", style: .default) { _ in
            UIPasteboard.general.string = self.tournament.object(forKey: "phone") as? String
            print("Copied: \(cellContent)")
        }
        let copyEmailAction = UIAlertAction(title: "Copy email address", style: .default) { _ in
            UIPasteboard.general.string = self.tournament.object(forKey: "email") as? String
            print("Copied: \(cellContent)")
        }

        
        // Hành động 2: Chuyển đến ViewController khác
        let navigateAction = UIAlertAction(title: "Update Information", style: .default) { _ in
            self.performSegue(withIdentifier: "updateTournamentInformation", sender: cellContent)
        }
        
        // Hành động huỷ bỏ
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        // Thêm các hành động vào Alert Controller
        if tournamentAccess {
            alertController.addAction(navigateAction)
            alertController.addAction(cancelAction)
            present(alertController, animated: true, completion: nil)

        } else {
            if indexPath.row == 3 {
                alertController.addAction(copyEmailAction)
                alertController.addAction(copyPhoneAction)
                alertController.addAction(cancelAction)
                present(alertController, animated: true, completion: nil)

            } else if indexPath.row == 0 {
                if let image = tournament.object(forKey: "image"), let imageAsset = image as? CKAsset {
                    if let imageData = try? Data.init(contentsOf: imageAsset.fileURL!) {
                        if let image = UIImage(data: imageData){
                            showFullScreenImage(image: image)
                        }
                    }
                }
            }
        }
        
        // Hiển thị Alert
    }
    
    func showFullScreenImage(image: UIImage) {
        let fullScreenImageView = UIImageView(frame: self.view.bounds)
        fullScreenImageView.image = image
        fullScreenImageView.contentMode = .scaleAspectFit
        fullScreenImageView.backgroundColor = .black
        fullScreenImageView.isUserInteractionEnabled = true
        fullScreenImageView.alpha = 0

        // Thêm gesture để đóng
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissFullScreenImage(_:)))
        fullScreenImageView.addGestureRecognizer(tapGesture)

        self.view.addSubview(fullScreenImageView)

        // Animation để hiển thị
        UIView.animate(withDuration: 0.3) {
            fullScreenImageView.alpha = 1
        }
    }

    @objc func dismissFullScreenImage(_ sender: UITapGestureRecognizer) {
        if let fullScreenImageView = sender.view as? UIImageView {
            UIView.animate(withDuration: 0.3, animations: {
                fullScreenImageView.alpha = 0
            }, completion: { _ in
                fullScreenImageView.removeFromSuperview()
            })
        }
    }

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "newleaguecreating"{
            let destination = segue.destination as! UINavigationController
            if let destinationController = destination.viewControllers.first as? LeagueCreateViewController{
                destinationController.tournament = self.tournament
                destinationController.onDismiss = { [weak self] in
                    if let tournament = self?.tournament {
                        self?.fetchRecordsFromCloudOnDismiss(for: tournament)
                    }
                }
            }
        } else if segue.identifier == "showLeagueDetail" {
            let destinationController = segue.destination as! LeagueDetailViewController
            if let indexPath = tableView.indexPathForSelectedRow {
                destinationController.league = leagues[indexPath.row]
                destinationController.tournament = self.tournament
                destinationController.tournamentAccess = self.tournamentAccess
            }
        } else if segue.identifier == "updateTournamentInformation" {
            let destinationNavigation = segue.destination as! UINavigationController
            if let destinationViewcontroller = destinationNavigation.viewControllers.first as? CreateTableViewController {
                destinationViewcontroller.cloudTournament = self.tournament
                destinationViewcontroller.onDismiss = { [ weak self] in
                    self?.tableView.reloadData()
                }
                destinationViewcontroller.onDismiss1 = {
                    DispatchQueue.main.async {
                        let alertController = UIAlertController(title: "Error", message: "No Internet connection.Check your internet.", preferredStyle: .alert)
                        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        self.present(alertController,animated: true, completion: nil)
                    }

                }
            }
        }
    }
}


