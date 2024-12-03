//
//  LoginViewController.swift
//  PlanYourLeague00
//
//  Created by Myung Woo on 12/2/24.
//

import UIKit
import FirebaseAuth
import CloudKit

class LoginViewController: UIViewController {
    
    var verifyCount: Int = 0
    
    var spinner = UIActivityIndicatorView()

    var cloudUser: CKRecord!
    var user: User!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        spinner.style = .medium
        spinner.hidesWhenStopped = true
        view.addSubview(spinner)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate( [ spinner.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 230.0),
                                       spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor)])
        
        spinner.transform = CGAffineTransform(scaleX: 2.0, y: 2.0)
        // Do any additional setup after loading the view.
    }
    
    func fetchRecordsFromCloudForUser(for userEmail: String) {
        print("Fetching")
        self.spinner.startAnimating()
        // Fetch data using Convenience API
        let cloudContainer = CKContainer.default()
        let publicDatabase = cloudContainer.publicCloudDatabase
        let predicate = NSPredicate(format: "userEmail == %@", userEmail)
        let query = CKQuery(recordType: "User", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let queryOperation = CKQueryOperation(query: query)
        queryOperation.desiredKeys = ["userID","userName","userPhone","userEmail","image"]
        queryOperation.queuePriority = .veryHigh
        queryOperation.resultsLimit = 50
        queryOperation.recordMatchedBlock = { (recordID, result) -> Void in
            do {
                self.cloudUser = (try result.get())
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
                self.spinner.stopAnimating()
//                if let refreshControl = self.refreshControl {
//                    if refreshControl.isRefreshing {
//                        refreshControl.endRefreshing()
//                    }
//                }
                if self.cloudUser == nil {
                    print("CloudUser is nil")
                    self.performSegue(withIdentifier: "fillInformation", sender: nil)
                } else {
                    print("Login Success")
                    self.performSegue(withIdentifier: "loginSuccess", sender: self.cloudUser)
                }
            }
        }
        publicDatabase.add(queryOperation)
    }

    @IBOutlet var emailTextField: RounderTextView! {
        didSet{
            emailTextField.tag = 1
            emailTextField.delegate = self
        }
    }
    
    @IBOutlet var passwordTextField: RounderTextView! {
        didSet{
            passwordTextField.tag = 2
            passwordTextField.delegate = self
        }
    }
    
    @IBAction func handleSignIn() {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            showAlert(message: "Please fill in all fields.")
            return
        }
        
        spinner.startAnimating()

        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let _ = error {
                self.spinner.stopAnimating()
                self.showAlert(message: "Can not SIGN IN! Check your information!")
                return
            } else {
                // Đăng nhập thành công
                self.spinner.stopAnimating()
                if let user = authResult?.user {
                    self.user = user
                    if user.isEmailVerified {
                        self.fetchRecordsFromCloudForUser(for: user.email!)
                    } else {
                        self.deleteUserAccount()
                        self.showAlert(message: "Account is not available! SIGN UP agint")
                    }
                }
            }
        }
    }

    @IBAction func handleSignUp() {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            showAlert(message: "Please fill in all fields")
            return
        }
        spinner.startAnimating()
        
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                self.spinner.stopAnimating()
                self.showAlert(message: "SIGN UP failed: \(error.localizedDescription)")
                return
            }
            
            // Gửi email xác minh
            authResult?.user.sendEmailVerification { error in
                self.spinner.stopAnimating()
                if let error = error {
                    self.showAlert(message: "Failed to send verification: \(error.localizedDescription)")
                } else {
                    self.verifyAlert(title: "Verification is sent")
                }
            }
        }
    }
    
    func verifyAlert(title: String) {
        let alertController = UIAlertController(title: title, message: "Check your mail box and verify your email before click OK", preferredStyle: .alert)
        let doneAction = UIAlertAction(title: "OK", style: .default){_ in
            self.verifyCount += 1
            self.verifyEmail()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .default){_ in
            self.deleteUserAccount()
        }
        alertController.addAction(cancelAction)
        alertController.addAction(doneAction)
        self.present(alertController,animated: true,completion:  nil)

    }
    
    func verifyEmail(){
        guard self.verifyCount <= 5 else {
            
            self.deleteUserAccount()
            return
        }
        self.spinner.startAnimating()
        
        if let user = Auth.auth().currentUser {
            user.reload { error in
                if let error = error {
                    print("Failed to reload user: \(error.localizedDescription)")
                    self.spinner.stopAnimating()
                    self.verifyEmail()
                } else if user.isEmailVerified {
                    self.spinner.stopAnimating()
                    print("Email is verified.")
                    self.user = user
                    self.performSegue(withIdentifier: "fillInformation", sender: nil)
                } else {
                    print("Email is not verified.")
                    self.spinner.stopAnimating()
                    self.verifyAlert(title: "Email is not verified!")
                }
            }
        }

    }
    
    func deleteUserAccount() {
        self.verifyCount = 0

        guard let user = Auth.auth().currentUser else {
            print("No user is currently logged in.")
            return
        }
        self.spinner.startAnimating()

        // Tiến hành xóa tài khoản
        user.delete { error in
            if let error = error {
                self.spinner.stopAnimating()
                print("Error deleting account: \(error.localizedDescription)")
            } else {
                print("Account deleted successfully.")
                self.spinner.stopAnimating()
                self.showAlert(message: "Email is not available and try to SIGN UP againt!")
                self.passwordTextField.text = ""
                // Thực hiện điều hướng hoặc thông báo cho người dùng
            }
        }
    }

    
    func showAlert(message: String) {
        let alert = UIAlertController(title: "Notification", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "fillInformation"{
            let destinationNAV = segue.destination as! UINavigationController
            if let destinationVC = destinationNAV.viewControllers.first as? CreateAccountViewController {
                destinationVC.userEmail = self.user.email
                destinationVC.userID = self.user.uid
            }
        } else if segue.identifier == "loginSuccess", let cloudUser = sender as? CKRecord {
            let destinationVC = segue.destination as! MainTabBarController
            destinationVC.cloudUser = cloudUser
            destinationVC.modalPresentationStyle = .fullScreen
        }
    }

}

extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let nextTextField = view.viewWithTag(textField.tag + 1){
            textField.resignFirstResponder()
            nextTextField.becomeFirstResponder()
        }
        
        return true
    }
}

