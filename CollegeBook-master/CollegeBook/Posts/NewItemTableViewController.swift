//
//  NewItemTableViewController.swift
//  CollegeBook
//
//  Created by Avi Khemani on 7/14/19.
//  Copyright © 2019 Avi Khemani. All rights reserved.
//

import UIKit
import Firebase
import UserNotifications

class NewItemTableViewController: UITableViewController {

    var textbooks = [Textbook]()
    let school = UserDefaults.standard.string(forKey: "School") ?? ""
    
    lazy var myRefreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        
        refreshControl.tintColor = .black
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(reloadTextbooks), for: .valueChanged)
        
        return refreshControl
    }()
    
    private func isLoggedIn() -> Bool {
        return Auth.auth().currentUser != nil
    }
    
    private func askForPermission() {
        let application = UIApplication.shared
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
            
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_, _ in })
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        application.registerForRemoteNotifications()
    }
   
    override func viewDidLoad() {
        super.viewDidLoad()
        if isLoggedIn() == false {
            performSegue(withIdentifier: "returnToLogin", sender: self)
        } else {
            askForPermission()
            if #available(iOS 10.0, *) {
                tableView.refreshControl = myRefreshControl
            } else {
                tableView.addSubview(myRefreshControl)
            }
            downloadTextbooks()
        }
    }
    
    @objc func reloadTextbooks() {
        downloadTextbooks()
        
        let deadline = DispatchTime.now() + .milliseconds(600)
        DispatchQueue.main.asyncAfter(deadline: deadline) {
            self.myRefreshControl.endRefreshing()
        }
    }
    
    private func downloadTextbooks() {
        let db = Firestore.firestore()
        db.collection("Schools/\(school.concatenated)/Books").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting textbooks: \(err)")
            } else {
                var updatedTextbooks = [Textbook]()
                for document in querySnapshot!.documents {
                    let newBook = Textbook(dictionary: document.data())
                    updatedTextbooks.append(newBook)
                }
                updatedTextbooks.sort()
                self.textbooks = updatedTextbooks
                self.tableView.reloadData()
            }
        }
    }

    // MARK: - Table View Data Source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return textbooks.count
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let ref = Firestore.firestore().collection("Schools/\(school.concatenated)/Users").document(Auth.auth().currentUser!.uid)
        let action = UIContextualAction(style: .normal, title: "Interested") { (action, view, completion) in
            ref.updateData(["InterestedIDs": FieldValue.arrayUnion([self.textbooks[indexPath.row].postID])])
            completion(true)
        }
        action.image = UIGraphicsImageRenderer(size: CGSize(width: 30, height: 30)).image { _ in
            UIImage(named: "star")?.draw(in: CGRect(x: 0, y: 0, width: 30, height: 30))
            action.backgroundColor = #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1)
        }
        return UISwipeActionsConfiguration(actions: [action])
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Item Cell", for: indexPath)
        let storageRef = Storage.storage().reference()
        
        if let itemCell = cell as? ItemTableViewCell {
            let textbook = textbooks[indexPath.row]
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
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let textbook = textbooks[indexPath.row]
        let cell = tableView.cellForRow(at: indexPath)
        if textbook.ownerUID == Auth.auth().currentUser!.uid {
            performSegue(withIdentifier: "Show Item Details Owner Segue", sender: cell)
        } else {
            performSegue(withIdentifier: "Show Item Details Segue", sender: cell)
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(125)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Show Item Details Segue" {
            if let destination = segue.destination as? ItemDetailsViewController {
                if let itemCell = sender as? ItemTableViewCell {
                    destination.textbook = itemCell.textbook
                }
            }
        } else if segue.identifier == "Show Item Details Owner Segue" {
            if let destination = segue.destination as? ItemOwnerViewController {
                if let itemCell = sender as? ItemTableViewCell {
                    destination.textbook = itemCell.textbook
                }
            }
        }
    }
    
    private struct Storyboard {
        static let megabyteValue = Int64(1 * 1024 * 1024)
    }
}
