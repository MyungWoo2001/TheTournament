//
//  LeagueMatchesTableViewController.swift
//  PlanYourLeague00
//
//  Created by Myung Woo on 10/8/24.
//

import UIKit
import CoreData
import CloudKit

class LeagueMatchesTableViewController: UITableViewController {

    var tournament: CKRecord!
    var league: CKRecord!
    var team: Team!
    var cloudTeams: [CKRecord] = []
    var coreTeams: [Team] = []
    var cloudMatches: [CKRecord] = []
    var coreMatches: [Match] = []
    
    var tournamentAccess: Bool!
    
    var spinner = UIActivityIndicatorView()
    
    @IBOutlet var headerView: MatchesTabHeaderView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        

        spinner.style = .medium
        spinner.hidesWhenStopped = true
        view.addSubview(spinner)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate( [ spinner.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 150.0),
                                       spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor)])
        spinner.transform = CGAffineTransform(scaleX: 2.0, y: 2.0) // Phóng to spinner lê
        
        if let tournamentAccess = tournamentAccess{
            if !tournamentAccess {
                navigationItem.centerItemGroups = []
            }
        }
        
        navigationItem.backButtonTitle = ""
        cleanTeamCoreData()
        
        //Do any additional setup after loading the view.
        fetchTeamData()
        fetchMatchData()
        fetchRecordsFromCloudForMatch(for: league)
        
        headerView.tournamentNameLabel.text = tournament.object(forKey: "shortName") as? String
        
        tableView.dataSource = matchDataSource
        tableView.delegate = self
    }
        
    @objc func fetchRecordsFromCloudForMatch(for league: CKRecord) {
        spinner.startAnimating()
        // Fetch data using Convenience API
        let cloudContainer = CKContainer.default()
        let publicDatabase = cloudContainer.publicCloudDatabase
        let predicate = NSPredicate(format: "league == %@", league)
        let query = CKQuery(recordType: "Match", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let queryOperation = CKQueryOperation(query: query)
        queryOperation.desiredKeys = ["date","round","summary","team1","team1ID","team1RecordID","team1Goal","team2","team2ID","team2RecordID","team2Goal"]
        queryOperation.queuePriority = .veryHigh
        queryOperation.resultsLimit = 50
        queryOperation.recordMatchedBlock = { (recordID, result) -> Void in
            do {
                if let _ = self.cloudMatches.first(where: { $0.recordID == recordID }) {
                    return
                }

                self.cloudMatches.append(try result.get())
                
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
            }
            
            DispatchQueue.main.async {
                self.fetchRecordsFromCloudForTeam(for: self.league, key: self.cloudMatches.isEmpty)
            }
        }
        publicDatabase.add(queryOperation)
    }
    
    @objc func fetchRecordsFromCloudForTeam(for league: CKRecord,key empty: Bool) {
        // Fetch data using Convenience API
        let cloudContainer = CKContainer.default()
        let publicDatabase = cloudContainer.publicCloudDatabase
        let predicate = NSPredicate(format: "league == %@", league)
        let query = CKQuery(recordType: "Team", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let queryOperation = CKQueryOperation(query: query)
        queryOperation.desiredKeys = ["teamID","name","rank","pls","goals","dif","points","logo"]
        queryOperation.queuePriority = .veryHigh
        queryOperation.resultsLimit = 50
        queryOperation.recordMatchedBlock = { (recordID, result) -> Void in
            do {
                if let _ = self.cloudTeams.first(where: { $0.recordID == recordID }) {
                    return
                }

                self.cloudTeams.append(try result.get())
                
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
                print("Successfully retrieve the data of Team from iCloud")
                //self.updateSnapshot()
            }
            
            DispatchQueue.main.async {
                self.saveTeamToCoreData(for: self.cloudTeams)
                print("coreteam after fetch and saveing to context: ", self.coreTeams.count)
                if empty == true {
                    if self.cloudTeams.count >= 4 {
                        self.generalGames(for: self.coreTeams, Turn: false)
                        self.updateTeamToCloud(from: self.coreTeams)
                    }
                } else {
                    self.saveMatchToCoreData(for: self.cloudMatches)
                }
                self.spinner.stopAnimating()
//                if let refreshControl = self.refreshControl {
//                    if refreshControl.isRefreshing {
//                        refreshControl.endRefreshing()
//                    }
//                }
            }
        }
        publicDatabase.add(queryOperation)
    }
    
    func saveTeamToCoreData(for teams:[CKRecord]){
        if let appDelegate = (UIApplication.shared.delegate as? AppDelegate) {
            for team in teams {
                let teamForCore = Team(context: appDelegate.persistentContainer.viewContext)
                teamForCore.teamID = team.recordID.recordName
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
    
    func saveMatchToCoreData(for matches:[CKRecord]){
        if let appDelegate = (UIApplication.shared.delegate as? AppDelegate) {
            //let context = appDelegate.persistentContainer.viewContext
            for match in matches {
                let matchForCore = Match(context: appDelegate.persistentContainer.viewContext)
                matchForCore.recordID = match.recordID.recordName
                matchForCore.date = match.object(forKey: "date") as! String
                matchForCore.round = match.object(forKey: "round") as! Int
                matchForCore.summary = match.object(forKey: "summary") as! String
                matchForCore.team1ID = match.object(forKey: "team1ID") as! String
                matchForCore.team1RecordID = match.object(forKey: "team1RecordID") as! String
                matchForCore.team1Goal = match.object(forKey: "team1Goal") as! String
                matchForCore.team2ID = match.object(forKey: "team2ID") as! String
                matchForCore.team2RecordID = match.object(forKey: "team2RecordID") as! String
                matchForCore.team2Goal = match.object(forKey: "team2Goal") as! String
                
                if let team1 = fetchTeamDataByTeamID(for: match.object(forKey: "team1ID") as! String){
                    matchForCore.team1 = team1
                }
                if let team2 = fetchTeamDataByTeamID(for: match.object(forKey: "team2ID") as! String){
                    matchForCore.team2 = team2
                }
            
                print("Saving Match to context")
                appDelegate.saveContext()
            }
        }
    }
    
    func generalGames(for teams: [Team], Turn turn: Bool) {
        var rounds: Int
        let totalTeam = teams.count
        var insertIndex = 0
        
        if totalTeam < 4 {
            return
        } else {
            if totalTeam % 2 == 0 {
                rounds = totalTeam - 1
                insertIndex = 1
                createMatch(for: teams,Round: rounds, InsertIndex: insertIndex, Turn: turn)
            } else {
                rounds = totalTeam
                insertIndex = 0
                createMatch(for: teams,Round: rounds, InsertIndex: insertIndex, Turn: turn)
            }
        }
    }
                
    func createMatch(for teams:[Team], Round rounds: Int, InsertIndex insertIndex: Int, Turn turn: Bool) {
        var teamsCopy = teams
        var match: Match!
        var matches: [Match] = []
        var index = 0
        for round in 0..<rounds {
            for matchIndex in 0..<Int(teamsCopy.count/2) {
                if let appDelegate = (UIApplication.shared.delegate as? AppDelegate) {
                    match = Match(context: appDelegate.persistentContainer.viewContext)
                    match.recordID = "_"
                    match.round = round
                    match.index = index
                    match.summary = "___"
                    match.date = "..."
                    match.team1 = teamsCopy[matchIndex]
                    match.team1ID = teamsCopy[matchIndex].teamID
                    match.team1RecordID = teamsCopy[matchIndex].recordID
                    match.team1Goal = "_"
                    match.team2ID = teamsCopy[teamsCopy.count - 1 - matchIndex].teamID
                    match.team2 = teamsCopy[teamsCopy.count - 1 - matchIndex]
                    match.team2RecordID = teamsCopy[teamsCopy.count - 1 - matchIndex].recordID
                    match.team2Goal = "_"
                    print("Saving Match to context")
                    appDelegate.saveContext()
                    matches.append(match)
                    index += 1
                }
                saveMatchToCloud(match: match)
            }
            let lastTeam = teamsCopy.removeLast()
            teamsCopy.insert(lastTeam, at: insertIndex)
            updateMatchSnapshot()
        }
        
        if turn == true {
            for matchh in matches {
                if let appDelegate = (UIApplication.shared.delegate as? AppDelegate) {
                    match = Match(context: appDelegate.persistentContainer.viewContext)
                    match.recordID = "_"
                    match.round = matchh.round + rounds
                    match.index = index
                    match.summary = "___"
                    match.date = "..."
                    match.team1 = matchh.team2
                    match.team1ID = matchh.team2ID
                    match.team1RecordID = matchh.team2RecordID
                    match.team1Goal = "_"
                    match.team2 = matchh.team1
                    match.team2ID = matchh.team1ID
                    match.team2RecordID = matchh.team1RecordID
                    match.team2Goal = "_"
                    print("Saving Match to context")
                    appDelegate.saveContext()
                    matches.append(match)
                    index += 1
                }
                saveMatchToCloud(match: match)
            }
        }
    }
    
    func saveMatchToCloud(match: Match) {
        // Get the Public iCloud Database
        let publicDatabase = CKContainer.default().publicCloudDatabase
        // Prepare the record to save
        let record = CKRecord(recordType: "Match")
        
        if let appDelegate = (UIApplication.shared.delegate as? AppDelegate){
            match.recordID = record.recordID.recordName
            appDelegate.saveContext()
        }

        record.setValue(match.date, forKey: "date")
        record.setValue(match.round, forKey: "round")
        record.setValue(match.summary, forKey: "summary")
        record.setValue(match.team1ID, forKey: "team1ID")
        record.setValue(match.team1RecordID, forKey: "team1RecordID")
        record.setValue(match.team1Goal, forKey: "team1Goal")
        record.setValue(match.team2ID, forKey: "team2ID")
        record.setValue(match.team2RecordID, forKey: "team2RecordID")
        record.setValue(match.team2Goal, forKey: "team2Goal")
     
        // Fetch record Tournament để tham chiếu
        let team1ID = CKRecord.ID(recordName: match.team1.recordID )
        let team1Reference = CKRecord.Reference(recordID: team1ID, action: .deleteSelf)
        let team2ID = CKRecord.ID(recordName: match.team2.recordID )
        let team2Reference = CKRecord.Reference(recordID: team2ID, action: .deleteSelf)
        // Fetch record Tournament để tham chiếu
        let leagueID = CKRecord.ID(recordName: league.recordID.recordName )
        let LeagueReference = CKRecord.Reference(recordID: leagueID, action: .deleteSelf)

        // Gán giá trị cho trường league
        record["league"] = LeagueReference
        record["team1"] = team1Reference
        record["team2"] = team2Reference

        // Save the record to iCloud
        publicDatabase.save(record, completionHandler: { (record, error) -> Void  in
            if error != nil {
                print(error.debugDescription)
                DispatchQueue.main.async {
                    let alertController = UIAlertController(title: "Error", message: "Can not connect to server! Please check your internet!", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alertController,animated: true, completion: nil)
                }

            }
            DispatchQueue.main.async{
                print("Success to save Match to Cloud")
                //self.onDismiss?()
            }
            
        })
    }
    
    func updateTeamToCloud(from corematches: [Team]){
        // Lấy reference tới public database
        let publicDatabase = CKContainer.default().publicCloudDatabase
        
        // Fetch record từ CloudKit
        for coreTeam in corematches {
            publicDatabase.fetch(withRecordID: (CKRecord.ID(recordName: coreTeam.recordID))) { record, error in
                if let error = error {
                    print("Lỗi khi fetch record: \(error.localizedDescription)")
                    return
                }
                
                guard let record = record else {
                    print("Không tìm thấy record.")
                    return
                }
                
                // Cập nhật giá trị của field
                record.setValue(coreTeam.teamID, forKey: "teamID")
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
    }
    
    func cleanTeamCoreData(){
        cleanMatchCoreData()
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Team")
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            // Thực hiện xóa
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
            let context = appDelegate.persistentContainer.viewContext

            try context.execute(batchDeleteRequest)
            try context.save()
            fetchTeamData()
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
            fetchMatchData()
            print("matches: ", self.coreMatches.count)
            print("teams: ", self.coreTeams.count)
            print("Successfully deleted all objects in Match: ")
        } catch {
            print("Failed to delete all objects in Match: \(error)")
        }
        tableView.reloadData()
    }
    
    func cleanMatchCloud(){
        let publicDatabase = CKContainer.default().publicCloudDatabase
        
        for match in self.coreMatches {
            // Thực hiện xóa bản ghi
            publicDatabase.delete(withRecordID: CKRecord.ID(recordName: match.recordID)) { deletedRecordID, error in
                if let error = error {
                    print("Error deleting record: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        let alertController = UIAlertController(title: "Error", message: "Can not connect to server! Please check your internet!", preferredStyle: .alert)
                        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        self.present(alertController,animated: true, completion: nil)
                    }

                } else if let deletedRecordID = deletedRecordID {
                    DispatchQueue.main.async {
                        if let appDelegate = (UIApplication.shared.delegate as? AppDelegate){
                            let context = appDelegate.persistentContainer.viewContext
                            context.delete(match)
                            appDelegate.saveContext()
                        }
                    }
                    print("Successfully deleted record with ID: \(deletedRecordID.recordName)")
                }
            }
        }
        self.cloudMatches.removeAll()
    }
    
    @IBAction func singleRoundButtonTapped(sender: UIButton){
        //self.cleanMatchCoreData()
        self.cleanMatchCloud()
        generalGames(for: coreTeams, Turn: false)
    }
    
    @IBAction func doubleRoundButtonTapped(sender: UIButton){
        //self.cleanMatchCoreData()
        self.cleanMatchCloud()
        generalGames(for: coreTeams, Turn: true)
    }

    var fetchTeamByIDResultController: NSFetchedResultsController<Team>!
    func fetchTeamDataByTeamID(for teamID: String) -> Team?{
        let fetchRequest: NSFetchRequest<Team> = Team.fetchRequest()
        
        let sortDescriptor = NSSortDescriptor(key: "rank", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchRequest.predicate = NSPredicate(format: "teamID == %@", teamID)
        
        if let appDelegate = (UIApplication.shared.delegate as? AppDelegate) {
            let context = appDelegate.persistentContainer.viewContext
            fetchTeamByIDResultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
            fetchTeamByIDResultController.delegate = self
            
            do {
                try fetchTeamByIDResultController.performFetch()
                return fetchTeamByIDResultController.fetchedObjects?.first
            } catch {
                print(error)
                
            }
        }
        return nil
    }
    
    var fetchTeamResultController: NSFetchedResultsController<Team>!
    func fetchTeamData(){
        let fetchRequest: NSFetchRequest<Team> = Team.fetchRequest()
        
        let sortDescriptor = NSSortDescriptor(key: "rank", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        if let appDelegate = (UIApplication.shared.delegate as? AppDelegate) {
            let context = appDelegate.persistentContainer.viewContext
            fetchTeamResultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
            fetchTeamResultController.delegate = self
            
            do {
                try fetchTeamResultController.performFetch()
                updateTeamSnapshot()
            } catch {
                print(error)
            }
        }
    }
    

    func updateTeamSnapshot(animatingChange: Bool = false){
        if let fetchedObjects = fetchTeamResultController.fetchedObjects {
            coreTeams = fetchedObjects
        }
    }
    
    // Match------------------------------------------------------------------
    func matchConfigureDataSource() -> MatchDiffableDataSource {
        let dataSource = MatchDiffableDataSource(
            tableView: tableView,
            cellProvider: {tableView, indexPath, match in
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: MatchesTableViewCell.self)) as! MatchesTableViewCell
                cell.team1Label.text = match.team1.name
                cell.team2label.text = match.team2.name
                cell.goal1Label.text = match.team1Goal
                cell.goal2Label.text = match.team2Goal
                cell.matchDateLabel.text = match.date
                cell.logo1ImageView.image = UIImage(data: match.team1.logoImage)
                cell.logo2ImageView.image = UIImage(data: match.team2.logoImage)
                return cell
                
            }
        )
        return dataSource
    }
    lazy var matchDataSource = matchConfigureDataSource()

    var fetchMatchResultController: NSFetchedResultsController<Match>!
    func fetchMatchData(){
        let fetchRequest: NSFetchRequest<Match> = Match.fetchRequest()
        
        let sortDescriptor = NSSortDescriptor(key:"round", ascending: true)

        fetchRequest.sortDescriptors = [sortDescriptor]
        
        if let appDelegate = (UIApplication.shared.delegate as? AppDelegate) {
            let context = appDelegate.persistentContainer.viewContext
            fetchMatchResultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: "round" , cacheName: nil)
            fetchMatchResultController.delegate = self
            
            do {
                try fetchMatchResultController.performFetch()
                updateMatchSnapshot()
            } catch {
                print(error)
            }
        }
    }
    func updateMatchSnapshot(animatingChange: Bool = false){
        if let fetchedObjects = fetchMatchResultController.fetchedObjects {
            coreMatches = fetchedObjects
        }
        
        guard let sections = fetchMatchResultController.sections else { return }
        
        var matchSnapshot = NSDiffableDataSourceSnapshot<Int, Match>()
        
        for section in sections {
            if let round = Int(section.name), let matchesInSection = section.objects as? [Match] {
                matchSnapshot.appendSections([round])
                matchSnapshot.appendItems(matchesInSection, toSection: round)
            }
        }
        
        matchDataSource.apply(matchSnapshot, animatingDifferences: animatingChange)
        
        // Reload toàn bộ headers để đảm bảo chúng hiển thị đúng
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
        
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30 // Đặt chiều cao của khoảng cách giữa các section
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = .white // Đặt màu nền cho header
        
        let label = UILabel()
        label.text = "Round \(section + 1)" // Hiển thị số round, thay đổi cách lấy dữ liệu nếu cần
        label.textColor = .black
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        headerView.addSubview(label)
        
        // Đặt constraints cho label
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            label.centerYAnchor.constraint(equalTo: headerView.centerYAnchor)
        ])
        
        return headerView
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showMatchDetail" {
            let destinationController = segue.destination as! MatchDetailViewController
            destinationController.tournament = self.tournament
            destinationController.league = self.league
            destinationController.tournamentAccess = self.tournamentAccess
            if let destinationIndex = tableView.indexPathForSelectedRow {
                destinationController.matchID = self.coreMatches[(destinationIndex.section*(self.coreTeams.count/2) + destinationIndex.row)].objectID
            }
        }
    }

}

extension LeagueMatchesTableViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<any NSFetchRequestResult>) {
        if controller == fetchMatchResultController {
            updateMatchSnapshot()
        } else if controller == fetchTeamResultController {
            updateTeamSnapshot()
        }
    }
}
