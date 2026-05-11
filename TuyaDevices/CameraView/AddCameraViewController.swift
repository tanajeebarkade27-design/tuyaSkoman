//
//  cameraViewController.swift
//  SkromanIsra
//
//  Created by Admin on 31/03/26.
//

import UIKit
import ThingSmartHomeKit
import SwiftKeychainWrapper
 import Alamofire


class AddCameraViewController: UIViewController {
    var ssid: String?
    var password: String?
    var tuyaHomeId: Int64?
    var tuyaRoomId: Int64?
    var selectedRoomId: String?
      var selectedHomeId: String?
    var roomName: String?
   
    @IBOutlet weak var otpCode: UITextField!
    
    
    @IBOutlet weak var verify: UIButton!
   
    @IBOutlet weak var verfiyOtpBtn: UIButton!
    
    @IBOutlet weak var wifipassword: UITextField!
    
    @IBOutlet weak var wifiName: UITextField!
    
    @IBOutlet weak var submitWifiDetail: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        wifiName.delegate = self
        wifipassword.delegate = self
        otpCode.delegate = self
        let backgroundImage = UIImageView(image: UIImage(named: "Screen Background"))
               backgroundImage.contentMode = .scaleAspectFill
                view.insertSubview(backgroundImage, at: 0)
               backgroundImage.translatesAutoresizingMaskIntoConstraints = false
               backgroundImage.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
               backgroundImage.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
               backgroundImage.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
               backgroundImage.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        print ("selectedRoomId \(selectedRoomId)  selectedHomeId\(selectedHomeId) tuyaHomeId\(tuyaHomeId) ")
//        let email = KeychainWrapper.standard.string(forKey: "emailId") ?? ""
//            let password = "Skroman@12"
            
           
            if let serverId = selectedHomeId,
               let home = SkromanIsraDatabaseHelper.shared.fetchHomeById(homeServerId: serverId) {
                
                self.tuyaHomeId = home.tuyaHomeId
                self.updateWifiUIVisibility()
                print("📦 DB TuyaHomeId:", self.tuyaHomeId ?? -1)
            }
            
         
//            if tuyaHomeId != nil {
//                print("👉 TuyaHomeId already exists → Direct login")
//                loginUser(email: email, password: password)
//            } else {
//                print("👉 No TuyaHomeId → Need to sync")
//                sendVerificationCode(email: email)
//            }
        otpCode.isHidden = true
        verify.isHidden =  true
        
        
        
        if let roomserverId = selectedRoomId {

            SkromanIsraDatabaseHelper.shared.fetchRoomByRoomId(roomId: roomserverId) { room in

                guard let room = room else {
                    print("❌ Room not found")
                    return
                }

                print("✅ Room Name:", room.tuyaRoomId  )

               
                let roomName = room.roomName

               
                
            }
            
            
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.startInitialFlow()
        }
        wifiName.isHidden = true
        wifipassword.isHidden = true
        submitWifiDetail.isHidden = true
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func startInitialFlow() {
        
        let email = KeychainWrapper.standard.string(forKey: "emailId") ?? ""
        let password = "Skroman@12"
        
        if tuyaHomeId != nil {
            loginUser(email: email, password: password)
        } else {
            sendVerificationCode(email: email)
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    
    @IBAction func backBtn(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    func updateWifiUIVisibility() {
        
        let shouldShow = (tuyaHomeId != nil && tuyaRoomId != nil)
        
        DispatchQueue.main.async {
            self.wifiName.isHidden = !shouldShow
            self.wifipassword.isHidden = !shouldShow
            self.submitWifiDetail.isHidden = !shouldShow
        }
    }
    
    @IBAction func verifyButton(_ sender: Any) {
        
        let email = KeychainWrapper.standard.string(forKey: "emailId") ?? ""
        let password = "Skroman@12"
        
        guard !email.isEmpty else {
            print("❌ Email not found")
            return
        }
        
        if tuyaHomeId == nil {
           
            sendVerificationCode(email: email)
            
        } else {
            // Already registered → Login
            loginUser(email: email, password: password)
        }
    }
    
    func sendVerificationCode(email: String) {
        
        let password = "Skroman@12"
        
        ThingSmartUser.sharedInstance().sendVerifyCode(
            withUserName: email,
            region: "EU",
            countryCode: "91",
            type: 1,
            success: {
                print("✅ OTP sent successfully")
                DispatchQueue.main.async {
                               self.otpCode.isHidden = false
                    self.verfiyOtpBtn.isHidden =  false
                           }
            },
            failure: { error in
                
                if let e = error {
                    print("❌ sendVerifyCode failed:", e.localizedDescription)
                    
                    // 🔥 IMPORTANT FIX
                    if e.localizedDescription.contains("User already exists") {
                        print("👉 User exists → Logging in directly")
                        
                        DispatchQueue.main.async {
                                               self.otpCode.isHidden = true
                            self.verfiyOtpBtn.isHidden =  true
                                           }
                        self.loginUser(email: email, password: password)
                    } else {
                        DispatchQueue.main.async {
                            self.showAlert("Error", e.localizedDescription)
                        }
                    }
                }
            }
        )
    }
    
    func registerUser(email: String, password: String) {
        
        guard let code = otpCode.text, !code.isEmpty else {
            print("❌ Enter OTP")
            return
        }
        
        ThingSmartUser.sharedInstance().register(
            withUserName: email,
            region: "EU",
            countryCode: "91",
            code: code,
            password: password,
            success: {
                print("✅ Registration successful")
                
                
                self.loginUser(email: email, password: password)
            },
            failure: { error in
                if let e = error {
                    print("❌ Registration failed:", e.localizedDescription)
                    DispatchQueue.main.async {
                        self.showAlert("Error", e.localizedDescription)
                    }
                }
            }
        )
    }
    

    func loginUser(email: String, password: String) {
        ThingSmartUser.sharedInstance().login(
            byEmail: "91",
            email: email,
            password: password,
            success: {
                
                print("✅ Login successful")
                
                self.fetchHomeList()
            },
            failure: { error in
                if let e = error {
                    print("❌ Login failed: \(e.localizedDescription)")
                    DispatchQueue.main.async {
                        self.showAlert("Error", e.localizedDescription)
                    }
                }
            }
          )
    }
    
    func fetchHomeList() {
        
        let homeManager = ThingSmartHomeManager()
        
        homeManager.getHomeList { homeList in
            
            if let homes = homeList as? [ThingSmartHomeModel], homes.count > 0 {
                
                print("🏠 Total Homes:", homes.count)
                
                let home = homes.first
                self.tuyaHomeId = home?.homeId
                
                print("✅ Tuya Home ID:", self.tuyaHomeId ?? -1)
                
               
                if let tuyaId = self.tuyaHomeId {
                    
                    let tuyaIdString = "\(tuyaId)"
                    let serverHomeId = self.selectedHomeId ?? ""
                    
                    self.updateTuyaHomeIdToServer(
                        tuyaHomeId: tuyaIdString,
                        serverHomeId: serverHomeId
                    )
                }
                
            } else {
                // No home → create
                self.createHome()
            }
            
        } failure: { error in
            print("⚠️ Failed to refresh home list:", error?.localizedDescription ?? "")
        }
    }
    
    func createHome() {
        
        let homeManager = ThingSmartHomeManager()
        let geoName = "Mumbai"
        let rooms = ["Nursery"]
        let latitude = 19.0760
        let longitude = 72.8777
        homeManager.addHome(
            withName: "My Home",
            geoName: geoName,
            rooms: rooms,
            latitude: latitude,
            longitude: longitude,
            success: { homeId in
                
                print("🏠 Home created with ID:", homeId)
                self.tuyaHomeId = homeId
                let tuyaIdString = "\(homeId)"
                           
                          
                           let serverHomeId = self.selectedHomeId ?? ""
                           
                         
                           self.updateTuyaHomeIdToServer(
                               tuyaHomeId: tuyaIdString,
                               serverHomeId: serverHomeId
                           )
                
            },
            failure: { error in
                print("⚠️ Failed to refresh home list: \(error?.localizedDescription ?? "unknown")")
            }
        )
    }
    
    
    
    func updateTuyaHomeIdToServer(tuyaHomeId: String, serverHomeId: String) {
      let  baseUrl = "https://skroman.in/"
        let url = baseUrl + "skroman/homeapi/v2/homeupdate"

        let parameters: [String: Any] = [
            "tuyaHomeId": tuyaHomeId,
            "homeId": serverHomeId
        ]

        print("📤 Updating TuyaHomeId to server:", parameters)

        AF.request(
            url,
            method: .put,
            parameters: parameters,
            encoding: JSONEncoding.default
        )
        .validate()
        .responseJSON { response in
            switch response.result {

            case .success(let value):
                print("✅ TuyaHomeId updated successfully:", value)

                
                self.handleRoomCreationAfterHome()

            case .failure(let error):
                print("❌ Failed to update TuyaHomeId:", error.localizedDescription)

                if let data = response.data,
                   let raw = String(data: data, encoding: .utf8) {
                    print("🔍 Server response:", raw)
                }
            }
        }
    }

    
    
    func handleRoomCreationAfterHome() {

        guard let roomserverId = selectedRoomId else {
            print("❌ Missing selectedRoomId")
            return
        }

        SkromanIsraDatabaseHelper.shared.fetchRoomByRoomId(roomId: roomserverId) { room in

            guard let room = room else {
                print("❌ Room not found")
                return
            }

            let roomName = room.roomName
            let serverRoomId = room.roomId

            print("📦 DB TuyaRoomId:", room.tuyaRoomId ?? -1)

           
            if let existingTuyaRoomId = room.tuyaRoomId {

                print("✅ TuyaRoom already exists → skip creation")

                
                self.tuyaRoomId = existingTuyaRoomId
                self.updateWifiUIVisibility()

                return
            }

            print("👉 No TuyaRoomId → creating room")

            
            if let tuyaHomeId = self.tuyaHomeId {
                self.createTuyaRoom(
                    tuyaHomeId: tuyaHomeId,
                    roomName: roomName,
                    serverRoomId: serverRoomId
                )
            }
        }
    }
    
    func createTuyaRoom(tuyaHomeId: Int64, roomName: String, serverRoomId: String) {

        guard let home = ThingSmartHome(homeId: tuyaHomeId) else {
            print("❌ Invalid Tuya Home")
            return
        }

         
        let existingRoomIds = Set((home.roomList as? [ThingSmartRoomModel])?.map { $0.roomId } ?? [])

        home.addRoom(
            withName: roomName,
            success: {

                print("✅ Tuya Room created:", roomName)

              
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {

                    guard let refreshedHome = ThingSmartHome(homeId: tuyaHomeId),
                          let rooms = refreshedHome.roomList as? [ThingSmartRoomModel] else {
                        print("❌ Failed to refresh home or rooms")
                        return
                    }

                  
                    if let newRoom = rooms.first(where: { !existingRoomIds.contains($0.roomId) }) {

                        let tuyaRoomId = newRoom.roomId
                        self.updateWifiUIVisibility()
                        print("📌 TuyaRoomId:", tuyaRoomId)

                        self.updateTuyaRoomIdToServer(
                            serverRoomId: serverRoomId,
                            tuyaRoomId: "\(tuyaRoomId)"
                        )
                    } else {
                        print("⚠️ Could not detect new room")
                    }
                }

            },
            failure: { error in
                print("❌ Room creation failed:", error?.localizedDescription ?? "")
            }
        )
    }
    
    
    func fetchTuyaRooms(homeId: Int64) {

        guard let home = ThingSmartHome(homeId: homeId) else {
            print("❌ Invalid Tuya Home")
            return
        }

        home.getDetailWithSuccess(
            { _ in
                guard let rooms = home.roomList else { return }

                for room in rooms {
                    print("Room name:", room.name, "roomId:", room.roomId)
                }

                
                if let createdRoom = rooms.first(where: { $0.name == self.roomName }) {

                    let tuyaRoomIdStr = "\(createdRoom.roomId)"

                    if let tuyaRoomIdInt = Int64(tuyaRoomIdStr) {
                        self.tuyaRoomId = tuyaRoomIdInt
                        self.updateWifiUIVisibility()
                    }

                    print("✅ Tuya Room ID:", tuyaRoomIdStr)

                  

                    
//                    if let serverRoomId = self.strRoomId {
//                        self.updateTuyaRoomIdToServer(
//                            serverRoomId: serverRoomId,
//                            tuyaRoomId: tuyaRoomIdStr
//                        )
//                    }
                }
            },
            failure: { error in
                print("❌ Fetch home detail failed:", error?.localizedDescription ?? "")
            }
        )
    }
   
    func updateTuyaRoomIdToServer(serverRoomId: String, tuyaRoomId: String) {

        let baseUrl = "https://skroman.in/"
        let url = baseUrl + "skroman/roomapi/v2/roomupdate"

        let parameters: [String: Any] = [
            "roomId": serverRoomId,
            "tuyaRoomId": tuyaRoomId
        ]

        print("📤 Updating TuyaRoomId to server:", parameters)

        AF.request(
            url,
            method: .put,
            parameters: parameters,
            encoding: JSONEncoding.default   // ✅ same as home
        )
        .validate()
        .responseJSON { response in

            switch response.result {
            case .success(let value):
                print("✅ TuyaRoomId updated successfully:", value)

            case .failure(let error):
                print("❌ Failed to update TuyaRoomId:", error.localizedDescription)

                if let data = response.data,
                   let raw = String(data: data, encoding: .utf8) {
                    print("🔍 Server response:", raw)
                }
            }
        }
    }
    func  showAlert(_ title: String, _ message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        })
        self.present(alert, animated: true, completion: nil)
    }
    
    
    @IBAction func submitWifiBtn(_ sender: Any) {

        guard let ssid = wifiName.text, !ssid.isEmpty,
              let password = wifipassword.text, !password.isEmpty else {
            showAlert("Error", "Enter WiFi details")
            return
        }

        print("📶 WiFi SSID:", ssid)
        print("🔐 Password:", password)

        let  vc =   storyboard?.instantiateViewController(identifier: "LockWifiViewController") as!
        LockWifiViewController
        

//        vc.ssid = ssid
//        vc.password = password
//        vc.tuyaHomeId = tuyaHomeId
//        vc.tuyaRoomId = tuyaRoomId
//        vc.roomName =  roomName

        self.navigationController?.pushViewController(vc, animated: true)
    }
    
   
}


    
   
extension AddCameraViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

