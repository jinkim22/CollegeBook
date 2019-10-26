//
//  ItemTableViewCell.swift
//  CollegeBook
//
//  Created by Avi Khemani on 7/14/19.
//  Copyright © 2019 Avi Khemani. All rights reserved.
//

import UIKit

class ItemTableViewCell: UITableViewCell {

    @IBOutlet weak var itemImageView: UIImageView!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var qualityLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var classLabel: UILabel!
    
    var textbook: Textbook? {
        didSet {
            titleLabel.text = textbook!.name
            authorLabel.text = textbook!.author
            qualityLabel.text = "Quality: \(textbook!.quality)"
            priceLabel.text = "Price: \(textbook!.price)"
            classLabel.text = "Class: \(textbook!.classes)"
            //itemImage = UIImage(named: textbook!.name) ?? UIImage(named: "noimage")
        }
    }
    
    var itemImage: UIImage? {
        didSet {
            itemImageView.image = itemImage
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
