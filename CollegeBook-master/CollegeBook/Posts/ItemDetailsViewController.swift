//
//  ItemDetailsViewController.swift
//  CollegeBook
//
//  Created by Avi Khemani on 7/24/19.
//  Copyright © 2019 Avi Khemani. All rights reserved.
//

import UIKit
import Firebase

class ItemDetailsViewController: UIViewController {
    
    var textbook: Textbook?
    var owner: User?
    
    let school = Utilities.getSchool()
    let currUID = Utilities.getUID()
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var qualityLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var classLabel: UILabel!
    @IBOutlet weak var userAndTimeLabel: UILabel!
    @IBOutlet weak var messageButton: UIButton!
    @IBOutlet weak var buyItemButton: UIButton!
    
    @IBOutlet weak var bookmarkButton: UIBarButtonItem!
    @IBOutlet weak var itemImageView: UIImageView!
    
    var itemImage: UIImage? {
        didSet {
            itemImageView.image = itemImage
        }
    }
    
    @IBAction func bookmarkItem(_ sender: UIBarButtonItem) {
        let userDefaults = UserDefaults.standard
        let ref = Firestore.firestore().collection("Schools/\(school.concatenated)/Users").document(currUID)
        var oldIDs = userDefaults.array(forKey: "BookmarkIDs") as? [String] ?? [String]()
        if #available(iOS 13.0, *) {
            if (bookmarkButton.image == UIImage(systemName: "bookmark.fill")) {
                
                bookmarkButton.image = UIImage(systemName: "bookmark")
                ref.updateData(["BookmarkIDs": FieldValue.arrayRemove([self.textbook!.postID])])
                
                let index = oldIDs.firstIndex(of: self.textbook!.postID)
                oldIDs.remove(at: index!)
                userDefaults.set(oldIDs, forKey: "BookmarkIDs")
            } else {
                bookmarkButton.image = UIImage(systemName: "bookmark.fill")
                ref.updateData(["BookmarkIDs": FieldValue.arrayUnion([self.textbook!.postID])])
                
                oldIDs.append(self.textbook!.postID)
                userDefaults.set(oldIDs, forKey: "BookmarkIDs")

                let alert = UIAlertController(
                    title: "Bookmarked Item!",
                    message: "",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(
                    title: "Ok",
                    style: .default
                ))
                self.present(alert, animated: true)
            }
        } else {
            // Fallback on earlier versions
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.isHidden = false
        
        setUpUI()
    }
    
    private func setUpUI() {
        titleLabel.text = textbook!.name
        authorLabel.text = textbook!.author
        qualityLabel.text = "Quality: \(textbook!.quality)"
        priceLabel.text = "Price: \(textbook!.price)"
        classLabel.text = "Class: \(textbook!.classes)"
        itemImage = UIImage(named: "placeholder")
        
        let imageRef = Storage.storage().reference().child("Schools/\(school.concatenated)/ProductImages/\(textbook!.imageID).jpg")
        imageRef.getData(maxSize: Storyboard.megabyteValue) { data, error in
            if error == nil {
                self.itemImage = UIImage(data: data!)
            } else {
                print("Error getting images: \(String(describing: error))")
                self.itemImage = UIImage(named: "noimage")
            }
        }
        let timeAdded = textbook!.timeAdded
        let format = DateFormatter()
        format.dateFormat = "MM/dd/yyyy"
        let postedDate = format.string(from: timeAdded)
                
        let userRef = Firestore.firestore().collection("Schools/\(school.concatenated)/Users").document(textbook!.ownerUID)
        userRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let data = document.data()!
                let user = User(dictionary: data)
                self.owner = user
                self.userAndTimeLabel.text = "Posted by \(user.name) on \(postedDate)"
                self.messageButton.setTitle("Message \(user.name)", for: .normal)
            } else {
                print("Document does not exist")
            }
        }
        
        let bookmarkIDs = UserDefaults.standard.array(forKey: "BookmarkIDs") as? [String] ?? [String]()
        
        if bookmarkIDs.contains(self.textbook!.postID) {
            if #available(iOS 13.0, *) {
                self.bookmarkButton.image = UIImage(systemName: "bookmark.fill")
            } else {
                // Fallback on earlier versions
            }
        } else {
            if #available(iOS 13.0, *) {
                self.bookmarkButton.image = UIImage(systemName: "bookmark")
            } else {
                // Fallback on earlier versions
            }
        }
        
    }
    
    @IBAction func buyItem(_ sender: UIButton) {
        if let appURL = URL(string: "venmo://") {
            UIApplication.shared.canOpenURL(appURL)
            
            let appName = "Wallet"
            let appScheme = "\(appName)://"
            let appSchemeURL = URL(string:appScheme)
            
            if UIApplication.shared.canOpenURL(appSchemeURL! as URL) {
                UIApplication.shared.open(appSchemeURL!, options: [:], completionHandler: nil)
            } else {
                let alert = UIAlertController(title: "\(appName) Error..", message: "The app named \(appName) was not found, please install the app via appstore.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func messageOwner(_ sender: UIButton) {
        let userRef = Firestore.firestore().collection("Schools/\(school.concatenated)/Users").document(currUID)
        userRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let data = document.data()!
                let currentUser = User(dictionary: data)
                
                var channelAlreadyExists: Bool = false
                for currChannelID in currentUser.channelIDs {
                    for otherChannelID in self.owner!.channelIDs {
                        if currChannelID == otherChannelID {
                            channelAlreadyExists = true
                            let existingChannel = Channel(channelID: currChannelID, currentUser: currentUser, otherUser: self.owner!)
                            let vc = ChatViewController(channel: existingChannel)
                            self.navigationController?.pushViewController(vc, animated: true)
                        }
                    }
                }
                
                if !channelAlreadyExists {
                    let channelID = UUID().uuidString
                    let newChannel = Channel(channelID: channelID, currentUser: currentUser, otherUser: self.owner!)
                    
                    let ref = Firestore.firestore()
                    ref.collection("Schools/\(self.school.concatenated)/Channels").document(channelID).setData(newChannel.toDictionary())
                    ref.collection("Schools/\(self.school.concatenated)/Users").document(currentUser.uid).updateData([
                        "ChannelIDs": FieldValue.arrayUnion([channelID])])
                    ref.collection("Schools/\(self.school.concatenated)/Users").document(self.owner!.uid).updateData([
                        "ChannelIDs": FieldValue.arrayUnion([channelID])])
                    self.owner?.channelIDs.append(channelID)
                    let vc = ChatViewController(channel: newChannel)
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            }
        }
    }
    
    private struct Storyboard {
        static let megabyteValue = Int64(1 * 1024 * 1024)
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}
