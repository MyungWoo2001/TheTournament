//
//  PersonalViewController.swift
//  PlanYourLeague00
//
//  Created by Myung Woo on 9/19/24.
//

import UIKit
import CloudKit
import FirebaseAuth

class PersonalViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    var cloudUser: CKRecord!
    var userEmail: String!
    
    var spinner = UIActivityIndicatorView()

    let personalFunctions = ["Your League", "Favorite"]
    let personalFunctionsImage = ["perleague","perfavorite"]
    let appFunctions = ["Setting", "Help and Support"]
    let appFunctionsImage = ["persetting", "perhelpandsupport"]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        spinner.style = .medium
        spinner.hidesWhenStopped = true
        view.addSubview(spinner)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate( [ spinner.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 230.0),
                                       spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor)])
        
        spinner.transform = CGAffineTransform(scaleX: 2.0, y: 2.0)
        
        if cloudUser == nil, userEmail != nil {
            fetchRecordsFromCloudForUser(for: userEmail)
        }
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableView.automaticDimension
    }
    
    func fetchRecordsFromCloudForUser(for userEmail: String) {
        print("Fetching")
        self.spinner.startAnimating()
        // Fetch data using Convenience API
        let cloudContainer = CKContainer.default()
        let publicDatabase = cloudContainer.publicCloudDatabase
        let predicate = NSPredicate(format: "userEmail == %@", userEmail)
        let query = CKQuery(recordType: "User", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let queryOperation = CKQueryOperation(query: query)
        queryOperation.desiredKeys = ["userID","userName","userPhone","userEmail","image"]
        queryOperation.queuePriority = .veryHigh
        queryOperation.resultsLimit = 50
        queryOperation.recordMatchedBlock = { (recordID, result) -> Void in
            do {
                self.cloudUser = (try result.get())
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
                    self.spinner.stopAnimating()
                    let alertController = UIAlertController(title: "Error", message: "Can not connect to server! Please check your internet!", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alertController,animated: true, completion: nil)
                }
            case .success:
                print("Successfully retrieve the data of Match from iCloud")
            }
            
            DispatchQueue.main.async {
                self.spinner.stopAnimating()
                self.tableView.reloadData()
            }
        }
        publicDatabase.add(queryOperation)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section{
        case 0: return 1
        case 1: return personalFunctions.count
        case 2: return appFunctions.count
        case 3: return 1
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cellIdentifier = "personalcell"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        
        switch indexPath.section {
        case 0:
            
            cell.textLabel?.text = "User"
            cell.imageView?.image = UIImage(named: "perthumbnailmale")
            
            guard let cloudUser = self.cloudUser else {return UITableViewCell()}
            cell.textLabel?.text = cloudUser.object(forKey: "userName") as? String
            if let image = cloudUser.object(forKey: "image"), let imageAsset = image as? CKAsset {
                print("minhvu")
                if let imageData = try? Data.init(contentsOf: imageAsset.fileURL!) {
                    cell.imageView?.image = UIImage(data: imageData)
                }
            }
            
            cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
        case 1:
            cell.textLabel?.text = personalFunctions[indexPath.row]
            cell.imageView?.image = UIImage(named: self.personalFunctionsImage[indexPath.row])
        case 2:
            cell.textLabel?.text = appFunctions[indexPath.row]
            cell.imageView?.image = UIImage(named: self.appFunctionsImage[indexPath.row])
        case 3:
            cell.textLabel?.text = "Log out"
            cell.imageView?.image = UIImage(named: "perlogout")
        default: break
        }

        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 3 {
            self.spinner.startAnimating()
            do {
                try Auth.auth().signOut()
                // Điều hướng đến màn hình đăng nhập
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    self.spinner.stopAnimating()
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginViewController")
                    window.rootViewController = loginVC
                    window.makeKeyAndVisible()
                }
                print("User logged out successfully.")
            } catch let error as NSError {
                self.spinner.stopAnimating()
                print("Error signing out: \(error.localizedDescription)")
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // Kiểm tra nếu là hàng đầu tiên (row 0) của section đầu tiên (section 0)
        if indexPath.section == 0 && indexPath.row == 0 {
            return 64 // Chiều cao mong muốn cho hàng đầu tiên trong section 0
        }
        
        return 44 // Chiều cao mặc định cho các hàng khác
    }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == 3 {
            return 100 // Tạo khoảng cách lớn ở section trước cell cần đẩy xuống dưới
        }
        return 0 // Chiều cao footer mặc định cho các section khác
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return ""
        case 1: return "Personal"
        case 2: return "Applicaton"
        case 3: return "Account"
        default: return ""
        }
    }
}
