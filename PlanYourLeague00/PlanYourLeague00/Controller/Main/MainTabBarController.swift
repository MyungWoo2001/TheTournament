//
//  MainTabBarController.swift
//  PlanYourLeague00
//
//  Created by Myung Woo on 10/1/24.
//

import UIKit
import CloudKit

class MainTabBarController: UITabBarController {
    
    var homeTabNav: UINavigationController!
    var searchTabNav: UINavigationController!
    var createTabNav: UINavigationController!
    var personalTabNav: UINavigationController!
    
    var cloudUser: CKRecord!
    var userEmail: String!
    
    var spinner = UIActivityIndicatorView()
    
    var matches: [Match] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        spinner.style = .medium
        spinner.hidesWhenStopped = true
        view.addSubview(spinner)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate( [ spinner.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 230.0),
                                       spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor)])
        
        spinner.transform = CGAffineTransform(scaleX: 2.0, y: 2.0)
        
        if cloudUser == nil {
            fetchRecordsFromCloudForUser(for: userEmail)
        } else {
            setupTabBarControllers()
        }
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
                self.setupTabBarControllers()
                self.spinner.stopAnimating()
            }
        }
        publicDatabase.add(queryOperation)
    }
    
    func setupTabBarControllers() {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        homeTabNav = storyboard.instantiateViewController(withIdentifier: "HomeTabNavigationController") as? UINavigationController
        homeTabNav?.tabBarItem = UITabBarItem(title: "Home", image: UIImage(systemName: "house.fill"), tag: 0)
        
        searchTabNav = storyboard.instantiateViewController(withIdentifier: "SearchTabNavigationController") as? UINavigationController
        searchTabNav?.tabBarItem = UITabBarItem(title: "Search", image: UIImage(systemName: "magnifyingglass"), tag: 1)
        
        createTabNav = storyboard.instantiateViewController(withIdentifier: "CreateTabNavigationController") as? UINavigationController
        createTabNav?.tabBarItem = UITabBarItem(title: "New", image: UIImage(systemName: "plus.app.fill"), tag: 2)
        
        personalTabNav = storyboard.instantiateViewController(withIdentifier: "PersonalTabNavigationController") as? UINavigationController
        personalTabNav?.tabBarItem = UITabBarItem(title: "Personal", image: UIImage(systemName: "person"), tag: 3)
        if let personalVC = personalTabNav.viewControllers.first as? PersonalViewController {
            personalVC.cloudUser = self.cloudUser
            personalVC.userEmail = self.userEmail
        }
        
        self.viewControllers = [homeTabNav,searchTabNav,createTabNav,personalTabNav]
    }
    
}
