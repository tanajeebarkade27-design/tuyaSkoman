import UIKit
import Alamofire
import SwiftKeychainWrapper
import ThingSmartHomeKit

class OTPVerificationViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var firstDigitTextField: UITextField!
    @IBOutlet weak var secndDigitTextField: UITextField!
    @IBOutlet weak var thirddigitTextField: UITextField!
    @IBOutlet weak var fourthDgitTextField: UITextField!
    
    @IBOutlet weak var verifyButton: UIButton!
    @IBOutlet weak var resendOTPButton: UIButton!
    
    @IBOutlet weak var backgroundimage: UIImageView!
    
    @IBOutlet weak var oTPView: UIView!
    
    @IBOutlet weak var appimageBackgroundView: UIView!
    var fcmToken: String?

    var emailId : String?
    var password:String?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        print("emailId \(emailId) password \(password)")
        if let token = FCMTokenManager.shared.token {
                self.fcmToken = token
                print("✅FCM Token (from manager):", token)
            }

            // 2️⃣ Listen for token if it arrives later
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleFCMToken),
                name: Notification.Name("FCMTokenReceived"),
                object: nil
            )
        
        backgroundimage.contentMode = .scaleAspectFill
        backgroundimage.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            backgroundimage.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundimage.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundimage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundimage.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        verifyButton.backgroundColor = .white
        verifyButton.setTitleColor(.black, for: .normal) // text color
        verifyButton.layer.cornerRadius = 10
        verifyButton.layer.masksToBounds = true
        setupTextFields()
        
      
        firstDigitTextField.isUserInteractionEnabled = true
        secndDigitTextField.isUserInteractionEnabled = true
        thirddigitTextField.isUserInteractionEnabled = true
        fourthDgitTextField.isUserInteractionEnabled = true
        
        appimageBackgroundView.borderWidth =  0.5
        appimageBackgroundView.borderColor =  .green
        appimageBackgroundView.cornerRadius =  15
        appimageBackgroundView.clipsToBounds =  true
        oTPView.borderWidth =  0.5
        oTPView.borderColor =  .green
        oTPView.cornerRadius =  15
        oTPView.clipsToBounds =  true
    }
    


    @objc func handleFCMToken(_ notification: Notification) {
        let token = notification.userInfo?["token"] as? String
        self.fcmToken = token
        print("FCM Token (from notification):", token ?? "nil")
    }

  
    // MARK: - Setup OTP Fields
    func setupTextFields() {
        let textFields = [
            firstDigitTextField,
            secndDigitTextField,
            thirddigitTextField,
            fourthDgitTextField
        ]

        for textField in textFields {
            guard let tf = textField else { continue }

            tf.delegate = self
            tf.keyboardType = .numberPad
            tf.textContentType = .oneTimeCode

            tf.textAlignment = .center
            tf.contentVerticalAlignment = .center

            tf.backgroundColor = .clear
            tf.layer.borderWidth = 0.5
            tf.layer.borderColor = UIColor.green.cgColor
            tf.layer.cornerRadius = 10
            tf.clipsToBounds = true
            tf.tintColor = .green   // cursor color
            tf.clearButtonMode = .never
            tf.translatesAutoresizingMaskIntoConstraints = false
            tf.widthAnchor.constraint(equalToConstant: 45).isActive = true
            tf.heightAnchor.constraint(equalToConstant: 45).isActive = true
            tf.autocorrectionType = .no
            tf.spellCheckingType = .no
            tf.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        }
    }

    
    
    @IBAction func backButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
   
   
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.firstDigitTextField.becomeFirstResponder()
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(false)
        firstDigitTextField.becomeFirstResponder()
    }
    // MARK: - Handle Backspace for OTP Fields
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {

        // Allow only numbers
        let characterSet = CharacterSet(charactersIn: "0123456789")
        let typedCharacterSet = CharacterSet(charactersIn: string)
        if !characterSet.isSuperset(of: typedCharacterSet) && !string.isEmpty {
            return false
        }

        // BACKSPACE
        // Enter digit
        if string.count > 0 {
            
            textField.text = string
            
            if textField == firstDigitTextField {
                secndDigitTextField.becomeFirstResponder()
            }
            else if textField == secndDigitTextField {
                thirddigitTextField.becomeFirstResponder()
            }
            else if textField == thirddigitTextField {
                fourthDgitTextField.becomeFirstResponder()
            }
            else if textField == fourthDgitTextField {
                textField.resignFirstResponder()    
            }

            if areAllOTPFieldsFilled() {
                VerificationOTP()
            }

            return false
        }
        // Enter digit
        textField.text = string
        moveToNextTextField(after: textField)

        if areAllOTPFieldsFilled() {
            VerificationOTP()
        }
        return false
    }
    
    
    func moveToNextTextField(after textField: UITextField) {
        let textFields = [firstDigitTextField, secndDigitTextField, thirddigitTextField, fourthDgitTextField]
        if let currentIndex = textFields.firstIndex(of: textField), currentIndex < textFields.count - 1 {
            textFields[currentIndex + 1]?.becomeFirstResponder()
        }
    }
    
    func moveToPreviousTextField(before textField: UITextField) {
        let textFields = [firstDigitTextField, secndDigitTextField, thirddigitTextField, fourthDgitTextField]
        if let currentIndex = textFields.firstIndex(of: textField), currentIndex > 0 {
            textFields[currentIndex - 1]?.becomeFirstResponder()
        }
    }
    
    func areAllOTPFieldsFilled() -> Bool {
        return !(firstDigitTextField.text?.isEmpty ?? true) &&
               !(secndDigitTextField.text?.isEmpty ?? true) &&
               !(thirddigitTextField.text?.isEmpty ?? true) &&
               !(fourthDgitTextField.text?.isEmpty ?? true)
    }
    
    // MARK: - Combine OTP Digits & Call API
    func getOTPString() -> String {
        return (firstDigitTextField.text ?? "") +
               (secndDigitTextField.text ?? "") +
               (thirddigitTextField.text ?? "") +
               (fourthDgitTextField.text ?? "")
    }

    func VerificationOTP() {

        guard let email = emailId, !email.isEmpty else {
            showAlert(title: "Error", message: "Email not found. Please login again.")
            return
        }

        guard let password = password, !password.isEmpty else {
            showAlert(title: "Error", message: "Password not found. Please login again.")
            return
        }

        let otpText = getOTPString()
        if otpText.count < 4 {
            showAlert(title: "Invalid OTP", message: "Please enter a valid 4-digit OTP.")
            return
        }
        guard let deviceToken = fcmToken, !deviceToken.isEmpty else {
            print("❌ FCM Token missing")
            return
        }
        let params: [String: Any] = [
            "emailId": email,
            "otp": otpText,
           "deviceToken": deviceToken
        ]

        print("📌 OTP API Params → \(params)")

        AF.request(MainApi.verifyOtp,
                   method: .post,
                   parameters: params,
                   encoding: JSONEncoding.default)
            .responseData { response in

                DispatchQueue.main.async {

                    switch response.result {

                    case .success(let data):
                        do {
                            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                                self.showAlert(title: "Error", message: "Invalid server response.")
                                return
                            }

                            print("📌 Parsed JSON → \(json)")

                            let msg = json["msg"] as? String ?? ""

                            switch msg {

                            case "Match OTP":
                                guard let result = json["result"] as? [String: Any] else {
                                    self.showAlert(title: "Error", message: "User data missing.")
                                    return
                                }

                                // Save user data
                                KeychainWrapper.standard.set(password, forKey: "login_password")
                                KeychainWrapper.standard.set(result["_id"] as? String ?? "", forKey: "_id")
                                KeychainWrapper.standard.set(result["userId"] as? String ?? "", forKey: "userId")
                                KeychainWrapper.standard.set(result["emailId"] as? String ?? "", forKey: "emailId")
                                KeychainWrapper.standard.set(result["verifyAlexa"] as? String ?? "", forKey: "verifyAlexa")
                                KeychainWrapper.standard.set(result["verifyGoogle"] as? String ?? "", forKey: "verifyGoogle")

                                
                                DispatchQueue.main.async {
                                    self.showAlertSuccess(title: "Success", message: "Login Successfully")
                                    SkromanIsraDatabaseHelper.shared.openDatabase()
                                    SkromanIsraDatabaseHelper.shared.createTables()

                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        self.SyncPostData()
                                    }
                                }


                            case "Not Match OTP":
                                self.showAlert(title: "Incorrect OTP", message: "The OTP you entered is incorrect.")

                            default:
                                self.showAlert(title: "Error", message: msg.isEmpty ? "Unknown server response." : msg)
                            }

                        } catch {
                            self.showAlert(title: "Error", message: "Failed to read server response.")
                        }

                    case .failure:
                        self.showAlert(title: "Network Error", message: "Please check your internet connection and try again.")
                    }
                }
            }
    }

    


    @IBAction func verifyButtonTapped(_ sender: UIButton) {
        VerificationOTP()
    }
    
    
    
    @IBAction func resendOTPButton(_ sender: Any) {
        guard let email = emailId, let password = password else {
            showAlert(title: "Error", message: "Missing email or password.")
            return
        }

        let params: [String: Any] = [
            "emailId": email,
            "password": password
        ]

        // Optional: show loader
        print("🔁 Resending OTP for: \(email)")

        AF.request(MainApi.loginUrl, method: .post, parameters: params, encoding: JSONEncoding.default).response { response in
            debugPrint(response)

            switch response.result {
            case .success(let data):
                do {
                    guard let data = data else {
                        self.showAlert(title: "Error", message: "No response from server")
                        return
                    }

                    if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any],
                       let msg = json["msg"] as? String {

                        DispatchQueue.main.async {
                            if msg == "success match password" {
                                self.showAlertSuccessresend(title: "OTP Sent", message: "A new OTP has been sent to your email.")
                                print("✅ OTP re-sent successfully to: \(email)")
                            } else {
                                self.showAlert(title: "Error", message: msg)
                            }
                        }
                    } else {
                        self.showAlert(title: "Error", message: "Invalid response from server")
                    }
                } catch {
                    self.showAlert(title: "Error", message: "Failed to parse response")
                }

            case .failure(let err):
                print("❌ Failed to resend OTP: \(err.localizedDescription)")
                self.showAlert(title: "Error", message: "Network error. Please try again.")
            }
        }.resume()
    }

    
    func showAlertSuccessresend(title: String, message: String) {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default) { _ in
                 
            }
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    
}

struct VerificationModel: Encodable {
    let emailId: String
    let otp: String
}
extension OTPVerificationViewController {
    func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }

    func showAlertSuccess(title: String, message: String) {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default) { _ in
                self.navigateToHome()
            }
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    
    private func navigateToHome(){
          let homeVc =  storyboard?.instantiateViewController(withIdentifier: "MainHomeViewController")as! MainHomeViewController
          navigationController?.pushViewController(homeVc, animated: true)
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
    
//    KeychainWrapper.standard.set(userEmail, forKey: "emailId")
//    KeychainWrapper.standard.set(userPassword, forKey: "login_password")


    func SyncPostData() {
        print("✅ SyncPostData() called")
//                SkromanIsraDatabaseHelper.shared.openDatabase()
//                SkromanIsraDatabaseHelper.shared.createTables()
        checkTuyaLoginStatus()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            SkromanIsraDatabaseHelper.shared.deleteAllTablesData { success in
                if success {
                    print("✅ All data was deleted successfully.")
                    self.syncServer()
                } else {
                    print("❌ Failed to delete data from one or more tables.")
                }
                
                
                
            }
        }
    }
    
    
    func syncServer() {
        let userId = KeychainWrapper.standard.string(forKey: "userId") ?? "Nothing"
        
        let syncDataParameters: [String: Any] = [
            "userId": userId
        ]
        
        print("call api")
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
                                
                                
                               
                                if let syncData = json["syncData"] as? [[String: Any]] {
                                    let hasTuyaHome = syncData.contains { home in
                                        
                                        if let id = home["tuyaHomeId"] as? Int64 {
                                            return id > 0
                                        }
                                        
                                        if let id = home["tuyaHomeId"] as? Int {
                                            return id > 0
                                        }
                                        
                                        if let idStr = home["tuyaHomeId"] as? String,
                                           let id = Int64(idStr) {
                                            return id > 0
                                        }
                                        
                                        return false
                                    }
                                    
                                    print("🔍 Tuya Home Available in Sync: \(hasTuyaHome)")
                                    
                                    
                                    if hasTuyaHome {
                                        let email = KeychainWrapper.standard.string(forKey: "emailId") ?? ""
                                        
                                        print("🚀 Calling Tuya Login (from sync response)")
                                        self.loginUser(email: email)
                                    } else {
                                        print("⚠️ No Tuya Home → skipping login")
                                    }
                                    
                                    self.insertHomeAndRoomsIntoDB(syncData: syncData) {
                                       print(" All sync data inserted successfully!")

                                       
                                       
                                            
                                            if self.isUserValid() {
                                                print("✅ Valid user → Home")
                                                self.navigateToHomeScreen()
                                            } else {
                                                print("❌ Invalid user → Edit Profile")
                                                self.navigateToEditProfileScreen()
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
                        if let id = home["tuyaHomeId"] as? Int64 {
                            return id
                        } else if let id = home["tuyaHomeId"] as? Int {
                            return Int64(id)
                        }
                        return nil
                    }()
                    
                    database.insertHome(homeServerId: homeId, homeName: homeName, homeUrl: homeImage, tuyaHomeId: tuyaHomeId, isFamilyHome: 0)
                    
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

    
    @objc func showPopupSync() {
        
        showPopupPresenter.showPopup1(on: self.view,
                                      animationName: "success",
                                      title: "Success!",
                                      subtitle: "Sync data successfully")
        
        
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
    
    func loginUser(email: String) {
        ThingSmartUser.sharedInstance().login(
            byEmail: "91",
            email: email,
            password: "Skroman@12",
            success: {
                
                print("✅ Login successful")
                
                
            },
            failure: { error in
                if let e = error {
                    print("❌ Login failed: \(e.localizedDescription)")
                   
                }
            }
          )
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
