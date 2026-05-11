//
//  AppDelegate.swift
//  SkromanIsra
//
//  Created by Admin on 18/01/25.
//

import UIKit
import FirebaseCore
import FirebaseMessaging
import UserNotifications
import AVFoundation
import AudioToolbox
import ThingSmartBaseKit
import ThingSmartLockKit

 

 
@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate, ThingSmartLockDeviceDelegate {

    var window: UIWindow?
    var isUnlockVCShown = false
    var globalLock: ThingSmartLockDevice?
    var globalDevice: ThingSmartDevice?
    var pendingDevIdFromNotification: String?
    var pendingUnlockDevice: ThingSmartLockDevice?
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        
        FirebaseApp.configure()
        
        
        UNUserNotificationCenter.current().delegate = self
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions
        ) { granted, error in
            if let error = error {
                print("Notification permission error:", error)
            } else {
                print("Notification permission granted:", granted)
            }
        }
        
        application.registerForRemoteNotifications()
        
        
        Messaging.messaging().delegate = self
        if #available(iOS 13.0, *) {
            UIApplication.shared.windows.forEach { window in
                window.overrideUserInterfaceStyle = .light
            }
        }
        
        ThingSmartSDK.sharedInstance().start(
            withAppKey: "hpwgfrxhcnp3uyv8dhrk",
            secretKey: "3tkst3vfjm7wh5ts7agj59vftfdqeqnu"
        )
        
        if let devId = UserDefaults.standard.string(forKey: "last_lock_devId") {
            //  globalLock = ThingSmartLockDevice(deviceId: devId)
            globalLock?.delegate = self
            
            print("🌍 Global lock listener started:", devId)
            
        }
        
#if DEBUG
        ThingSmartSDK.sharedInstance().debugMode = true
#endif
        setupPushNotifications(application: application)
        
        
        if let devId = UserDefaults.standard.string(forKey: "last_lock_devId") {
            
            globalLock = ThingSmartLockDevice(deviceId: devId)
            globalLock?.delegate = self
            
            globalDevice = ThingSmartDevice(deviceId: devId)
            globalDevice?.delegate = self
            
            print("🌍 Global listeners started:", devId)
        }
            
            return true
        }
        
    
    
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
       
        Messaging.messaging().apnsToken = deviceToken

        
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("APNs Token:", tokenString)
    }
    


    func messaging(
        _ messaging: Messaging,
        didReceiveRegistrationToken fcmToken: String?
    ) {
        print("FCM Token:", fcmToken ?? "nil")

        FCMTokenManager.shared.token = fcmToken

        NotificationCenter.default.post(
            name: Notification.Name("FCMTokenReceived"),
            object: nil,
            userInfo: ["token": fcmToken ?? ""]
        )
    }


    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Failed to register for notifications:", error)
    }

private func setupPushNotifications(application: UIApplication) {
            if #available(iOS 10.0, *) {
                let center = UNUserNotificationCenter.current()
                center.delegate = self
                let options: UNAuthorizationOptions = [.alert, .badge, .sound]
                center.requestAuthorization(options: options) { granted, error in
                    if granted {
                        DispatchQueue.main.async {
                            application.registerForRemoteNotifications()
                        }
                    } else {
                        print("❌ Push permission denied: \(String(describing: error))")
                    }
                }
            } else {
         
                let settings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
                application.registerUserNotificationSettings(settings)
                application.registerForRemoteNotifications()
            }
        }
    
    
    
    
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {

        saveTuyaUnlockLink(userInfo)
        print("📩 Foreground notification:", userInfo)
        if let dp = userInfo["dpCode"] as? [String],
           dp.contains("unlock_request") {

            let devId = userInfo["devId"] as? String ?? ""

            print("✅ Unlock request notification tapped")

            openUnlockRequestVC(devId: devId)
        }
    }
    
    func openUnlockRequestVC(devId: String) {
        DispatchQueue.main.async {

            guard let window = UIApplication.shared
                    .connectedScenes
                    .compactMap({ $0 as? UIWindowScene })
                    .flatMap({ $0.windows })
                    .first(where: { $0.isKeyWindow }),
                  let rootVC = window.rootViewController else {
                print("❌ No active window")
                return
            }

            let sb = UIStoryboard(name: "Main", bundle: nil)
            let vc = sb.instantiateViewController(withIdentifier: "LockOpenVC") as! LockOpenVC
            vc.deviceId = devId
            
            vc.pendingUnlockDevice = self.pendingUnlockDevice
            var topVC = rootVC
            while let presented = topVC.presentedViewController {
                topVC = presented
            }

            print("✅ Presenting from:", type(of: topVC))

            topVC.present(vc, animated: true)
        }
    }
    
    func device(_ device: ThingSmartLockDevice,
                didReceiveRemoteUnlockRequest seconds: Int) {

        guard seconds > 0 else { return }

        guard !isUnlockVCShown else { return }
        isUnlockVCShown = true

        print("✅ REAL unlock request device received")

        self.pendingUnlockDevice = device

        guard let devId = device.deviceModel.devId else {
            print("❌ devId missing")
            return
        }

        DispatchQueue.main.async {
                if let window = UIApplication.shared.windows.first,
                   let vc = window.rootViewController?.presentedViewController as? LockOpenVC {

                    vc.pendingUnlockDevice = device
                    print("🔄 Injected device into VC")
                }
            }
    }
    
    private func saveTuyaUnlockLink(_ userInfo: [AnyHashable: Any]) {

        if let link = userInfo["link"] as? String {
            UserDefaults.standard.set(link, forKey: "tuya_unlock_link")
            print("🔗 Tuya unlock link saved:", link)
        }
    }
    
     
    
    
    
   
    @available(iOS 10.0, *)
    @available(iOS 10.0, *)
//    func userNotificationCenter(_ center: UNUserNotificationCenter,
//                                didReceive response: UNNotificationResponse,
//                                withCompletionHandler completionHandler: @escaping () -> Void) {
//
//        let userInfo = response.notification.request.content.userInfo
//        let title = response.notification.request.content.title
//
//        print("📩 Notification tapped:", userInfo)
//        print("📩 Title:", title)
//
//        if isSupportPaymentSuccess(userInfo: userInfo) {
//            handleSupportPaymentNotificationTap(userInfo: userInfo)
//            completionHandler()
//            return
//        }
        
       
//        if title == "Remote unlocking request" {
//
//            let devId = userInfo["devId"] as? String ?? ""
//            self.pendingDevIdFromNotification = devId
//
//            print("📌 Stored devId from tap:", devId)
//
//           
//            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
//
//                if self.pendingUnlockDevice == nil {
//                    print("⚠️ DPS not received → fallback open VC")
//
//                    self.pendingUnlockDevice = ThingSmartLockDevice(deviceId: devId)
//                    self.pendingUnlockDevice?.delegate = self
//
//                    self.openLockScreenVC(devId: devId)
//                }
//            }
//        }
//        completionHandler()
//    }
    
    func openLockScreenVC(devId: String) {

        DispatchQueue.main.async {

            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first,
                  let rootVC = window.rootViewController else {
                print("❌ Window / rootVC not found")
                return
            }

            // 🔥 Prevent duplicate presentation
            if rootVC.presentedViewController is LockOpenVC {
                print("⚠️ LockOpenVC already presented")
                return
            }

            let sb = UIStoryboard(name: "Main", bundle: nil)
            let vc = sb.instantiateViewController(withIdentifier: "LockOpenVC") as! LockOpenVC

            vc.deviceId = devId
            vc.pendingUnlockDevice = self.pendingUnlockDevice

            print("👉 Presenting LockOpenVC")

            var topVC = rootVC
            while let presented = topVC.presentedViewController {
                topVC = presented
            }

            topVC.present(vc, animated: true)
        }
    }
    
 
    
    func device(_ device: ThingSmartDevice?, didReceiveData data: [AnyHashable : Any]?) {

        guard let dps = data?["dps"] as? [String: Any] else { return }

        print("🌍 Global DPS:", dps)

        guard let devId = device?.deviceModel.devId else { return }

        
        if let countdown = dps["9"] as? Int, countdown > 0 {

            print("🔔 Unlock request detected:", countdown)

//            guard !isUnlockVCShown else { return }
//            isUnlockVCShown = true
//
//            let finalDevId = self.pendingDevIdFromNotification ?? devId
//
//            self.pendingUnlockDevice = ThingSmartLockDevice(deviceId: finalDevId)
//            self.pendingUnlockDevice?.delegate = self

//            DispatchQueue.main.async {
//                print("🚀 Opening VC with devId:", finalDevId)
//                self.openLockScreenVC(devId: finalDevId)
//            }
            
            DispatchQueue.main.async {
                print("🚀 Opening VC")
                self.openLockScreenVC(devId: devId)
            }


            self.pendingDevIdFromNotification = nil
        }
    }
    
    
    func showBellNotification() {
        
        let content = UNMutableNotificationContent()
        content.title = "🔔 Door Bell"
        content.body = "Someone is at your door"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Notification error:", error)
            } else {
                print("✅ Bell notification shown")
            }
        }
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        print("Foreground notification:", userInfo)

        // ✅ Let system show notification
        completionHandler([.banner, .sound, .badge])
    }
    

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
     
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
     
    }


}

