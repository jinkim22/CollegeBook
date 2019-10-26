//
//  NewItemCollectionViewController.swift
//  CollegeBook
//
//  Created by Avi Khemani on 10/6/19.
//  Copyright © 2019 Avi Khemani. All rights reserved.
//

import UIKit
import Firebase
import NVActivityIndicatorView

private let reuseIdentifier = "Textbook Cell"

class NewItemCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    var textbooks = [Textbook]()
    var spinner: NVActivityIndicatorView?
    
    let school = Utilities.getSchool()
    let currUID = Utilities.getUID()
    
    lazy var myRefreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        
        refreshControl.tintColor = .black
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(reloadTextbooks), for: .valueChanged)
        
        return refreshControl
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let frame = CGRect(x: collectionView.frame.width/2 - 15, y: collectionView.frame.height/3.5 , width: 70, height: 70)
        spinner = NVActivityIndicatorView(frame: frame, type: .pacman, color: .white)
        collectionView.addSubview(spinner!)
        
        if isLoggedIn() == false {
            performSegue(withIdentifier: "returnToLogin", sender: self)
        } else {
            askForPermission()
            if #available(iOS 10.0, *) {
                collectionView.refreshControl = myRefreshControl
            } else {
                collectionView.addSubview(myRefreshControl)
            }
            spinner?.startAnimating()
            downloadTextbooks()
        }
    }
    
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
                self.collectionView.reloadData()
                self.spinner?.stopAnimating()
            }
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return textbooks.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
        
        if let textbookCell = cell as? TextbookCollectionViewCell {
            let textbook = textbooks[indexPath.row]
            textbookCell.textbook = textbook
            textbookCell.itemImage = UIImage(named: "placeholder")
            
//            let imageRef = storageRef.child("ProductImages/\(textbook.imageID).jpg")
//            imageRef.getData(maxSize: Storyboard.megabyteValue) { data, error in
//                if error == nil {
//                    textbookCell.itemImage = UIImage(data: data!)
//                } else {
//                    print("Error getting images: \(String(describing: error))")
//                    textbookCell.itemImage = UIImage(named: "noimage")
//                }
//            }
            
            ImageCache.getImage(with: "Schools/\(school.concatenated)/ProductImages/\(textbook.imageID).jpg") { image in
                textbookCell.itemImage = image
            }
        }
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let textbook = textbooks[indexPath.row]
        let cell = collectionView.cellForItem(at: indexPath)
        if textbook.ownerUID == currUID {
            performSegue(withIdentifier: "Show Item Details Owner Segue", sender: cell)
        } else {
            performSegue(withIdentifier: "Show Item Details Segue", sender: cell)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.size.width - 10, height: CGFloat(140))
    }
    
    
    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Show Item Details Segue" {
            if let destination = segue.destination as? ItemDetailsViewController {
                if let textbookCell = sender as? TextbookCollectionViewCell {
                    destination.textbook = textbookCell.textbook
                }
            }
        } else if segue.identifier == "Show Item Details Owner Segue" {
            if let destination = segue.destination as? ItemOwnerViewController {
                if let textbookCell = sender as? TextbookCollectionViewCell {
                    destination.textbook = textbookCell.textbook
                }
            }
        }
    }
    
    private struct Storyboard {
           static let megabyteValue = Int64(1 * 1024 * 1024)
       }

}
