//
//  ListMiscViewController.swift
//  CollegeBook
//
//  Created by Avi Khemani on 10/12/19.
//  Copyright © 2019 Avi Khemani. All rights reserved.
//

import UIKit
import Firebase
import InstantSearchClient

class ListMiscViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var itemImageView: UIImageView!
    @IBOutlet weak var priceTextField: UITextField!
    
    let school = UserDefaults.standard.string(forKey: "School") ?? ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        nameTextField.delegate = self
        priceTextField.delegate = self
        descriptionTextView.delegate = self
    }
    
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
    
    @IBAction func addMiscItem(_ sender: UIButton) {
        let name = nameTextField.text
        let price = priceTextField.text
        let description = descriptionTextView.text ?? ""
        let image = itemImageView.image
        
        let alert: UIAlertController
        if name == "" || price == "" || image == nil {
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
            
            let newMisc: [String: Any] = ["Name": name!, "Price": price!, "Description": description, "ImageID": imageIdentifier, "OwnerUID": currentUser.uid, "TimeAdded": Date(), "PostID" : postIdentifier]
            Firestore.firestore().collection("Schools/\(school.concatenated)/Misc").document(postIdentifier).setData(newMisc)
            
            writeImageToDatabase(image: image!, name: imageIdentifier)
            
            //            let client = Client(appID: "P6X728Y0HP", apiKey: "5b309ec79c4f09ce850f1ace9e1115f0")
            //            let index = client.index(withName: "dev_Books")
            //
            //            let newObject = ["objectID" : postIdentifier, "Name": title]
            //            index.addObject(newObject, completionHandler: { (content, error) -> Void in
            //                if error == nil {
            //                    if let objectID = content!["objectID"] as? String {
            //                        print("Object ID: \(objectID)")
            //                    }
            //                }
            //            })
            
            let ref = Firestore.firestore().collection("Schools/\(school.concatenated)/Users").document(currentUser.uid)
            
            ref.updateData([
                "MiscPostIDs": FieldValue.arrayUnion([String(postIdentifier)])
            ])
            alert = UIAlertController(
                title: "Item Added",
                message: "\(name!) has been successfully added",
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
        nameTextField.text = nil
        priceTextField.text = nil
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
