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

class SearchUserTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    var searchResults = [String]()
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    let school = Utilities.getSchool()
    
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
            let userUID = searchResults[indexPath.row]
            
            let userRef = Firestore.firestore().collection("Schools/\(school.concatenated)/Users").document(userUID)
            userRef.getDocument { (document, error) in
                if let document = document, document.exists {
                    let user = User(dictionary: document.data()!)
                    print(user)
                    userCell.user = user
                } else {
                    print("Document does not exist")
                }
            }
            
            let storageRef = Storage.storage().reference()
            let profRef = storageRef.child("Schools/\(school.concatenated)/UserImages/\(userUID).jpg")
            profRef.getData(maxSize: 1 * 1024 * 1024) { data, error in
                if let error = error {
                    print("error")
                } else {
                    userCell.userImage = UIImage(data: data!)
                }
            }
        }
        
        return cell
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let client = Client(appID: "P6X728Y0HP", apiKey: "5b309ec79c4f09ce850f1ace9e1115f0")
        let index = client.index(withName: "dev_Users")
        let query = Query(query: searchText)
        query.filters = "(School:\(school)"
        query.attributesToRetrieve = ["Name"]
        query.hitsPerPage = 50
        index.search(query, completionHandler: { (content, error) -> Void in
            if error == nil {
                print("content starts here")
                let arr = content?["hits"] as! NSArray
                let json = arr.count != 0 ? arr[0] as? [String: Any] : ["Name": "ye"]
                print(json?["Name"] ?? "ye")
                let db = Firestore.firestore()
                db.collection("Schools/\(self.school.concatenated)/Users").whereField("Name", isEqualTo: json?["Name"] ?? "ye").getDocuments() { (querySnapshot, err) in
                    if let err = err {
                        print("Error getting documents: \(err)")
                    } else {
                        var newResults = [String]()
                        for document in querySnapshot!.documents {
                            newResults.append(document.documentID)
                        }
                        self.searchResults = newResults
                        self.tableView.reloadData()
                    }
                }
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
