//
//  ViewController.swift
//  Homestead FBLA
//
//  Created by Samrudh Shenoy on 4/22/20.
//  Copyright © 2020 Samrudh Shenoy. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import GoogleSignIn

class MainViewController: UIViewController {

    @IBOutlet weak var scanCode: UIButton!
    @IBOutlet weak var signInButton: GIDSignInButton!
    @IBOutlet weak var verifyAcc: UIButton!
    @IBOutlet weak var username: UILabel!
    @IBOutlet weak var checkMark: UIImageView!
    var db: Firestore!
    var verified = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        checkMark.isHidden = true
        
        // [START setup]
        let settings = FirestoreSettings()

        Firestore.firestore().settings = settings
        // [END setup]
        db = Firestore.firestore()
        
        GIDSignIn.sharedInstance()?.presentingViewController = self
        
        scanCode.layer.masksToBounds = false;
        scanCode.layer.shadowColor = UIColor.lightGray.cgColor
        scanCode.layer.shadowOffset = CGSize(width: 1, height: 2)
        scanCode.layer.shadowRadius = 2
        scanCode.layer.shadowOpacity = 0.8
        scanCode.layer.cornerRadius = 35
        verifyAcc.layer.masksToBounds = false;
        verifyAcc.layer.shadowColor = UIColor.lightGray.cgColor
        verifyAcc.layer.shadowOffset = CGSize(width: 1, height: 2)
        verifyAcc.layer.shadowRadius = 2
        verifyAcc.layer.shadowOpacity = 0.8
        verifyAcc.layer.cornerRadius = 5
//        verifyAcc.isHidden = true
        
        let user = Auth.auth().currentUser
        if let user = user {
//            verifyAcc.isHidden = true
            signInButton.isHidden = true
            username.text = user.email
            checkMark.isHidden = false
            verified = true
        }
        
        // Do any additional setup after loading the view.
        
        
    }
    
    @IBAction func verify (sender: Any) {
        
        self.verifyAcc.setTitle("Verifying...", for: .normal)
        UIView.animate(withDuration: 0.4, animations: {
            self.verifyAcc.backgroundColor = UIColor.lightGray
        })
        
        var email = ""
        
        let user = Auth.auth().currentUser
        if let user = user {
            let uid = user.uid
            email = user.email ?? ""
            
            print("User ID: \(uid)")
            print("User Email: \(email)")
        }
        else {
            print("error with sign in")
        }
        
        db.collection("users").whereField("email", isEqualTo: email).getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    self.username.text = user?.email
                    self.verified = true
                    print("\(document.documentID) => \(document.data())")
                    self.verifyAcc.setTitle("Verified", for: .normal)
                    self.verifyAcc.setTitleColor(UIColor.black, for: .normal)
                    UIView.animate(withDuration: 0.4, animations: {
                        self.verifyAcc.backgroundColor = UIColor.green
                    self.signInButton.isHidden = true
                    self.checkMark.isHidden = false
                        
                    })
                }
            }
        }

    }
    
    @IBAction func openScanner (sender: UIButton) {
        print("verified? \(verified)")
        
        if verified == false {
            do {
                let firebaseAuth = Auth.auth()
                try firebaseAuth.signOut()
                
                let errorAlert = UIAlertController(title: "Error", message: "This account is not linked with a valid Homestead FBLA account, either sign in with a different account or ask an officer for help.", preferredStyle: UIAlertController.Style.alert)
                let done = UIAlertAction(title: "Okay", style: UIAlertAction.Style.default, handler: { action in })
                errorAlert.addAction(done)
                present(errorAlert, animated: true, completion: nil)
            } catch let signOutError as NSError {
                print ("Error signing out: %@", signOutError)
            }
        }
        
        else {
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "scannerview") as! ScanViewController
            self.present(vc, animated: true, completion: nil)
        }
    }
    
}

extension UIViewController {
    /*! @fn showMessagePrompt
     @brief Displays an alert with an 'OK' button and a message.
     @param message The message to display.
     */
    func showMessagePrompt(_ message: String) {
      let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
      let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
      alert.addAction(okAction)
      present(alert, animated: false, completion: nil)
    }

    /*! @fn showTextInputPromptWithMessage
     @brief Shows a prompt with a text field and 'OK'/'Cancel' buttons.
     @param message The message to display.
     @param completion A block to call when the user taps 'OK' or 'Cancel'.
     */
    func showTextInputPrompt(withMessage message: String,
                             completionBlock: @escaping ((Bool, String?) -> Void)) {
      let prompt = UIAlertController(title: nil, message: message, preferredStyle: .alert)
      let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
        completionBlock(false, nil)
      }
      weak var weakPrompt = prompt
      let okAction = UIAlertAction(title: "OK", style: .default) { _ in
        guard let text = weakPrompt?.textFields?.first?.text else { return }
        completionBlock(true, text)
      }
      prompt.addTextField(configurationHandler: nil)
      prompt.addAction(cancelAction)
      prompt.addAction(okAction)
      present(prompt, animated: true, completion: nil)
    }
}

