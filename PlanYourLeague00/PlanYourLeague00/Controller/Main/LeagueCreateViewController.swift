//
//  TeamsCreateViewController.swift
//  PlanYourLeague00
//
//  Created by Myung Woo on 10/2/24.
//

import UIKit
import CloudKit

class LeagueCreateViewController: UITableViewController {
    
    var tournament: CKRecord!
    
    var onDismiss: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Dismiss the keyboard
        let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @IBOutlet var leagueNameTextField: RounderTextView! {
        didSet {
            leagueNameTextField.tag = 1
            leagueNameTextField.becomeFirstResponder()
            leagueNameTextField.delegate = self
        }
    }
    
    @IBAction func saveButtonTapped(sender: UIButton){
        if leagueNameTextField.text == "" {
            let alertController = UIAlertController(title: "Sorry", message: "You have to fill team name", preferredStyle: .alert)
            let alertAction = UIAlertAction(title: "OK", style: .default, handler:  nil)
            alertController.addAction(alertAction)
            present(alertController, animated: true, completion: nil)
            return
        }
        
        // Prepare the record to save
        let record = CKRecord(recordType: "League")
        record.setValue(leagueNameTextField.text, forKey: "name")
        record.setValue(0, forKey: "teamCount")

        // Fetch record Tournament để tham chiếu
        let tournamentID = CKRecord.ID(recordName: tournament.recordID.recordName )
        let tournamentReference = CKRecord.Reference(recordID: tournamentID, action: .deleteSelf)

        // Gán giá trị cho trường tournament
        record["tournament"] = tournamentReference

        // Get the Public iCloud Database
        let publicDatabase = CKContainer.default().publicCloudDatabase

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
            DispatchQueue.main.async {
                // Call onDismiss after save is complete
                self.onDismiss?()
                // Dismiss the view controller after saving is done
                self.dismiss(animated: true, completion: nil)
            }
        })
    }
}

extension LeagueCreateViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return true
    }
}
