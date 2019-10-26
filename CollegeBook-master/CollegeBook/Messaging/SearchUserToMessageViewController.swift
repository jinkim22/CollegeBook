//
//  SearchUserTableViewController.swift
//  CollegeBook
//
//  Created by Avi Khemani on 8/8/19.
//  Copyright © 2019 Avi Khemani. All rights reserved.
//

import UIKit
import Firebase
import InstantSearchClient

class SearchUserToMessageViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    var searchResults = [User]()
    
    let school = Utilities.getSchool()
    let currUID = Utilities.getUID()
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        searchBar.delegate = self
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "User Cell", for: indexPath)
        if let userCell = cell as? UserTableViewCell {
            let user = searchResults[indexPath.row]
            userCell.user = user
            
            userCell.userImage = UIImage(named: "placeholder")
            let storageRef = Storage.storage().reference()
            let profRef = storageRef.child("Schools/\(school.concatenated)/UserImages/\(user.uid).jpg")
            profRef.getData(maxSize: 1 * 1024 * 1024) { data, error in
                if let _ = error {
                    print("error")
                } else {
                    userCell.userImage = UIImage(data: data!)
                }
            }
        }
        return cell
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        searchBar.resignFirstResponder()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let userRef = Firestore.firestore().collection("Schools/\(school.concatenated)/Users").document(currUID)
        userRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let data = document.data()!
                let currentUser = User(dictionary: data)
                let otherUser = self.searchResults[indexPath.row]
                
                var channelAlreadyExists: Bool = false
                for currChannelID in currentUser.channelIDs {
                    for otherChannelID in otherUser.channelIDs {
                        if currChannelID == otherChannelID {
                            channelAlreadyExists = true
                            let existingChannel = Channel(channelID: currChannelID, currentUser: currentUser, otherUser: otherUser)
                            let vc = ChatViewController(channel: existingChannel)
                            self.navigationController?.pushViewController(vc, animated: true)
                        }
                    }
                }
                
                if !channelAlreadyExists {
                    let channelID = UUID().uuidString
                    let newChannel = Channel(channelID: channelID, currentUser: currentUser, otherUser: otherUser)
                    
                    let ref = Firestore.firestore()
                    ref.collection("Schools/\(self.school.concatenated)/Channels").document(channelID).setData(newChannel.toDictionary())
                    ref.collection("Schools/\(self.school.concatenated)/Users").document(currentUser.uid).updateData([
                        "ChannelIDs": FieldValue.arrayUnion([channelID])])
                    ref.collection("Schools/\(self.school.concatenated)/Users").document(otherUser.uid).updateData([
                        "ChannelIDs": FieldValue.arrayUnion([channelID])])
                    let vc = ChatViewController(channel: newChannel)
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            } else {
                print("Document does not exist")
            }
        }
    }

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = true
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchResults = []
        tableView.reloadData()
        searchBar.text = ""
        searchBar.placeholder = "Search"
        searchBar.resignFirstResponder()
        searchBar.showsCancelButton = false
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    let dispatchGroup = DispatchGroup()
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchResults = []
        tableView.reloadData()
        
        let db = Firestore.firestore()
        let client = Client(appID: "P6X728Y0HP", apiKey: "5b309ec79c4f09ce850f1ace9e1115f0")
        let index = client.index(withName: "dev_Users")
        let query = Query(query: searchText)
        query.filters = "(School:\(school))"

        query.attributesToRetrieve = ["Name"]
        query.hitsPerPage = 50
        index.search(query, completionHandler: { (content, error) -> Void in
            if error == nil {
                var newResults = [User]()
                
                let arr = content?["hits"] as! NSArray
                var seen = Set<String>()
                for i in 0..<arr.count {
                    let json = arr[i] as! [String: Any]
                    let name = json["Name"] as! String
                    if !seen.insert(name).inserted {
                        continue
                    }
                    
                    self.dispatchGroup.enter()
                    db.collection("Schools/\(self.school.concatenated)/Users").whereField("Name", isEqualTo: name).getDocuments() { (querySnapshot, err) in
                        if let err = err {
                            print("Error getting documents: \(err)")
                        } else {
                            for document in querySnapshot!.documents {
                                if document.documentID != self.currUID {
                                    let userRef = db.collection("Schools/\(self.school.concatenated)/Users").document(document.documentID)
                                    userRef.getDocument { (document, error) in
                                        if let document = document, document.exists {
                                            let user = User(dictionary: document.data()!)
                                            newResults.append(user)
                                        } else {
                                            print("Document does not exist")
                                        }
                                        self.dispatchGroup.leave()
                                    }
                                }
                            }
                        }
                    }
                }
                
                self.dispatchGroup.notify(queue: .main, execute: {
                    self.searchResults = newResults
                    self.tableView.reloadData()
                })
            }
        })
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(70)
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    //    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    //    }
    
    
    private struct Storyboard {
        static let megabyteValue = Int64(1 * 1024 * 1024)
    }
    
}
