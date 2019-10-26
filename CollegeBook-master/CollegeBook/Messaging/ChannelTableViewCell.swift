//
//  MessageUserTableViewCell.swift
//  CollegeBook
//
//  Created by Avi Khemani on 9/7/19.
//  Copyright © 2019 Avi Khemani. All rights reserved.
//

import UIKit
import Firebase

class ChannelTableViewCell: UITableViewCell {

    @IBOutlet weak var otherUserImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var lastMessageLabel: UILabel!
    @IBOutlet weak var readDot: UIView!
    
    let school = Utilities.getSchool()
    
    var otherUserImage: UIImage? {
        didSet {
            otherUserImageView.image = otherUserImage
        }
    }
    
    var channel: Channel? {
        didSet {
            nameLabel.text = channel!.otherUser.name
            
            if let lastMessageDate = channel!.lastMessageDate {
                let format = DateFormatter()
                format.dateFormat = "HH:mm"
                let selectedDate = format.string(from: lastMessageDate)
                lastMessageLabel.text = "\(channel!.lastMessage ?? "") • \(selectedDate)"
            } else {
                lastMessageLabel.text = ""
            }
            
            if let lastID = channel?.lastMessageSenderID {
                if lastID != channel?.currentUser.uid, !channel!.read! {
                    readDot.isHidden = false
                } else {
                    readDot.isHidden = true
                }
            }
            
            otherUserImage = UIImage(named: "placeholder")
            
            let storageRef = Storage.storage().reference()
            let profRef = storageRef.child("Schools/\(school.concatenated)/UserImages/\(channel!.otherUser.uid).jpg")
            profRef.getData(maxSize: 1 * 1024 * 1024) { data, error in
                if error != nil {
                    self.otherUserImage = UIImage(named: "noimage")
                    print("error")
                } else {
                    self.otherUserImage = UIImage(data: data!)
                }
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        otherUserImageView.layer.cornerRadius = otherUserImageView.frame.size.width / 2.5
        otherUserImageView.clipsToBounds = true
        
        readDot.layer.cornerRadius = readDot.frame.size.width / 2
        readDot.clipsToBounds = true
    }
    
}
