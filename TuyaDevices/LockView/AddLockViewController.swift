//
//  AddLockViewController.swift
//  SkromanIsra
//

import UIKit
import ThingSmartHomeKit
import SwiftKeychainWrapper
import Alamofire

class AddLockViewController: UIViewController {

    // MARK: - VARIABLES

    var selectedRoomId: String?
    var selectedHomeId: String?

    var tuyaHomeId: Int64?
    var tuyaRoomId: Int64?

    var roomName: String?

    // MARK: - OUTLETS

    @IBOutlet weak var otpCode: UITextField!
    @IBOutlet weak var verify: UIButton!
    @IBOutlet weak var verfiyOtpBtn: UIButton!

    @IBOutlet weak var wifiName: UITextField!
    @IBOutlet weak var wifipassword: UITextField!
    @IBOutlet weak var submitWifiDetail: UIButton!

    // MARK: - LIFE CYCLE

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupBackground()

        wifiName.delegate = self
        wifipassword.delegate = self
        otpCode.delegate = self

        fetchLocalTuyaIds()

        let tap = UITapGestureRecognizer(
            target: self,
            action: #selector(dismissKeyboard)
        )

        view.addGestureRecognizer(tap)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }

    // MARK: - SETUP

    func setupUI() {

        wifiName.isHidden = true
        wifipassword.isHidden = true
        submitWifiDetail.isHidden = true

        otpCode.isHidden = true
        verfiyOtpBtn.isHidden = true
    }

    func setupBackground() {

        let backgroundImage = UIImageView(
            image: UIImage(named: "Screen Background")
        )

        backgroundImage.contentMode = .scaleAspectFill

        view.insertSubview(backgroundImage, at: 0)

        backgroundImage.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            backgroundImage.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImage.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundImage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImage.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    // MARK: - FETCH LOCAL IDS

    func fetchLocalTuyaIds() {

        // FETCH HOME ID
        if let serverHomeId = selectedHomeId,
           let home = SkromanIsraDatabaseHelper.shared.fetchHomeById(
                homeServerId: serverHomeId
           ) {

            self.tuyaHomeId = home.tuyaHomeId

            print("🏠 Local TuyaHomeId:", self.tuyaHomeId ?? -1)
        }

        // FETCH ROOM ID
        guard let roomServerId = selectedRoomId else {
            checkInitialFlow()
            return
        }

        SkromanIsraDatabaseHelper.shared.fetchRoomByRoomId(
            roomId: roomServerId
        ) { room in

            guard let room = room else {

                print("❌ Room not found")
                self.checkInitialFlow()
                return
            }

            self.roomName = room.roomName
            self.tuyaRoomId = room.tuyaRoomId

            print("🚪 Local TuyaRoomId:", self.tuyaRoomId ?? -1)

            DispatchQueue.main.async {

                self.checkInitialFlow()
            }
        }
    }

    // MARK: - MAIN FLOW

    func checkInitialFlow() {

        print("======== INITIAL FLOW ========")

        // HOME + ROOM ALREADY EXISTS
        if let homeId = tuyaHomeId,
           homeId > 0,
           let roomId = tuyaRoomId,
           roomId > 0 {

            print("✅ Tuya Home + Room already exists")

            showWifiUI()

            return
        }

        // HIDE WIFI UI
        hideWifiUI()

        // CHECK LOGIN / REGISTER FLOW
        checkTuyaLoginFlow()
    }

    // MARK: - LOGIN FLOW

    func checkTuyaLoginFlow() {

        let email = KeychainWrapper.standard.string(
            forKey: "emailId"
        ) ?? ""

        let password = "Skroman@12"

        guard !email.isEmpty else {

            showAlert("Error", "Email not found")
            return
        }

        // ALREADY LOGIN
        if ThingSmartUser.sharedInstance().isLogin {

            print("✅ Tuya already login")

            createHomeAndRoomIfNeeded()

            return
        }

        // LOGIN
        loginUser(email: email, password: password)
    }

    // MARK: - LOGIN

    func loginUser(email: String, password: String) {

        ThingSmartUser.sharedInstance().login(
            byEmail: "91",
            email: email,
            password: password
        ) {

            print("✅ Login success")

            DispatchQueue.main.async {

                self.createHomeAndRoomIfNeeded()
            }

        } failure: { error in

            if let e = error {

                print("❌ Login failed:", e.localizedDescription)

                // USER NOT REGISTERED
                if e.localizedDescription.contains(
                    "Incorrect account or password"
                ) {

                    print("👉 User not registered")

                    self.sendVerificationCode(email: email)

                } else {

                    self.showAlert("Error", e.localizedDescription)
                }
            }
        }
    }

    // MARK: - SEND OTP

    func sendVerificationCode(email: String) {

        let password = "Skroman@12"

        ThingSmartUser.sharedInstance().sendVerifyCode(
            withUserName: email,
            region: "EU",
            countryCode: "91",
            type: 1
        ) {

            print("✅ OTP Sent")

            DispatchQueue.main.async {

                self.otpCode.isHidden = false
                self.verfiyOtpBtn.isHidden = false
            }

        } failure: { error in

            if let e = error {

                print("❌ OTP Failed:", e.localizedDescription)

                // USER ALREADY EXISTS
                if e.localizedDescription.contains("User already exists") {

                    self.loginUser(
                        email: email,
                        password: password
                    )

                } else {

                    self.showAlert("Error", e.localizedDescription)
                }
            }
        }
    }

    // MARK: - REGISTER

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

    // MARK: - CREATE HOME / ROOM

    func createHomeAndRoomIfNeeded() {

        // HOME NOT EXISTS
        if tuyaHomeId == nil || tuyaHomeId == 0 {

            print("👉 Creating Tuya Home")

            createHome()

        } else {

            print("✅ Tuya Home Exists")

            handleRoomCreationAfterHome()
        }
    }

    // MARK: - CREATE HOME

    func createHome() {

        let homeManager = ThingSmartHomeManager()

        homeManager.addHome(
            withName: "My Home",
            geoName: "Mumbai",
            rooms: ["Default"],
            latitude: 19.0760,
            longitude: 72.8777
        ) { homeId in

            print("✅ Home Created:", homeId)

            self.tuyaHomeId = homeId

            self.updateTuyaHomeIdToServer(
                tuyaHomeId: "\(homeId)",
                serverHomeId: self.selectedHomeId ?? ""
            )

        } failure: { error in

            print("❌ Home Creation Failed:",
                  error?.localizedDescription ?? "")
        }
    }

    // MARK: - CREATE ROOM

    func handleRoomCreationAfterHome() {

        guard let roomServerId = selectedRoomId else {
            return
        }

        SkromanIsraDatabaseHelper.shared.fetchRoomByRoomId(
            roomId: roomServerId
        ) { room in

            guard let room = room else {
                return
            }

            // ROOM ALREADY EXISTS
            if let roomId = room.tuyaRoomId,
               roomId > 0 {

                print("✅ Tuya Room Exists")

                self.tuyaRoomId = roomId

                self.showWifiUI()

                return
            }

            // CREATE ROOM
            guard let homeId = self.tuyaHomeId else {
                return
            }

            self.createTuyaRoom(
                tuyaHomeId: homeId,
                roomName: room.roomName,
                serverRoomId: room.roomId,
                homeId: room.homeId,
                roomIconId: room.roomIconId ?? "",
                roomIconType: room.roomIconType ?? ""
            )
        }
    }

    func createTuyaRoom(
        tuyaHomeId: Int64,
        roomName: String,
        serverRoomId: String,
        homeId: String?,
        roomIconId: String,
        roomIconType: String
    ) {

        guard let home = ThingSmartHome(homeId: tuyaHomeId) else {

            print("❌ Invalid Home")
            return
        }

        let existingRoomIds = Set(
            (home.roomList as? [ThingSmartRoomModel])?
                .map { $0.roomId } ?? []
        )

        home.addRoom(withName: roomName) {

            print("✅ Room Created")

            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {

                guard let refreshedHome = ThingSmartHome(
                    homeId: tuyaHomeId
                ),
                let rooms = refreshedHome.roomList
                    as? [ThingSmartRoomModel] else {

                    return
                }

                if let newRoom = rooms.first(
                    where: {
                        !existingRoomIds.contains($0.roomId)
                    }
                ) {

                    let newRoomId = newRoom.roomId

                    print("✅ New Room ID:", newRoomId)

                    self.tuyaRoomId = newRoomId

                    // UPDATE LOCAL DB
                    if let homeId = homeId {

                        SkromanIsraDatabaseHelper.shared.updateRoom(
                            roomId: serverRoomId,
                            newRoomName: roomName,
                            newRoomIconId: roomIconId,
                            newRoomIconType: roomIconType,
                            tuyaRoomId: newRoomId,
                            homeId: homeId
                        )
                    }

                    // UPDATE SERVER
                    self.updateTuyaRoomIdToServer(
                        serverRoomId: serverRoomId,
                        tuyaRoomId: "\(newRoomId)"
                    )

                    // SHOW WIFI UI
                    self.showWifiUI()
                }
            }

        } failure: { error in

            print("❌ Room Create Failed:",
                  error?.localizedDescription ?? "")
        }
    }

    // MARK: - UPDATE HOME ID

    func updateTuyaHomeIdToServer(
        tuyaHomeId: String,
        serverHomeId: String
    ) {

        let url =
        "https://skroman.in/skroman/homeapi/v2/homeupdate"

        let parameters: [String: Any] = [
            "tuyaHomeId": tuyaHomeId,
            "homeId": serverHomeId
        ]

        AF.request(
            url,
            method: .put,
            parameters: parameters,
            encoding: JSONEncoding.default
        )
        .validate()
        .responseJSON { response in

            switch response.result {

            case .success:

                print("✅ Home ID Updated")

                self.handleRoomCreationAfterHome()

            case .failure(let error):

                print("❌ Home Update Failed:",
                      error.localizedDescription)
            }
        }
    }

    // MARK: - UPDATE ROOM ID

    func updateTuyaRoomIdToServer(
        serverRoomId: String,
        tuyaRoomId: String
    ) {

        let url =
        "https://skroman.in/skroman/roomapi/v2/roomupdate"

        let parameters: [String: Any] = [
            "roomId": serverRoomId,
            "tuyaRoomId": tuyaRoomId
        ]

        AF.request(
            url,
            method: .put,
            parameters: parameters,
            encoding: JSONEncoding.default
        )
        .validate()
        .responseJSON { response in

            switch response.result {

            case .success:

                print("✅ Room ID Updated")

            case .failure(let error):

                print("❌ Room Update Failed:",
                      error.localizedDescription)
            }
        }
    }

    // MARK: - WIFI UI

    func showWifiUI() {

        DispatchQueue.main.async {

            self.wifiName.isHidden = false
            self.wifipassword.isHidden = false
            self.submitWifiDetail.isHidden = false
        }
    }

    func hideWifiUI() {

        DispatchQueue.main.async {

            self.wifiName.isHidden = true
            self.wifipassword.isHidden = true
            self.submitWifiDetail.isHidden = true
        }
    }

    // MARK: - ACTIONS

    @IBAction func verifyButton(_ sender: Any) {

        let email = KeychainWrapper.standard.string(
            forKey: "emailId"
        ) ?? ""

        registerUser(
            email: email,
            password: "Skroman@12"
        )
    }

    @IBAction func backBtn(_ sender: Any) {

        navigationController?.popViewController(animated: true)
    }

    @IBAction func submitWifiBtn(_ sender: Any) {

        guard let ssid = wifiName.text,
              !ssid.isEmpty,
              let password = wifipassword.text,
              !password.isEmpty else {

            showAlert("Error", "Enter WiFi details")
            return
        }

        let vc = storyboard?.instantiateViewController(
            identifier: "LockWifiViewController"
        ) as! LockWifiViewController

        vc.ssid = ssid
        vc.password = password
        vc.tuyaHomeId = tuyaHomeId
        vc.tuyaRoomId = tuyaRoomId
        vc.roomName = roomName

        navigationController?.pushViewController(
            vc,
            animated: true
        )
    }

    // MARK: - ALERT

    func showAlert(
        _ title: String,
        _ message: String
    ) {

        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )

        alert.addAction(
            UIAlertAction(
                title: "OK",
                style: .default
            )
        )

        present(alert, animated: true)
    }

    // MARK: - KEYBOARD

    @objc func dismissKeyboard() {

        view.endEditing(true)
    }
}

// MARK: - TEXTFIELD

extension AddLockViewController: UITextFieldDelegate {

    func textFieldShouldReturn(
        _ textField: UITextField
    ) -> Bool {

        textField.resignFirstResponder()

        return true
    }
}
