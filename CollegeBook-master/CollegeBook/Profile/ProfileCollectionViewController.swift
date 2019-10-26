////
////  ProfileCollectionViewController.swift
////  CollegeBook
////
////  Created by Jin Kim on 10/21/19.
////  Copyright © 2019 Avi Khemani. All rights reserved.
////
//
//import Foundation
//import GoogleSignIn
//import Firebase
//
//class ProfileCollectionViewController: UICollectionViewController, UITableViewDelegate, UITableViewDataSource {
//
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return itemsToDisplay.count
//    }
//
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: "Item Cell", for: indexPath)
//        let storageRef = Storage.storage().reference()
//        if let itemCell = cell as? ItemTableViewCell {
//            let textbook = itemsToDisplay[indexPath.row]
//            itemCell.textbook = textbook
//            let islandRef = storageRef.child("Schools/\(school.concatenated)/ProductImages/\(textbook.imageID).jpg")
//            islandRef.getData(maxSize: Storyboard.megabyteValue) { data, error in
//                if error != nil {
//                    print("Failed to get \(textbook.name) image")
//                    print("Error: \(error!)")
//                    itemCell.itemImage = UIImage(named: "noimage")
//                } else {
//                    print("Successfully downloaded image!")
//                    itemCell.itemImage = UIImage(data: data!)
//                }
//            }
//        }
//        return cell
//    }
//
//    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return CGFloat(125)
//    }
//
//
//}
