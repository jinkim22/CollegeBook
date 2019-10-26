//
//  MessagesCollectionViewController.swift
//  CollegeBook
//
//  Created by Avi Khemani on 10/11/19.
//  Copyright © 2019 Avi Khemani. All rights reserved.
//

import UIKit
import Firebase
import FirebaseMessaging
import NVActivityIndicatorView

private let reuseIdentifier = "Channel Collection Cell"

class MessagesCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    var channels = [Channel]()
    let dispatchGroup = DispatchGroup()
    var spinner: NVActivityIndicatorView?
    
    let school = Utilities.getSchool()
    let currUID = Utilities.getUID()
    
    lazy var myRefreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        
        refreshControl.tintColor = .black
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(reloadMessages), for: .valueChanged)
        
        return refreshControl
    }()
    
    @objc func reloadMessages() {
        downloadMessages()
        
        let deadline = DispatchTime.now() + .milliseconds(600)
        DispatchQueue.main.asyncAfter(deadline: deadline) {
            self.myRefreshControl.endRefreshing()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let frame = CGRect(x: collectionView.frame.width/2 - 15, y: collectionView.frame.height/3.5 , width: 70, height: 70)
        spinner = NVActivityIndicatorView(frame: frame, type: .pacman, color: .white)
        collectionView.addSubview(spinner!)
        
        if #available(iOS 10.0, *) {
            collectionView.refreshControl = myRefreshControl
        } else {
            collectionView.addSubview(myRefreshControl)
        }
        
        spinner?.startAnimating()
        downloadMessages()
    }
    
    private func downloadMessages() {
        let userRef = Firestore.firestore().collection("Schools/\(self.school.concatenated)/Users").document(currUID)
        userRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let data = document.data()!
                let currentUser = User(dictionary: data)
                
                var newChannels = [Channel]()
                for channelID in currentUser.channelIDs {
                    self.dispatchGroup.enter()
                    let channelRef = Firestore.firestore().collection("Schools/\(self.school.concatenated)/Channels").document(channelID)
                    channelRef.getDocument { (document, error) in
                        if let document = document, document.exists {
                            let channelData = document.data()!
                            let user1UID = channelData["User1UID"] as? String ?? "N/A"
                            let user2UID = channelData["User2UID"] as? String ?? "N/A"
                            let otherUID = self.currUID == user1UID ? user2UID : user1UID
                            
                            let userRef = Firestore.firestore().collection("Schools/\(self.school.concatenated)/Users").document(otherUID)
                            userRef.getDocument { (document, error) in
                                if let document = document, document.exists {
                                    let otherUser = User(dictionary: document.data()!)
                                    
                                    let newChannel = Channel(dictionary: channelData, currentUser: currentUser, otherUser: otherUser)
                                    newChannels.append(newChannel)
                                }
                                self.dispatchGroup.leave()
                            }
                        }
                    }
                }
                self.dispatchGroup.notify(queue: .main, execute: {
                    newChannels.sort()
                    self.channels = newChannels
                    self.collectionView.reloadData()
                    self.spinner?.stopAnimating()
                })
            } else {
                print("Document does not exist")
            }
        }
    }
    
    // MARK: UICollectionViewDataSource
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return channels.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
        if let messageCell = cell as? ChannelCollectionViewCell {
            let channel = channels[indexPath.row]
            messageCell.channel = channel
        }
        return cell
    }
    
    // MARK: UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let channel = channels[indexPath.row]
        
        if let read = channel.read {
            if !read {
                Firestore.firestore().collection("Schools/\(school.concatenated)/Channels").document(channel.channelID).setData(["read": true], merge: true)
                Utilities.decBadgeNum()
            }
        }
        
        
        
        let vc = ChatViewController(channel: channel)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction private func returnToMessages(bySegue: UIStoryboardSegue) {
        if let source = bySegue.source as? SearchUserToMessageViewController {
            source.searchBar.resignFirstResponder()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.size.width - 10, height: CGFloat(70))
    }
    
}
