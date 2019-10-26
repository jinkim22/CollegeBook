//
//  LoginViewController.swift
//  CollegeBook
//
//  Created by Avi Khemani on 7/23/19.
//  Copyright © 2019 Avi Khemani. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn
import SwiftyJSON

class LoginViewController: UIViewController {
    
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var googleSignIn: UIView!
    
    @IBAction func googleSignIn(_ sender: GIDSignInButton) {
        GIDSignIn.sharedInstance().signIn()
    }
    
    private func isLoggedIn() -> Bool {
        return Auth.auth().currentUser != nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        GIDSignIn.sharedInstance()?.presentingViewController = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(didSignIn), name: NSNotification.Name("SuccessfulSignInNotification"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(notEduNotification), name: NSNotification.Name("NonEduNotification"), object: nil)
    }
    
    @objc func notEduNotification() {
        let alert = UIAlertController(
            title: "Please use a .edu email.",
        message: "",
        preferredStyle: .alert)
        alert.addAction(UIAlertAction(
        title: "Ok",
        style: .default))
        self.present(alert, animated: true)
    }
    
    @IBAction func didSignIn()  {
        let UID = UserDefaults.standard.string(forKey: "UID")
        if UID != nil {
            performSegue(withIdentifier: Storyboard.loginSegue, sender: self)
        } else {
            let functions = Functions.functions()
            let currUser = Auth.auth().currentUser!
            
            let domainSplit = currUser.email!.split(separator: "@")
            let periodSplit = domainSplit[domainSplit.count-1].split(separator: ".")
            let domain = periodSplit[periodSplit.count-2] + ".edu"
            
            let dispatchGroup = DispatchGroup()
            var school: String?
            var user: User?
            
            dispatchGroup.enter()
            if domain == "claremontmckenna.edu" {
                school = "Stanford University"
                let userRef = Firestore.firestore().collection("Schools/\(school!.concatenated)/Users").document(currUser.uid)
                userRef.getDocument { (document, error) in
                    if let document = document, document.exists {
                        user = User(dictionary: document.data()!)
                    }
                    dispatchGroup.leave()
                }
            } else {
                functions.httpsCallable("getSchoolFromDomain").call(["text":domain]) { (result, error) in
                    let jsonObj = JSON(result?.data)
                    print(jsonObj)
                    school = jsonObj["text"][0]["name"].stringValue
                    let userRef = Firestore.firestore().collection("Schools/\(school!.concatenated)/Users").document(currUser.uid)
                    userRef.getDocument { (document, error) in
                        if let document = document, document.exists {
                            user = User(dictionary: document.data()!)
                        }
                        dispatchGroup.leave()
                    }
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                let userDefaults = UserDefaults.standard
                userDefaults.set(user!.uid, forKey: "UID")
                userDefaults.set(user!.name, forKey: "Name")
                userDefaults.set(user!.email, forKey: "Email")
                userDefaults.set(user!.venmoID, forKey: "VenmoID")
                userDefaults.set(user!.bio, forKey: "Bio")
                userDefaults.set(user!.school, forKey: "School")
                userDefaults.set(user!.bookmarkIDs, forKey: "BookmarkIDs")
                userDefaults.set(user!.postIDs, forKey: "PostIDs")
                self.performSegue(withIdentifier: Storyboard.loginSegue, sender: self)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Storyboard.loginSegue {
            NotificationCenter.default.removeObserver(self)
            print("Removed Notification")
        }
    }
    
    private struct Storyboard {
        static let loginSegue = "Login Segue"
    }
    
}
