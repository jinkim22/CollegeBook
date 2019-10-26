//
//  ChannelCollectionViewCell.swift
//  CollegeBook
//
//  Created by Avi Khemani on 10/11/19.
//  Copyright © 2019 Avi Khemani. All rights reserved.
//

import UIKit
import Firebase

class ChannelCollectionViewCell: UICollectionViewCell {
    
    let school = Utilities.getSchool()

    @IBOutlet weak var otherUserImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var lastMessageLabel: UILabel!
    @IBOutlet weak var readDot: UIView!
    @IBOutlet weak var dateLabel: UILabel!
    
    var otherUserImage: UIImage? {
        didSet {
            otherUserImageView.image = otherUserImage
        }
    }
    
    var channel: Channel? {
        didSet {
            nameLabel.text = channel!.otherUser.name
            lastMessageLabel.text = "\(channel!.lastMessage ?? "")"
            
            if let lastMessageDate = channel!.lastMessageDate {
                let calendar = Calendar.current
                if !calendar.isDateInToday(lastMessageDate) {
                    let format = DateFormatter()
                    format.dateFormat = "EEEE"
                    let selectedDate = format.string(from: lastMessageDate)
                    let endIndex = selectedDate.index(selectedDate.startIndex, offsetBy: 3)
                    let range = selectedDate.startIndex..<endIndex
                    dateLabel.text = "• \(selectedDate[range])"
                } else{
                    let format = DateFormatter()
                    format.dateFormat = "h:mm a"
                    format.amSymbol = "am"
                    format.pmSymbol = "pm"
                    let selectedDate = format.string(from: lastMessageDate)
                    dateLabel.text = "• \(selectedDate)"
                }
            } else {
                lastMessageLabel.text = ""
                dateLabel.text = ""
            }
            
            if let lastID = channel?.lastMessageSenderID {
                if lastID != channel?.currentUser.uid, !channel!.read! {
                    readDot.isHidden = false
                } else {
                    readDot.isHidden = true
                }
            }
            
            otherUserImage = UIImage(named: "placeholder")
            
            ImageCache.getImage(with: "Schools/\(school.concatenated)/UserImages/\(channel!.otherUser.uid).jpg") { image in
                self.otherUserImage = image
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.layer.cornerRadius = 10
        self.clipsToBounds = true
        
        otherUserImageView.layer.cornerRadius = otherUserImageView.frame.size.width / 2
        otherUserImageView.clipsToBounds = true
        
        readDot.layer.cornerRadius = readDot.frame.size.width / 2
        readDot.clipsToBounds = true
    }
    
}
