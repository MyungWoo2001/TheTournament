//
//  TeamsCreateViewController.swift
//  PlanYourLeague00
//
//  Created by Myung Woo on 10/2/24.
//

import UIKit
import CloudKit

class TeamsCreateViewController: UITableViewController {
    
    var team: Team!
    var teams: [Team] = []
    var league: CKRecord!
    
    @IBOutlet var photoImageView: UIImageView!{
        didSet {
            photoImageView.layer.cornerRadius = 10.0
            photoImageView.clipsToBounds = true
        }
    }
    
    var onDismiss: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Dismiss the keyboard
        let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0{
            let photoSourceRequestController = UIAlertController(title: "", message: "Choose your photo sources", preferredStyle: .actionSheet)
            
            let cameraAction = UIAlertAction(title: "Camera", style: .default, handler: {(action) in
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    let imagePicker = UIImagePickerController()
                    imagePicker.delegate = self
                    imagePicker.allowsEditing = false
                    imagePicker.sourceType = .camera
                    self.present(imagePicker, animated: true, completion: nil)
                }
            })
            
            let photoLibraryAction = UIAlertAction(title: "Photo Library", style: .default, handler: {(action) in
                if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                    let imagePicker = UIImagePickerController()
                    imagePicker.delegate = self
                    imagePicker.allowsEditing = false
                    imagePicker.sourceType = .photoLibrary
                    self.present(imagePicker, animated: true, completion: nil)
                }
            })
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            
            photoSourceRequestController.addAction(cameraAction)
            photoSourceRequestController.addAction(photoLibraryAction)
            photoSourceRequestController.addAction(cancelAction)
            
            // for ipad
            if let popoverController = photoSourceRequestController.popoverPresentationController {
                if let cell = tableView.cellForRow(at: indexPath){
                    popoverController.sourceView = cell
                    popoverController.sourceRect = cell.bounds
                }
            }
            
            present(photoSourceRequestController, animated: true, completion: nil)
        }
    }
    
    @IBOutlet var teamNameTextField: RounderTextView! {
        didSet {
            teamNameTextField.tag = 1
            teamNameTextField.becomeFirstResponder()
            teamNameTextField.delegate = self
        }
    }
    
    @IBAction func saveButtonTapped(sender: UIButton){
        if teamNameTextField.text == "" {
            let alertController = UIAlertController(title: "Sorry", message: "You have to fill team name", preferredStyle: .alert)
            let alertAction = UIAlertAction(title: "OK", style: .default, handler:  nil)
            alertController.addAction(alertAction)
            present(alertController, animated: true, completion: nil)
            return
        }
        
        if let appDelegate = (UIApplication.shared.delegate as? AppDelegate) {
            team = Team(context: appDelegate.persistentContainer.viewContext)
            team.recordID = "_"
            team.teamID = "_"
            team.name = teamNameTextField.text!
            team.rank = teams.count + 1
            team.pls = 0
            team.goals = 0
            team.dif = 0
            team.point = 0
            
            if let imageData = photoImageView.image?.pngData(){
                team.logoImage = imageData
            }
            print("Saving Team to context")
            appDelegate.saveContext()
        }
        
        saveRecordToCloud(team: team)
        
        dismiss(animated: true, completion: nil)
    }
    
    func saveRecordToCloud(team: Team) {
        // Prepare the record to save
        let record = CKRecord(recordType: "Team")
        record.setValue(team.name, forKey: "name")
        record.setValue(team.goals, forKey: "goals")
        record.setValue(team.pls, forKey: "pls")
        record.setValue(team.point, forKey: "points")
        record.setValue(team.rank, forKey: "rank")
        record.setValue(team.dif, forKey: "dif")

        let imageData = team.logoImage as Data
        
        // Resize the image
        let originalImage = UIImage(data: imageData)!
        let scalingFactor = (originalImage.size.width > 1024) ? 1024 / originalImage.size.width : 1.0
        let scaledImage = UIImage(data: imageData, scale: scalingFactor)!

        // Write the image to local file for temporary use
        let imageFilePath = NSTemporaryDirectory() + team.name
        let imageFileURL = URL(fileURLWithPath: imageFilePath)
        try? scaledImage.jpegData(compressionQuality: 0.8)?.write(to: imageFileURL)

        // Create image asset for upload
        let imageAsset = CKAsset(fileURL: imageFileURL)
        record.setValue(imageAsset, forKey: "logo")
        
        // Fetch record Tournament để tham chiếu
        let leagueID = CKRecord.ID(recordName: league.recordID.recordName )
        let LeagueReference = CKRecord.Reference(recordID: leagueID, action: .deleteSelf)

        // Gán giá trị cho trường league
        record["league"] = LeagueReference

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

            // Remove temp file
            try? FileManager.default.removeItem(at: imageFileURL)
            DispatchQueue.main.async{
                if let appDelegate = (UIApplication.shared.delegate as? AppDelegate){
                    if let recordID = record?.recordID.recordName{
                        team.recordID = recordID
                    }
                    appDelegate.saveContext()
                }
                self.onDismiss?()
            }
            
        })
    }

}

extension TeamsCreateViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return true
    }
}

extension TeamsCreateViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            photoImageView.image = selectedImage
            photoImageView.contentMode = .scaleAspectFill
            photoImageView.clipsToBounds = true
        }
        
        dismiss(animated: true, completion: nil)
    }
}
