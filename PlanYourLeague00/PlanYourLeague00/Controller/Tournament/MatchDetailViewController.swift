//
//  MatchDetailViewController.swift
//  PlanYourLeague00
//
//  Created by Myung Woo on 10/12/24.
//

import UIKit
import CoreData
import CloudKit

class MatchDetailViewController: UIViewController {
    
    @IBOutlet var tableView: UITableView!
    
    var tournament: CKRecord!
    var league: CKRecord!
    var cloudMatch: CKRecord!
    var team1: Team!
    var team2: Team!
    var match: Match!
    var matchID: NSManagedObjectID?
    
    var keyword: String!
    var tournamentAccess: Bool!
    @IBOutlet var updateButton: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let tournamentAccess = tournamentAccess{
            if !tournamentAccess {
                updateButton.isHidden = !tournamentAccess
            }
        }
        print("minhvuc")
        
        navigationItem.backButtonTitle = "" 

        // Do any additional setup after loading the view.
        tableView.dataSource = self
        tableView.delegate = self
        
        if let matchID = matchID {
            fetchMatch(with: matchID)
        } else {
            let publicDatabase = CKContainer.default().publicCloudDatabase
            let fetchRecordsImageOperation = CKFetchRecordsOperation(recordIDs: [cloudMatch.recordID])
            fetchRecordsImageOperation.desiredKeys = ["team1", "team2"]
            fetchRecordsImageOperation.queuePriority = .veryHigh
            
            fetchRecordsImageOperation.perRecordResultBlock = { (recordID, result) in
                do {
                    let matchRecord = try result.get()
                    if let team1Reference = matchRecord.object(forKey: "team1") as? CKRecord.Reference{
                        let fetchRecordsImageOperation = CKFetchRecordsOperation(recordIDs: [team1Reference.recordID])
                        fetchRecordsImageOperation.desiredKeys = ["teamID","name","rank","pls","goals","dif","points","logo"]
                        fetchRecordsImageOperation.queuePriority = .veryHigh
                        
                        fetchRecordsImageOperation.perRecordResultBlock = { (recordID, result) in
                            do {
                                let team1Record = try result.get()
                                DispatchQueue.main.async {
                                    if let appDelegate = (UIApplication.shared.delegate as? AppDelegate) {
                                        self.team1 = Team(context: appDelegate.persistentContainer.viewContext)
                                        self.team1.teamID = team1Record.recordID.recordName
                                        self.team1.recordID = team1Record.recordID.recordName
                                        self.team1.name = team1Record.object(forKey: "name") as! String
                                        self.team1.rank = team1Record.object(forKey: "rank") as! Int
                                        self.team1.pls = team1Record.object(forKey: "pls") as! Int
                                        self.team1.goals = team1Record.object(forKey: "goals") as! Int
                                        self.team1.dif = team1Record.object(forKey: "dif") as! Int
                                        self.team1.point = team1Record.object(forKey: "points") as! Int
                                            
                                        if let image = team1Record.object(forKey: "logo"), let imageAsset = image as? CKAsset {
                                            if let imageData = try? Data.init(contentsOf: imageAsset.fileURL!){
                                                self.team1.logoImage = imageData
                                            }
                                        print("Saving Team1 to context")
                                        appDelegate.saveContext()
                                        }
                                    }
                                }         
                                if let team2Reference = matchRecord.object(forKey: "team2") as? CKRecord.Reference{
                                    let fetchRecordsImageOperation = CKFetchRecordsOperation(recordIDs: [team2Reference.recordID])
                                    fetchRecordsImageOperation.desiredKeys = ["teamID","name","rank","pls","goals","dif","points","logo"]
                                    fetchRecordsImageOperation.queuePriority = .veryHigh
                                    
                                    fetchRecordsImageOperation.perRecordResultBlock = { (recordID, result) in
                                        do {
                                            let team2Record = try result.get()
                                            DispatchQueue.main.async {
                                                if let appDelegate = (UIApplication.shared.delegate as? AppDelegate) {
                                                    self.team2 = Team(context: appDelegate.persistentContainer.viewContext)
                                                    self.team2.teamID = team2Record.recordID.recordName
                                                    self.team2.recordID = team2Record.recordID.recordName
                                                    self.team2.name = team2Record.object(forKey: "name") as! String
                                                    self.team2.rank = team2Record.object(forKey: "rank") as! Int
                                                    self.team2.pls = team2Record.object(forKey: "pls") as! Int
                                                    self.team2.goals = team2Record.object(forKey: "goals") as! Int
                                                    self.team2.dif = team2Record.object(forKey: "dif") as! Int
                                                    self.team2.point = team2Record.object(forKey: "points") as! Int
                                                    
                                                    if let image = team2Record.object(forKey: "logo"), let imageAsset = image as? CKAsset {
                                                        if let imageData = try? Data.init(contentsOf: imageAsset.fileURL!){
                                                            self.team2.logoImage = imageData
                                                        }
                                                        
                                                    }
                                                    
                                                    self.match = Match(context: appDelegate.persistentContainer.viewContext)
                                                    self.match.recordID = self.cloudMatch.recordID.recordName
                                                    self.match.date = self.cloudMatch.object(forKey: "date") as! String
                                                    self.match.round = self.cloudMatch.object(forKey: "round") as! Int
                                                    self.match.summary = self.cloudMatch.object(forKey: "summary") as! String
                                                    self.match.team1ID = self.cloudMatch.object(forKey: "team1ID") as! String
                                                    self.match.team1RecordID = self.cloudMatch.object(forKey: "team1RecordID") as! String
                                                    self.match.team1Goal = self.cloudMatch.object(forKey: "team1Goal") as! String
                                                    self.match.team2ID = self.cloudMatch.object(forKey: "team2ID") as! String
                                                    self.match.team2RecordID = self.cloudMatch.object(forKey: "team2RecordID") as! String
                                                    self.match.team2Goal = self.cloudMatch.object(forKey: "team2Goal") as! String
                                                    self.match.team1 = self.team1
                                                    self.match.team2 = self.team2
                                                    self.matchID = self.match.objectID
                                                    
                                                    
                                                    print("Saving Team2 and Match to context")
                                                    appDelegate.saveContext()
                                                }
                                                
                                                self.tableView.reloadData()
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
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let matchID = matchID {
            print("Continuing with matchID: \(matchID)")
            // Sử dụng matchID tại đây
        }

        updateMatch()
        tableView.reloadData()
    }
    
    func fetchMatch(with objectID: NSManagedObjectID) {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

        do {
            match = try context.existingObject(with: objectID) as? Match
        } catch {
            print("Can't fetch Match: \(error)")
        }
    }
    
    func updateMatch() {
        // Sau khi cập nhật dữ liệu, fetch lại đối tượng từ CoreData
        
        if let matchID = matchID {
            fetchMatch(with: matchID)
        }
    }
    
}

extension MatchDetailViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            guard let cloudMatch = cloudMatch else {
                print("Match is nil")
                return UITableViewCell() // Hoặc có thể return một cell mặc định
            }
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: MatchDetailRowZeroCell.self)) as! MatchDetailRowZeroCell
            
            cell.leagueNameLabel.text = "The Tounament"
            
            let publicDatabase = CKContainer.default().publicCloudDatabase
            let fetchRecordsImageOperation = CKFetchRecordsOperation(recordIDs: [cloudMatch.recordID])
            fetchRecordsImageOperation.desiredKeys = ["league"]
            fetchRecordsImageOperation.queuePriority = .veryHigh
            
            fetchRecordsImageOperation.perRecordResultBlock = { (recordID, result) in
                do {
                    let matchRecord = try result.get()
                    if let leagueReference = matchRecord.object(forKey: "league") as? CKRecord.Reference{
                        let fetchRecordsImageOperation = CKFetchRecordsOperation(recordIDs: [leagueReference.recordID])
                        fetchRecordsImageOperation.desiredKeys = ["tournament"]
                        fetchRecordsImageOperation.queuePriority = .veryHigh
                        
                        fetchRecordsImageOperation.perRecordResultBlock = { (recordID, result) in
                            do {
                                let leagueRecord = try result.get()
                                DispatchQueue.main.async {
                                    self.league = leagueRecord
                                }
                                if let team2Reference = leagueRecord.object(forKey: "tournament") as? CKRecord.Reference{
                                    let fetchRecordsImageOperation = CKFetchRecordsOperation(recordIDs: [team2Reference.recordID])
                                    fetchRecordsImageOperation.desiredKeys = ["name","shortName","manager","summary","phone","email","image"]
                                    fetchRecordsImageOperation.queuePriority = .veryHigh
                                    
                                    fetchRecordsImageOperation.perRecordResultBlock = { (recordID, result) in
                                        do {
                                            let tournamentRecord = try result.get()
                                            DispatchQueue.main.async {
                                                self.tournament = tournamentRecord
                                                cell.leagueNameLabel.text = self.tournament.object(forKey: "name") as? String
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
            
            return cell
            
        case 1:
            guard let match = match else {
                print("Match is nil")
                return UITableViewCell() // Hoặc có thể return một cell mặc định
            }
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: MatchDetailRowOneCell.self)) as! MatchDetailRowOneCell
            cell.team1NameLabel.text = match.team1.name
            cell.team2NameLabel.text = match.team2.name
            cell.team1GoalLabel.text = match.team1Goal
            cell.team2GoalLabel.text = match.team2Goal
            cell.team1ImageView.image = UIImage(data: match.team1.logoImage)
            cell.team2ImageView.image = UIImage(data: match.team2.logoImage)
            cell.matchdateLabel.text = match.date
            return cell
            
        case 2:
            guard let match = match else {
                print("Match is nil")
                return UITableViewCell() // Hoặc có thể return một cell mặc định
            }
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: MatchDetailRowTwoCell.self)) as! MatchDetailRowTwoCell
            cell.matchSummaryLabel.text = match.summary
            
            return cell
        default:
            fatalError("Failed to instantiate the table cell for detail view controller")

        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard let tournament = self.tournament, indexPath.row == 0 else {
            self.tableView.deselectRow(at: indexPath, animated: true)
            return }
        
        self.performSegue(withIdentifier: "showLeague", sender: tournament)
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "matchUpdate"{
            let destinationVs = segue.destination as! MatchDetailUpdateTableViewController
            destinationVs.match = self.match
            destinationVs.matchID = self.matchID
            destinationVs.onMatchIDUpdate = { [weak self] updatedMatchID in
                self?.matchID = updatedMatchID // Cập nhật matchID khi quay lại
            }
        }
        else  if segue.identifier == "showLeague" {
            let destinationController = segue.destination as! TournamentDetailViewController
            if let tournament = sender as? CKRecord {
                destinationController.tournament = tournament
            }
        }
    }
}
