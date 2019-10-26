//
//  AppDelegate.swift
//  CollegeBook
//
//  Created by Avi Khemani on 7/14/19.
//  Copyright © 2019 Avi Khemani. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn
import UserNotifications
import FirebaseMessaging
import InstantSearchClient
import SwiftEntryKit
import SwiftyJSON

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GIDSignInDelegate {
   
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser, withError error: Error?){
        let authentication = user.authentication
        if authentication == nil {
            return
        }
        let credential = GoogleAuthProvider.credential(withIDToken: authentication!.idToken, accessToken: authentication!.accessToken)
        
        Auth.auth().signIn(with: credential) { (authResult, error) in
            if let error = error {
                print(error)
                return
            }
            if authResult?.additionalUserInfo?.isNewUser == false {
                NotificationCenter.default.post(
                name: Notification.Name("SuccessfulSignInNotification"), object: nil, userInfo: nil)
                return
            }
            
            let currUser = Auth.auth().currentUser!
            let displayName = currUser.displayName!
            let uid = currUser.uid
            let email = currUser.email!
            
            let domainSplit = email.split(separator: "@")
            let periodSplit = domainSplit[domainSplit.count-1].split(separator: ".")
            let domain = periodSplit[periodSplit.count-2] + ".edu"
            
            if (periodSplit[periodSplit.count-1] != "edu") {
                currUser.delete() { error in
                    if let error = error {
                        print("error deleting non-edu account")
                    } else {
                        print("succesfully deleted non-edu account")
                        NotificationCenter.default.post(
                                name: Notification.Name("NonEduNotification"), object: nil, userInfo: nil)
                    }
                }
                return
            }
            
            var school: String?
            let functions = Functions.functions()
            
            let dispatchGroup = DispatchGroup()
            dispatchGroup.enter()
            if domain == "claremontmckenna.edu" {
                school = "Stanford University"
                dispatchGroup.leave()
            } else {
                functions.httpsCallable("getSchoolFromDomain").call(["text": domain]) { (result, error) in
                    let json = JSON(result?.data)
                    school = json["text"][0]["name"].string
                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.notify(queue: .main, execute: {
                if school == nil {
                    print("No school was returned!")
                    return
                }
                
                let newObject = ["objectID" : uid, "Name": displayName, "School": school!]
                let client = Client(appID: "P6X728Y0HP", apiKey: "5b309ec79c4f09ce850f1ace9e1115f0")
                let index = client.index(withName: "dev_Users")
                index.addObject(newObject as [String : Any], completionHandler: { (content, error) -> Void in
                    if error == nil {
                        if let objectID = content!["objectID"] as? String {
                            print("Object ID: \(objectID)")
                        }
                    }
                })
                           
                let userDefaults = UserDefaults.standard
                userDefaults.set(uid, forKey: "UID")
                userDefaults.set(displayName, forKey: "Name")
                userDefaults.set(email, forKey: "Email")
                userDefaults.set("", forKey: "VenmoID")
                userDefaults.set("", forKey: "Bio")
                userDefaults.set(school!, forKey: "School")
                userDefaults.set([String](), forKey: "PostIDs")
                userDefaults.set([String](), forKey: "BookmarkIDs")

                
                let db = Firestore.firestore()
                db.collection("Schools/\(school!.concatenated)/Users").document(currUser.uid).setData([
                    "Name": displayName,
                    "UID": uid,
                    "Email": email,
                    "PostIDs": [],
                    "MiscPostIDs": [],
                    "BookmarkIDs": [],
                    "VenmoID": "",
                    "ChannelIDs": [],
                    "School": school!
                ], merge: true) { err in
                    if let err = err {
                        print("Error writing document: \(err)")
                        return
                    }
                    print("Wrote")
                    NotificationCenter.default.post(
                        name: Notification.Name("SuccessfulSignInNotification"), object: nil, userInfo: nil)
                }
                
                DispatchQueue.global(qos: .userInitiated).async {
                    if let photoURL = currUser.photoURL, let imageData = try? Data(contentsOf: photoURL) {
                        let profilePic = UIImage(data: imageData)!
                        DispatchQueue.main.async {
                            self.writeImageToDatabase(image: profilePic, name: uid)
                        }
                    }
                }
            })
        }
    }
    
    private func writeImageToDatabase(image: UIImage, name: String) {
        let storageRef = Storage.storage().reference()
        let data = image.jpegData(compressionQuality: CGFloat(1))!
        let school = UserDefaults.standard.string(forKey: "School") ?? ""

        let imageRef = storageRef.child("Schools/\(school.concatenated)/UserImages/\(name).jpg")
        
        let uploadTask = imageRef.putData(data, metadata: nil) { (metadata, error) in
            guard let metadata = metadata else {
                return
            }
            let size = metadata.size
            imageRef.downloadURL { (url, error) in
                guard let downloadURL = url else {
                    return
                }
            }
        }
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        // Perform any operations when the user disconnects from app here.
        // ...
    }
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
        GIDSignIn.sharedInstance().delegate = self
        
        // do any other necessary launch configuration
        Messaging.messaging().delegate = self
        Messaging.messaging().isAutoInitEnabled = true
        
        if(launchOptions?[UIApplication.LaunchOptionsKey.remoteNotification] != nil) {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let vc = storyboard.instantiateViewController(withIdentifier: "TabViewController") as? UITabBarController {
                vc.selectedViewController = vc.customizableViewControllers?[3]
                self.window?.rootViewController = vc
            }
        }
        
        return true
    }
    
    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any])
        -> Bool {
            return GIDSignIn.sharedInstance().handle(url)
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    
    // Push notification functions
    
    func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Messaging.messaging().apnsToken = deviceToken
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        if let curUser = Auth.auth().currentUser {
            let db = Firestore.firestore()
            
            let school = UserDefaults.standard.string(forKey: "School") ?? ""
            if school == "" {
                return
            }
            db.collection("Schools/\(school.concatenated)/Users").document(curUser.uid).setData(["DeviceToken": token], merge: true)
            InstanceID.instanceID().instanceID { (result, error) in
                if let error = error {
                    print("Error fetching remote instance ID: \(error)")
                } else if let result = result {
                    print("Remote instance ID token: \(result.token)")
                    db.collection("Schools/\(school.concatenated)/Users").document(curUser.uid).setData(["fcmToken": result.token], merge: true)
                }
            }
        } else {
            print("error")
        }
    }
    
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register: \(error)")
    }
    
    func registerForPushNotifications() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) {
                [weak self] granted, error in
                
                print("Permission granted: \(granted)")
                guard granted else { return }
                self?.getNotificationSettings()
        }
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        let application = UIApplication.shared
        if(application.applicationState == .active) {
            let notifChannelID = userInfo[AnyHashable("channel_id")] as? String ?? "N/A"
            let rootController = self.window?.rootViewController as? UITabBarController
            let navController = rootController?.selectedViewController as? UINavigationController
            let topController = navController?.visibleViewController
            if let vc = topController as? ChatViewController {
                let channelID = vc.channel.channelID
                if channelID == notifChannelID {
                    let school = UserDefaults.standard.string(forKey: "School") ?? ""
                    Firestore.firestore().collection("Schools/\(school.concatenated)/Channels").document(channelID).setData(["read": true], merge: true)
                    return
                }
            } else if let vc = topController as? MessagesCollectionViewController {
                vc.reloadMessages()
                let generator = UIImpactFeedbackGenerator(style: .heavy)
                generator.impactOccurred()
                if let tabItems = rootController?.tabBar.items {
                    let tabItem = tabItems[3]
                    tabItem.badgeValue = " "
                }
                return
            }
            
            if let tabItems = rootController?.tabBar.items {
                let tabItem = tabItems[3]
                tabItem.badgeValue = " "
            }
            let notificationJson = userInfo[AnyHashable("aps")] as! [String: Any]
            let alert = notificationJson["alert"] as! [String: Any]
            let senderName = alert["title"] as! String
            let body = alert["body"] as! String
            
            let action = {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                if let vc = storyboard.instantiateViewController(withIdentifier: "TabViewController") as? UITabBarController {
                    vc.selectedViewController = vc.customizableViewControllers?[3]
                    self.window?.rootViewController = vc
                }
            }
            
            var attributes = EKAttributes.topFloat
            attributes.entryBackground = .gradient(gradient: .init(colors: [EKColor(.white), EKColor(.white)], startPoint: .zero, endPoint: CGPoint(x: 1, y: 1)))
            attributes.popBehavior = .animated(animation: .init(translate: .init(duration: 0.3), scale: .init(from: 1, to: 0.7, duration: 0.7)))
            attributes.shadow = .active(with: .init(color: .black, opacity: 0.5, radius: 10, offset: .zero))
            attributes.statusBar = .dark
            attributes.scroll = .enabled(swipeable: true, pullbackAnimation: .jolt)
            attributes.entryInteraction.customTapActions.append(action)
            
            let bold = UIFont.boldSystemFont(ofSize: 15)
            let font = UIFont.systemFont(ofSize: 12)
            let title = EKProperty.LabelContent(text: senderName, style: .init(font: bold, color: .black))
            let description = EKProperty.LabelContent(text: body, style: .init(font: font, color: .black))
            let simpleMessage = EKSimpleMessage(title: title, description: description)
            let notificationMessage = EKNotificationMessage(simpleMessage: simpleMessage)
            
            let contentView = EKNotificationMessageView(with: notificationMessage)
            SwiftEntryKit.display(entry: contentView, using: attributes)
            
            //            let banner = FloatingNotificationBanner(title: senderName, subtitle: body, style: .info)
            //
            //            banner.onTap = action
            //            banner.show(cornerRadius: 20, shadowColor: .black)
        }
        if(application.applicationState == .inactive){
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let vc = storyboard.instantiateViewController(withIdentifier: "TabViewController") as? UITabBarController {
                vc.selectedViewController = vc.customizableViewControllers?[3]
                self.window?.rootViewController = vc
            }
        }
    }
    
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: () -> Void) {
        let application = UIApplication.shared
        if(application.applicationState == .active){
            print("user tapped the notification bar when the app is in foreground")
        }
        if(application.applicationState == .inactive){
            print("user tapped the notification bar when the app is in background")
        }
        
        /* Change root view controller to a specific viewcontroller */
        // let storyboard = UIStoryboard(name: "Main", bundle: nil)
        // let vc = storyboard.instantiateViewController(withIdentifier: "ViewControllerStoryboardID") as? ViewController
        // self.window?.rootViewController = vc
        
        completionHandler()
    }
    
}


extension AppDelegate: MessagingDelegate {
    // [START refresh_token]
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        print("Firebase registration token: \(fcmToken)")
        // TODO: If necessary send token to application server.
        if let curUser = Auth.auth().currentUser {
            let db = Firestore.firestore()
            let school = UserDefaults.standard.string(forKey: "School") ?? ""
            if school == "" {
                return
            }
            db.collection("Schools/\(school.concatenated)/Users").document(curUser.uid).setData(["fcmToken": fcmToken], merge: true)
            
            // Note: This callback is fired at each app startup and whenever a  new token is generated.
        }
    }
    // [END refresh_token]
    // [START ios_10_data_message]
    // Receive data messages on iOS 10+ directly from FCM (bypassing APNs) when the app is in the foreground.
    // To enable direct data messages, you can set Messaging.messaging().shouldEstablishDirectChannel to true.
    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        print("Received data message: \(remoteMessage.appData)")
    }
    // [END ios_10_data_message]
}
