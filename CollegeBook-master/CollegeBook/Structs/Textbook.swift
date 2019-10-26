//
//  Textbook.swift
//  CollegeBook
//
//  Created by Avi Khemani on 7/18/19.
//  Copyright © 2019 Avi Khemani. All rights reserved.
//

import Foundation
import Firebase

struct Textbook {
    
    var name: String
    var author: String
    var quality: String
    var price: Double
    var classes: [String]
    var imageID: String
    var ownerUID: String
    var timeAdded: Date
    var postID: String
    
    init(dictionary: [String: Any]) {
        name = dictionary["Name"] as? String ?? "N/A"
        author = dictionary["Author"] as? String ?? "N/A"
        quality = dictionary["Quality"] as? String ?? "N/A"
        price = dictionary["Price"] as? Double ?? 0.0
        classes = dictionary["Class"] as? [String] ?? []
        imageID = dictionary["ImageID"] as? String ?? ""
        ownerUID = dictionary["OwnerUID"] as? String ?? "N/A"
        let timestamp = dictionary["TimeAdded"] as? Timestamp
        timeAdded = timestamp?.dateValue() ?? Date()
        postID = dictionary["PostID"] as? String ?? "N/A"
    }
    
}

extension Textbook: Comparable {
    
    static func < (lhs: Textbook, rhs: Textbook) -> Bool {
        return lhs.timeAdded > rhs.timeAdded
    }
    
}
