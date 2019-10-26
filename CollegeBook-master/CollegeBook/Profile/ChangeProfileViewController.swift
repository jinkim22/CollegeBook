//
//  ChangeProfileViewController.swift
//  CollegeBook
//
//  Created by Avi Khemani on 9/25/19.
//  Copyright © 2019 Avi Khemani. All rights reserved.
//

import UIKit
import RSKImageCropper
import Firebase
import InstantSearchClient

class ChangeProfileViewController: UIViewController, UIImagePickerControllerDelegate, RSKImageCropViewControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {
    
    var userDetails: UserDetails?
    var profileImage: UIImage?
    
    let school = Utilities.getSchool()
    let currUID = Utilities.getUID()
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UITextField!
    @IBOutlet weak var bioLabel: UITextField!
    @IBOutlet weak var venmoIDLabel: UITextField!

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
        let imageRef = storageRef.child("Schools/\(school.concatenated)/UserImages/\(name).jpg")
        
        let _ = imageRef.putData(data, metadata: nil) { (metadata, error) in
            guard let metadata = metadata else {
                return
            }
            let _ = metadata.size
            imageRef.downloadURL { (url, error) in
                guard let _ = url else {
                    return
                }
            }
        }
    }
    
    private func importPicture(withType sourceType: UIImagePickerController.SourceType) {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.sourceType = sourceType
                
        self.present(imagePickerController, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let image = (info[.originalImage] as? UIImage)!

        let imageCropVC = RSKImageCropViewController(image: image, cropMode: .circle)
        imageCropVC.delegate = self
        picker.pushViewController(imageCropVC, animated: true)
    }
    
    func imageCropViewControllerDidCancelCrop(_ controller: RSKImageCropViewController) {
        self.navigationController?.dismiss(animated: true)
    }
    
    func imageCropViewController(_ controller: RSKImageCropViewController, didCropImage croppedImage: UIImage, usingCropRect cropRect: CGRect, rotationAngle: CGFloat) {
        profileImage = croppedImage
        profileImageView.image = croppedImage
        
        self.navigationController?.dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    @IBAction func saveInfo(_ sender: UIBarButtonItem) {
        userDetails?.name = nameLabel.text ?? ""
        userDetails?.bio = bioLabel.text ?? ""
        userDetails?.venmoID = venmoIDLabel.text ?? ""
        
        let userDefaults = UserDefaults.standard
        userDefaults.set(userDetails!.name, forKey: "Name")
        userDefaults.set(userDetails!.bio, forKey: "Bio")
        userDefaults.set(userDetails!.venmoID, forKey: "VenmoID")
        
        let updatedUser: [String: Any] = ["Name": userDetails?.name ?? "", "Bio": userDetails?.bio ?? "", "VenmoID": userDetails?.venmoID ?? ""]
        Firestore.firestore().collection("Schools/\(school.concatenated)/Users").document(currUID).setData(updatedUser, merge: true)
        
        //update algolia
        let client = Client(appID: "P6X728Y0HP", apiKey: "5b309ec79c4f09ce850f1ace9e1115f0")
        let index = client.index(withName: "dev_Users")
        let partialObject = ["Name": nameLabel.text ?? ""]
        index.partialUpdateObject(partialObject, withID: currUID)
        
        writeImageToDatabase(image: profileImage!, name: currUID)
        
        performSegue(withIdentifier: "Save Profile", sender: sender)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        nameLabel.delegate = self
        bioLabel.delegate = self
        venmoIDLabel.delegate = self

        profileImageView.layer.cornerRadius = profileImageView.frame.size.width / 2
        profileImageView.clipsToBounds = true
        profileImageView.image = profileImage
        
        if let details = userDetails {
            nameLabel.text = details.name
            bioLabel.text = details.bio
            venmoIDLabel.text = details.venmoID
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }
    
    private struct Storyboard {
        static let photoLibraryOption = "Photo Library"
        static let cameraOption = "Camera"
        static let cancelOption = "Cancel"
        static let megabyteValue = Int64(1 * 1024 * 1024)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Save Profile" {
            if let vc = segue.destination as? ProfileViewController {
                vc.user?.name = userDetails?.name ?? ""
                vc.user?.bio = userDetails?.bio ?? ""
                vc.user?.venmoID = userDetails?.venmoID ?? ""
                vc.profileImageView.image = profileImage
            }
        }
    }
    

}
