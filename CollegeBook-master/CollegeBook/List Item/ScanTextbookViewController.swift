//
//  ScanTextbookViewController.swift
//  CollegeBook
//
//  Created by Avi Khemani on 10/5/19.
//  Copyright © 2019 Avi Khemani. All rights reserved.
//

import UIKit
import Firebase
import AVFoundation
import SwiftyJSON

class ScanTextbookViewController: UIViewController, UINavigationControllerDelegate, AVCaptureMetadataOutputObjectsDelegate {
    
    lazy var functions = Functions.functions()
    var scanner: Scanner?
    var image: UIImage?
    
    @IBOutlet weak var scanButton: UIButton!
    @IBOutlet weak var enterButton: UIButton!
    private var scannedTitle: String?
    private var scannedAuthor: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scanButton.layer.cornerRadius = 10
        scanButton.clipsToBounds = true
        
        enterButton.layer.cornerRadius = 10
        enterButton.clipsToBounds = true
    }
    
    func scanISBN(isbn: String) {
        functions.httpsCallable("isbnAutofill").call(["text":isbn]) { (result, error) in
            let jsonObj = JSON(result?.data)
            let info = jsonObj["text"]["items"][0]["volumeInfo"]
            self.scannedTitle = info["title"].stringValue
            self.scannedAuthor = info["authors"][0].stringValue
//            let array = infoJson!["items"] as? NSArray
//            let info = array![0] as? [String: Any]
//            let volumeInfo = info!["volumeInfo"] as? [String: Any]
//            let title = volumeInfo!["title"] as? String
//            let authors = volumeInfo!["authors"] as? NSArray
//            self.scannedTitle = title
//            self.scannedAuthor = authors?[0] as? String
            
            self.performSegue(withIdentifier: "Scan ISBN Segue", sender: nil)
        }
    }
    
    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection : AVCaptureConnection) {
        self.scanner?.scannerDelegate(output, didOutput: metadataObjects, from: connection)
        // tutorial sends the output back to scanner, but do we want to?
    }
    
    
    @IBAction func isbnScanner(_ sender: UIButton) {
        self.scanner = Scanner(withViewController: self, view: self.view, codeOutputHandler: self.handleCode)
        if let scanner = self.scanner {
            scanner.requestCaptureSessionStartRunning()
        }
    }
    
    func handleCode(code: String) {
        scanISBN(isbn: code)
    }

     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Scan ISBN Segue" {
            if let destination = segue.destination as? ListItemViewController {
                destination.bookTitle = scannedTitle
                destination.bookAuthor = scannedAuthor
            }
        }
     }
}
