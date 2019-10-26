//
//  UserTableViewCell.swift
//  CollegeBook
//
//  Created by Avi Khemani on 8/8/19.
//  Copyright © 2019 Avi Khemani. All rights reserved.
//

import UIKit

class UserTableViewCell: UITableViewCell {

    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    
    var user: User? {
        didSet {
            nameLabel.text = user?.name
            emailLabel.text = user?.email
        }
    }
    
    var userImage: UIImage? {
        didSet {
            userImageView.image = userImage
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
