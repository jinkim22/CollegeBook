//
//  User.swift
//  CollegeBook
//
//  Created by Avi Khemani on 8/8/19.
//  Copyright © 2019 Avi Khemani. All rights reserved.
//

import Foundation

struct User {
    
    var name: String
    var uid: String
    var bio: String
    var email: String
    var postIDs: [String]
    var venmoID: String
    var channelIDs: [String]
    var fcmToken: String
    var deviceToken: String
    var bookmarkIDs: [String]
    var school: String
    
    init(dictionary: [String: Any]) {
        name = dictionary["Name"] as? String ?? "N/A"
        uid = dictionary["UID"] as? String ?? "N/A"
        bio = dictionary["Bio"] as? String ?? "N/A"
        email = dictionary["Email"] as? String ?? "N/A"
        postIDs = dictionary["PostIDs"] as? [String] ?? []
        venmoID = dictionary["VenmoID"] as? String ?? "N/A"
        channelIDs = dictionary["ChannelIDs"] as? [String] ?? []
        fcmToken = dictionary["fcmToken"] as? String ?? "N/A"
        deviceToken = dictionary["DeviceToken"] as? String ?? "N/A"
        bookmarkIDs = dictionary["BookmarkIDs"] as? [String] ?? []
        school = dictionary["School"] as? String ?? "N/A"
    }
    
    
}
