//
//  MessageImage.swift
//  CollegeBook
//
//  Created by Avi Khemani on 9/8/19.
//  Copyright © 2019 Avi Khemani. All rights reserved.
//

import Foundation
import UIKit
import MessageKit

struct MessageImage: MediaItem {
    
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
    
}
