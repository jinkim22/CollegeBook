//
//  SearchItemViewController.swift
//  CollegeBook
//
//  Created by Avi Khemani on 7/14/19.
//  Copyright © 2019 Avi Khemani. All rights reserved.
//

import UIKit
import Firebase
import InstantSearchClient

class SearchItemViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
   
    var textbookResults = [Textbook]()
    var userResults = [User]()
    var segmentedIndex: Int {
        get {
            segmentedControl.selectedSegmentIndex
        }
    }
    
    let school = Utilities.getSchool()
    let currUID = Utilities.getUID()
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBAction func segmentedControlTap(_ sender: UISegmentedControl) {
        tableView.reloadData()
    }
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.isHidden = true
        
        tableView.delegate = self
        tableView.dataSource = self
        searchBar.delegate = self
        searchBar.resignFirstResponder()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return segmentedIndex == 0 ? textbookResults.count : userResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        let storageRef = Storage.storage().reference()
        if segmentedIndex == 0 {
            cell = tableView.dequeueReusableCell(withIdentifier: "Item Cell", for: indexPath)
            if let itemCell = cell as? ItemTableViewCell {
                let textbook = textbookResults[indexPath.row]
                itemCell.textbook = textbook
                itemCell.itemImage = UIImage(named: "placeholder")
                
                let imageRef = storageRef.child("Schools/\(school.concatenated)/ProductImages/\(textbook.imageID).jpg")
                imageRef.getData(maxSize: Storyboard.megabyteValue) { data, error in
                    if error == nil {
                        itemCell.itemImage = UIImage(data: data!)
                    } else {
                        print("Error getting images: \(String(describing: error))")
                        itemCell.itemImage = UIImage(named: "noimage")
                    }
                }
            }
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: "User Cell", for: indexPath)
            if let userCell = cell as? UserTableViewCell {
                let user = userResults[indexPath.row]
                userCell.user = user
                
                userCell.userImage = UIImage(named: "placeholder")
                let profRef = storageRef.child("Schools/\(school.concatenated)/UserImages/\(user.uid).jpg")
                profRef.getData(maxSize: 1 * 1024 * 1024) { data, error in
                    if let _ = error {
                        print("error")
                    } else {
                        userCell.userImage = UIImage(data: data!)
                    }
                }
            }
        }
        return cell
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = true
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        textbookResults = []
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
        let db = Firestore.firestore()
        let client = Client(appID: "P6X728Y0HP", apiKey: "5b309ec79c4f09ce850f1ace9e1115f0")
        
        print("reloading...")
        if segmentedIndex == 0 {
            textbookResults = []
            tableView.reloadData()
            
            let index = client.index(withName: "dev_Books")
            let query = Query(query: searchText)
            query.filters = "School:\(school.concatenated)"
            query.attributesToRetrieve = ["Name"]
            query.hitsPerPage = 50
            print("searching")
            index.search(query, completionHandler: { (content, error) -> Void in
                if let error = error {
                    print(error)
                }
                if error == nil {
                    var newResults = [Textbook]()
                    
                    let arr = content?["hits"] as! NSArray
                    print(content)
                    var seen = Set<String>()
                    for i in 0..<arr.count {
                        let json = arr[i] as! [String: Any]
                        let name = json["Name"] as! String
                        if !seen.insert(name).inserted {
                            continue
                        }
                        
                        self.dispatchGroup.enter()
                        db.collection("Schools/\(self.school.concatenated)/Books").whereField("Name", isEqualTo: name).getDocuments() { (querySnapshot, err) in
                            if let err = err {
                                print("Error getting documents: \(err)")
                            } else {
                                for document in querySnapshot!.documents {
                                    newResults.append(Textbook(dictionary: document.data()))
                                }
                            }
                            self.dispatchGroup.leave()
                        }
                    }
                    
                    self.dispatchGroup.notify(queue: .main, execute: {
                        self.textbookResults = newResults
                        self.tableView.reloadData()
                    })
                }
            })
        } else {
            userResults = []
            tableView.reloadData()
            
            let index = client.index(withName: "dev_Users")
            let query = Query(query: searchText)
            query.filters = "School:\(school.concatenated)" 
            query.attributesToRetrieve = ["Name"]
            query.hitsPerPage = 50
            dispatchGroup.enter()
            index.search(query, completionHandler: { (content, error) -> Void in
                if error != nil {
                    print(error)
                } else {
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
                                        self.dispatchGroup.enter()
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
                            self.dispatchGroup.leave()
                        }
                    }
                    
                    self.dispatchGroup.leave()
                    self.dispatchGroup.notify(queue: .main, execute: {
                        self.userResults = newResults
                        self.tableView.reloadData()
                    })
                }
            })
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return segmentedIndex == 0 ? CGFloat(125) : CGFloat(70)
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Show Item Details Segue" {
            if let destination = segue.destination as? ItemDetailsViewController {
                if let itemCell = sender as? ItemTableViewCell {
                    destination.textbook = itemCell.textbook
                }
            }
        } else if segue.identifier == "User Details Segue" {
            if let destination = segue.destination as? UserDetailsViewController {
                if let userCell = sender as? UserTableViewCell {
                    destination.user = userCell.user
                }
            }
        }
    }
    
    private struct Storyboard {
        static let megabyteValue = Int64(1 * 1024 * 1024)
    }
}
