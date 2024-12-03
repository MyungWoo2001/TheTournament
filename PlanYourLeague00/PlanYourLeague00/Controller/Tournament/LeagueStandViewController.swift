//
//  LeagueStandViewController.swift
//  PlanYourLeague00
//
//  Created by Myung Woo on 9/29/24.
//

import UIKit
import CoreData
import CloudKit

class LeagueStandViewController: UITableViewController {

    var tournament: CKRecord!
    var league: CKRecord!
    var team: Team!
    var teams: [CKRecord] = []
    var teamsCore: [Team] = []
    
    var tournamentAccess: Bool!
    @IBOutlet var barAddButtonItem: UIBarButtonItem!
    @IBOutlet var barResetButtonItem: UIBarButtonItem!

    
    var spinner = UIActivityIndicatorView()
    
    @IBOutlet var headerView: LeagueStandHeaderView!
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.cleanCoreData()
        
        if let navController = self.navigationController {
            print(navController)
        }
        
        if let tournamentAccess = tournamentAccess {
            barAddButtonItem.isHidden = !tournamentAccess
            barResetButtonItem.isHidden = !tournamentAccess
            navigationItem.centerItemGroups = []
            self.setNeedsStatusBarAppearanceUpdate()
        }

        
        spinner.style = .medium
        spinner.hidesWhenStopped = true
        view.addSubview(spinner)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate( [ spinner.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 150.0),
                                       spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor)])
        spinner.transform = CGAffineTransform(scaleX: 2.0, y: 2.0) // Phóng to spinner lên 2 lần

        spinner.startAnimating()
             
        fetchTeamData()
        fetchRecordsFromCloud(for: league)
        
        tableView.delegate = self
        tableView.dataSource = dataSource
        
        headerView.leagueNameLabel.text = tournament.object(forKey: "shortName") as? String
    
        tableView.rowHeight = 56
    
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        cleanCoreData()
    }

    
    @objc func fetchRecordsFromCloud(for league: CKRecord) {
        // Fetch data using Convenience API
        let cloudContainer = CKContainer.default()
        let publicDatabase = cloudContainer.publicCloudDatabase
        let predicate = NSPredicate(format: "league == %@", league)
        let query = CKQuery(recordType: "Team", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let queryOperation = CKQueryOperation(query: query)
        queryOperation.desiredKeys = ["name","rank","pls","goals","dif","points","logo"]
        queryOperation.queuePriority = .veryHigh
        queryOperation.resultsLimit = 50
        queryOperation.recordMatchedBlock = { (recordID, result) -> Void in
            do {
                if let _ = self.teams.first(where: { $0.recordID == recordID }) {
                    return
                }

                self.teams.append(try result.get())
                
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
                //self.updateSnapshot()
            }
            
            DispatchQueue.main.async {
                self.saveToCoreData(for: self.teams)
                self.updateRank(for: self.teamsCore)
               
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
    
    func saveToCoreData(for teams:[CKRecord]){
        if let appDelegate = (UIApplication.shared.delegate as? AppDelegate) {
            for team in teams {
                let teamForCore = Team(context: appDelegate.persistentContainer.viewContext)
                teamForCore.teamID = "_"
                teamForCore.recordID = team.recordID.recordName
                teamForCore.name = team.object(forKey: "name") as! String
                teamForCore.rank = team.object(forKey: "rank") as! Int
                teamForCore.pls = team.object(forKey: "pls") as! Int
                teamForCore.goals = team.object(forKey: "goals") as! Int
                teamForCore.dif = team.object(forKey: "dif") as! Int
                teamForCore.point = team.object(forKey: "points") as! Int
                
                if let image = team.object(forKey: "logo"), let imageAsset = image as? CKAsset {
                    if let imageData = try? Data.init(contentsOf: imageAsset.fileURL!){
                        teamForCore.logoImage = imageData
                    }
                }
                print("Saving Team to context")
                appDelegate.saveContext()
            }
        }
    }
    
    func cleanCoreData(){
        cleanMatchCoreData()
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Team")
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            // Thực hiện xóa
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
            let context = appDelegate.persistentContainer.viewContext

            try context.execute(batchDeleteRequest)
            try context.save()
            print("Successfully deleted all objects in Team.")
        } catch {
            print("Failed to delete all objects in Team: \(error)")
        }
    }
    func cleanMatchCoreData(){
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Match")
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            // Thực hiện xóa
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
            let context = appDelegate.persistentContainer.viewContext

            try context.execute(batchDeleteRequest)
            try context.save()
            print("Successfully deleted all objects in Match.")
        } catch {
            print("Failed to delete all objects in Match: \(error)")
        }
    }

    
    func updateRank(for teams: [Team]){
        spinner.startAnimating()
        if let appDelegate = (UIApplication.shared.delegate as? AppDelegate){
            for teamForCore in teams {
                                if let rank = teams.firstIndex(of: teamForCore){
                    teamForCore.rank = rank + 1
                }
            }
            appDelegate.saveContext()
        }
        self.updateSnapshot()
        self.updateToCloud(from: self.teamsCore)
        self.spinner.stopAnimating()
        tableView.reloadData()
    }

    func updateToCloud(from coreTeams: [Team]){
        spinner.startAnimating()
        // Lấy reference tới public database
        let publicDatabase = CKContainer.default().publicCloudDatabase
        
        // Fetch record từ CloudKit
        for coreTeam in coreTeams {
            publicDatabase.fetch(withRecordID: (CKRecord.ID(recordName: coreTeam.recordID))) { record, error in
                if let error = error {
                    print("Lỗi khi fetch record: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        let alertController = UIAlertController(title: "Error", message: "Can not connect to server! Please check your internet!", preferredStyle: .alert)
                        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        self.present(alertController,animated: true, completion: nil)
                    }

                    return
                }
                
                guard let record = record else {
                    print("Không tìm thấy record.")
                    return
                }
                
                // Cập nhật giá trị của field
                record.setValue(coreTeam.rank, forKey: "rank")
                record.setValue(coreTeam.pls,forKey: "pls")
                record.setValue(coreTeam.dif,forKey: "dif")
                record.setValue(coreTeam.point,forKey: "points")
                record.setValue(coreTeam.goals,forKey: "goals")
                
                // Lưu lại record sau khi chỉnh sửa
                publicDatabase.save(record) { savedRecord, saveError in
                    if let saveError = saveError {
                        print("Lỗi khi lưu record: \(saveError.localizedDescription)")
                        DispatchQueue.main.async {
                            let alertController = UIAlertController(title: "Error", message: "Can not connect to server! Please check your internet!", preferredStyle: .alert)
                            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                            self.present(alertController,animated: true, completion: nil)
                        }

                    } else {
                        print("Record đã được cập nhật thành công!")
                    }
                }
            }
        }
        self.spinner.stopAnimating()
    }
    
    func deleteRecord(recordID: String) {
        spinner.startAnimating()
        // Lấy CKDatabase (Database có thể là public hoặc private)
        let database = CKContainer.default().publicCloudDatabase
        
        // Gọi phương thức delete để xoá bản ghi
        database.delete(withRecordID: (CKRecord.ID(recordName: recordID))) { (deletedRecordID, error) in
            if let error = error {
                // Xử lý lỗi nếu có
                print("Error deleting record: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    let alertController = UIAlertController(title: "Error", message: "Can not connect to server! Please check your internet!", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alertController,animated: true, completion: nil)
                }

            } else {
                // Thông báo thành công
                print("Record deleted successfully with ID: \(recordID)")
            }
        }
        self.spinner.stopAnimating()
    }
    
    @IBAction func resetButtonTapped(sender: UIButton){
        spinner.startAnimating()
        if let appDelegate = (UIApplication.shared.delegate as? AppDelegate){
            for team in teamsCore {
                team.pls = 0
                team.goals = 0
                team.dif = 0
                team.point = 0
            }
            appDelegate.saveContext()
        }
        updateRank(for: self.teamsCore)
        self.spinner.stopAnimating()
    }
        
    func ConfigureDataSource() -> TeamDiffableDataSource {
        let dataSource = TeamDiffableDataSource(
            tableView: tableView,
            cellProvider: {tableView, indexPath, team in
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: LeagueStandTableViewCell.self)) as! LeagueStandTableViewCell
                
                cell.rankLabel.text = String(team.rank)
                cell.nameLabel.text = team.name
                cell.playsLabel.text = String(team.pls)
                cell.difLabel.text = String(team.dif)
                cell.ptsLabel.text = String(team.point)
                cell.logoImageView.image = UIImage(data: team.logoImage)
                
                return cell
            }
        )
        return dataSource
    }
    
    lazy var dataSource = ConfigureDataSource()
    
    var fetchResultController: NSFetchedResultsController<Team>!
    func fetchTeamData(){
        let fetchRequest: NSFetchRequest<Team> = Team.fetchRequest()
        
        let rankSortDescriptor = NSSortDescriptor(key: "point", ascending: false)
        let difSortDescriptor = NSSortDescriptor(key: "dif", ascending: false)
        let goalsSortDescriptor = NSSortDescriptor(key: "goals", ascending: false)
        let nameSortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        fetchRequest.sortDescriptors = [rankSortDescriptor, difSortDescriptor, goalsSortDescriptor, nameSortDescriptor]
            
        if let appDelegate = (UIApplication.shared.delegate as? AppDelegate) {
            let context = appDelegate.persistentContainer.viewContext
            fetchResultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
            fetchResultController.delegate = self
            
            do {
                try fetchResultController.performFetch()
                updateSnapshot()
            } catch {
                print(error)
            }
        }
        
    }
    
    func updateSnapshot(animatingChange: Bool = false){
        if let fetchedObjects = fetchResultController.fetchedObjects {
            teamsCore = fetchedObjects
        }

        var snapshot = NSDiffableDataSourceSnapshot<Section, Team>()
        snapshot.appendSections([.all])
        snapshot.appendItems(teamsCore, toSection: .all)
        
        dataSource.apply(snapshot, animatingDifferences: animatingChange)
        
    }
    
        
    // MARK: Trailing swipe to open navigation bar
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        // Get the selected league(row)
        guard let team = self.dataSource.itemIdentifier(for: indexPath) else {
            return UISwipeActionsConfiguration()
        }
        
        // Delete Action
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") {
            (action, sourceView, completionHandler) in
            self.deleteRecord(recordID: team.recordID)
            if let appDelegate = (UIApplication.shared.delegate as? AppDelegate) {
                let context = appDelegate.persistentContainer.viewContext
                // Delete the item
                context.delete(team)
                appDelegate.saveContext()
            }
            self.updateRank(for: self.teamsCore)
        }
        deleteAction.backgroundColor = UIColor.systemRed
        deleteAction.image = UIImage(systemName: "trash")
        
        // Configure action as swipe action
        let swipeConfiguration = UISwipeActionsConfiguration(actions: [deleteAction])
        return swipeConfiguration
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "createNewTeam"{
            let destination = segue.destination as! UINavigationController
            if let teamCreateController = destination.viewControllers.first as? TeamsCreateViewController {
                teamCreateController.league = self.league
                teamCreateController.teams = self.teamsCore
                teamCreateController.onDismiss = { [weak self] in
                    if let teamsCore = self?.teamsCore{
                        self?.updateRank(for: teamsCore)
                    }
                }
            }
        }
    }
}

extension LeagueStandViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<any NSFetchRequestResult>) {
        updateSnapshot()
    }
}

