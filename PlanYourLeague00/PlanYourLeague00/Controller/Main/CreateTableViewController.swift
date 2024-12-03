//
//  CreateTableViewController.swift
//  PlanYourLeague00
//
//  Created by Myung Woo on 9/23/24.
//

import UIKit
import CloudKit

class CreateTableViewController: UITableViewController {

    var tournament: Tournament!
    var cloudTournament: CKRecord!

    // MARK: Screen Display
    var onDismiss: (() -> Void)?
    var onDismiss1: (() -> Void)?
    
    var spinner = UIActivityIndicatorView()

   
    // first time
    override func viewDidLoad() {
        super.viewDidLoad()
        
        spinner.style = .medium
        spinner.hidesWhenStopped = true
        view.addSubview(spinner)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate( [ spinner.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 300.0),
                                       spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor)])
        
        spinner.transform = CGAffineTransform(scaleX: 2.0, y: 2.0) // Phóng to spinner lên 2 lần
        
        if let cloudTournament = cloudTournament{
            NSLayoutConstraint.activate( [ spinner.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 15.0),
                                           spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor)])
            if let image = cloudTournament.object(forKey: "image"), let assetImage = image as? CKAsset {
                if let dataImage = try? Data.init(contentsOf: assetImage.fileURL!) {
                    logoImageView.image = UIImage(data: dataImage)
                }
            }
            fullNameTextView.text = cloudTournament.object(forKey: "name") as? String
            shortNameTextView.text = cloudTournament.object(forKey: "shortName") as? String
            summaryTextView.text = cloudTournament.object(forKey: "summary") as? String
            managerNameTextView.text = cloudTournament.object(forKey: "manager") as? String
            managerPhoneTextView.text = cloudTournament.object(forKey: "phone") as? String
            managerEmailTextView.text = cloudTournament.object(forKey: "email") as? String
            accessPasswordTextView.text = cloudTournament.object(forKey: "AccessPassword") as? String

        } else {
            logoImageView.image = UIImage(named: "logo")
            fullNameTextView.text = ""
            shortNameTextView.text = ""
            summaryTextView.text = ""
            managerNameTextView.text = ""
            managerPhoneTextView.text = ""
            managerEmailTextView.text = ""
            accessPasswordTextView.text = ""
        }
        
        let tap = UITapGestureRecognizer(target:view, action: #selector(UIView.endEditing))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
    }
    // first time and later
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        let tap = UITapGestureRecognizer(target:view, action: #selector(UIView.endEditing))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
        
    // MARK: Logo image and photo update
    @IBOutlet var logoImageView: UIImageView! {
        didSet {
            logoImageView.layer.cornerRadius = 10.0
            logoImageView.clipsToBounds = true
        }
    }
    override func tableView(_ tableview: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            let photoSourceRequestController = UIAlertController(title: "", message: "Choose your photo source", preferredStyle: .actionSheet)
            
            let photoLibraryAction = UIAlertAction(title: "Photo Library", style: .default, handler: {(action) in
            
                if UIImagePickerController.isSourceTypeAvailable(.photoLibrary){
                    let imagePicker = UIImagePickerController()
                    imagePicker.allowsEditing = false
                    imagePicker.sourceType = .photoLibrary
                    imagePicker.delegate = self
                    self.present(imagePicker, animated: true, completion: nil)
                }
            })
            
            let cameraAction = UIAlertAction(title: "Camera", style: .default, handler: {(action) in
                    
                if UIImagePickerController.isSourceTypeAvailable(.camera){
                    let imagePicker = UIImagePickerController()
                    imagePicker.allowsEditing = false
                    imagePicker.sourceType = .camera
                    imagePicker.delegate = self
                    self.present(imagePicker, animated: true, completion: nil)
                }
            })
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            
            photoSourceRequestController.addAction(cameraAction)
            photoSourceRequestController.addAction(photoLibraryAction)
            photoSourceRequestController.addAction(cancelAction)
            
            // For Ipad
            if let popoverController = photoSourceRequestController.popoverPresentationController {
                if let cell = tableview.cellForRow(at: indexPath) {
                    popoverController.sourceView = cell
                    popoverController.sourceRect = cell.bounds
                }
                
            }
            
            present(photoSourceRequestController, animated: true, completion: nil)
        }
    }
    
    // MARK: Text Field
    @IBOutlet var fullNameTextView: RounderTextView! {
        didSet {
            fullNameTextView.tag = 1
            fullNameTextView.becomeFirstResponder()
            fullNameTextView.delegate = self
        }
    }
    @IBOutlet var shortNameTextView: RounderTextView! {
        didSet {
            shortNameTextView.tag = 2
            shortNameTextView.delegate = self
        }
    }
    @IBOutlet var summaryTextView: RounderTextView! {
        didSet {
            summaryTextView.tag = 3
            summaryTextView.delegate = self
        }
    }
    @IBOutlet var managerNameTextView: RounderTextView! {
        didSet {
            managerNameTextView.tag = 4
            managerNameTextView.delegate = self
        }
    }
    @IBOutlet var managerPhoneTextView: RounderTextView! {
        didSet {
            managerPhoneTextView.tag = 5
            managerPhoneTextView.delegate = self
        }
    }
    @IBOutlet var managerEmailTextView: RounderTextView! {
        didSet {
            managerEmailTextView.tag = 6
            managerEmailTextView.delegate = self
        }
    }
    @IBOutlet var accessPasswordTextView: RounderTextView! {
        didSet {
            accessPasswordTextView.tag = 7
            accessPasswordTextView.delegate = self
        }
    }
        
    // MARK: Football Button - Save new league as a Football league
    @IBAction func saveButtonTapped(sender: UIButton){
        self.spinner.startAnimating()
        
        if fullNameTextView.text == "" || shortNameTextView.text == "" || summaryTextView.text == "" || managerNameTextView.text == "" || managerEmailTextView.text == "" || managerPhoneTextView.text == "" || accessPasswordTextView.text == "" {
                    let alertController = UIAlertController(title: "Sorry", message: "You have to fill all the text fill", preferredStyle: .alert)
                    let alertAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alertController.addAction(alertAction)
                    present(alertController, animated: true, completion: nil)
                    return
                }
        
        let record: CKRecord!
        
        if let cloudTournament = self.cloudTournament{
            record = cloudTournament
        } else {
            record = CKRecord(recordType: "Tournament")
        }
        
        record.setValue(fullNameTextView.text!, forKey: "name")
        record.setValue(shortNameTextView.text!, forKey: "shortName")
        record.setValue(managerNameTextView.text!, forKey: "manager")
        record.setValue(managerPhoneTextView.text!, forKey: "phone")
        record.setValue(managerEmailTextView.text!, forKey: "email")
        record.setValue(summaryTextView.text!, forKey: "summary")
        record.setValue(accessPasswordTextView.text!, forKey: "AccessPassword")

        if let imageData = logoImageView.image?.pngData(){
            let imageData = imageData as Data
            
            // Resize the image
            let originalImage = UIImage(data: imageData)!
            let scalingFactor = (originalImage.size.width > 1024) ? 1024 / originalImage.size.width : 1.0
            let scaledImage = UIImage(data: imageData, scale: scalingFactor)!

            // Write the image to local file for temporary use
            let imageFilePath = NSTemporaryDirectory() + fullNameTextView.text!
            let imageFileURL = URL(fileURLWithPath: imageFilePath)
            try? scaledImage.jpegData(compressionQuality: 0.8)?.write(to: imageFileURL)

            // Create image asset for upload
            let imageAsset = CKAsset(fileURL: imageFileURL)
            record.setValue(imageAsset, forKey: "image")

            // Get the Public iCloud Database
            let publicDatabase = CKContainer.default().publicCloudDatabase

            // Save the record to iCloud
            publicDatabase.save(record, completionHandler: { (record, error) -> Void  in
                if let error = error as? CKError {
                        switch error.code {
                        case .networkUnavailable, .networkFailure:
                            print("No Internet connection. Data will be synced later.")
                            DispatchQueue.main.async {
                                self.onDismiss1?()
                                self.dismiss(animated: true)
                            }

                            
                        default:
                            DispatchQueue.main.async {
                                let alertController = UIAlertController(title: "Error", message: "No Internet connection.Check your internet.", preferredStyle: .alert)
                                alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                                self.present(alertController,animated: true, completion: nil)
                            }
                            print("Error saving record: \(error.localizedDescription)")
                        }
                } else if let record = record {
                    DispatchQueue.main.async {
                        self.spinner.stopAnimating()
                        if self.cloudTournament != nil {
                            self.onDismiss?()
                            self.dismiss(animated: true)
                        } else {
                            self.logoImageView.image = UIImage(named: "logo")
                            self.fullNameTextView.text = ""
                            self.shortNameTextView.text = ""
                            self.summaryTextView.text = ""
                            self.managerNameTextView.text = ""
                            self.managerPhoneTextView.text = ""
                            self.managerEmailTextView.text = ""
                            self.accessPasswordTextView.text = ""
                            
                            self.performSegue(withIdentifier: "showNewTournament", sender: record)

                        }
                    }
                    try? FileManager.default.removeItem(at: imageFileURL)
                }
            })
        }
        
        if let textField = view.viewWithTag(8){
            textField.resignFirstResponder()
        }
        if let nextTextField = view.viewWithTag(1){
            nextTextField.becomeFirstResponder()
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showNewTournament" {
            if let destinationVc = segue.destination as? TournamentDetailViewController {
                if let tournament = sender as? CKRecord {
                    destinationVc.tournament = tournament
                }
            }
        }
    }

}
// MARK: Move onto next text field
extension CreateTableViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let nextTextField = view.viewWithTag(textField.tag + 1){
            textField.resignFirstResponder()
            nextTextField.becomeFirstResponder()
        }
        
        return true
    }
}

extension CreateTableViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let selectedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            logoImageView.image = selectedImage
            logoImageView.contentMode = .scaleAspectFill
            logoImageView.clipsToBounds = true
        }
        
        dismiss(animated: true, completion: nil)
    }
}
