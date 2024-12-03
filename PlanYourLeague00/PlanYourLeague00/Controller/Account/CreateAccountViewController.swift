//
//  CteateAccountViewController.swift
//  PlanYourLeague00
//
//  Created by Myung Woo on 12/2/24.
//

import UIKit
import CloudKit

class CreateAccountViewController: UITableViewController {
    
    var userEmail: String!
    var userID: String!
    
    var spinner = UIActivityIndicatorView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        spinner.style = .medium
        spinner.hidesWhenStopped = true
        view.addSubview(spinner)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate( [ spinner.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 230.0),
                                       spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor)])
        
        spinner.transform = CGAffineTransform(scaleX: 2.0, y: 2.0)
        
        if let userEmail = userEmail {
            userEmailTextField.text = userEmail
        }
        
        userImage.image = UIImage(named: "avatar")
    }
    
    @IBOutlet var userImage: UIImageView!{
        didSet{
            userImage.layer.cornerRadius = 10.0
            userImage.clipsToBounds = true
        }
    }
    
    @IBOutlet var userNameTextField: RounderTextView!{
        didSet {
            userNameTextField.tag = 1
            userNameTextField.delegate = self
        }
    }
    @IBOutlet var userPhoneTextField: RounderTextView!{
        didSet{
            userPhoneTextField.tag = 2
            userPhoneTextField.delegate = self
        }
    }
    @IBOutlet var userEmailTextField: RounderTextView!{
        didSet{
            userEmailTextField.tag = 3
            userEmailTextField.delegate = self
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
    
    @IBAction func saveButtonTapped(sender: UIButton){
        self.spinner.startAnimating()

        if userNameTextField.text == "" || userPhoneTextField.text == "" || userEmailTextField.text == "" || userImage.image == UIImage(named: "avatar") {
            self.spinner.stopAnimating()
            let alertController = UIAlertController(title: "Information is missing", message: "Fill all the information and select a picture as your profile avatar!!!", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertController.addAction(cancelAction)
            self.present(alertController,animated: true, completion: nil)
            
            return
        }
        
        let publicDatabase = CKContainer.default().publicCloudDatabase
        let cloudUser = CKRecord(recordType: "User")
        cloudUser.setValue(userNameTextField.text!, forKey: "userName")
        cloudUser.setValue(userPhoneTextField.text!, forKey: "userPhone")
        cloudUser.setValue(userEmailTextField.text!, forKey: "userEmail")
        cloudUser.setValue(userID,forKey: "userID")
        
        if let imageData = userImage.image?.pngData(){
        let imageData = imageData as Data
        
        // Resize the image
        let originalImage = UIImage(data: imageData)!
        let scalingFactor = (originalImage.size.width > 1024) ? 1024 / originalImage.size.width : 1.0
        let scaledImage = UIImage(data: imageData, scale: scalingFactor)!

        // Write the image to local file for temporary use
        let imageFilePath = NSTemporaryDirectory() + userNameTextField.text!
        let imageFileURL = URL(fileURLWithPath: imageFilePath)
        try? scaledImage.jpegData(compressionQuality: 0.8)?.write(to: imageFileURL)

        // Create image asset for upload
        let imageAsset = CKAsset(fileURL: imageFileURL)
        cloudUser.setValue(imageAsset, forKey: "image")

            // Save the record to iCloud
        publicDatabase.save(cloudUser, completionHandler: { (record, error) -> Void  in
            if let error = error as? CKError {
                DispatchQueue.main.async {
                    self.spinner.stopAnimating()
                    let alertController = UIAlertController(title: "Error", message: "No Internet connection.Check your internet.", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alertController,animated: true, completion: nil)
                }
                print("Error saving record: \(error.localizedDescription)")
            } else if let record = record {
                DispatchQueue.main.async {
                    self.spinner.stopAnimating()
                    //self.performSegue(withIdentifier: "showNewTournament", sender: record)
                    self.performSegue(withIdentifier: "loginSuccess", sender: record)
                }
                try? FileManager.default.removeItem(at: imageFileURL)
            }
            })
        }
        
        if let textField = view.viewWithTag(4){
            textField.resignFirstResponder()
        }
        if let nextTextField = view.viewWithTag(1){
            nextTextField.becomeFirstResponder()
        }
    }
        
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "loginSuccess", let record = sender as? CKRecord{
            let destinationVC = segue.destination as? MainTabBarController
            destinationVC?.cloudUser = record
            destinationVC?.modalPresentationStyle = .fullScreen
        }
    }
}

extension CreateAccountViewController: UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let nextTextField = view.viewWithTag(textField.tag + 1){
            textField.resignFirstResponder()
            nextTextField.becomeFirstResponder()
        }
        
        return true
    }
}

extension CreateAccountViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let selectedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            userImage.image = selectedImage
            userImage.contentMode = .scaleAspectFill
            userImage.clipsToBounds = true
        }
        
        dismiss(animated: true, completion: nil)
    }
}
