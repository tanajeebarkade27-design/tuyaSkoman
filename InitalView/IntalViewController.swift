import UIKit
import Network
import SwiftKeychainWrapper
import Alamofire
 import SwiftyGif
import ThingSmartHomeKit

class IntalViewController: UIViewController {
    var activityIndicator: UIActivityIndicatorView!
    let monitor = NWPathMonitor()
    let queue = DispatchQueue.global(qos: .background)
    let gifOverlayView = UIView()
    let gifImageView = UIImageView()
    override func viewDidLoad() {
        super.viewDidLoad()
        monitorNetworkConnectivity()
        setupActivityIndicator()
        
    }
    
    private func monitorNetworkConnectivity() {
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                if path.status == .satisfied {
                    print("Internet connection available.")
                    self.navigateToAppropriateViewController()
                } else {
                    print("No internet connection.")
                    self.showNoInternetAlert()
                }
            }
        }
        monitor.start(queue: queue)
    }

    private func setupActivityIndicator() {
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.center = self.view.center
        activityIndicator.hidesWhenStopped = true
        self.view.addSubview(activityIndicator)
    }
    
    private func showNoInternetAlert() {
        let alert = UIAlertController(title: "No Internet Connection", message: "Please check your internet connection and try again.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    func navigateToAppropriateViewController() {
        self.showGIF(named: "Comp 1.gif") {
            self.decideNextScreen()
        }
    }



    func showGIF(named name: String, completion: (() -> Void)? = nil) {
        do {
            let gif = try UIImage(gifName: name)

            // Play once
            gifImageView.setGifImage(gif, loopCount: 1)

            gifOverlayView.frame = view.bounds
            gifOverlayView.backgroundColor = .black
            gifImageView.frame = view.bounds
            gifImageView.contentMode = .scaleAspectFit

            gifOverlayView.addSubview(gifImageView)
            view.addSubview(gifOverlayView)

            // SwiftyGif duration is NON-optional → safe to use directly
            let totalDuration: TimeInterval = gif.duration > 0 ? gif.duration : 2.0

            // Freeze on last frame after GIF finishes
            DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration) {

                if let frames = gif.images, let last = frames.last {
                    self.gifImageView.stopAnimatingGif()
                    self.gifImageView.image = last   // Freeze here
                }

                completion?()
            }

        } catch {
            print("❌ Failed to load GIF:", name)
            completion?()
        }
    }



    private func decideNextScreen() {
        if let email = KeychainWrapper.standard.string(forKey: "emailId"),
           let password = KeychainWrapper.standard.string(forKey: "login_password") {
            
            print("✅ User credentials found")
//            SkromanIsraDatabaseHelper.shared.openDatabase()
//            SkromanIsraDatabaseHelper.shared.createTables()
            SyncPostData()
            
            
        } else {
            print("❌ No credentials found")
            navigateToLoginScreen()
        }
    }


//    func startAppFlowWithGIFs() {
//        showGIF(named: "Comp 1.gif", duration: 2.0) {
//          
//        }
//    }

    
    private func navigateToHomeScreen() {
    

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let tabBarController = storyboard.instantiateViewController(withIdentifier: "MainTabBarController") as? UITabBarController,
           let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let delegate = windowScene.delegate as? UIWindowSceneDelegate,
           let window = delegate.window {
            
            window?.rootViewController = tabBarController
            window?.makeKeyAndVisible()
        }
        
    }

   

    private func navigateToLoginScreen() {
        let loginVC = storyboard?.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController

        navigationController?.pushViewController(loginVC, animated: true)
    }
    
    

    func performInitializationLogic() {
        // Put your logic here that runs while GIF is showing
        print("✅ Background logic started")
        
        // Example: Navigate to next screen after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let tabBarVC = UIStoryboard(name: "Main", bundle: nil)
                .instantiateViewController(withIdentifier: "MainTabBarController")
            tabBarVC.modalTransitionStyle = .crossDissolve
            tabBarVC.modalPresentationStyle = .fullScreen
            self.present(tabBarVC, animated: true, completion: nil)
        }
    }
    
    private func navigateToEditProfileScreen() {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        if let editProfileVC = storyboard.instantiateViewController(withIdentifier: "EditprofileViewController") as? EditprofileViewController,
           let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let delegate = windowScene.delegate as? UIWindowSceneDelegate,
           let window = delegate.window {
            
            editProfileVC.shouldShowCompleteProfilePopup = true
            
            let navController = UINavigationController(rootViewController: editProfileVC)
            
            window?.rootViewController = navController
            window?.makeKeyAndVisible()
        }
    }
    
    func isUserValid() -> Bool {
        let userId = KeychainWrapper.standard.string(forKey: "userId") ?? ""
        
        if userId.isEmpty { return false }
        
        let users = SkromanIsraDatabaseHelper.shared.fetchUserById(userId: userId)
        
        guard let user = users.first else { return false }
        
        return !(user.pinCode ?? "").isEmpty
    }

}


extension IntalViewController {
    
    func SyncPostData() {
       
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            SkromanIsraDatabaseHelper.shared.deleteAllTablesData { success in
                if success {
                    print("✅ Deleted all old data")
                    SkromanIsraDatabaseHelper.shared.printHomeTableSchema()
                    self.syncServer()
                } else {
                    print("❌ Failed to delete old data")
                }
            }
        }
    }
    
    
    
    
    func syncServer() {
        let userId = KeychainWrapper.standard.string(forKey: "userId") ?? "Nothing"
        
        let syncDataParameters: [String: Any] = [
            "userId": userId
        ]
        print("call api ")
        print ("main api \(MainApi.sync_everything)")
        AF.request(MainApi.sync_everything, method: .post, parameters: syncDataParameters, encoding: JSONEncoding.default, headers: nil)
            .response { response in
                switch response.result {
                case .success(let data):
                    if let responseData = data {
                        do {
                            if let json = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String: Any] {
                                print("Parsed sync JSON: \(json)")
                                
                                // Insert User Data
                                if let userData = json["userData"] as? [String: Any] {
                                    
                                    let pinCode = userData["pinCode"] as? String ?? ""
                                    
                                    // ✅ ALWAYS insert user first
                                    SkromanIsraDatabaseHelper.shared.insertUser(
                                        userId: userData["userId"] as? String ?? "",
                                        userName: userData["userName"] as? String,
                                        emailId: userData["emailId"] as? String,
                                        mobileNumber: userData["mobileNumber"] as? String,
                                        address1: userData["address1"] as? String,
                                        address2: userData["address2"] as? String,
                                        city: userData["city"] as? String,
                                        state: userData["state"] as? String,
                                        pinCode: pinCode,
                                        loginType: userData["loginType"] as? String,
                                        imageUser: userData["imageUser"] as? String,
                                        verifyAlexa: userData["verifyAlexa"] as? String,
                                        verifyGoogle: userData["verifyGoogle"] as? String,
                                        password: userData["password"] as? String
                                    )
                                    
                                    print("✅ User inserted")
                                    
                                    
                                    if pinCode.isEmpty {
                                        print("❌ Pincode is missing")
                                    } else {
                                        print("✅ Pincode found: \(pinCode)")
                                    }
                                }
                                if let syncData = json["syncData"] as? [[String: Any]] {
                                                               self.insertHomeAndRoomsIntoDB(syncData: syncData) {
                                                                   
                                                                   self.checkTuyaLoginStatus()
                                                                    
                                                                   self.gifImageView.removeFromSuperview()
                                                                   self.gifOverlayView.removeFromSuperview()

                                                                  
                                                                   self.showGIF(named: "Comp 2.gif") {
                                                                       
                                                                       if self.isUserValid() {
                                                                           print("✅ Valid user → Home")
                                                                           self.navigateToHomeScreen()
                                                                       } else {
                                                                           print("❌ Invalid user → Edit Profile")
                                                                           self.navigateToEditProfileScreen()
                                                                       }
                                                                   }
                                    }
                                }
                               
                                if let familySync = json["familySync"] as? [[String: Any]] {
                                    print("📌 Found Family Sync")

                                    for familyEntry in familySync {
                                        if let homes = familyEntry["homes"] as? [[String: Any]] {
                                            
                                            self.insertFamilyHomeAndRoomsIntoDB(familyHomes: homes) {
                                                print("✅ Family Sync inserted successfully")
                                            }
                                        }
                                    }
                                }



                            }
                        } catch {
                            print("JSON Parsing Error: \(error.localizedDescription)")
                        }
                    } else {
                        print("No data received from the API.")
                    }
                    
                case .failure(let error):
                    print("API Sync Error: \(error.localizedDescription)")
                }
            }
    }
    
    func insertHomeAndRoomsIntoDB(syncData: [[String: Any]], completion: @escaping () -> Void) {
        let database = SkromanIsraDatabaseHelper.shared
        DispatchQueue.global(qos: .background).async {
            
            for home in syncData {
                if let homeId = home["homeId"] as? String,
                   let homeName = home["homeName"] as? String {
                    let homeImage = home["homeImage"] as? String ?? ""
                    print("home url  at\(homeImage)  home   name  is\(homeName) ")
                    
                    let tuyaHomeId: Int64? = {
                        
                        let raw = home["tuyaHomeId"]
                        
                        print("🔍 Raw tuyaHomeId:", raw ?? "nil")
                        
                        
                        if let id = raw as? Int64 {
                            return id
                        }
                        
                        
                        if let id = raw as? Int {
                            return Int64(id)
                        }
                        
                        
                        if let str = raw as? String {
                            
                            if str == "<null>" || str.isEmpty {
                                return nil
                            }
                            
                            return Int64(str)
                        }
                        
                        return nil
                    }()
                    
                    database.insertHome(
                        homeServerId: homeId,
                        homeName: homeName,
                        homeUrl: homeImage, tuyaHomeId: tuyaHomeId,
                        isFamilyHome:0)
                    
                    if let rooms = home["rooms"] as? [[String: Any]] {
                        for room in rooms {
                            
                            if let roomId = room["roomId"] as? String,
                               let roomName = room["roomName"] as? String {
                                
                                let roomIconId = room["roomIconId"] as? String ?? ""
                                let roomIconType = room["roomIconType"] as? String ?? ""
                                
                                // ✅ Parse tuyaRoomId
                                let tuyaRoomId: Int64? = {
                                    let raw = room["tuyaRoomId"]
                                    
                                    if let id = raw as? Int64 {
                                        return id
                                    }
                                    
                                    if let id = raw as? Int {
                                        return Int64(id)
                                    }
                                    
                                    if let str = raw as? String {
                                        if str == "<null>" || str.isEmpty {
                                            return nil
                                        }
                                        return Int64(str)
                                    }
                                    
                                    return nil
                                }()
                                
                                // ✅ Pass it here
                                database.insertRoom(
                                    roomId: roomId,
                                    roomName: roomName,
                                    roomIconId: roomIconId,
                                    roomIconType: roomIconType,
                                    tuyaRoomId: tuyaRoomId,
                                    homeId: homeId
                                )
                                
                            

                                if let roomScenes = room["roomScene"] as? [[String: Any]] {
                                    for scene in roomScenes {
                                        let sceneNo: String? = {
                                            if let intValue = scene["sceneNo"] as? Int {
                                                return String(intValue)
                                            } else if let strValue = scene["sceneNo"] as? String {
                                                return strValue
                                            }
                                            return nil
                                        }()
                                        
                                        let sceneName = scene["sceneName"] as? String ?? ""
                                        let sceneIcon = scene["sceneIcon"] as? String ?? ""
                                        
                                        print("➡️ inserting scene → roomId: \(roomId), sceneNo: \(sceneNo ?? "nil")")
                                        
                                        database.insertRoomScene(
                                            roomId: roomId,
                                            sceneNo: sceneNo,
                                            sceneName: sceneName,
                                            sceneIcon: sceneIcon
                                        )
                                    }
                                }
                                
                              
                                // Insert Devices
                                if let devices = room["devices"] as? [[String: Any]] {
                                    for device in devices {
                                        if room["roomId"] as! String == "ROOM_Id-JjFsBo53D" {
                                            print  ( "here ios room: \(device) ")
                                        }
                                        
                                        if
                                            let deviceUid = device["deviceUid"] as? String,
                                            let deviceName = device["deviceName"] as? String,
                                            let uniqueId = device["unique_id"] as? String,
                                            let POP = device["POP"] as? String,
                                            let deviceModelNo = device["deviceModelNo"] as? String,
                                            let deviceType = device["deviceType"] as? String,
                                            let connectedSsid = device["connectedSsid"] as? String,
                                            let connectedPassword = device["connectedPassword"] as? String
                                        {
                                           
                                            let deviceDimmingType = device["deviceDimmingType"] as? String ?? "null"
                                            let deviceCategory = device["deviceCategory"] as? String ?? "null"

                                            
                                            database.insertDevice(
                                                deviceUid: deviceUid,
                                                roomId: roomId,
                                                homeId: homeId,
                                                userId: home["userId"] as? String ?? "",
                                                deviceName: deviceName,
                                                uniqueId: uniqueId,
                                                POP: POP,
                                                deviceModelNo: deviceModelNo,
                                                deviceDimmingType: deviceDimmingType,
                                                deviceType: deviceType,
                                                connectedSsid: connectedSsid,
                                                connectedPassword: connectedPassword,
                                                deviceCategory: deviceCategory
                                            )
                                            if let buttons = device["button_Details"] as? [[String: Any]] {
                                                for button in buttons {
                                                    print("🔄 Processing button: \(button)")
                                                    
                                                    let buttonId = button["_id"] as? String
                                                    let buttonControlName = button["buttonControlName"] as? String
                                                    let buttonIconId = button["buttonIconId"] as? Int
                                                    let buttonName = button["buttonName"] as? String
                                                    let buttonNo = button["buttonNo"] as? Int
                                                    let deviceServerId = button["deviceServerId"] as? String
                                                    let power = button["power"] as? Int
                                                    let switchName = button["switchName"] as? String
                                                    let isShortcut = button["isShortcut"] as? Int
                                                    let buttonIconName = button["buttonIconName"] as? String
                                                    let buttonIconColor = button["buttonIconColor"] as? String
                                                    let isFavourite = button["isFavourite"] as? Int
                                                    let isHomeFav = button["isHomeFav"] as? Int                // ✅ Extracted
                                                    
                                                    
                                                    database.insertButtonDetails(
                                                        buttonId: buttonId,
                                                        buttonControlName: buttonControlName,
                                                        buttonIconId: buttonIconId,
                                                        buttonName: buttonName,
                                                        buttonNo: buttonNo,
                                                        deviceServerId: deviceServerId,
                                                        deviceUid: deviceUid,
                                                        power: power,
                                                        roomName: roomName,
                                                        switchName: switchName,
                                                        uniqueId: uniqueId,
                                                        isShortcut: isShortcut,
                                                        buttonIconName: buttonIconName,
                                                        buttonIconColor: buttonIconColor,
                                                        isFavourite: isFavourite, isHomeFav: isHomeFav
                                                    )
                                                }
                                                
                                                
                                                if let deviceStates = device["deviceStates"] as? [[String: Any]] {
                                                    for state in deviceStates {
                                                        let deviceStateUid = state["deviceStateUid"] as? String ?? ""
                                                        let workingMode = state["working_mode"] as? String ?? ""
                                                        let master = state["master"] as? String ?? ""
                                                        let childLockF = state["child_lock_f"] as? String ?? ""
                                                        let childLockL = state["child_lock_l"] as? String ?? ""
                                                        let childLockM = state["child_lock_m"] as? String ?? ""
                                                        let configButtons = state["config_buttons"] as? String ?? ""
                                                        let configDim = state["config_dim"] as? String ?? ""
                                                        let connectivity = state["connectivity"] as? String ?? ""
                                                        let destButton = state["dest_button"] as? String ?? ""
                                                        let fSpeed = state["F_speed"] as? String ?? ""
                                                        let fState = state["F_state"] as? String ?? ""
                                                        let fanDest = state["fan_dest"] as? String ?? ""
                                                        let lSpeed = state["L_speed"] as? String ?? ""
                                                        let lState = state["L_state"] as? String ?? ""
                                                        let series = state["series"] as? String ?? ""
                                                        

                                                        // ✅ Optional ota_status
                                                        let otaStatus = state["ota_status"] as? Int
                                                        let fRegulator =  state["F_regulator"] as?  String ?? ""

                                                        database.insertDeviceState(
                                                            deviceUid: deviceUid,
                                                            deviceStateUid: deviceStateUid,
                                                            uniqueId: uniqueId,
                                                            working_mode: workingMode,
                                                            master: master,
                                                            child_lock_f: childLockF,
                                                            child_lock_l: childLockL,
                                                            child_lock_m: childLockM,
                                                            config_buttons: configButtons,
                                                            config_dim: configDim,
                                                            connectivity: connectivity,
                                                            dest_button: destButton,
                                                            f_speed: fSpeed,
                                                            f_state: fState,
                                                            fan_dest: fanDest,
                                                            l_speed: lSpeed,
                                                            l_state: lState,
                                                            series: series,
                                                            ota_status: otaStatus, F_regulator: fRegulator
                                                        )
                                                    }
                                                }

                                                
                                                if let scenes = device["scenes"] as? [[String: Any]] {
                                                    for scene in scenes {
                                                        if let sceneId = scene["sceneId"] as? String,
                                                           let sceneName = scene["sceneName"] as? String,
                                                           let sceneNo = "\(scene["sceneNo"] ?? "")" as String? {

                                                            let configButtons = "\(scene["config_buttons"] ?? "")"
                                                            let configDim = "\(scene["config_dim"] ?? "")"
                                                            let destButton = "\(scene["dest_button"] ?? "")"
                                                            let fanDest = "\(scene["fan_dest"] ?? "")"
                                                            let fSpeed = "\(scene["F_speed"] ?? "")"
                                                            let fState = "\(scene["F_state"] ?? "")"
                                                            let lSpeed = "\(scene["L_speed"] ?? "")"
                                                            let lState = "\(scene["L_state"] ?? "")"
                                                            let fRedundant = scene["F_redundant"] as? String ?? "NA"
                                                            let lRedundant = scene["L_redundant"] as? String ?? "NA"

                                                            database.insertScene(
                                                                sceneId: sceneId,
                                                                deviceUid: deviceUid,
                                                                homeId: homeId,
                                                                roomId: roomId,
                                                                uniqueId: uniqueId,
                                                                modelNo: deviceModelNo,
                                                                deviceType: deviceType,
                                                                sceneNo: sceneNo,
                                                                sceneName: sceneName,
                                                                destButton: destButton,
                                                                configButtons: configButtons,
                                                                configDim: configDim,
                                                                LState: lState,
                                                                LSpeed: lSpeed,
                                                                FState: fState,
                                                                FSpeed: fSpeed,
                                                                fanDest: fanDest,
                                                                LRedundant: lRedundant,
                                                                FRedundant: fRedundant
                                                            )
                                                        }

                                                    }
                                                    
                                                    if let schedules = device["timeShedules"] as? [[String: Any]] {
                                                        print("Found \(schedules.count) schedules for device \(uniqueId)")
                                                        
                                                        for schedule in schedules {
                                                            
                                                            if let schedules = device["timeShedules"] as? [[String: Any]] {
                                                                print("Found \(schedules.count) schedules for device \(uniqueId)")
                                                                
                                                                for schedule in schedules {
                                                                    let scheduleId = schedule["sheduleId"] as? String ?? UUID().uuidString
                                                                    
                                                                    // ✅ Handle scheduleNumber safely
                                                                    let scheduleNumber: String
                                                                    if let num = schedule["sheduleNumber"] as? Int {
                                                                        scheduleNumber = String(num)
                                                                    } else if let num = schedule["sheduleNumber"] as? String {
                                                                        scheduleNumber = num
                                                                    } else {
                                                                        scheduleNumber = ""
                                                                    }
                                                                    
                                                                    let time = schedule["time"] as? String ?? ""
                                                                    let date = schedule["date"] as? String ?? ""
                                                                    let weekSchedule = schedule["week_schedule"] as? String ?? ""
                                                                    let fSpeed = "\(schedule["F_speed"] ?? "0")"
                                                                    let fState = "\(schedule["F_state"] ?? "0")"
                                                                    let lSpeed = "\(schedule["L_speed"] ?? "0")"
                                                                    let lState = "\(schedule["L_state"] ?? "0")"
                                                                    let configButtons = schedule["config_buttons"] as? String ?? ""
                                                                    let destButton = "\(schedule["dest_button"] ?? "")"
                                                                    let fanDest = "\(schedule["fan_dest"] ?? "")"
                                                                    let master = schedule["master"] as? String ?? "0"
                                                                    let modelNo = "\(schedule["modelNo"] ?? "")"
                                                                    let sceneId = schedule["sceneId"] as? String ?? ""
                                                                    
                                                                    print("Inserting schedule: ID=\(scheduleId), Number=\(scheduleNumber), Device=\(deviceUid), Time=\(time)")
                                                                    
                                                                    database.insertSchedule(
                                                                        scheduleId: scheduleId,
                                                                        scheduleNumber: scheduleNumber,
                                                                        deviceUid: deviceUid,
                                                                        uniqueId: uniqueId,
                                                                        date: date,
                                                                        time: time,
                                                                        weekSchedule: weekSchedule,
                                                                        LState: lState,
                                                                        LSpeed: lSpeed,
                                                                        FState: fState,
                                                                        FSpeed: fSpeed,
                                                                        configButtons: configButtons,
                                                                        destButton: destButton,
                                                                        fanDest: fanDest,
                                                                        master: master,
                                                                        modelNo: modelNo,
                                                                        sceneId: sceneId
                                                                    )
                                                                }
                                                            }
                                                        }
                                                    }
                                                    
                                                    
                                                }
                                            }
                                        }else {
                                            print("Device insert not data found:")
                                            
                                            let deviceUid = device["deviceUid"] as? String ?? "null"
                                            let deviceName = device["deviceName"] as? String ?? "null"
                                            let uniqueId = device["unique_id"] as? String ?? "null"
                                            let POP = device["POP"] as? String ?? "null"
                                            let deviceModelNo = device["deviceModelNo"] as? String ?? "null"
                                            let deviceDimmingType = device["deviceDimmingType"] as? String ?? "null"
                                            let deviceType = device["deviceType"] as? String ?? "null"
                                            let connectedSsid = device["connectedSsid"] as? String ?? "null"
                                            let connectedPassword = device["connectedPassword"] as? String ?? "null"
                                            let deviceCategory = device["deviceCategory"] as? String ?? "null"
                                            
                                            print("""
                                            🧩 Device Info:
                                              • deviceUid: \(deviceUid)
                                              • deviceName: \(deviceName)
                                              • uniqueId: \(uniqueId)
                                              • POP: \(POP)
                                              • deviceModelNo: \(deviceModelNo)
                                              • deviceDimmingType: \(deviceDimmingType)
                                              • deviceType: \(deviceType)
                                              • connectedSsid: \(connectedSsid)
                                              • connectedPassword: \(connectedPassword)
                                              • deviceCategory: \(deviceCategory)
                                            """)
                                        }

                                    }
                                }
                            }
                            
                        }
                    }
                }
            }
            
            
            print("✅ Sync data inserted into SQLite successfully!")
            DispatchQueue.main.async {
                completion()
            }
            
        }
        
    }
    
    func insertFamilyHomeAndRoomsIntoDB(familyHomes: [[String: Any]], completion: @escaping () -> Void) {
        
        let database = SkromanIsraDatabaseHelper.shared
        
        DispatchQueue.global(qos: .background).async {
            
            for home in familyHomes {
                
                guard let homeId = home["homeId"] as? String,
                      let homeName = home["homeName"] as? String else { continue }
                
                let homeImage = home["homeImage"] as? String ?? ""
                
                let tuyaHomeId: Int64? = {
                    if let id = home["tuyaHomeId"] as? Int64 {
                        return id
                    } else if let id = home["tuyaHomeId"] as? Int {
                        return Int64(id)
                    }
                    return nil
                }()
                
                database.insertHome(
                    homeServerId: homeId,
                    homeName: homeName,
                    homeUrl: homeImage, tuyaHomeId: tuyaHomeId,
                    isFamilyHome: 1)
                
                // INSERT ROOMS
                if let rooms = home["rooms"] as? [[String: Any]] {
                    for room in rooms {
                        
                        if let roomId = room["roomId"] as? String,
                           let roomName = room["roomName"] as? String {
                            
                            let roomIconId = room["roomIconId"] as? String ?? ""
                            let roomIconType = room["roomIconType"] as? String ?? ""
                            
                            // ✅ Parse tuyaRoomId
                            let tuyaRoomId: Int64? = {
                                let raw = room["tuyaRoomId"]
                                
                                if let id = raw as? Int64 {
                                    return id
                                }
                                
                                if let id = raw as? Int {
                                    return Int64(id)
                                }
                                
                                if let str = raw as? String {
                                    if str == "<null>" || str.isEmpty {
                                        return nil
                                    }
                                    return Int64(str)
                                }
                                
                                return nil
                            }()
                            
                            // ✅ Pass it here
                            database.insertRoom(
                                roomId: roomId,
                                roomName: roomName,
                                roomIconId: roomIconId,
                                roomIconType: roomIconType,
                                tuyaRoomId: tuyaRoomId,   // 🔥 FIX
                                homeId: homeId
                            )
                            
                            
                            // INSERT DEVICES (same as your old logic)
                            if let devices = room["devices"] as? [[String: Any]] {
                                for device in devices {
                                    if room["roomId"] as! String == "ROOM_Id-JjFsBo53D" {
                                        print  ( "here ios room: \(device) ")
                                    }
                                    
                                    if
                                        let deviceUid = device["deviceUid"] as? String,
                                        let deviceName = device["deviceName"] as? String,
                                        let uniqueId = device["unique_id"] as? String,
                                        let POP = device["POP"] as? String,
                                        let deviceModelNo = device["deviceModelNo"] as? String,
                                        let deviceType = device["deviceType"] as? String,
                                        let connectedSsid = device["connectedSsid"] as? String,
                                        let connectedPassword = device["connectedPassword"] as? String
                                    {
                                        
                                        let deviceDimmingType = device["deviceDimmingType"] as? String ?? "null"
                                        let deviceCategory = device["deviceCategory"] as? String ?? "null"
                                        
                                        
                                        database.insertDevice(
                                            deviceUid: deviceUid,
                                            roomId: roomId,
                                            homeId: homeId,
                                            userId: home["userId"] as? String ?? "",
                                            deviceName: deviceName,
                                            uniqueId: uniqueId,
                                            POP: POP,
                                            deviceModelNo: deviceModelNo,
                                            deviceDimmingType: deviceDimmingType,
                                            deviceType: deviceType,
                                            connectedSsid: connectedSsid,
                                            connectedPassword: connectedPassword,
                                            deviceCategory: deviceCategory
                                        )
                                        if let buttons = device["button_Details"] as? [[String: Any]] {
                                            for button in buttons {
                                                print("🔄 Processing button: \(button)")
                                                
                                                let buttonId = button["_id"] as? String
                                                let buttonControlName = button["buttonControlName"] as? String
                                                let buttonIconId = button["buttonIconId"] as? Int
                                                let buttonName = button["buttonName"] as? String
                                                let buttonNo = button["buttonNo"] as? Int
                                                let deviceServerId = button["deviceServerId"] as? String
                                                let power = button["power"] as? Int
                                                let switchName = button["switchName"] as? String
                                                let isShortcut = button["isShortcut"] as? Int
                                                let buttonIconName = button["buttonIconName"] as? String
                                                let buttonIconColor = button["buttonIconColor"] as? String
                                                let isFavourite = button["isFavourite"] as? Int
                                                let isHomeFav = button["isHomeFav"] as? Int                // ✅ Extracted
                                                
                                                
                                                database.insertButtonDetails(
                                                    buttonId: buttonId,
                                                    buttonControlName: buttonControlName,
                                                    buttonIconId: buttonIconId,
                                                    buttonName: buttonName,
                                                    buttonNo: buttonNo,
                                                    deviceServerId: deviceServerId,
                                                    deviceUid: deviceUid,
                                                    power: power,
                                                    roomName: roomName,
                                                    switchName: switchName,
                                                    uniqueId: uniqueId,
                                                    isShortcut: isShortcut,
                                                    buttonIconName: buttonIconName,
                                                    buttonIconColor: buttonIconColor,
                                                    isFavourite: isFavourite, isHomeFav: isHomeFav
                                                )
                                            }
                                            
                                            
                                            if let deviceStates = device["deviceStates"] as? [[String: Any]] {
                                                for state in deviceStates {
                                                    let deviceStateUid = state["deviceStateUid"] as? String ?? ""
                                                    let workingMode = state["working_mode"] as? String ?? ""
                                                    let master = state["master"] as? String ?? ""
                                                    let childLockF = state["child_lock_f"] as? String ?? ""
                                                    let childLockL = state["child_lock_l"] as? String ?? ""
                                                    let childLockM = state["child_lock_m"] as? String ?? ""
                                                    let configButtons = state["config_buttons"] as? String ?? ""
                                                    let configDim = state["config_dim"] as? String ?? ""
                                                    let connectivity = state["connectivity"] as? String ?? ""
                                                    let destButton = state["dest_button"] as? String ?? ""
                                                    let fSpeed = state["F_speed"] as? String ?? ""
                                                    let fState = state["F_state"] as? String ?? ""
                                                    let fanDest = state["fan_dest"] as? String ?? ""
                                                    let lSpeed = state["L_speed"] as? String ?? ""
                                                    let lState = state["L_state"] as? String ?? ""
                                                    let series = state["series"] as? String ?? ""
                                                    
                                                    // ✅ Optional ota_status
                                                    let otaStatus = state["ota_status"] as? Int
                                                    let fRegulator =  state["F_regulator"] as?  String ?? ""
                                                    database.insertDeviceState(
                                                        deviceUid: deviceUid,
                                                        deviceStateUid: deviceStateUid,
                                                        uniqueId: uniqueId,
                                                        working_mode: workingMode,
                                                        master: master,
                                                        child_lock_f: childLockF,
                                                        child_lock_l: childLockL,
                                                        child_lock_m: childLockM,
                                                        config_buttons: configButtons,
                                                        config_dim: configDim,
                                                        connectivity: connectivity,
                                                        dest_button: destButton,
                                                        f_speed: fSpeed,
                                                        f_state: fState,
                                                        fan_dest: fanDest,
                                                        l_speed: lSpeed,
                                                        l_state: lState,
                                                        series: series,
                                                        ota_status: otaStatus, F_regulator: fRegulator
                                                    )
                                                }
                                            }
                                            
                                            
                                            if let scenes = device["scenes"] as? [[String: Any]] {
                                                for scene in scenes {
                                                    if let sceneId = scene["sceneId"] as? String,
                                                       let sceneName = scene["sceneName"] as? String,
                                                       let sceneNo = "\(scene["sceneNo"] ?? "")" as String? {
                                                        
                                                        let configButtons = "\(scene["config_buttons"] ?? "")"
                                                        let configDim = "\(scene["config_dim"] ?? "")"
                                                        let destButton = "\(scene["dest_button"] ?? "")"
                                                        let fanDest = "\(scene["fan_dest"] ?? "")"
                                                        let fSpeed = "\(scene["F_speed"] ?? "")"
                                                        let fState = "\(scene["F_state"] ?? "")"
                                                        let lSpeed = "\(scene["L_speed"] ?? "")"
                                                        let lState = "\(scene["L_state"] ?? "")"
                                                        let fRedundant = scene["F_redundant"] as? String ?? "NA"
                                                        let lRedundant = scene["L_redundant"] as? String ?? "NA"
                                                        
                                                        database.insertScene(
                                                            sceneId: sceneId,
                                                            deviceUid: deviceUid,
                                                            homeId: homeId,
                                                            roomId: roomId,
                                                            uniqueId: uniqueId,
                                                            modelNo: deviceModelNo,
                                                            deviceType: deviceType,
                                                            sceneNo: sceneNo,
                                                            sceneName: sceneName,
                                                            destButton: destButton,
                                                            configButtons: configButtons,
                                                            configDim: configDim,
                                                            LState: lState,
                                                            LSpeed: lSpeed,
                                                            FState: fState,
                                                            FSpeed: fSpeed,
                                                            fanDest: fanDest,
                                                            LRedundant: lRedundant,
                                                            FRedundant: fRedundant
                                                        )
                                                    }
                                                    
                                                }
                                                
                                                if let schedules = device["timeShedules"] as? [[String: Any]] {
                                                    print("Found \(schedules.count) schedules for device \(uniqueId)")
                                                    
                                                    for schedule in schedules {
                                                        
                                                        if let schedules = device["timeShedules"] as? [[String: Any]] {
                                                            print("Found \(schedules.count) schedules for device \(uniqueId)")
                                                            
                                                            for schedule in schedules {
                                                                let scheduleId = schedule["sheduleId"] as? String ?? UUID().uuidString
                                                                
                                                                // ✅ Handle scheduleNumber safely
                                                                let scheduleNumber: String
                                                                if let num = schedule["sheduleNumber"] as? Int {
                                                                    scheduleNumber = String(num)
                                                                } else if let num = schedule["sheduleNumber"] as? String {
                                                                    scheduleNumber = num
                                                                } else {
                                                                    scheduleNumber = ""
                                                                }
                                                                
                                                                let time = schedule["time"] as? String ?? ""
                                                                let date = schedule["date"] as? String ?? ""
                                                                let weekSchedule = schedule["week_schedule"] as? String ?? ""
                                                                let fSpeed = "\(schedule["F_speed"] ?? "0")"
                                                                let fState = "\(schedule["F_state"] ?? "0")"
                                                                let lSpeed = "\(schedule["L_speed"] ?? "0")"
                                                                let lState = "\(schedule["L_state"] ?? "0")"
                                                                let configButtons = schedule["config_buttons"] as? String ?? ""
                                                                let destButton = "\(schedule["dest_button"] ?? "")"
                                                                let fanDest = "\(schedule["fan_dest"] ?? "")"
                                                                let master = schedule["master"] as? String ?? "0"
                                                                let modelNo = "\(schedule["modelNo"] ?? "")"
                                                                let sceneId = schedule["sceneId"] as? String ?? ""
                                                                
                                                                print("Inserting schedule: ID=\(scheduleId), Number=\(scheduleNumber), Device=\(deviceUid), Time=\(time)")
                                                                
                                                                database.insertSchedule(
                                                                    scheduleId: scheduleId,
                                                                    scheduleNumber: scheduleNumber,
                                                                    deviceUid: deviceUid,
                                                                    uniqueId: uniqueId,
                                                                    date: date,
                                                                    time: time,
                                                                    weekSchedule: weekSchedule,
                                                                    LState: lState,
                                                                    LSpeed: lSpeed,
                                                                    FState: fState,
                                                                    FSpeed: fSpeed,
                                                                    configButtons: configButtons,
                                                                    destButton: destButton,
                                                                    fanDest: fanDest,
                                                                    master: master,
                                                                    modelNo: modelNo,
                                                                    sceneId: sceneId
                                                                )
                                                            }
                                                        }
                                                    }
                                                }
                                                
                                                
                                            }
                                        }
                                    }else {
                                        print("Device insert not data found:")
                                        
                                        let deviceUid = device["deviceUid"] as? String ?? "null"
                                        let deviceName = device["deviceName"] as? String ?? "null"
                                        let uniqueId = device["unique_id"] as? String ?? "null"
                                        let POP = device["POP"] as? String ?? "null"
                                        let deviceModelNo = device["deviceModelNo"] as? String ?? "null"
                                        let deviceDimmingType = device["deviceDimmingType"] as? String ?? "null"
                                        let deviceType = device["deviceType"] as? String ?? "null"
                                        let connectedSsid = device["connectedSsid"] as? String ?? "null"
                                        let connectedPassword = device["connectedPassword"] as? String ?? "null"
                                        let deviceCategory = device["deviceCategory"] as? String ?? "null"
                                        
                                        print("""
                                    🧩 Device Info:
                                      • deviceUid: \(deviceUid)
                                      • deviceName: \(deviceName)
                                      • uniqueId: \(uniqueId)
                                      • POP: \(POP)
                                      • deviceModelNo: \(deviceModelNo)
                                      • deviceDimmingType: \(deviceDimmingType)
                                      • deviceType: \(deviceType)
                                      • connectedSsid: \(connectedSsid)
                                      • connectedPassword: \(connectedPassword)
                                      • deviceCategory: \(deviceCategory)
                                    """)
                                    }
                                    
                                }
                            }
                            
                        }
                    }
                }
                
                print("✅ FAMILY Homes + Rooms inserted successfully!")
                DispatchQueue.main.async {
                    completion()
                }
            }
        }
        
    }
    func checkTuyaLoginStatus() {
        
        if ThingSmartUser.sharedInstance().isLogin {
            print("✅ Tuya user already logged in")
            
            fetchTuyaHomeOnly()
            
        } else {
            print("❌ Tuya user NOT logged in")
            
             
        }
    }
    
    func fetchTuyaHomeOnly() {
        
        let homeManager = ThingSmartHomeManager()
        
        homeManager.getHomeList { [weak self] homeList in
            
            guard let self = self else { return }
            
            guard let homes = homeList, !homes.isEmpty else {
                print("❌ No Tuya homes available")
                return
            }
            
            print("✅ Total Homes: \(homes.count)")
            
            for home in homes {
                
                let homeId = home.homeId
                let homeName = home.name ?? "Unknown"
                
                print("\n🏠 Home: \(homeName) | ID: \(homeId)")
                
                guard let homeInstance = ThingSmartHome(homeId: homeId) else {
                    print("❌ Failed to create home instance")
                    continue
                }
                
                // ✅ Load Home Details
                homeInstance.getDetailWithSuccess({ _ in
                    
                    print("✅ Home details loaded")
                    
                    guard let allDevices = homeInstance.deviceList else {
                        print("⚠️ No devices found in home")
                        return
                    }
                    
                    // =========================
                    // ✅ HANDLE ROOMS
                    // =========================
                    
                    let rooms = homeInstance.roomList ?? []
                    print("📦 Rooms Count: \(rooms.count)")
                    
                    for room in rooms {
                        
                        let roomId = room.roomId
                        let roomName = room.name ?? "Unknown Room"
                        
                        print("\n🏡 Room: \(roomName) | ID: \(roomId)")
                        
                        let roomDevices = allDevices.filter { $0.roomId == roomId }
                        
                        if roomDevices.isEmpty {
                            print("⚠️ No devices in this room")
                            continue
                        }
                        
                        print("🔌 Devices Count: \(roomDevices.count)")
                        
                        for device in roomDevices {
                            
                            let deviceId = device.devId ?? ""
                            guard !deviceId.isEmpty else { continue }
                            
                            let deviceName = device.name ?? "Unknown Device"
                            let deviceCategory = device.category ?? "unknown"
                            
                            print("""
                            🔌 Device:
                               Name     : \(deviceName)
                               DeviceId : \(deviceId)
                               Category : \(deviceCategory)
                            """)
                            
                            SkromanIsraDatabaseHelper.shared.insertTuyaDevice(
                                tuyaHomeId: homeId,
                                tuyaRoomId: roomId,
                                deviceId: deviceId,
                                deviceName: deviceName,
                                deviceCategory: deviceCategory
                            )
                        }
                    }
                    NotificationCenter.default.post(name: NSNotification.Name("TuyaSyncDone"), object: nil)

                    // =========================
                    // ✅ HANDLE UNASSIGNED DEVICES
                    // =========================

                    let unassignedDevices = allDevices.filter { $0.roomId == 0 }

                    if !unassignedDevices.isEmpty {

                        print("\n⚠️ Unassigned Devices:")

                        for device in unassignedDevices {

                            let deviceId = device.devId ?? ""
                            guard !deviceId.isEmpty else { continue }

                            let deviceName = device.name ?? "Unknown Device"
                            let deviceCategory = device.category ?? "unknown"

                            print("""
                            🔌 Device:
                               Name     : \(deviceName)
                               DeviceId : \(deviceId)
                               Category : \(deviceCategory)
                            """)

                            SkromanIsraDatabaseHelper.shared.insertTuyaDevice(
                                tuyaHomeId: homeId,
                                tuyaRoomId: -1,
                                deviceId: deviceId,
                                deviceName: deviceName,
                                deviceCategory: deviceCategory
                            )
                        }
                    }
                    
                }, failure: { error in
                    print("❌ Failed to load home detail:", error?.localizedDescription ?? "")
                })
            }
            
        } failure: { error in
            print("❌ Error fetching Tuya homes:", error?.localizedDescription ?? "")
        }
    }
    
    
}
