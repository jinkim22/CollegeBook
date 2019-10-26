//
//  SellingViewController.swift
//  CollegeBook
//
//  Created by Avi Khemani on 10/12/19.
//  Copyright © 2019 Avi Khemani. All rights reserved.
//

import UIKit

class SellingViewController: UIViewController {

    @IBOutlet weak var textbookButton: UIButton!
    @IBOutlet weak var dormitemsButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        textbookButton.layer.cornerRadius = 15
        textbookButton.clipsToBounds = true
        
        dormitemsButton.layer.cornerRadius = 15
        dormitemsButton.clipsToBounds = true
    }


}
