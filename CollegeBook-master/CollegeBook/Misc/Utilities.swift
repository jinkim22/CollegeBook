//
//  Utilities.swift
//  CollegeBook
//
//  Created by Jin Kim on 10/19/19.
//  Copyright © 2019 Avi Khemani. All rights reserved.
//

import Foundation
import Firebase

class Utilities {
    
    static func getSchool() -> String {
        return UserDefaults.standard.string(forKey: "School") ?? "NoSchool"
    }
    
    static func getUID() -> String {
        return UserDefaults.standard.string(forKey: "UID") ?? ""
    }
    
    static func decBadgeNum() {
        if UIApplication.shared.applicationIconBadgeNumber > 0 {
            UIApplication.shared.applicationIconBadgeNumber -= 1
        }
    }
    
    static func writeImageToDatabase(image: UIImage, name: String, ref: String) {
        let storageRef = Storage.storage().reference()
        let data = image.jpegData(compressionQuality: CGFloat(0.5))!
        let imageRef = storageRef.child(ref)
        
        imageRef.putData(data, metadata: nil) { (metadata, error) in
            guard let metadata = metadata else {
                return
            }
            imageRef.downloadURL { (url, error) in
                guard let downloadURL = url else {
                    return
                }
            }
        }
    }
}

extension String {
    
    var concatenated: String {
        return self.split(separator: " ").joined()
    }
    
}
