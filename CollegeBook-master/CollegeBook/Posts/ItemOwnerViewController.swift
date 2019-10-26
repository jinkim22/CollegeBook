//
//  ItemOwnerViewController.swift
//  CollegeBook
//
//  Created by Avi Khemani on 9/28/19.
//  Copyright © 2019 Avi Khemani. All rights reserved.
//

import UIKit
import Firebase

class ItemOwnerViewController: UIViewController {
    
    var textbook: Textbook?
    let school = Utilities.getSchool()
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var qualityLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var classLabel: UILabel!
    @IBOutlet weak var userAndTimeLabel: UILabel!
    
    @IBOutlet weak var itemImageView: UIImageView!
    
    var itemImage: UIImage? {
        didSet {
            itemImageView.image = itemImage
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
                self.userAndTimeLabel.text = "Posted by \(user.name) on \(postedDate)"
            } else {
                print("Document does not exist")
            }
        }
    }
    
    @IBAction func goBackToPostWithoutEditing(segue: UIStoryboardSegue) {
           
       }
    
    @IBAction func goBackToPostWithEditing(segue: UIStoryboardSegue) {
       titleLabel.text = textbook!.name
       authorLabel.text = textbook!.author
       qualityLabel.text = "Quality: \(textbook!.quality)"
       priceLabel.text = "Price: \(textbook!.price)"
       classLabel.text = "Class: \(textbook!.classes)"
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Change Post Segue" {
            if let nc = segue.destination as? UINavigationController {
                if let vc = nc.visibleViewController as? ChangePostViewController {
                    vc.textbook = textbook
                }
            }
        }
    }
    
    private struct Storyboard {
        static let megabyteValue = Int64(1 * 1024 * 1024)
    }
    
}
