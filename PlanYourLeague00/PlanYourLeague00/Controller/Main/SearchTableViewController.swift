//
//  LeagueTableViewController.swift
//  PlanYourLeague00
//
//  Created by Myung Woo on 8/28/24.
//

import UIKit
import CoreData
import CloudKit

class SearchTableViewController: UITableViewController {
    
    var tournament: Tournament!
    var tournaments: [CKRecord] = []
    
    var spinner = UIActivityIndicatorView()
    
    private var imageCache = NSCache<CKRecord.ID, NSURL>()
    
    @IBOutlet var searchEmptyView: UIView!
    var searchController: UISearchController!
    
    // MARK: Setting screen display
    // first time
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshControl = UIRefreshControl()
        refreshControl?.backgroundColor = UIColor.white
        refreshControl?.tintColor = UIColor.gray
        refreshControl?.addTarget(self, action: #selector(fetchRecordsFromCloud), for: UIControl.Event.valueChanged)
        
        
        spinner.style = .medium
        spinner.hidesWhenStopped = true
        view.addSubview(spinner)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate( [ spinner.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 120.0),
                                       spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor)])
        spinner.transform = CGAffineTransform(scaleX: 2.0, y: 2.0) // Phóng to spinner lên 2 lần

        
        tableView.backgroundView = searchEmptyView
        tableView.backgroundView?.isHidden = tournaments.count == 0 ? false : true
        
        navigationController?.hidesBarsOnSwipe = true
        
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.tintColor = .black
        tableView.tableHeaderView = searchController.searchBar
        //self.navigationItem.searchController = searchController
        
        fetchRecordsFromCloud()
        tableView.dataSource = dataSource
        
    }
     //first time and later
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.setNavigationBarHidden(false, animated: animated)
        tableView.backgroundView?.isHidden = tournaments.count == 0 ? false : true
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = true
        tableView.backgroundView?.isHidden = tournaments.count == 0 ? false : true
    }
    
    func configureDataSource() -> UITableViewDiffableDataSource<Section, CKRecord> {
        
        let cellIdentifier = "datacell"

        let dataSource = UITableViewDiffableDataSource<Section, CKRecord>(tableView: tableView) { (tableView, indexPath, tournament) -> UITableViewCell? in

            let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! SearchTableViewCell

            cell.nameLabel.text = tournament.object(forKey: "name") as? String
            cell.managerLabel.text = tournament.object(forKey: "manager") as? String
            cell.summaryLabel.text = tournament.object(forKey: "summary") as? String
            
            cell.thumbnailImageView.image = UIImage(systemName: "photo")
            cell.thumbnailImageView.tintColor = .black
            
            if let imageFileURL = self.imageCache.object(forKey: tournament.recordID) {
                // Fetch image from cache
                print("Get image from cache")
                if let imageData = try? Data.init(contentsOf: imageFileURL as URL) {
                    cell.thumbnailImageView.image = UIImage(data: imageData)
                }

            } else {
                print("fetch")
                // Fetch Image from Cloud in background
                let publicDatabase = CKContainer.default().publicCloudDatabase
                let fetchRecordsImageOperation = CKFetchRecordsOperation(recordIDs: [tournament.recordID])
                fetchRecordsImageOperation.desiredKeys = ["image"]
                fetchRecordsImageOperation.queuePriority = .veryHigh
                
                fetchRecordsImageOperation.perRecordResultBlock = { (recordID, result) in
                    do {
                        let restaurantRecord = try result.get()
                        
                        if let image = restaurantRecord.object(forKey: "image"),
                           let imageAsset = image as? CKAsset {
                            
                            if let imageData = try? Data.init(contentsOf: imageAsset.fileURL!) {
                                
                                // Replace the placeholder image with the restaurant image
                                DispatchQueue.main.async {
                                    cell.thumbnailImageView.image = UIImage(data: imageData)
                                    cell.setNeedsLayout()
                                }
                                
                                // Add the image URL to cache
                                self.imageCache.setObject(imageAsset.fileURL! as NSURL, forKey: tournament.recordID)
                            }
                        }
                    } catch {
                        print("Failed to get restaurant image: \(error.localizedDescription)")
                    }
                }
                
                publicDatabase.add(fetchRecordsImageOperation)
            }
            
            return cell
        }

        return dataSource
    }
    
    lazy var dataSource = configureDataSource()
    
    @objc func fetchRecordsFromCloud() {
        spinner.startAnimating()
        tournaments.removeAll()

        // Fetch data using Convenience API
        let cloudContainer = CKContainer.default()
        let publicDatabase = cloudContainer.publicCloudDatabase
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "Tournament", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let queryOperation = CKQueryOperation(query: query)
        queryOperation.desiredKeys = ["AccessPassword","name","shortName","manager","summary","phone","email","image"]
        queryOperation.queuePriority = .veryHigh
        queryOperation.resultsLimit = 50
        queryOperation.recordMatchedBlock = { (recordID, result) -> Void in
            do {
                if let _ = self.tournaments.first(where: { $0.recordID == recordID }) {
                    return
                }

                self.tournaments.append(try result.get())
                
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
                self.updateSnapshot()
            }
            
            DispatchQueue.main.async {
                self.tableView.backgroundView?.isHidden = self.tournaments.count == 0 ? false : true
                self.spinner.stopAnimating()
                
                if let refreshControl = self.refreshControl {
                    if refreshControl.isRefreshing {
                        refreshControl.endRefreshing()
                    }
                }
            }
        }
        publicDatabase.add(queryOperation)
    }
    
    @objc func fetchRecordsFromCloud1(searchText: String = "") {

        tournaments.removeAll()
        // Fetch data using Convenience API
        let cloudContainer = CKContainer.default()
        let publicDatabase = cloudContainer.publicCloudDatabase
        var predicate = NSPredicate(value: true)
        
        
        if !searchText.isEmpty {
            predicate = NSPredicate(format: "name == %@", searchText)
        }
        
        //let predicate = NSPredicate(format: "name CONTAINS %@", "The Tournament App")
        let query = CKQuery(recordType: "Tournament", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let queryOperation = CKQueryOperation(query: query)
        queryOperation.desiredKeys = ["AccessPassword","name","shortName","manager","summary","phone","email","image"]
        queryOperation.queuePriority = .veryHigh
        queryOperation.resultsLimit = 50
        queryOperation.recordMatchedBlock = { (recordID, result) -> Void in
            do {
                if let _ = self.tournaments.first(where: { $0.recordID == recordID }) {
                    return
                }

                self.tournaments.append(try result.get())
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
                print("Successfully retrieve the data from iCloud1")
                self.updateSnapshot()
            }
            
            DispatchQueue.main.async {
                self.spinner.stopAnimating()
                
                if let refreshControl = self.refreshControl {
                    if refreshControl.isRefreshing {
                        refreshControl.endRefreshing()
                    }
                }
            }
        }
        publicDatabase.add(queryOperation)
    }
    
    func updateSnapshot(animatingChange: Bool = false){
        var snapshot = NSDiffableDataSourceSnapshot<Section, CKRecord>()
        snapshot.appendSections([.all])
        snapshot.appendItems(tournaments, toSection: .all)
        
        dataSource.apply(snapshot,animatingDifferences: false)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showTournamentDetail" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let destinationController = segue.destination as! TournamentDetailViewController
                destinationController.tournament = self.tournaments[indexPath.row]
                destinationController.ondismiss = {[ weak self] in
                    self?.tableView.reloadData()
                    if let recordID = self?.tournaments[indexPath.row].recordID {
                        self?.imageCache.removeObject(forKey: recordID)
                    }
                }
                destinationController.ondismiss1 = { [weak self] in
                    self?.fetchRecordsFromCloud()
                }
            }
        }
    }
}

extension SearchTableViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text else {
            return
        }
        fetchRecordsFromCloud1(searchText: searchText)
    }
}


