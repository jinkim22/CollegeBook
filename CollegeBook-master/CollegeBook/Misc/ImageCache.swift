//
//  ImageCache.swift
//  CollegeBook
//
//  Created by Jin Kim on 10/14/19.
//  Copyright © 2019 Avi Khemani. All rights reserved.
//

import Foundation
import UIKit
import Firebase

class ImageCache {
    
    static let cache = NSCache<NSString, UIImage>()
    
    static func downloadImage(withURL url: URL, completion: @escaping (_ image:UIImage?)->()) {
        let storageRef = Storage.storage().reference()
        let profRef = storageRef.child(url.absoluteString)
        profRef.getData(maxSize: 1 * 1024 * 1024) { data, error in
            if let error = error {
                print(error)
                return
            }
            let downloadedImage = UIImage(data: data!)
            if downloadedImage != nil {
                cache.setObject(downloadedImage!, forKey: url.absoluteString as NSString)
            }
            completion(downloadedImage)
        }
        
        //        let dataTask = URLSession.shared.dataTask(with: url) { data, responseURL, error in
        //            var downloadedImage: UIImage?
        //
        //            if let data = data {
        //                downloadedImage = UIImage(data:data)
        //            }
        //
        //            if downloadedImage != nil {
        //                cache.setObject(downloadedImage!, forKey: url.absoluteString as NSString)
        //            }
        //
        //            DispatchQueue.main.async {
        //                completion(downloadedImage)
        //            }
        //
        //        }
        //        dataTask.resume()
    }
    
    static func getImage(with urlString: String, completion: @escaping (_ image: UIImage?) -> ()) {
        let downloadURL = URL(string: urlString)!
        if let image = cache.object(forKey: downloadURL.absoluteString as NSString) {
            completion(image)
        } else {
            downloadImage(withURL: downloadURL, completion: completion)
        }
    }
    
    //
    //    static func storeImage(urlString: String, img: UIImage) {
    //        let path = NSTemporaryDirectory().appending(UUID().uuidString)
    //        let url = URL(fileURLWithPath: path)
    //
    //        let data = img.jpegData(compressionQuality: 0.5)
    //        try? data?.write(to: url)
    //
    //        var dict = UserDefaults.standard.object(forKey: "ImageCache") as? [String: String]
    //        if dict == nil {
    //            dict = [String:String]()
    //        }
    //        dict![urlString] = path
    //        UserDefaults.standard.set(dict, forKey: "ImageCache")
    //    }
    //
    //    static func loadImage(urlString: String, completion: @escaping (String, UIImage?) -> Void) {
    //
    //        if let dict = UserDefaults.standard.object(forKey: "ImageCache") as? [String:String] {
    //            if let path = dict[urlString] {
    //                if let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
    //                    let img = UIImage(data: data)
    //                    completion(urlString, img)
    //                }
    //            }
    //        }
    //
    //        guard let url = URL(string: urlString) else { return }
    //
    //        let task = URLSession.shared.dataTask(with:url) {(data, response, error) in
    //            guard error == nil else {return}
    //            guard let d = data else {return}
    //            DispatchQueue.main.async {
    //                if let image = UIImage(data: d) {
    //                    storeImage(urlString: urlString, img: image)
    //                    completion(urlString, image)
    //                }
    //            }
    //        }
    //    }
}
