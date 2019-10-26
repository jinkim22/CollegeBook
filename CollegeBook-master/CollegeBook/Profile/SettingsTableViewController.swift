//
//  SettingsTableViewController.swift
//  CollegeBook
//
//  Created by Avi Khemani on 8/6/19.
//  Copyright © 2019 Avi Khemani. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn

class SettingsTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source

    let dispatchGroup = DispatchGroup()
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 2 && indexPath.row == 0 {
            let defaults = UserDefaults.standard
            let dictionary = defaults.dictionaryRepresentation()
            for key in dictionary.keys {
                defaults.removeObject(forKey: key)
            }
            let application = UIApplication.shared
            application.unregisterForRemoteNotifications()
            
            GIDSignIn.sharedInstance().signOut()
            do {
                try Auth.auth().signOut()
            }
            catch let signOutError as NSError {
                print ("Error signing out: \(signOutError)")
            }
            performSegue(withIdentifier: "Return To Home", sender: nil)
        } else if indexPath.section == 2 && indexPath.row == 1 {
//            let currentUID = Auth.auth().currentUser!.uid
//            let userRef = Firestore.firestore().collection("Users").document(currentUID)
//
//            dispatchGroup.enter() // 1
//            userRef.getDocument { (document, error) in
//                if let document = document, document.exists {
//                    let data = document.data()!
//                    let user = User(dictionary: data)
//
//                    let bookRef = Firestore.firestore().collection("Books")
//                    let storageRef = Storage.storage().reference()
//                    let channelRef = Firestore.firestore().collection("Channels")
//
//                    // Delete Profile Picutre
//                    self.dispatchGroup.enter()
//                    storageRef.child("UserImages/\(currentUID).jpg").delete { error in
//                        self.dispatchGroup.leave()
//                        if let error = error {
//                            print(error)
//                        }
//                    }
//
//                    // Delete product images as well as post IDs
//                    for postID in user.postIDs {
//                        self.dispatchGroup.enter()
//                        bookRef.document(postID).getDocument { (document, error) in
//                            if document != nil && document!.exists {
//                                let textbook = Textbook(dictionary: document!.data()!)
//                                let imageID = textbook.imageID
//                                storageRef.child("ProductImages/\(imageID).jpg").delete { error in
//                                    self.dispatchGroup.leave()
//                                    if let error = error {
//                                        print(error)
//                                    }
//                                }
//                            }
//                        }
//                        self.dispatchGroup.enter()
//                        bookRef.document(postID).delete { error in
//                            self.dispatchGroup.leave()
//                        }
//                    }
//
//                    for channelID in user.channelIDs {
//                        let currChannelRef = channelRef.document(channelID)
//                        self.dispatchGroup.enter()
//                        currChannelRef.getDocument { (document, error) in
//                            if let document = document, document.exists {
//                                let channelData = document.data()!
//                                let user1UID = channelData["User1UID"] as? String ?? "N/A"
//                                let user2UID = channelData["User2UID"] as? String ?? "N/A"
//                                let otherUID = currentUID == user1UID ? user2UID : user1UID
//
//                                let userRef = Firestore.firestore().collection("Users").document(otherUID)
//                                userRef.updateData(["ChannelIDs": FieldValue.arrayRemove([channelID])])
//                                self.dispatchGroup.leave()
//                            }
//                        }
//
//                        self.dispatchGroup.enter()
//                        Functions.functions().httpsCallable("recursiveDelete").call(["path": "Channels/\(channelID)/thread"]) { (result, error) in
//                            self.dispatchGroup.leave()
//                            print("Firebase function error")
//                            if error != nil {
//                                print(error)
//                            }
//                        }
//                    }
//                    self.dispatchGroup.enter() // 2
//                    userRef.delete { error in
//                        self.dispatchGroup.leave() // 2
//                    }
//                    self.dispatchGroup.leave()
//                }
//            }
//
//            dispatchGroup.notify(queue: .main, execute: {
//                Auth.auth().currentUser?.delete(completion: { error in
//                    print("I FUCKIN DELETED THE USER")
//                    print(error ?? "jk no error")
//                    GIDSignIn.sharedInstance().signOut()
//                    do {
//                        try Auth.auth().signOut()
//                    }
//                    catch let signOutError as NSError {
//                        print ("Error signing out: \(signOutError)")
//                    }
//                    let application = UIApplication.shared
//                    application.unregisterForRemoteNotifications()
//                    self.performSegue(withIdentifier: "Return To Home", sender: nil)
//                })
//
//            })
        }
    }
}
