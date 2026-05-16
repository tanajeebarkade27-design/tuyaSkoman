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
import ThingSmartHomeKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate, ThingSmartLockDeviceDelegate {

    var window: UIWindow?
    var isUnlockVCShown = false
    var globalLock: ThingSmartLockDevice?
    var globalDevice: ThingSmartDevice?
    var pendingDevIdFromNotification: String?
    var pendingUnlockDevice: ThingSmartLockDevice?

    /// One SDK listener per lock so doorbell / unlock events carry the correct `devId`.
    private var monitoredLocks: [String: ThingSmartLockDevice] = [:]
    private var monitoredDevices: [String: ThingSmartDevice] = [:]
    private let monitoredLockCategories: Set<String> = ["jtmspro", "videolock"]
    
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
        
#if DEBUG
        ThingSmartSDK.sharedInstance().debugMode = true
#endif
        setupPushNotifications(application: application)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshAllLockListeners),
            name: NSNotification.Name("TuyaSyncDone"),
            object: nil
        )

        // If we relaunch and the user is already logged in, make sure
        // the push switches on the Tuya server are still ON. The token
        // itself will be re-supplied by didRegisterForRemoteNotifications.
        enableTuyaPushIfLoggedIn()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.refreshAllLockListeners()
        }

        return true
    }

    /// Register `ThingSmartLockDevice` / `ThingSmartDevice` delegates for every Tuya lock (not only the first).
    @objc func refreshAllLockListeners() {
        let deviceIds = TuyaDeviceManager.shared.devices
            .filter { monitoredLockCategories.contains($0.deviceCategory.lowercased()) }
            .map(\.deviceId)
            .filter { !$0.isEmpty }

        guard !deviceIds.isEmpty else {
            print("⚠️ No Tuya locks in TuyaDeviceManager to monitor yet")
            return
        }

        print("🔐 Monitoring \(deviceIds.count) lock(s):", deviceIds)

        let activeIds = Set(deviceIds)

        for (id, lock) in monitoredLocks where !activeIds.contains(id) {
            lock.delegate = nil
            monitoredLocks.removeValue(forKey: id)
        }
        for (id, device) in monitoredDevices where !activeIds.contains(id) {
            device.delegate = nil
            monitoredDevices.removeValue(forKey: id)
        }

        for devId in deviceIds {
            if monitoredLocks[devId] == nil {
                let lock = ThingSmartLockDevice(deviceId: devId)
                lock?.delegate = self
                monitoredLocks[devId] = lock
            } else {
                monitoredLocks[devId]?.delegate = self
            }

            if monitoredDevices[devId] == nil {
                let smartDevice = ThingSmartDevice(deviceId: devId)
                smartDevice?.delegate = self
                monitoredDevices[devId] = smartDevice
            } else {
                monitoredDevices[devId]?.delegate = self
            }
        }

        if let first = deviceIds.first {
            globalLock = monitoredLocks[first]
            globalDevice = monitoredDevices[first]
            UserDefaults.standard.set(first, forKey: "last_lock_devId")
        }
    }

    private func extractDevId(from userInfo: [AnyHashable: Any]) -> String? {
        let keys = ["devId", "deviceId", "dev_id", "device_id"]
        for key in keys {
            if let id = userInfo[key] as? String, !id.isEmpty { return id }
        }
        if let device = userInfo["device"] as? [String: Any],
           let id = device["devId"] as? String, !id.isEmpty {
            return id
        }
        if let link = userInfo["link"] as? String,
           let id = devId(fromDeepLink: link), !id.isEmpty {
            return id
        }
        if let id = pendingDevIdFromNotification, !id.isEmpty { return id }
        return nil
    }

    private func devId(fromDeepLink link: String) -> String? {
        guard let url = URL(string: link),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }
        return components.queryItems?
            .first(where: { $0.name == "devId" })?
            .value
    }

    private func notificationAlertText(from userInfo: [AnyHashable: Any]) -> (title: String, body: String) {
        guard let aps = userInfo["aps"] as? [String: Any] else {
            return ("", "")
        }
        if let alert = aps["alert"] as? [String: Any] {
            let t = alert["title"] as? String ?? ""
            let b = alert["body"] as? String ?? ""
            return (t, b)
        }
        if let text = aps["alert"] as? String {
            return ("", text)
        }
        return ("", "")
    }

    /// Tuya video-lock doorbell: `msgType` doorlock, link `videoCall`, title "You have a visitor", etc.
    private func isDoorbellNotification(title: String, userInfo: [AnyHashable: Any]) -> Bool {
        if userInfo["type"] as? String == "doorbell" { return true }

        let msgType = (userInfo["msgType"] as? String)?.lowercased() ?? ""
        if msgType == "doorlock" { return true }

        if let link = userInfo["link"] as? String,
           link.lowercased().contains("videocall") {
            return true
        }

        let alert = notificationAlertText(from: userInfo)
        let combinedTitle = title.isEmpty ? alert.title : title
        let combinedBody = alert.body

        if combinedTitle.localizedCaseInsensitiveContains("visitor") { return true }
        if combinedTitle.localizedCaseInsensitiveContains("door bell") { return true }
        if combinedTitle.localizedCaseInsensitiveContains("doorbell") { return true }
        if combinedBody.localizedCaseInsensitiveContains("ringing the bell") { return true }
        if combinedBody.localizedCaseInsensitiveContains("ringing") && combinedBody.localizedCaseInsensitiveContains("bell") {
            return true
        }

        return false
    }

    private func isUnlockRequestNotification(title: String, userInfo: [AnyHashable: Any]) -> Bool {
        if title == "Remote unlocking request" { return true }
        if let dp = userInfo["dpCode"] as? [String], dp.contains("unlock_request") { return true }
        return false
    }

    /// Handles notification tap (foreground, background, or cold start).
    func handleLockNotificationTap(userInfo: [AnyHashable: Any], title: String) {
        guard let devId = extractDevId(from: userInfo), !devId.isEmpty else {
            print("❌ handleLockNotificationTap: no devId in", userInfo)
            return
        }

        pendingDevIdFromNotification = devId
        print("📌 Lock notification tap, devId:", devId, "title:", title)

        let shouldOpen = isUnlockRequestNotification(title: title, userInfo: userInfo)
            || isDoorbellNotification(title: title, userInfo: userInfo)

        guard shouldOpen else {
            print("⚠️ Notification ignored (not lock bell/unlock). title:", title,
                  "msgType:", userInfo["msgType"] ?? "nil")
            return
        }

        if pendingUnlockDevice == nil {
            pendingUnlockDevice = ThingSmartLockDevice(deviceId: devId)
            pendingUnlockDevice?.delegate = self
        }

        let forceVideo = isDoorbellNotification(title: title, userInfo: userInfo)
        presentLockOpenVC(devId: devId, forceVideoPreview: forceVideo)
    }
        
    
    
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {

        Messaging.messaging().apnsToken = deviceToken

        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("APNs Token:", tokenString)

        // ✅ Hand the APNs token to the Tuya SDK so the cloud can
        // route lock / device notifications (remote unlock, alarms, etc.)
        // to this device. Without this Tuya push will NEVER fire.
        ThingSmartSDK.sharedInstance().setDeviceToken(deviceToken, withError: nil, success: { _ in
            print("✅ Tuya: device token registered")
            self.enableTuyaPushIfLoggedIn()
        }, failure: { error in
            print("❌ Tuya: device token register failed:", error?.localizedDescription ?? "")
        })
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Failed to register for notifications:", error)

        // Inform Tuya about the failure too so it can clear its state.
        ThingSmartSDK.sharedInstance().setDeviceToken(nil, withError: error)
    }

    /// Turns ON all Tuya push channels for the logged-in account.
    /// Safe to call multiple times; Tuya treats it as idempotent.
    private func enableTuyaPushIfLoggedIn() {

        guard ThingSmartUser.sharedInstance().isLogin else {
            print("⚠️ Tuya: user not logged in, skip push enable")
            return
        }

        let sdk = ThingSmartSDK.sharedInstance()

        // Master app push switch
        sdk.setPushStatusWithStatus(true, success: {
            print("✅ Tuya: app push enabled")
        }, failure: { err in
            print("❌ Tuya: app push enable failed:", err?.localizedDescription ?? "")
        })

        // Device alert push (lock unlock requests, alarms, sensor triggers, ...)
        sdk.setDevicePushStatusWithStauts(true, success: {
            print("✅ Tuya: device alert push enabled")
        }, failure: { err in
            print("❌ Tuya: device push enable failed:", err?.localizedDescription ?? "")
        })

        // Home / family push
        sdk.setFamilyPushStatusWithStauts(true, success: {
            print("✅ Tuya: family push enabled")
        }, failure: { err in
            print("❌ Tuya: family push enable failed:", err?.localizedDescription ?? "")
        })

        // Notice / system message push
        sdk.setNoticePushStatusWithStauts(true, success: {
            print("✅ Tuya: notice push enabled")
        }, failure: { err in
            print("❌ Tuya: notice push enable failed:", err?.localizedDescription ?? "")
        })
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
        print("📩 Foreground remote notification:", userInfo)

        let alert = notificationAlertText(from: userInfo)
        let title = alert.title

        if extractDevId(from: userInfo) != nil,
           isDoorbellNotification(title: title, userInfo: userInfo)
            || isUnlockRequestNotification(title: title, userInfo: userInfo) {
            handleLockNotificationTap(userInfo: userInfo, title: title)
        }
    }

    func presentLockOpenVC(devId: String, forceVideoPreview: Bool = false, attempt: Int = 0) {
        guard !devId.isEmpty else {
            print("❌ presentLockOpenVC: empty devId")
            return
        }

        UserDefaults.standard.set(devId, forKey: "last_lock_devId")
        pendingDevIdFromNotification = devId

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            guard let window = UIApplication.shared
                .connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap(\.windows)
                .first(where: \.isKeyWindow),
                  let rootVC = window.rootViewController else {
                if attempt < 15 {
                    print("⏳ Window not ready, retry present LockOpenVC (\(attempt + 1))")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
                        self?.presentLockOpenVC(devId: devId, forceVideoPreview: forceVideoPreview, attempt: attempt + 1)
                    }
                } else {
                    print("❌ No active window after retries")
                }
                return
            }

            var topVC: UIViewController = rootVC
            while let presented = topVC.presentedViewController {
                topVC = presented
            }

            if let existing = topVC as? LockOpenVC {
                if existing.deviceId == devId {
                    print("⚠️ LockOpenVC already showing devId:", devId)
                    return
                }
                existing.dismiss(animated: false) { [weak self] in
                    self?.presentLockOpenVC(devId: devId, forceVideoPreview: forceVideoPreview)
                }
                return
            }

            if let existing = topVC.presentedViewController as? LockOpenVC {
                if existing.deviceId == devId {
                    print("⚠️ LockOpenVC already presented for devId:", devId)
                    return
                }
                existing.dismiss(animated: false) { [weak self] in
                    self?.presentLockOpenVC(devId: devId, forceVideoPreview: forceVideoPreview)
                }
                return
            }

            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            guard let vc = storyboard.instantiateViewController(
                withIdentifier: "LockOpenVC"
            ) as? LockOpenVC else {
                print("❌ LockOpenVC not found")
                return
            }

            vc.deviceId = devId
            vc.selectedLock = TuyaDeviceManager.shared.devices.first { $0.deviceId == devId }
            let category = vc.selectedLock?.deviceCategory.lowercased()
                ?? ThingSmartDevice(deviceId: devId)?.deviceModel.category?.lowercased()
                ?? ""
            vc.forceVideoPreview = forceVideoPreview || category == "videolock"
            vc.pendingUnlockDevice = self.pendingUnlockDevice
            vc.loadViewIfNeeded()

            if vc.cameraPreview == nil {
                print("❌ LockOpenVC storyboard outlets missing — check Main.storyboard connections")
            }

            print("👉 Presenting LockOpenVC for devId:", devId, "name:", vc.selectedLock?.deviceName ?? "?")

            self.isUnlockVCShown = true
            topVC.present(vc, animated: true)
        }
    }

    func device(_ device: ThingSmartLockDevice,
                didReceiveRemoteUnlockRequest seconds: Int) {

        guard seconds > 0 else { return }

        guard let devId = device.deviceModel.devId, !devId.isEmpty else {
            print("❌ devId missing on unlock request")
            return
        }

        print("✅ Remote unlock request from lock:", devId)

        pendingUnlockDevice = device
        pendingDevIdFromNotification = devId

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            if let window = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap(\.windows)
                .first(where: \.isKeyWindow),
               let presented = window.rootViewController?.presentedViewController as? LockOpenVC,
               presented.deviceId == devId {
                presented.pendingUnlockDevice = device
                print("🔄 Injected unlock device into existing LockOpenVC")
                return
            }

            self.presentLockOpenVC(devId: devId)
        }
    }
    
    private func saveTuyaUnlockLink(_ userInfo: [AnyHashable: Any]) {

        if let link = userInfo["link"] as? String {
            UserDefaults.standard.set(link, forKey: "tuya_unlock_link")
            print("🔗 Tuya unlock link saved:", link)
        }
    }
    
     
    
    
    
   
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {

        let userInfo = response.notification.request.content.userInfo
        let title = response.notification.request.content.title

        print("📩 Notification tapped:", userInfo)
        print("📩 Title:", title)

        handleLockNotificationTap(userInfo: userInfo, title: title)

        completionHandler()
    }
    
 
    
    func device(_ device: ThingSmartDevice?, didReceiveData data: [AnyHashable : Any]?) {

        guard let dps = data?["dps"] as? [String: Any] else { return }
        guard let devId = device?.deviceModel.devId, !devId.isEmpty else { return }

        print("🌍 DPS from lock \(devId):", dps)

        if let doorbell = dps["53"] as? Int, doorbell == 1 {
            print("🔔 Doorbell from lock:", devId)
            showBellNotification(devId: devId)
            return
        }

        if let countdown = dps["9"] as? Int, countdown > 0 {
            print("🔔 Unlock countdown from lock:", devId, countdown)

            pendingDevIdFromNotification = devId
            pendingUnlockDevice = ThingSmartLockDevice(deviceId: devId)
            pendingUnlockDevice?.delegate = self

            DispatchQueue.main.async { [weak self] in
                self?.presentLockOpenVC(devId: devId)
            }
        }
    }

    func showBellNotification(devId: String) {
        let lockName = TuyaDeviceManager.shared.devices
            .first { $0.deviceId == devId }?
            .deviceName ?? "your door"

        let content = UNMutableNotificationContent()
        content.title = "🔔 Door Bell"
        content.body = "Someone is at \(lockName)"
        content.sound = .default
        content.userInfo = [
            "devId": devId,
            "type": "doorbell"
        ]

        let request = UNNotificationRequest(
            identifier: "doorbell-\(devId)-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Bell notification error:", error)
            } else {
                print("✅ Bell notification for devId:", devId)
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
    

    func applicationDidBecomeActive(_ application: UIApplication) {
        enableTuyaPushIfLoggedIn()
        refreshAllLockListeners()
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
     
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
     
    }


}

