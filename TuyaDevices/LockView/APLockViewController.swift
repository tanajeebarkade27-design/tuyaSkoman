//
//  EazyLockViewController.swift
//  SkromanIsra
//
//  Created by Admin on 07/04/26.
//

import UIKit
import ThingSmartHomeKit
import ThingSmartActivatorKit
import SystemConfiguration.CaptiveNetwork
import CoreLocation
import NetworkExtension
 
class APLockViewController: UIViewController, ThingSmartActivatorDelegate {
    var roomId: String?
    var addedDeviceId: String?
    var ssid: String?
    var password: String?
    var tuyaHomeId: Int64?
    var tuyaRoomId: Int64?
    var isConfirmed = false
    lazy var ezActivator: ThingSmartActivator = {
        let activator = ThingSmartActivator()
        activator.delegate = self
        return activator
    }()
    
    var activator: ThingSmartActivator?
    var hasStartedPairing = false
    let locationManager = CLLocationManager()
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        let backgroundImage = UIImageView(image: UIImage(named: "Screen Background"))
               backgroundImage.contentMode = .scaleAspectFill
                view.insertSubview(backgroundImage, at: 0)
               backgroundImage.translatesAutoresizingMaskIntoConstraints = false
               backgroundImage.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
               backgroundImage.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
               backgroundImage.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
               backgroundImage.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        NotificationCenter.default.addObserver(
               self,
               selector: #selector(handleDeviceAssigned),
               name: NSNotification.Name("DeviceAssigned"),
               object: nil
           )

    }
    @objc func handleDeviceAssigned() {
        print("📲 Device assigned notification received")
        showSuccessPopup()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
//        if !isConfirmed {
//            checkPermissionAndStart()
//        } else {
//            print("🔁 Returned from WiFi settings — DO NOTHING")
//        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
        checkAndStartAPFlow()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    func checkPermissionAndStart() {
        
        let status = CLLocationManager.authorizationStatus()
        
        print("📍 Location status:", status.rawValue)
        
        switch status {
            
        case .notDetermined:
            print("⏳ Asking permission...")
            locationManager.requestWhenInUseAuthorization()
            
        case .authorizedWhenInUse, .authorizedAlways:
            print("✅ Permission granted")
            startAPModePairing()
            
        case .denied, .restricted:
            print("❌ Permission denied")
            showPermissionAlert()
            
        default:
            break
        }
    }
    
    @IBAction func backBtn(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    
    func showPermissionAlert() {
        
        let alert = UIAlertController(
            title: "Permission Required",
            message: "Please enable Location access to connect your device.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        self.present(alert, animated: true)
    }
    
    func checkAndStartAPFlow() {

        guard !hasStartedPairing else { return }

        isConnectedToDeviceAP { [weak self] isConnected in
            
            guard let self = self else { return }

            if !isConnected {
                print("❌ Not connected to device AP")
                return
            }

            print("✅ Connected to device AP")

            self.hasStartedPairing = true
            self.checkPermissionAndStart()
        }
    }
    
    
    func startAPModePairing() {
        
        guard let password = self.password, !password.isEmpty else {
            print("❌ Password missing")
            return
        }

        guard let homeId = self.tuyaHomeId else {
            print("❌ HomeId missing")
            return
        }

        print("🚀 AP Mode Pairing Started")

       
        ezActivator.getTokenWithHomeId(homeId, success: { [weak self] token in
            
            guard let self = self,
                  let token = token,
                  !token.isEmpty else {
                print("❌ Token error")
                return
            }
            
            print("✅ Token:", token)

            // 2️⃣ Get SSID
            self.getSSIDNew { fetchedSSID in
                
                let finalSSID = fetchedSSID ?? self.ssid
                
                guard let ssidToUse = finalSSID, !ssidToUse.isEmpty else {
                    print("❌ SSID missing")
                    self.showWiFiPermissionAlert()
                    return
                }

                print("📡 Router SSID:", ssidToUse)

                // 3️⃣ Ask user to connect to DEVICE WiFi
                DispatchQueue.main.async {
                    
                    let alert = UIAlertController(
                        title: "Connect Device WiFi",
                        message: "Go to WiFi settings and connect to your lock hotspot (SmartLife-XXXX). Then come back and tap 'Connected'.",
                        preferredStyle: .alert
                    )
                    
                  
                    alert.addAction(UIAlertAction(title: "Open WiFi", style: .default, handler: { _ in
                        if let url = URL(string: "App-Prefs:root=WIFI") {
                            UIApplication.shared.open(url)
                        }
                    }))
                    
                   
                    alert.addAction(UIAlertAction(title: "Connected", style: .default, handler: { _ in
                        
                        print("📲 User connected to device AP")
                        self.isConfirmed = true
                        // 4️⃣ Start AP Config
                        self.ezActivator.delegate = self
                        
                        self.ezActivator.startConfigWiFi(
                            .AP,
                            ssid: ssidToUse,
                            password: password,
                            token: token,
                            timeout: 120
                        )
                        self.startFallbackCheck()
                        print("🚀 AP Config Started")
                    }))
                    
                    self.present(alert, animated: true)
                }
            }

        }, failure: { error in
            print("❌ Token failed:", error?.localizedDescription ?? "Unknown")
        })
    }
    func openWiFiSettings() {
        if let url = URL(string: "App-Prefs:root=WIFI") {
            UIApplication.shared.open(url)
        }
    }
    func showWiFiPermissionAlert() {
        
        let alert = UIAlertController(
            title: "WiFi Permission Required",
            message: "Please enable Location & Local Network access to continue",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }

   
    func isConnectedToDeviceAP(completion: @escaping (Bool) -> Void) {
        
        getSSIDNew { ssid in
            
            guard let ssid = ssid, !ssid.isEmpty else {
                print("❌ SSID NIL")
                completion(false)
                return
            }

            print("📡 Current SSID:", ssid)

            let isConnected =
                ssid.contains("SmartLife") ||
                ssid.contains("Tuya") ||
                ssid.contains("Skroman")

            completion(isConnected)
        }
    }
    
    
    func startConfigWiFi(ssid: String, password: String, token: String) {
        
        ezActivator.delegate = self

       
        
    }

    func startFallbackCheck() {

        print("⏳ Waiting for device response...")

        DispatchQueue.main.asyncAfter(deadline: .now() + 40) { [weak self] in

            guard let self = self else { return }

            if self.addedDeviceId != nil {

                print("✅ Device already added")
                return
            }

            print("❌ Pairing timeout")

            // IMPORTANT
            // STOP AP CONFIG
            self.ezActivator.stopConfigWiFi()

            DispatchQueue.main.async {

                guard self.presentedViewController == nil else {
                    return
                }

                let alert = UIAlertController(
                    title: "Failed",
                    message: "Device not responding. Please retry.",
                    preferredStyle: .alert
                )

                alert.addAction(
                    UIAlertAction(
                        title: "Retry",
                        style: .default,
                        handler: { _ in

                            self.hasStartedPairing = false
                            self.startAPModePairing()
                        }
                    )
                )

                alert.addAction(
                    UIAlertAction(
                        title: "Cancel",
                        style: .cancel
                    )
                )

                self.present(alert, animated: true)
            }
        }
    }
  
    func retryAPConfig() {

        guard let password = self.password,
              let homeId = self.tuyaHomeId,
              let ssid = self.ssid else {
            return
        }

        ezActivator.getTokenWithHomeId(homeId, success: { [weak self] token in
            
            guard let self = self,
                  let token = token else { return }

            print("🔁 Retrying AP config...")

            self.ezActivator.startConfigWiFi(
                .AP,
                ssid: ssid,
                password: password,
                token: token,
                timeout: 120
            )

        }, failure: { error in
            print("❌ Retry token failed")
        })
    }
    func activator(_ activator: ThingSmartActivator,
                   didReceiveDevice deviceModel: ThingSmartDeviceModel?,
                   error: Error?) {
        
        if let device = deviceModel {

            print("🎉 Device Added:", device.name ?? "", device.devId ?? "")

            ezActivator.stopConfigWiFi()

            DevicePairingManager.shared.pendingDeviceId = device.devId
            DevicePairingManager.shared.tuyaHomeId = self.tuyaHomeId
          

            DevicePairingManager.shared.startMonitoringAndAssign()

           

            

        } else if let error = error   {
            
            print("❌ Failed:", error.localizedDescription)

            DispatchQueue.main.async {
                let alert = UIAlertController(
                    title: "Failed",
                    message: error.localizedDescription,
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "Retry", style: .default))
                self.present(alert, animated: true)
            }
        }
    }
    
     
    
    
    
    func assignDevice(deviceId: String) {

        guard let homeId = tuyaHomeId else {
            print("❌ Missing HomeId")
            return
        }

        // ✅ GET CORRECT ROOM ID FROM DB
        guard let roomIdStr = UserDefaults.standard.string(forKey: "selectedRoomId"),
              let validRoomId = SkromanIsraDatabaseHelper.shared
                    .getTuyaRoomIdFromDB(roomId: roomIdStr) else {
            print("❌ No valid TuyaRoomId from DB")
            return
        }

        let room = ThingSmartRoom(roomId: validRoomId, homeId: homeId)

        room?.addDevice(withDeviceId: deviceId, success: {

            print("✅ Device added to room SUCCESS")

            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name("DeviceAssigned"), object: nil)
            }

        }, failure: { error in
            print("❌ Failed:", error?.localizedDescription ?? "")
        })
    }
    func assignDeviceToRoom(deviceId: String) {

        guard let homeId = tuyaHomeId,
              let roomId = tuyaRoomId else {
            print("❌ Missing IDs")
            return
        }

        let room = ThingSmartRoom(roomId: roomId, homeId: homeId)

        room?.addDevice(withDeviceId: deviceId, success: {
            
            print("✅ Device added to room SUCCESS")

            self.showSuccessPopup()

        }, failure: { error in
            
            print("❌ Failed:", error?.localizedDescription ?? "")
        })
    }
    func showSuccessPopup() {
        let alert = UIAlertController(
            title: "Success",
            message: "Device added successfully 🎉",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true)
    }
    
    func addDeviceToRoom(device: ThingSmartDeviceModel) {

        guard let homeId = tuyaHomeId else {
            print("❌ HomeId missing")
            return
        }

        guard let roomIdStr = roomId else {
            print("❌ roomId missing")
            return
        }

        // 🔥 THIS IS THE CORRECT FUNCTION
        guard let validRoomId = SkromanIsraDatabaseHelper.shared
                .getTuyaRoomIdFromDB(roomId: roomIdStr) else {
            print("❌ No valid TuyaRoomId")
            return
        }

        guard let deviceId = device.devId else {
            print("❌ DeviceId missing")
            return
        }

        print("📦 Assigning device to room...")
        print("DeviceId:", deviceId)
        print("HomeId:", homeId)
        print("RoomId (DB):", validRoomId)

        let room = ThingSmartRoom(roomId: validRoomId, homeId: homeId)

        room?.addDevice(withDeviceId: deviceId, success: {
            print("✅ Device added to room SUCCESS")
        }, failure: { error in
            print("❌ Failed:", error?.localizedDescription ?? "")
        })
    }
    
    
    func getSSIDNew(completion: @escaping (String?) -> Void) {
        NEHotspotNetwork.fetchCurrent { network in
            if let ssid = network?.ssid {
                print("📡 SSID (NEW):", ssid)
                completion(ssid)
            } else {
                print("❌ SSID still nil")
                completion(nil)
            }
        }
    }

}
 
 
extension APLockViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager,
                         didChangeAuthorization status: CLAuthorizationStatus) {
        
        print("📍 Permission changed:", status.rawValue)
        
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.startUpdatingLocation()
            startAPModePairing()
        }
    }
}
