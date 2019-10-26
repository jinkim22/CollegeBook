//
//  ProfileViewController.swift
//  CollegeBook
//
//  Created by Avi Khemani on 7/29/19.
//  Copyright © 2019 Avi Khemani. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn

class ProfileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var user: User?
    
    let school = Utilities.getSchool()
    let currUID = Utilities.getUID()
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var venmoIDLabel: UILabel!
    @IBOutlet weak var bioLabel: UILabel!
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var itemTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        itemTableView.delegate = self
        itemTableView.dataSource = self
        
        profileImageView.layer.cornerRadius = profileImageView.frame.size.width / 2
        profileImageView.clipsToBounds = true
        
        loadUserInfo()
    }
    
    func loadUserInfo() {
        let userDefaults = UserDefaults.standard
        nameLabel.text = userDefaults.string(forKey: "Name") ?? ""
        bioLabel.text = userDefaults.string(forKey: "Bio") ?? ""
        venmoIDLabel.text = userDefaults.string(forKey: "VenmoID") ?? ""
        
        profileImageView.image = UIImage(named: "placeholder")
        
        let storageRef = Storage.storage().reference()
        let profRef = storageRef.child("Schools/\(school.concatenated)/UserImages/\(currUID).jpg")
        profRef.getData(maxSize: 1 * 1024 * 1024) { data, error in
            if let error = error {
                print(error)
                self.profileImageView.image = UIImage(named: "noimage")
            } else {
                self.profileImageView.image = UIImage(data: data!)
            }
        }
    }
    
    let dispatchGroup = DispatchGroup()
    
    @IBAction func segmentedControlTap(_ sender: UISegmentedControl) {
        let index = sender.selectedSegmentIndex
        let userDefaults = UserDefaults.standard
        
        switch index {
        case 0:
            itemsToDisplay.removeAll()
            let postIDs = userDefaults.array(forKey: "PostIDs") as? [String] ?? [String]()
            
            var newTextbooks = [Textbook]()
            for postID in postIDs {
                dispatchGroup.enter()
                let bookRef = Firestore.firestore().collection("Schools/\(self.school.concatenated)/Books").document(postID)
                bookRef.getDocument { (document, error) in
                    if let document = document, document.exists {
                        let textbook = Textbook(dictionary: document.data()!)
                        newTextbooks.append(textbook)
                        self.dispatchGroup.leave()
                    }
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                self.itemsToDisplay = newTextbooks
                self.itemTableView.reloadData()
            }
            
        case 1:
            itemsToDisplay.removeAll()
            let bookmarkIDs = userDefaults.array(forKey: "BookmarkIDs") as? [String] ?? [String]()
            
            var newTextbooks = [Textbook]()
            for bookmarkID in bookmarkIDs {
                dispatchGroup.enter()
                let bookRef = Firestore.firestore().collection("Schools/\(self.school.concatenated)/Books").document(bookmarkID)
                bookRef.getDocument { (document, error) in
                    if let document = document, document.exists {
                        let textbook = Textbook(dictionary: document.data()!)
                        newTextbooks.append(textbook)
                        self.dispatchGroup.leave()
                    }
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                self.itemsToDisplay = newTextbooks
                self.itemTableView.reloadData()
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
    
    @IBAction func goBackWithoutEditing(segue: UIStoryboardSegue) {
        
    }
    
    @IBAction func goBackWithEditing(segue: UIStoryboardSegue) {
        if let changeVC = segue.source as? ChangeProfileViewController {
            let userDetails = changeVC.userDetails
            nameLabel.text = userDetails?.name ?? ""
            bioLabel.text = userDetails?.bio ?? ""
            venmoIDLabel.text = userDetails?.venmoID ?? ""
        }
    }
   
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Change Profile Segue" {
            if let nc = segue.destination as? UINavigationController {
                if let vc = nc.visibleViewController as? ChangeProfileViewController {
                    let name = nameLabel.text ?? ""
                    let bio = bioLabel.text ?? ""
                    let venmoID = venmoIDLabel.text ?? ""
                    vc.userDetails = UserDetails(name: name, bio: bio, venmoID: venmoID)
                    vc.profileImage = profileImageView.image
                }
            }
        }
    }
    
    private struct Storyboard {
        static let photoLibraryOption = "Photo Library"
        static let cameraOption = "Camera"
        static let cancelOption = "Cancel"
        static let megabyteValue = Int64(1 * 1024 * 1024)
    }
    
    
}
