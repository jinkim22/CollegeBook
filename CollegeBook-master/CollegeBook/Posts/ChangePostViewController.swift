//
//  ChangePostViewController.swift
//  CollegeBook
//
//  Created by Avi Khemani on 9/29/19.
//  Copyright © 2019 Avi Khemani. All rights reserved.
//

import UIKit
import Firebase
import InstantSearchClient

class ChangePostViewController: UIViewController, UITextFieldDelegate {

    var textbook: Textbook?
    
    @IBOutlet weak var itemImageView: UIImageView!
    
    let school = Utilities.getSchool()
    
    private var itemImage: UIImage? {
        didSet {
            itemImageView.image = itemImage
        }
    }
    
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var authorTextField: UITextField!
    @IBOutlet weak var qualityTextField: UITextField!
    @IBOutlet weak var priceTextField: UITextField!
    @IBOutlet weak var classTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleTextField.delegate = self
        authorTextField.delegate = self
        qualityTextField.delegate = self
        priceTextField.delegate = self
        classTextField.delegate = self
        
        titleTextField.text = textbook?.name
        authorTextField.text = textbook?.author
        qualityTextField.text = textbook?.quality
        priceTextField.text = "\(textbook!.price)"
        classTextField.text = textbook?.classes[0]
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
    }
    
    
    @IBAction func savePost(_ sender: UIBarButtonItem) {
        let newTitle = titleTextField.text!
        let newAuthor = authorTextField.text!
        let newQuality = qualityTextField.text!
        let newPrice = priceTextField.text!
        let newClass = classTextField.text!
        
        textbook?.name = newTitle
        textbook?.author = newAuthor
        textbook?.quality = newQuality
        textbook?.price = Double(newPrice) ?? 0.0
        textbook?.classes = [newClass]
        
        let newTextbook: [String: Any] = ["Name": textbook!.name, "Author": textbook!.author, "Class": textbook!.classes, "Price": textbook!.price, "Quality": textbook!.quality]
        Firestore.firestore().collection("Schools/\(school.concatenated)/Books").document(textbook!.postID).updateData(newTextbook)
        
        let client = Client(appID: "P6X728Y0HP", apiKey: "5b309ec79c4f09ce850f1ace9e1115f0")
               let index = client.index(withName: "dev_Books")
        let partialObject = ["Name": textbook!.name]
        index.partialUpdateObject(partialObject, withID: textbook!.postID)
        
        performSegue(withIdentifier: "Save Item", sender: nil)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }
    
    private struct Storyboard {
        static let megabyteValue = Int64(1 * 1024 * 1024)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Save Item" {
            if let destination = segue.destination as? ItemOwnerViewController {
                destination.textbook = textbook
            }
        }
    }
    

}
