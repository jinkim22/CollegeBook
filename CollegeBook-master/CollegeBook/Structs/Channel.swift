//
//  Channel.swift
//  CollegeBook
//
//  Created by Avi Khemani on 9/7/19.
//  Copyright © 2019 Avi Khemani. All rights reserved.
//

import Foundation
import Firebase

struct Channel {
    
    var channelID: String
    var currentUser: User
    var otherUser: User
    var lastMessage: String?
    var lastMessageDate: Date?
    var lastMessageSenderID: String?
    var read: Bool?
    //var lastMessage: String = "This was the last message!"
    
    func toDictionary() -> [String : Any]{
        return ["ChannelID": channelID, "User1UID": currentUser.uid, "User2UID": otherUser.uid]
    }
    
    init(dictionary: [String: Any], currentUser: User, otherUser: User) {
        channelID = dictionary["ChannelID"] as? String ?? "N/A"
        lastMessage = dictionary["lastMessage"] as? String ?? ""
        let timestamp = dictionary["lastMessageTime"] as? Timestamp
        lastMessageDate = timestamp?.dateValue()
        self.currentUser = currentUser
        self.otherUser = otherUser
        self.lastMessageSenderID = dictionary["lastMessageSenderID"] as? String ?? ""
        self.read = dictionary["read"] as? Bool ?? true
    }
    
    init(channelID: String, currentUser: User, otherUser: User) {
        self.channelID = channelID
        self.currentUser = currentUser
        self.otherUser = otherUser
    }
    
}

extension Channel: Comparable {
    
    static func < (lhs: Channel, rhs: Channel) -> Bool {
        if lhs.lastMessageDate == nil {
            return false
        } else if rhs.lastMessageDate == nil {
            return true
        } else {
            return lhs.lastMessageDate! > rhs.lastMessageDate!
        }
    }
    
    static func == (lhs: Channel, rhs: Channel) -> Bool {
        return lhs.channelID == rhs.channelID
    }
    
}
