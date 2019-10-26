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
import Stripe
import UserNotifications
import FirebaseMessaging

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GIDSignInDelegate {
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error?){
        // ...
        if let error = error {
            // ...
            return
        }
        guard let authentication = user.authentication else { return }
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken, accessToken: authentication.accessToken)
        Auth.auth().signIn(with: credential) { (authResult, error) in
            if let error = error {
                print(error)
                return
            } else {
                if authResult?.additionalUserInfo?.isNewUser == true {
                    let curUser = Auth.auth().currentUser
                    let db = Firestore.firestore()
                    print(curUser!.uid)
                    db.collection("Users").document(curUser!.uid).setData([
                        "Name": curUser!.displayName!,
                        "UID": curUser!.uid,
                        "Email": curUser!.email!,
                        "PostIDs": [],
                        "VenmoID": "",
                        "ChannelIDs": []
                    ], merge: true) { err in
                        if let err = err {
                            print("Error writing document: \(err)")
                        } else {
                            print("Document successfully written!")
                        }
                    }
                    
                    DispatchQueue.global(qos: .userInitiated).async {
                        if let photoURL = curUser?.photoURL, let imageData = try? Data(contentsOf: photoURL) {
                            let profilePic = UIImage(data: imageData)!
                            DispatchQueue.main.async {
                                self.writeImageToDatabase(image: profilePic, name: curUser!.uid)
                            }
                        }
                    }
                }
                
            }
        
            NotificationCenter.default.post(
                name: Notification.Name("SuccessfulSignInNotification"), object: nil, userInfo: nil)
        }
    }
    
    private func writeImageToDatabase(image: UIImage, name: String) {
        let storageRef = Storage.storage().reference()
        let data = image.jpegData(compressionQuality: CGFloat(1))!
        let imageRef = storageRef.child("UserImages/\(name).jpg")
        
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
        
        STPPaymentConfiguration.shared().publishableKey = "pk_test_LJW9zVsf3jTAsul4Sw0zm6YO00Qd3HggRR"
        // do any other necessary launch configuration
        Messaging.messaging().delegate = self
        Messaging.messaging().isAutoInitEnabled = true
        return true
    }

    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any])
        -> Bool {
            return GIDSignIn.sharedInstance().handle(url, sourceApplication:options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
                                                     annotation: [:])
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
            print("Notification settings: \(settings)")
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
        print("DeviceToken: \(token)")
        if let curUser = Auth.auth().currentUser {
            print("there is a current User")
            print(curUser)
            print(curUser.uid)
            let db = Firestore.firestore()
            db.collection("Users").document(curUser.uid).setData(["DeviceToken": token], merge: true)
            InstanceID.instanceID().instanceID { (result, error) in
                if let error = error {
                    print("Error fetching remote instance ID: \(error)")
                } else if let result = result {
                    print("Remote instance ID token: \(result.token)")
                    db.collection("Users").document(curUser.uid).setData(["fcmToken": result.token], merge: true)
                }
            }
        } else {
            print("smd")
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

}

extension AppDelegate : MessagingDelegate {
    // [START refresh_token]
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        print("Firebase registration token: \(fcmToken)")
        // TODO: If necessary send token to application server.
        if let curUser = Auth.auth().currentUser {
            print(curUser.uid)
            let db = Firestore.firestore()
            db.collection("Users").document(curUser.uid).setData(["fcmToken": fcmToken], merge: true)
            
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

