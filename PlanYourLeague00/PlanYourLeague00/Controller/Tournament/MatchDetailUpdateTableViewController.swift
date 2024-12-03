//
//  MatchDetailUpdateTableViewController.swift
//  PlanYourLeague00
//
//  Created by Myung Woo on 10/12/24.
//

import UIKit
import CoreData
import CloudKit

class MatchDetailUpdateTableViewController: UITableViewController {
    
    var match: Match!
    var matchID: NSManagedObjectID?
    var onMatchIDUpdate: ((NSManagedObjectID) -> Void)?
    
    @IBOutlet var tableViewCell: MatchDetailUpdateCell!


    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if self.isMovingFromParent {
            if let matchID = matchID {
                onMatchIDUpdate?(matchID) // Gọi closure khi quay lại
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        tableViewCell.team1NameLabel.text = match.team1.name
        tableViewCell.team2NameLabel.text = match.team2.name
        tableViewCell.team1LogoImageView.image = UIImage(data: match.team1.logoImage)
        tableViewCell.team2LogoImageView.image = UIImage(data: match.team2.logoImage)
        
    }
        
    @IBOutlet var team1GoalTextField: RounderTextView! {
        didSet {
            team1GoalTextField.tag = 1
            team1GoalTextField.becomeFirstResponder()
            team1GoalTextField.delegate = self
            team1GoalTextField.keyboardType = .numberPad
        }
    }
    @IBOutlet var team2GoalTextField: RounderTextView! {
        didSet {
            team2GoalTextField.tag = 2
            team2GoalTextField.delegate = self
            team2GoalTextField.keyboardType = .numberPad
        }
    }
    @IBOutlet var matchSummaryTextView: UITextView! {
        didSet {
            matchSummaryTextView.tag =  3
            matchSummaryTextView.layer.cornerRadius = 10.0
            matchSummaryTextView.layer.masksToBounds = true
        }
    }
  
    @IBOutlet var datePicker: UIDatePicker!
    var selectedDate: String = ""
    @IBAction func dateChanged(_ sender: UIDatePicker) {
       // Lấy ngày giờ từ DatePicker
        let selectedDate = sender.date
       
       // Định dạng ngày giờ để hiển thị
        let formatter = DateFormatter()
        formatter.dateStyle = .medium // Định dạng ngày tháng (ví dụ: Oct 18, 2024)
        formatter.timeStyle = .short  // Định dạng giờ phút (ví dụ: 7:30 AM)
       
       // Cập nhật Label với giá trị ngày giờ đã chọn
        self.selectedDate = formatter.string(from: selectedDate)
   }
    
    @IBAction func saveButtonTapped(sender: UIButton) {

        if team1GoalTextField.text == "" && team2GoalTextField.text != "" ||  team1GoalTextField.text != "" && team2GoalTextField.text == ""{
            let alertController = UIAlertController(title: "You can not fill only 1 team goals", message: "Fill both of 2 teams's goal to update match's result OR don't fill any goals to only update match information!", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "OK",style: .default){_ in
                self.team1GoalTextField.text = ""
                self.team2GoalTextField.text = ""
            }
            alertController.addAction(cancelAction)
            self.present(alertController,animated: true, completion: nil)
            return
        } else if team1GoalTextField.text == "" , team2GoalTextField.text == "" {
            if let appDelegate = (UIApplication.shared.delegate as? AppDelegate) {
                match.team1Goal = "_"
                match.team2Goal = "_"
                match.date = selectedDate
                match.summary = matchSummaryTextView.text!
                
                print("Update match information!!!")
                appDelegate.saveContext()
            }
            let publicDatabase = CKContainer.default().publicCloudDatabase
            
            publicDatabase.fetch(withRecordID: CKRecord.ID(recordName: match.recordID)){ record, error in
            
                if let error = error {
                    print( "fail to fetch record: ", error)
                    self.alertError()
                }
                
                guard let record = record else {
                    print("Can't find record")
                    self.alertError()
                    return
                }
                record.setValue(self.match.date, forKey: "date")
                record.setValue(self.match.summary, forKey: "summary")
                record.setValue(self.match.team1Goal, forKey: "team1Goal")
                record.setValue(self.match.team2Goal, forKey: "team2Goal")
                
                publicDatabase.save(record){ saveRecord, saveError in
                    if let saveError = saveError {
                        print("Fail to update Match to Cloud!: \(saveError.localizedDescription)")
                        self.alertError()
                    } else {
                        print("Success to update Match to Cloud!")
                    }
                }
            }

        } else if team1GoalTextField.text != "" && team2GoalTextField.text != ""{
            if let appDelegate = (UIApplication.shared.delegate as? AppDelegate) {
                
                if (match.team1Goal == "_"){
                    match.team1.pls += 1
                    match.team2.pls += 1
                } else {
                    if  let team1goal = Int(match.team1Goal), let team2goal = Int(match.team2Goal){
                        match.team1.dif -= (team1goal - team2goal)
                        match.team1.goals -= team1goal
                        match.team2.dif -= (team2goal - team1goal)
                        match.team2.goals -= team2goal

                        if team1goal > team2goal {
                            match.team1.point -= 3
                        } else if team1goal == team2goal {
                            match.team1.point -= 1
                            match.team2.point -= 1
                        } else {
                            match.team2.point -= 3
                        }
                    }
                }
                if let team1goaltext = team1GoalTextField.text, let team1goal = Int(team1goaltext), let team2goaltext = team2GoalTextField.text, let team2goal = Int(team2goaltext){
                    match.team1.dif += (team1goal - team2goal)
                    match.team1.goals += team1goal
                    match.team2.dif += (team2goal - team1goal)
                    match.team2.goals += team2goal
                    
                    if team1goal > team2goal {
                        match.team1.point += 3
                    } else if team1goal == team2goal {
                        match.team1.point += 1
                        match.team2.point += 1
                    } else {
                        match.team2.point += 3
                    }
                }
                match.team1Goal = team1GoalTextField.text!
                match.team2Goal = team2GoalTextField.text!
                match.date = selectedDate
                match.summary = matchSummaryTextView.text!
                
                print("Update match information!!!")
                appDelegate.saveContext()
            }
            updateToCloud(for: match)
        }
        navigationController?.popViewController(animated: true)
    }
    
    func updateToCloud(for match: Match){
        let publicDatabase = CKContainer.default().publicCloudDatabase
        
        publicDatabase.fetch(withRecordID: CKRecord.ID(recordName: match.recordID)){ record, error in
        
            if let error = error {
                print( "fail to fetch record: ", error)
                self.alertError()
            }
            
            guard let record = record else {
                print("Can't find record")
                self.alertError()
                return
            }
            record.setValue(match.date, forKey: "date")
            record.setValue(match.summary, forKey: "summary")
            record.setValue(match.team1Goal, forKey: "team1Goal")
            record.setValue(match.team2Goal, forKey: "team2Goal")
            
            publicDatabase.save(record){ saveRecord, saveError in
                if let saveError = saveError {
                    print("Fail to update Match to Cloud!: \(saveError.localizedDescription)")
                    self.alertError()
                } else {
                    print("Success to update Match to Cloud!")
                }
            }
        }
        
        publicDatabase.fetch(withRecordID: CKRecord.ID(recordName: match.team1.recordID)){ record, error in
        
            if let error = error {
                print( "fail to fetch record: ", error)
                self.alertError()
            }
            
            guard let record = record else {
                print("Can't find record")
                self.alertError()
                return
            }
            record.setValue(match.team1.goals, forKey: "goals")
            record.setValue(match.team1.dif, forKey: "dif")
            record.setValue(match.team1.point, forKey: "points")
            record.setValue(match.team1.pls, forKey: "pls")
            
            publicDatabase.save(record){ saveRecord, saveError in
                if let saveError = saveError {
                    print("Fail to update Team1 of Match to Cloud!: \(saveError.localizedDescription)")
                    self.alertError()
                } else {
                    print("Success to update Team1 Match to Cloud!")
                }
            }
        }
        publicDatabase.fetch(withRecordID: CKRecord.ID(recordName: match.team2.recordID)){ record, error in
        
            if let error = error {
                print( "fail to fetch record: ", error)
                self.alertError()
            }
            
            guard let record = record else {
                print("Can't find record")
                return
            }
            record.setValue(match.team2.goals, forKey: "goals")
            record.setValue(match.team2.dif, forKey: "dif")
            record.setValue(match.team2.point, forKey: "points")
            record.setValue(match.team2.pls, forKey: "pls")
            
            publicDatabase.save(record){ saveRecord, saveError in
                if let saveError = saveError {
                    print("Fail to update Team2 of Match to Cloud!: \(saveError.localizedDescription)")
                    self.alertError()
                } else {
                    print("Success to update Team2 Match to Cloud!")
                }
            }
        }
    }
    
    func alertError(){
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: "Error", message: "Can not connect to server! Please check your internet!", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alertController,animated: true, completion: nil)
        }
    }
}

extension MatchDetailUpdateTableViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let nextTextFiew = view.viewWithTag(textField.tag + 1) {
            textField.resignFirstResponder()
            nextTextFiew.becomeFirstResponder()
        }
        
        return true
    }
    
    // Delegate method để giới hạn chỉ nhập số
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Chỉ cho phép ký tự số
        let allowedCharacters = CharacterSet.decimalDigits
        let characterSet = CharacterSet(charactersIn: string)
        return allowedCharacters.isSuperset(of: characterSet)
    }
}


