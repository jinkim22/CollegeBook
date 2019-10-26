//
//  ListItemViewController.swift
//  CollegeBook
//
//  Created by Avi Khemani on 7/15/19.
//  Copyright © 2019 Avi Khemani. All rights reserved.
//

import UIKit
import Firebase
import InstantSearchClient

class ListItemViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {
    
    lazy var functions = Functions.functions()
    var scanner: Scanner?
    var bookTitle: String?
    var bookAuthor: String?
    
    let school = UserDefaults.standard.string(forKey: "School") ?? ""
    
    @IBOutlet weak var titleTextField: UITextField! {
        didSet {
            titleTextField.text = bookTitle
        }
    }
    @IBOutlet weak var authorTextField: UITextField! {
        didSet {
            authorTextField.text = bookAuthor
        }
    }
    @IBOutlet weak var qualityTextField: UITextField!
    @IBOutlet weak var priceTextField: UITextField!
    @IBOutlet weak var classTextField: UITextField!
    
    @IBOutlet weak var itemImageView: UIImageView!

    @IBAction func chooseImage(_ sender: UIButton) {
        let actionSheet = UIAlertController(
            title: "Photo Options",
            message: nil,
            preferredStyle: .actionSheet
        )
        actionSheet.addAction(UIAlertAction(
            title: Storyboard.cameraOption,
            style: .default,
            handler: { finished in
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    self.importPicture(withType: .camera)
                } else {
                    print("Cannot access camera")
                }
        }
        ))
        actionSheet.addAction(UIAlertAction(
            title: Storyboard.photoLibraryOption,
            style: .default,
            handler: { finished in
                self.importPicture(withType: .photoLibrary)
        }
        ))
        actionSheet.addAction(UIAlertAction(
            title: Storyboard.cancelOption,
            style: .cancel
        ))
        present(actionSheet, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleTextField.delegate = self
        authorTextField.delegate = self
        qualityTextField.delegate = self
        priceTextField.delegate = self
        classTextField.delegate = self
    }
    
    private func writeImageToDatabase(image: UIImage, name: String) {
        let storageRef = Storage.storage().reference()
        let data = image.jpegData(compressionQuality: CGFloat(0.5))!
        let imageRef = storageRef.child("Schools/\(school.concatenated)/ProductImages/\(name).jpg")
        
        let uploadTask = imageRef.putData(data, metadata: nil) { (metadata, error) in
            guard let metadata = metadata else {
                return
            }
            let size = metadata.size
            imageRef.downloadURL { (url, error) in
                guard let downloadURL = url else {
                    return
                }
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    private func importPicture(withType sourceType: UIImagePickerController.SourceType) {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.sourceType = sourceType
        imagePickerController.allowsEditing = true
        
        self.present(imagePickerController, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let image = info[.editedImage] as? UIImage {
            itemImageView.image = image
        } else if let image = info[.originalImage] as? UIImage {
            itemImageView.image = image
        }
        
        picker.dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    @IBAction func addTextbook(_ sender: UIButton) {
        let title = titleTextField.text
        let author = authorTextField.text
        let quality = qualityTextField.text
        let price = priceTextField.text
        let classes = classTextField.text
        let image = itemImageView.image
        
        let alert: UIAlertController
        if title == "" || author == "" || quality == "" || price == "" || classes == "" || image == nil {
            alert = UIAlertController(
                title: "Incomplete",
                message: "Please fill out all of the sections above",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(
                title: "Ok",
                style: .default
            ))
        } else {
            let postIdentifier = UUID().uuidString
            let imageIdentifier = UUID().uuidString
            let currentUser = Auth.auth().currentUser!
            
            let newTextbook: [String: Any] = ["Name": title!, "Author": author!, "Class": classes!.split(separator: ","), "Price": Double(price!) ?? 0.0, "Quality": quality!, "ImageID": imageIdentifier, "OwnerUID": currentUser.uid, "TimeAdded": Date(), "PostID" : postIdentifier]
            Firestore.firestore().collection("Schools/\(self.school.concatenated)/Books").document(postIdentifier).setData(newTextbook)
            
            var oldIDs = UserDefaults.standard.array(forKey: "PostIDs") as? [String] ?? [String]()
            oldIDs.append(postIdentifier)
            UserDefaults.standard.set(oldIDs, forKey: "PostIDs")
            
            writeImageToDatabase(image: image!, name: imageIdentifier)
            
            let client = Client(appID: "P6X728Y0HP", apiKey: "5b309ec79c4f09ce850f1ace9e1115f0")
            let index = client.index(withName: "dev_Books")
            
            let newObject = ["objectID" : postIdentifier, "Name": title]
            index.addObject(newObject, completionHandler: { (content, error) -> Void in
                if error == nil {
                    if let objectID = content!["objectID"] as? String {
                        print("Object ID: \(objectID)")
                    }
                }
            })
            
            let ref = Firestore.firestore().collection("Schools/\(self.school.concatenated)/Users").document(currentUser.uid)
            
            ref.updateData([
                "PostIDs": FieldValue.arrayUnion([String(postIdentifier)])
                ])
            
            alert = UIAlertController(
                title: "Textbook Added",
                message: "Your textbook \(title!) has been successfully added",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(
                title: "Ok",
                style: .default,
                handler: { finished in
                    self.resetFields()
                }
            ))
        }
        present(alert, animated: true)
    }
    
    private func resetFields() {
        titleTextField.text = nil
        authorTextField.text = nil
        qualityTextField.text = nil
        priceTextField.text = nil
        classTextField.text = nil
        itemImageView.image = nil
    }
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
    
    private struct Storyboard {
        static let photoLibraryOption = "Photo Library"
        static let cameraOption = "Camera"
        static let cancelOption = "Cancel"
    }
    
}
