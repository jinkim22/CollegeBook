//
//  MessagesTableViewController.swift
//  CollegeBook
//
//  Created by Avi Khemani on 9/7/19.
//  Copyright © 2019 Avi Khemani. All rights reserved.
//

import UIKit
import Firebase
import FirebaseMessaging

class MessagesTableViewController: UITableViewController {
    
    var channels = [Channel]()
    
    let userImagesMap = [String : UIImage]()
    
    let dispatchGroup = DispatchGroup()
    
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
        if #available(iOS 10.0, *) {
            tableView.refreshControl = myRefreshControl
        } else {
            tableView.addSubview(myRefreshControl)
        }
        
        downloadMessages()
    }
    
    private func downloadMessages() {
        let userRef = Firestore.firestore().collection("Schools/\(school.concatenated)/Users").document(currUID)
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
                    self.tableView.reloadData()
                })
            } else {
                print("Document does not exist")
            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return channels.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Message User Cell", for: indexPath)
        if let messageCell = cell as? ChannelTableViewCell {
            let channel = channels[indexPath.row]
            messageCell.channel = channel
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(70)
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
