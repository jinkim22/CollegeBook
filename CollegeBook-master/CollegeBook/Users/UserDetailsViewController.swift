//
//  UserDetailsViewController.swift
//  CollegeBook
//
//  Created by Avi Khemani on 9/27/19.
//  Copyright © 2019 Avi Khemani. All rights reserved.
//

import UIKit
import Firebase

class UserDetailsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var user: User?
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var venmoIDLabel: UILabel!
    @IBOutlet weak var bioLabel: UILabel!
    
    let school = Utilities.getSchool()
    let currUID = Utilities.getUID()
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var itemTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.isHidden = false
        
        itemTableView.delegate = self
        itemTableView.dataSource = self
        
        nameLabel.text = user?.name ?? ""
        bioLabel.text = user?.bio ?? ""
        venmoIDLabel.text = user?.venmoID ?? ""
        
        profileImageView.layer.cornerRadius = profileImageView.frame.size.width / 2
        profileImageView.clipsToBounds = true
        
        profileImageView.image = UIImage(named: "placeholder")
        let storageRef = Storage.storage().reference()
        let profRef = storageRef.child("Schools/\(school.concatenated)/UserImages/\(user!.uid).jpg")
        profRef.getData(maxSize: 1 * 1024 * 1024) { data, error in
            if let error = error {
                print(error)
                self.profileImageView.image = UIImage(named: "noimage")
            } else {
                self.profileImageView.image = UIImage(data: data!)
            }
        }
    }
    
    @IBAction func messageUser(_ sender: UIBarButtonItem) {
        let userRef = Firestore.firestore().collection("Schools/\(school.concatenated)/Users").document(currUID)
        userRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let data = document.data()!
                let currentUser = User(dictionary: data)
                
                var channelAlreadyExists: Bool = false
                for currChannelID in currentUser.channelIDs {
                    for otherChannelID in self.user!.channelIDs {
                        if currChannelID == otherChannelID {
                            channelAlreadyExists = true
                            let existingChannel = Channel(channelID: currChannelID, currentUser: currentUser, otherUser: self.user!)
                            let vc = ChatViewController(channel: existingChannel)
                            self.navigationController?.pushViewController(vc, animated: true)
                        }
                    }
                }
                
                if !channelAlreadyExists {
                    let channelID = UUID().uuidString
                    let newChannel = Channel(channelID: channelID, currentUser: currentUser, otherUser: self.user!)
                    
                    let ref = Firestore.firestore()
                    ref.collection("Schools/\(self.school.concatenated)/Channels").document(channelID).setData(newChannel.toDictionary())
                    ref.collection("Schools/\(self.school.concatenated)/Users").document(self.currUID).updateData([
                        "ChannelIDs": FieldValue.arrayUnion([channelID])])
                    ref.collection("Schools/\(self.school.concatenated)/Users").document(self.user!.uid).updateData([
                        "ChannelIDs": FieldValue.arrayUnion([channelID])])
                    self.user?.channelIDs.append(channelID)
                    let vc = ChatViewController(channel: newChannel)
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            }
        }
    }
    
    @IBAction func segmentedControlTap(_ sender: UISegmentedControl) {
        let index = sender.selectedSegmentIndex
        let userUID = user!.uid
        
        switch index {
        case 0:
            itemsToDisplay.removeAll()
            
            var postIDs = [String]()
            let userRef = Firestore.firestore().collection("Schools/\(school.concatenated)/Users").document(userUID)
            userRef.getDocument { (document, error) in
                if let document = document, document.exists {
                    let data = document.data()!
                    postIDs = data["PostIDs"] as? [String] ?? []
                    
                    for postID in postIDs {
                        let bookRef = Firestore.firestore().collection("Schools/\(self.school.concatenated)/Books").document(postID)
                        bookRef.getDocument { (document, error) in
                            if let document = document, document.exists {
                                let textbook = Textbook(dictionary: document.data()!)
                                self.itemsToDisplay.append(textbook)
                                self.itemTableView.reloadData()
                            } else {
                                print("Document does not exist")
                            }
                        }
                    }
                    
                } else {
                    print("Document does not exist")
                }
            }
        default:
            itemsToDisplay.removeAll()
            itemTableView.reloadData()
        }
    }
    
    var itemsToDisplay = [Textbook]()
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return itemsToDisplay.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Item Cell", for: indexPath)
        let storageRef = Storage.storage().reference()
        if let itemCell = cell as? ItemTableViewCell {
            let textbook = itemsToDisplay[indexPath.row]
            itemCell.textbook = textbook
            let islandRef = storageRef.child("Schools/\(school.concatenated)/ProductImages/\(textbook.imageID).jpg")
            islandRef.getData(maxSize: Storyboard.megabyteValue) { data, error in
                if error != nil {
                    print("Failed to get \(textbook.name) image")
                    print("Error: \(error!)")
                    itemCell.itemImage = UIImage(named: "noimage")
                } else {
                    print("Successfully downloaded image!")
                    itemCell.itemImage = UIImage(data: data!)
                }
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(125)
    }
    
    private struct Storyboard {
        static let photoLibraryOption = "Photo Library"
        static let cameraOption = "Camera"
        static let cancelOption = "Cancel"
        static let megabyteValue = Int64(1 * 1024 * 1024)
    }
    
}
