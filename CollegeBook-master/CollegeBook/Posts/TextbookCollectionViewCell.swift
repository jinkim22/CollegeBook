//
//  TextbookCollectionViewCell.swift
//  CollegeBook
//
//  Created by Avi Khemani on 10/6/19.
//  Copyright © 2019 Avi Khemani. All rights reserved.
//

import UIKit

class TextbookCollectionViewCell: UICollectionViewCell {
    
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
        }
    }
    
    var itemImage: UIImage? {
        didSet {
            itemImageView.image = itemImage
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.layer.cornerRadius = 10
        self.clipsToBounds = true
        
        itemImageView.layer.cornerRadius = 10
        itemImageView.clipsToBounds = true
    }
    
}
