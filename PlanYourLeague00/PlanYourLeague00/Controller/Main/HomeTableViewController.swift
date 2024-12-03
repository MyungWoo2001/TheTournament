//
//  HomeTableViewController.swift
//  PlanYourLeague00
//
//  Created by Myung Woo on 9/8/24.
//

import UIKit
import CloudKit

class HomeTableViewController: UITableViewController {
    
    @IBOutlet var homeEmptyView: UIView!
    var matches: [CKRecord] = []
    var teams: [CKRecord] = []
    var teamsRecordID: [String] = []
    
    private var imageCache = NSCache<CKRecord.ID, NSURL>()
    
    var spinner = UIActivityIndicatorView()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Prepare the empty view
        refreshControl = UIRefreshControl()
        refreshControl?.backgroundColor = UIColor.white
        refreshControl?.tintColor = UIColor.gray
        refreshControl?.addTarget(self, action: #selector(fetchRecordsFromCloudForMatch), for: UIControl.Event.valueChanged)
        
        spinner.style = .medium
        spinner.hidesWhenStopped = true
        view.addSubview(spinner)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate( [ spinner.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 100.0),
                                       spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor)])
        
        spinner.transform = CGAffineTransform(scaleX: 2.0, y: 2.0) // Phóng to spinner lên 2 lần

        spinner.startAnimating()
        
        fetchRecordsFromCloudForMatch()
        
        tableView.backgroundView = homeEmptyView
        tableView.backgroundView?.isHidden = matches.count == 0 ? false : true

        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.backButtonTitle = ""
        tableView.dataSource = dataSource
        
    }
    
        
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Navigation
        navigationController?.navigationBar.prefersLargeTitles = true
        // Walkthrough
        if UserDefaults.standard.bool(forKey: "walkthroughDone"){
            return
        }
        let storyboard = UIStoryboard(name: "Onboarding", bundle: nil)
        if let walkthroughViewController = storyboard.instantiateViewController(withIdentifier: "WalkthroughViewController") as? WalkthroughViewController {
            present(walkthroughViewController, animated: true, completion: nil)
        }
    }
    
    @objc func fetchRecordsFromCloudForMatch() {
        // Fetch data using Convenience API
        self.matches.removeAll()
        let cloudContainer = CKContainer.default()
        let publicDatabase = cloudContainer.publicCloudDatabase
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "Match", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let queryOperation = CKQueryOperation(query: query)
        queryOperation.desiredKeys = ["date","round","summary","team1","team1ID","team1RecordID","team1Goal","team2","team2ID","team2RecordID","team2Goal"]
        queryOperation.queuePriority = .veryHigh
        queryOperation.resultsLimit = 50
        queryOperation.recordMatchedBlock = { (recordID, result) -> Void in
            do {
                if let _ = self.matches.first(where: { $0.recordID == recordID }) {
                    return
                }

                self.matches.append(try result.get())
                
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
                print("Successfully retrieve the data of Match from iCloud")
                self.matches = self.matches.shuffled()
                self.updateMatchSnapshot()
            }
            
            DispatchQueue.main.async {
                self.tableView.backgroundView?.isHidden = self.matches.count == 0 ? false : true
                self.spinner.stopAnimating()
                print(self.matches.count)
                
                if let refreshControl = self.refreshControl {
                    if refreshControl.isRefreshing {
                        refreshControl.endRefreshing()
                    }
                }

            }
        }
        publicDatabase.add(queryOperation)
    }
    
    func homeConfigureDataSource() -> UITableViewDiffableDataSource<Section, CKRecord> {
        
        let dataSource = UITableViewDiffableDataSource<Section, CKRecord>(tableView: tableView) { (tableView, indexPath, match) -> UITableViewCell? in
            
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: HomeTableViewCell.self), for: indexPath) as! HomeTableViewCell

            cell.leagueNameLabel.text = "League Name"
            cell.dateLabel.text = match.object(forKey: "date") as? String
            cell.team1NameLabel.text = "team1"
            cell.team1GoalLabel.text = match.object(forKey: "team1Goal") as? String
            cell.team1logo.image = UIImage(systemName: "photo")
            cell.team2NameLabel.text = "team2"
            cell.team2GoalLabel.text = match.object(forKey: "team2Goal") as? String
            cell.team2Logo.image = UIImage(systemName: "photo")
            
            let publicDatabase = CKContainer.default().publicCloudDatabase
            let fetchRecordsImageOperation = CKFetchRecordsOperation(recordIDs: [match.recordID])
            fetchRecordsImageOperation.desiredKeys = ["league"]
            fetchRecordsImageOperation.queuePriority = .veryHigh
            
            fetchRecordsImageOperation.perRecordResultBlock = { (recordID, result) in
                do {
                    let matchRecord = try result.get()
                    if let leagueReference = matchRecord.object(forKey: "league") as? CKRecord.Reference{
                        let fetchRecordsImageOperation = CKFetchRecordsOperation(recordIDs: [leagueReference.recordID])
                        fetchRecordsImageOperation.desiredKeys = ["name"]
                        fetchRecordsImageOperation.queuePriority = .veryHigh
                        
                        fetchRecordsImageOperation.perRecordResultBlock = { (recordID, result) in
                            do {
                                let leagueRecord = try result.get()
                                DispatchQueue.main.async {
                                    cell.leagueNameLabel.text = leagueRecord.object(forKey: "name") as? String
                                }
                                
                            } catch {
                                print("Failed to get restaurant image: \(error.localizedDescription)")
                                DispatchQueue.main.async {
                                    let alertController = UIAlertController(title: "Error", message: "Can not connect to server! Please check your internet!", preferredStyle: .alert)
                                    alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                                    self.present(alertController,animated: true, completion: nil)
                                }
                            }
                        }
                        publicDatabase.add(fetchRecordsImageOperation)
                        
                    }
                } catch {
                    print("Failed to get restaurant image: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        let alertController = UIAlertController(title: "Error", message: "Can not connect to server! Please check your internet!", preferredStyle: .alert)
                        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        self.present(alertController,animated: true, completion: nil)
                    }
                }
            }
            publicDatabase.add(fetchRecordsImageOperation)

            if let team1ID = match.object(forKey: "team1RecordID") as? String {
                let publicDatabase = CKContainer.default().publicCloudDatabase
                publicDatabase.fetch(withRecordID: CKRecord.ID(recordName: team1ID)) { record, error in
                    DispatchQueue.main.async {
                        if let team1 = record {
                            cell.team1NameLabel.text = team1.object(forKey: "name") as? String
                            
                            if let imageFileURL = self.imageCache.object(forKey: team1.recordID) {
                                        // Fetch image from cache
                                print("Get image from cache")
                                if let imageData = try? Data.init(contentsOf: imageFileURL as URL) {
                                    cell.team1logo.image = UIImage(data: imageData)
                                }

                            } else {
                                // Fetch Image from Cloud in background
                                let publicDatabase = CKContainer.default().publicCloudDatabase
                                let fetchRecordsImageOperation = CKFetchRecordsOperation(recordIDs: [team1.recordID])
                                fetchRecordsImageOperation.desiredKeys = ["logo"]
                                fetchRecordsImageOperation.queuePriority = .veryHigh
                                
                                fetchRecordsImageOperation.perRecordResultBlock = { (recordID, result) in
                                    do {
                                        let restaurantRecord = try result.get()
                                        
                                        if let image = restaurantRecord.object(forKey: "logo"),
                                           let imageAsset = image as? CKAsset {
                                            
                                            if let imageData = try? Data.init(contentsOf: imageAsset.fileURL!) {
                                                
                                                // Replace the placeholder image with the restaurant image
                                                DispatchQueue.main.async {
                                                    cell.team1logo.image = UIImage(data: imageData)
                                                    cell.setNeedsLayout()
                                                }
                                                
                                                // Add the image URL to cache
                                                self.imageCache.setObject(imageAsset.fileURL! as NSURL, forKey: team1.recordID)
                                            }
                                        }
                                    } catch {
                                        print("Failed to get team1 image: \(error.localizedDescription)")
                                    }
                                }
                                
                                publicDatabase.add(fetchRecordsImageOperation)
                            }
                            
                        } else {
                            cell.team1NameLabel.text = "Unknown Team"
                        }
                    }
                }
            }

            // Fetch team2
            if let team2ID = match.object(forKey: "team2RecordID") as? String {
                let publicDatabase = CKContainer.default().publicCloudDatabase
                publicDatabase.fetch(withRecordID: CKRecord.ID(recordName: team2ID)) { record, error in
                    DispatchQueue.main.async {
                        if let team2 = record {
                            cell.team2NameLabel.text = team2.object(forKey: "name") as? String
                            
                            if let imageFileURL = self.imageCache.object(forKey: team2.recordID) {
                                        // Fetch image from cache
                                print("Get image from cache")
                                if let imageData = try? Data.init(contentsOf: imageFileURL as URL) {
                                    cell.team2Logo.image = UIImage(data: imageData)
                                }

                            } else {
                                // Fetch Image from Cloud in background
                                let publicDatabase = CKContainer.default().publicCloudDatabase
                                let fetchRecordsImageOperation = CKFetchRecordsOperation(recordIDs: [team2.recordID])
                                fetchRecordsImageOperation.desiredKeys = ["logo"]
                                fetchRecordsImageOperation.queuePriority = .veryHigh
                                
                                fetchRecordsImageOperation.perRecordResultBlock = { (recordID, result) in
                                    do {
                                        let restaurantRecord = try result.get()
                                        
                                        if let image = restaurantRecord.object(forKey: "logo"),
                                           let imageAsset = image as? CKAsset {
                                            
                                            if let imageData = try? Data.init(contentsOf: imageAsset.fileURL!) {
                                                
                                                // Replace the placeholder image with the restaurant image
                                                DispatchQueue.main.async {
                                                    cell.team2Logo.image = UIImage(data: imageData)
                                                    cell.setNeedsLayout()
                                                }
                                                
                                                // Add the image URL to cache
                                                self.imageCache.setObject(imageAsset.fileURL! as NSURL, forKey: team2.recordID)
                                            }
                                        }
                                    } catch {
                                        print("Failed to get restaurant image: \(error.localizedDescription)")
                                    }
                                }
                                
                                publicDatabase.add(fetchRecordsImageOperation)
                            }
                            
                        } else {
                            cell.team2NameLabel.text = "Unknown Team"
                        }
                    }
                }
            }
            
            return cell

            }

        return dataSource
    }
    
    lazy var dataSource = homeConfigureDataSource()
    
    func updateMatchSnapshot(animatingChange: Bool = false){
        var snapshot = NSDiffableDataSourceSnapshot<Section, CKRecord>()
        snapshot.appendSections([.all])
        snapshot.appendItems(matches, toSection: .all)
        
        dataSource.apply(snapshot, animatingDifferences: animatingChange)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "homeMatchDetail" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let destinationController = segue.destination as! MatchDetailViewController
                destinationController.cloudMatch = matches[indexPath.row]
                
            }
        }
    }
}
