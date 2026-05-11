//
//  MenuViewController.swift
//  SkromanIsra
//
//  Created by Admin on 01/02/25.
//

import UIKit
 import SwiftKeychainWrapper
import Alamofire
import ThingSmartHomeKit

class MenuViewController: UIViewController {
    
    @IBOutlet weak var userView: UIView!
    
    @IBOutlet weak var menuBackGroundview: UIView!
    @IBOutlet weak var userImage: UIImageView!
    
    @IBOutlet weak var backgroundCollectionView: UIView!
    @IBOutlet weak var backgroundLogo: UIImageView!
    
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var userMialIdLabel: UILabel!
    
    @IBOutlet weak var backButton: UIButton!
    var verifyAlexaStatus: Bool = false
    var verifyGoogleStatus: Bool =  false
    
    @IBOutlet weak var profileImageView: UIView!
    
    @IBOutlet var mainview: UIView!
    
    @IBOutlet weak var HomemenuTableView: UITableView!
    
    @IBOutlet weak var backgroundimage: UIImageView!
    var fcmToken: String?
    
    var syncAlert: UIAlertController?
    var syncPopup: SyncProcessingPopup?
    
    var iconsArray :[String] =  [ "syncData 1","alexa", "google","familyMember","complain", "usermanual", "support","aboutUs","logout" ]
    var optionsNameArray : [String] = [  "Sync Server Data", "Enable Alexa", "Enable  Ok Google", "Add Family Member", "Raise comaplaint","User manual", "Support & Help", "About", "LogOut"   ]
    override func viewDidLoad() {
        super.viewDidLoad()
        backButton.setTitle("", for: .normal)
        HomemenuTableView.dataSource =  self
        HomemenuTableView.delegate =  self
        menubarCell()
        
        backgroundimage.contentMode = .scaleAspectFill
        backgroundimage.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            backgroundimage.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundimage.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundimage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundimage.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        userImage.layer.cornerRadius = userImage.frame.size.width / 2
        
        userImage.backgroundColor = UIColor.clear
        
        profileImageView.layer.masksToBounds = true
        profileImageView.layer.cornerRadius = profileImageView.frame.size.width / 2
        
        profileImageView.backgroundColor = UIColor.clear
        profileImageView.layer.masksToBounds = true
        profileImageView.layer.borderColor = UIColor.white.cgColor
        profileImageView.layer.borderWidth = 2.0
        
        let email = KeychainWrapper.standard.string(forKey: "emailId")
        let userid  =  KeychainWrapper.standard.string(forKey: "userId")
        userMialIdLabel.text =  email
        userInfofetch(userid: userid)
        
        fetchUserData()
        
        
        menuBackGroundview.cornerRadius =  15
        menuBackGroundview.clipsToBounds =  true
        HomemenuTableView.backgroundColor = .clear
        
        HomemenuTableView.separatorStyle = .singleLine
        HomemenuTableView.separatorColor = UIColor.lightGray // or any color you like
        
        
        if let token = FCMTokenManager.shared.token {
            self.fcmToken = token
            print("✅ FCM Token (from manager):", token)
        }
        
        // 2️⃣ Listen for token if it arrives later
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleFCMToken),
            name: Notification.Name("FCMTokenReceived"),
            object: nil
        )
        
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(profileImageTapped))
        profileImageView.isUserInteractionEnabled = true
        profileImageView.addGestureRecognizer(tapGesture)
        
    }
    @objc func profileImageTapped() {
        let vc = storyboard?.instantiateViewController(identifier: "EditprofileViewController") as! EditprofileViewController
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func handleFCMToken(_ notification: Notification) {
        let token = notification.userInfo?["token"] as? String
        self.fcmToken = token
        print("FCM Token (from notification):", token ?? "nil")
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    
    
    @IBAction func editProfileButton(_ sender: Any) {
        let vc = storyboard?.instantiateViewController(identifier: "EditprofileViewController") as! EditprofileViewController
        
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func Syncdata(){
        print("sync")
        SyncPostData()
        showSyncPopup()
    }
    
    
    
    func userInfofetch(userid: String?) {
        let usersData = SkromanIsraDatabaseHelper.shared.fetchUserById(userId: userid ?? "")
        print("userInfo : \(usersData)")
        
        if let user = usersData.first {
            userNameLabel.text = user.userName ?? ""
            userMialIdLabel.text = user.emailId ?? ""
            
            if let imageUrlString = user.imageUser, !imageUrlString.isEmpty,
               let imageUrl = URL(string: imageUrlString) {
                loadImage(from: imageUrl)
            } else {
                // If no image, set a default placeholder
                userImage.image = UIImage(named: "user-4")
            }
        } else {
            userNameLabel.text = ""
            print("No user found for ID: \(userid ?? "nil")")
        }
    }
    
    
    func tuyaLogout(){
        ThingSmartUser.sharedInstance().loginOut({
            print("✅ Logout successful")
            
        }, failure: { error in
            print("❌ Logout failed: \(error?.localizedDescription ?? "Unknown error")")
        })
    }
    
    
    
    
    
    func menubarCell(){
        let  uiNib =  UINib(nibName: "HomeMenuTableViewCell", bundle: nil)
        HomemenuTableView.register(uiNib, forCellReuseIdentifier: "HomeMenuTableViewCell")
        
    }
    
    @IBAction func backButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    
    func logOut() {
        // Remove values from Keychain
        KeychainWrapper.standard.removeObject(forKey: "userId")
        KeychainWrapper.standard.removeObject(forKey: "_id")
        KeychainWrapper.standard.removeObject(forKey: "login_password")
        KeychainWrapper.standard.remove(forKey: "emailId")
        KeychainWrapper.standard.removeAllKeys()
        
        // Delete the database
        SkromanIsraDatabaseHelper.shared.deleteDatabase()
        
        
        showPopup()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { // Adjust delay as needed
            self.navigateToLogin()
        }
    }
    
    @objc func showPopup() {
        
        showPopupPresenter.showPopup1(on: self.view,
                                      animationName: "success",
                                      title: "Success!",
                                      subtitle: "successfully  logOut")
    }
    
    func showSyncPopup() {
        
        let popup = SyncProcessingPopup(frame: view.bounds)
        
        popup.configure(
            title: "Syncing Data",
            message: "Please wait while your data is syncing with the server."
        )
        
        view.addSubview(popup)
        
        syncPopup = popup
    }
    
    func hideSyncPopup() {
        
        DispatchQueue.main.async {
            
            self.syncPopup?.stop()
            self.syncPopup?.removeFromSuperview()
            self.syncPopup = nil
        }
    }
    
    func showLogoutConfirmation() {
        let alertController = UIAlertController(title: "Confirm Logout", message: "Are you sure you want to log out?", preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let confirmAction = UIAlertAction(title: "OK", style: .destructive) { _ in
            
            self.LogoutUser()
            self.logOut()
            self.tuyaLogout()
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(confirmAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func showDeleteAccConfirmation() {
        
        // Step 1: Are you sure popup
        let confirmAlert = UIAlertController(
            title: "Delete Account",
            message: "Are you sure you want to delete your account?",
            preferredStyle: .alert
        )
        
        confirmAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        confirmAlert.addAction(UIAlertAction(title: "OK", style: .destructive) { _ in
            self.showDeleteInputPopup()
        })
        
        present(confirmAlert, animated: true)
    }
    
    
    // MARK: Step 2: Type DELETE popup
    
    func showDeleteInputPopup() {
        
        let inputAlert = UIAlertController(
            title: "Confirm Delete",
            message: "Type DELETE to confirm",
            preferredStyle: .alert
        )
        
        inputAlert.addTextField { textField in
            textField.placeholder = "DELETE"
            textField.autocapitalizationType = .allCharacters
        }
        
        inputAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        inputAlert.addAction(UIAlertAction(title: "OK", style: .destructive) { _ in
            
            let userInput = inputAlert.textFields?.first?.text ?? ""
            
            if userInput.uppercased() == "DELETE" {
                self.delete_user()
            } else {
                self.showWrongDeleteText()
            }
        })
        
        present(inputAlert, animated: true)
    }
    
    
    // MARK: Wrong DELETE entered
    
    func showWrongDeleteText() {
        
        let alert = UIAlertController(
            title: "Error",
            message: "Please type DELETE exactly to continue.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    func navigateToLogin(){
        let loginVc = storyboard?.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
        navigationController?.pushViewController(loginVc, animated: true)
        
        
    }
    
    
    func LogoutUser() {
        
        let email = KeychainWrapper.standard.string(forKey: "emailId")
        guard let email = email else { return }
        
        guard let deviceToken = fcmToken, !deviceToken.isEmpty else {
            print("FCM Token missing")
            return
        }
        print("FCM Token:", fcmToken ?? "nil")
        let logout_user_params : Parameters = [
            
            "emailId": email,
            "deviceToken": deviceToken
        ]
        
        
        AF.request(
            "http://3.7.18.55:3000/skroman/userapi/logout-user",
            method: .post,
            parameters: logout_user_params,
            encoding: JSONEncoding.default
        )
        .validate()
        .responseData { response in
            
            
            switch response.result {
            case .success(let data):
                
                
                if let jsonString = String(data: data, encoding: .utf8) {
                    
                }
                
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        print("Parsed Logout Response:", json)
                        
                        let msg = json["Logout successful"] as? String ?? ""
                        
                        if msg.isEmpty {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                self.navigateToLogin()
                            }
                        }
                    }
                } catch {
                    print("JSON Parse Error:", error.localizedDescription)
                }
                
            case .failure(let error):
                print("Logout API Error:", error.localizedDescription)
            }
        }
        
        
    }
    
    
    
    func delete_user() {
        let email = KeychainWrapper.standard.string(forKey: "emailId")
        guard let email = email else { return }
        
        let delete_user_params : Parameters = [
            
            "emailId": email
            
        ]
        
        
        AF.request("http://3.7.18.55:3000/skroman/userapi/deleteuser", method: .post, parameters: delete_user_params, encoding: JSONEncoding.default, headers: nil).response { response in
            debugPrint(response)
            
            switch response.result
            {
            case .success(let data) :
                do {
                    
                    
                    let jsonOne = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary
                    
                    if let parseJson = jsonOne,
                       
                        let msg = parseJson["msg"] as? String {
                        
                        
                        if msg == "Successfully delete user" {
                            
                            let when = DispatchTime.now() + 2
                            
                            DispatchQueue.main.asyncAfter(deadline: when)  {
                                
                                
                                self.navigateToLogin()
                            }
                        }
                        
                        else {
                            
                            // self.allAlert(alertTitle: "Error", alertMessage: "User not deleted")
                            
                        }
                        
                    }
                    
                }
                catch {
                    
                }
                
                
            case .failure(let err):
                print(err.localizedDescription)
                
            }
            
        }.resume()
        
    }
    
    func SyncPostData() {
        print("✅ SyncPostData() called")
        //        SkromanIsraDatabaseHelper.shared.openDatabase()
        //        SkromanIsraDatabaseHelper.shared.createTables()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            SkromanIsraDatabaseHelper.shared.deleteAllTablesData { success in
                if success {
                    print("✅ All data was deleted successfully.")
                } else {
                    print("❌ Failed to delete data from one or more tables.")
                }
                
                
                self.syncServer()
            }
        }
    }
    
    
    func syncServer() {
        let userId = KeychainWrapper.standard.string(forKey: "userId") ?? "Nothing"
        
        let syncDataParameters: [String: Any] = [
            "userId": userId
        ]
        print("📡 call api")
        
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
                                    SkromanIsraDatabaseHelper.shared.insertUser(
                                        userId: userData["userId"] as? String ?? "",
                                        userName: userData["userName"] as? String,
                                        emailId: userData["emailId"] as? String,
                                        mobileNumber: userData["mobileNumber"] as? String,
                                        address1: userData["address1"] as? String,
                                        address2: userData["address2"] as? String,
                                        city: userData["city"] as? String,
                                        state: userData["state"] as? String,
                                        pinCode: userData["pinCode"] as? String,
                                        loginType: userData["loginType"] as? String,
                                        imageUser: userData["imageUser"] as? String,
                                        verifyAlexa: userData["verifyAlexa"] as? String,
                                        verifyGoogle: userData["verifyGoogle"] as? String,
                                        password: userData["password"] as? String
                                    )
                                    print("✅ User data inserted successfully")
                                }
                                
                                // Insert Home and Rooms Data
                                if let syncData = json["syncData"] as? [[String: Any]] {
                                    self.insertHomeAndRoomsIntoDB(syncData: syncData) {
                                        print("✅ Sync completed successfully!")
                                        DispatchQueue.main.async {
                                            self.navigateToHome()
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
                                    
                                } else {
                                    print("⚠️ No syncData found in response")
                                    DispatchQueue.main.async {
                                        self.navigateToHome()
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
                                        if let deviceUid = device["deviceUid"] as? String,
                                           let deviceName = device["deviceName"] as? String,
                                           let uniqueId = device["unique_id"] as? String,
                                           let POP = device["POP"] as? String,
                                           let deviceModelNo = device["deviceModelNo"] as? String,
                                           let deviceDimmingType = device["deviceDimmingType"] as? String,
                                           let deviceType = device["deviceType"] as? String,
                                           let connectedSsid = device["connectedSsid"] as? String,
                                           let connectedPassword = device["connectedPassword"] as? String,
                                           let deviceCategory = device["deviceCategory"] as? String {
                                            
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
                                                           let sceneNo = scene["sceneNo"] as? String,
                                                           let configButtons = scene["config_buttons"] as? String,
                                                           let configDim = scene["config_dim"] as? String,
                                                           let destButton = scene["dest_button"] as? String,
                                                           let fanDest = scene["fan_dest"] as? String,
                                                           let fSpeed = scene["F_speed"] as? String,
                                                           let fState = scene["F_state"] as? String,
                                                           let lSpeed = scene["L_speed"] as? String,
                                                           let lState = scene["L_state"] as? String,
                                                           let fredundant =  scene["F_redundant"] as? String,
                                                           let lredundant =  scene["L_redundant"] as? String{
                                                            
                                                            database.insertScene(sceneId: sceneId, deviceUid: deviceUid, homeId: homeId, roomId: roomId, uniqueId: uniqueId, modelNo: deviceModelNo, deviceType: deviceType, sceneNo: sceneNo, sceneName: sceneName, destButton: destButton, configButtons:configButtons, configDim: configDim, LState: lState, LSpeed: lSpeed, FState: fState, FSpeed: fSpeed, fanDest: fanDest, LRedundant: lredundant, FRedundant: fredundant)
                                                        }
                                                    }
                                                    
                                                    if let schedules = device["timeShedules"] as? [[String: Any]] {
                                                        print("Found \(schedules.count) schedules for device \(uniqueId)")
                                                        
                                                        for schedule in schedules {
                                                            
                                                            let scheduleId = schedule["sheduleId"] as? String ?? UUID().uuidString
                                                            let scheduleNumber = schedule["scheduleNumber"] as? String ?? ""  //
                                                            
                                                            let time = schedule["time"] as? String ?? ""
                                                            let date = schedule["date"] as? String ?? ""
                                                            let weekSchedule = schedule["week_schedule"] as? String ?? ""
                                                            let fSpeed = schedule["F_speed"] as? String ?? "0"
                                                            let fState = schedule["F_state"] as? String ?? "0"
                                                            let lSpeed = schedule["L_speed"] as? String ?? "0"
                                                            let lState = schedule["L_state"] as? String ?? "0"
                                                            let configButtons = schedule["config_buttons"] as? String ?? ""
                                                            let destButton = schedule["dest_button"] as? String ?? ""
                                                            let fanDest = schedule["fan_dest"] as? String ?? ""
                                                            let master = schedule["master"] as? String ?? "0"
                                                            let modelNo = schedule["modelNo"] as? String ?? ""
                                                            let sceneId = schedule["sceneId"] as? String ?? ""
                                                            
                                                            
                                                            print("Inserting schedule: ID=\(scheduleId), Device=\(deviceUid), Time=\(time), Date=\(date), Scene=\(sceneId)")
                                                            
                                                            
                                                            let success = database.insertSchedule(
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
    
    
    
    @objc func showPopupSync() {
        
        showPopupPresenter.showPopup1(on: self.view,
                                      animationName: "success",
                                      title: "Success!",
                                      subtitle: "Sync data successfully")
        
        
    }
    func navigateToHome(){
        let  vc = storyboard?.instantiateViewController(identifier: "MainHomeViewController") as!
        MainHomeViewController
        
        navigationController?.pushViewController(vc, animated: true)
    }
    func fetchUserData() {
        let userId = KeychainWrapper.standard.string(forKey: "userId") ?? ""
        
        guard !userId.isEmpty else {
            print("User ID is missing")
            return
        }
        
        let users = SkromanIsraDatabaseHelper.shared.fetchUserById(userId: userId)
        
        if let user = users.first {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                if user.verifyAlexa?.lowercased() == "True" {
                    self.verifyAlexaStatus = true
                    print(" check image  not  show ")
                } else {
                    self.verifyAlexaStatus = false
                    print("check image show ")
                }
                if user.verifyGoogle?.lowercased() == "true" {
                    self.verifyGoogleStatus =  true
                    
                } else {
                    self.verifyGoogleStatus =  false
                }
                
                self.HomemenuTableView.reloadData()  // Reload UI
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
    
}


extension MenuViewController: UITableViewDataSource, UITableViewDelegate{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return optionsNameArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell =  tableView.dequeueReusableCell(withIdentifier: "HomeMenuTableViewCell", for : indexPath) as! HomeMenuTableViewCell
        cell.optionNameLabel.text = optionsNameArray[indexPath.row]
        let iconName = iconsArray[indexPath.row]
        cell.iconImageView.image = UIImage(named: iconName)
        cell.selectionStyle = .none

                cell.isTrueImage.isHidden = true
        
                  if optionsNameArray[indexPath.row] == "Enable Alexa" {
                      cell.isTrueImage.isHidden = !verifyAlexaStatus
                  } else if optionsNameArray[indexPath.row] == "Enable Google" {
                      cell.isTrueImage.isHidden = !verifyGoogleStatus
                  }
        
  return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedOption = optionsNameArray[indexPath.row]
        print("📌 Selected option: \(selectedOption)")
        
        if selectedOption == "LogOut" {
            showLogoutConfirmation()
        }  else if selectedOption == "Sync Server Data" {
            
            showSyncPopup()

            DispatchQueue.global(qos: .background).async {

                self.SyncPostData()
            }
        }
     
        
        else if selectedOption == "Enable Alexa" {
            let vc = storyboard?.instantiateViewController(identifier: "AlexaViewController") as! AlexaViewController
            
            navigationController?.pushViewController(vc, animated: true)
            
            }
        else if selectedOption == "Enable  Ok Google" {
            let vc = storyboard?.instantiateViewController(identifier: "GoogleCheckViewController") as! GoogleCheckViewController
            
            navigationController?.pushViewController(vc, animated: true)
            
            }
        else if selectedOption == "Payment" {
            let vc = storyboard?.instantiateViewController(identifier: "RazorPayViewController") as! RazorPayViewController
            
            navigationController?.pushViewController(vc, animated: true)
            
        } else if selectedOption == "Support & Help"{
            let vc = storyboard?.instantiateViewController(identifier: "HelpAndSupportViewController") as! HelpAndSupportViewController
            
            navigationController?.pushViewController(vc, animated: true)
            
        }
        else if selectedOption == "User manual"{
            let vc = storyboard?.instantiateViewController(identifier: "UserManualViewController") as! UserManualViewController
            
            navigationController?.pushViewController(vc, animated: true)
            
        }
        else if selectedOption == "About"{
            let vc = storyboard?.instantiateViewController(identifier: "AboutUsViewController") as! AboutUsViewController
            
            navigationController?.pushViewController(vc, animated: true)
            
        }
        else if selectedOption == "Add Family Member"{
        
        
          
            if let vc = storyboard?.instantiateViewController(withIdentifier: "FamilyMemberListViewController") as? FamilyMemberListViewController {
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }

        else if selectedOption == "Raise comaplaint"{
          
            if let vc = storyboard?.instantiateViewController(withIdentifier: "ComplaintViewController") as? ComplaintViewController {
                self.navigationController?.pushViewController(vc, animated: true)
            }
            print("Raise complaint tapped")
            
            
        }
          
            
                
    }
    
}


extension MenuViewController {
    func loadImage(from url: URL) {
        DispatchQueue.global().async {
            if let data = try? Data(contentsOf: url),
               let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.userImage.image = image
                    self.userImage.contentMode = .scaleAspectFill
                    self.userImage.layer.cornerRadius = self.userImage.frame.width / 2
                    self.userImage.layer.masksToBounds = true
                }
            } else {
                DispatchQueue.main.async {
                    self.userImage.image = UIImage(named: "profilePlaceholder")
                }
            }
        }
    }
}


