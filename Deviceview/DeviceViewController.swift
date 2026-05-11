//
//  DeviceViewController.swift
//  SkromanIsra
//
//  Created by Admin on 06/02/25.
//

import UIKit
import AWSCore
import AWSIoT
import Alamofire
import Lottie

class DeviceViewController: UIViewController {

    @IBOutlet var deviceBackGroundView: UIView!
   
    @IBOutlet weak var menuBarbackgroundView: UIView!
    @IBOutlet weak var scrollBackgroundView: UIView!
    @IBOutlet weak var mainBackgroundview: UIView!
    @IBOutlet weak var devicesCollectionView: UICollectionView!
    
    @IBOutlet weak var backbutton: UIButton!
    @IBOutlet weak var isOnlineButton: UIButton!
    @IBOutlet weak var settingButton: UIButton!
    @IBOutlet weak var sceneView: UIView!
    
    var connectIoTDataWebSocket: UIButton!
    var device_value_on_click : String!
    @IBOutlet weak var wifiImageContainer: UIView!
    
    @IBOutlet weak var wifiNetworkName: UILabel!
    
    var roomId: String?
    var homeId : String?
    var receivedDeviceStates: [DeviceStateArray] = []
    var deviceScene: [DeviceScene] = []
    var currentDeviceScene :DeviceScene?
    var buttonItems: [String] = []
    var PUB_TOPIC_: String?
    var SUB_TOPIC_ : String?
    var FETCH_ALL_RECV_FLAG = 0
    var connected = false
    var iotDataManager: AWSIoTDataManager!
    var iotManager: AWSIoTManager!
    var iot: AWSIoT!
    var logTextView: UITextView!
    var  SelectedDeviecUid : String?
    var connectButton: UIButton!
    var  deviceUniqueId: String?
    var currentDeviceState: DeviceStateArray?
    var previousDeviceUniqueId: String?
    var mappedValues: [[String: String]] = []
    var devices: [Device] = []
    var selectedDevice: Device?
    var selectedSceneIndex: IndexPath?
    var isDeviceCatgery: String?
    var wifiAnimationView: LottieAnimationView?
    var scenes: [String] = []
    @IBOutlet weak var sceneCollectionView: UICollectionView!
    @IBOutlet weak var buttonsCollectionView: UICollectionView!
    @IBOutlet weak var allDimButton: UIButton!
    var isAllDimSelected = false

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        allDimButton.setTitle("", for: .normal)
        if let unselectedImage = UIImage(named: "Unselect")?.resized(to: CGSize(width: 30, height: 30)) {
                allDimButton.setImage(unselectedImage, for: .normal)
            }
        
        settingButton.setTitle("", for: .normal)
        
        buttonsCollectionView.dataSource = self
        buttonsCollectionView.delegate = self
        devicesCollectionView.dataSource = self
        devicesCollectionView.delegate = self
        sceneCollectionView.dataSource = self
        sceneCollectionView.delegate = self
        
        registerCells()
        applyGradientBackground()
        fetchDevice()
       
        connetion_aws_function()
        fetch_all_function()
        subscribe_topic_function()

        backbutton.setTitle("Unselect", for: .normal)
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
           sceneCollectionView.addGestureRecognizer(longPressGesture)
        isDeviceCatgery = selectedDevice?.deviceCategory
        print("DeviceCatgery..\(selectedDevice?.deviceCategory)")
        setupLottieAnimation()
        
       
        
        showConnectingStatus()
        DispatchQueue.main.asyncAfter(deadline: .now() + 15.0) {
                if !self.connected {
                    self.updateOnlineStatus(isOnline: false)
                }
            }
    }

    func showConnectingStatus() {
        isOnlineButton.backgroundColor = UIColor.systemYellow  // Yellow for "Connecting..."
        isOnlineButton.setTitle("Connecting...", for: .normal)
        wifiNetworkName.text = "Checking..."  // Temporary status
        wifiAnimationView?.play() 
        isOnlineButton.cornerRadius = 10
        isOnlineButton.clipsToBounds =  true
        isOnlineButton.titleLabel?.font =  UIFont.systemFont(ofSize: 16)
        
    }

    func fetchDeviceScenes() {
        guard let deviceUid = SelectedDeviecUid else {
            print("❌ SelectedDeviecUid is nil")
            return
        }

        DispatchQueue.main.async {
            self.deviceScene.removeAll()
            self.sceneCollectionView.reloadData()
        }
       guard let selectedUniqueId  = deviceUniqueId
        else {
            print("❌ SelectedDeviecUid is nil")
            return
        }
        let fetchedScenes = SkromanIsraDatabaseHelper.shared.fetchScenesByUniqueId(uniqueId: selectedUniqueId)

        // ✅ Sort scenes by `sceneNo` (converted to Int)
        let sortedScenes = fetchedScenes.sorted {
            (Int($0.sceneNo) ?? 0) < (Int($1.sceneNo) ?? 0)
        }

        DispatchQueue.main.async {
            self.deviceScene = sortedScenes
            print("✅ Sorted Scene List: \(self.deviceScene.map { "\($0.sceneNo): \($0.sceneName)" })")

            self.sceneCollectionView.reloadData()
        }
    }
    func setupLottieAnimation() {
           wifiAnimationView = LottieAnimationView(name: "wifi")  // JSON filename (wifi.json)
           wifiAnimationView?.frame = wifiImageContainer.bounds
           wifiAnimationView?.contentMode = .scaleAspectFit
           wifiAnimationView?.loopMode = .loop
           wifiAnimationView?.animationSpeed = 1.0
           wifiImageContainer.addSubview(wifiAnimationView!)
           wifiAnimationView?.play()  // Start animation
       }

    @IBAction func allDimButton(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let dimSetVC = storyboard.instantiateViewController(withIdentifier: "DimSetViewController") as? DimSetViewController {
            dimSetVC.devices = self.devices
            dimSetVC.devicestate = self.receivedDeviceStates

            // ✅ Set delegate
            dimSetVC.delegate = self

            dimSetVC.modalPresentationStyle = .overFullScreen
            dimSetVC.modalTransitionStyle = .crossDissolve

            // ✅ Change button image to "allDim"
            if let selectedImage = UIImage(named: "allDim")?.resized(to: CGSize(width: 30, height: 30)) {
                allDimButton.setImage(selectedImage, for: .normal)
            }

            present(dimSetVC, animated: true)
        }
    }



    

    @IBAction func backButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        applyGradientBackground()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
       
        subscribe_topic_function()

       
        requestLatestDeviceState()
       // fetchgetButtonDetails()
    }

    
    @IBAction func menuButton(_ sender: Any) {
        

        
        let menuPOPUp = storyboard?.instantiateViewController(withIdentifier: "DeviceMenuViewController") as! DeviceMenuViewController
        
        menuPOPUp.devicestate = self.receivedDeviceStates
        menuPOPUp.buttonItems = self.buttonItems
        menuPOPUp.devices =  self.devices
        menuPOPUp.deviceScene =  self.deviceScene
        print("devices at.\(receivedDeviceStates)")
        print("devices at..\(devices)")
        print("devices at... \(deviceScene)")
        menuPOPUp.isDeviceCatgery = isDeviceCatgery
        navigationController?.pushViewController(menuPOPUp, animated: true)
      
 
    }


    @objc func DimminSetting(){
        
        let popupVC = DimmingPopupViewController()
        popupVC.modalPresentationStyle = .overFullScreen
        popupVC.modalTransitionStyle = .crossDissolve

        // Convert [String] to [(text: String, isActive: Bool)]
        popupVC.buttonItems = self.buttonItems.map { ($0, false) }
        popupVC.devicestate = self.receivedDeviceStates // Now correctly passes [DeviceStateArray]

        present(popupVC, animated: true)
    }

 

    func fetchDevice() {
        guard let roomId = roomId else {
            print("Error: roomId is nil")
            return
        }

        SkromanIsraDatabaseHelper.shared.fetchDevicesByRoomId(roomId: roomId) { [weak self] fetchedDevices in
            guard let self = self else { return }

            DispatchQueue.main.async {
                guard !fetchedDevices.isEmpty else {
                    print("No devices found in the room.")
                    return
                }

                self.devices = fetchedDevices
                print("Fetched \(fetchedDevices.count) devices.")
                
                self.setSelectedDevice(fetchedDevices[0])
                self.devicesCollectionView.reloadData()
            }
        }
    }



    func setSelectedDevice(_ device: Device) {
        selectedDevice = device
        deviceUniqueId = device.uniqueId
        SelectedDeviecUid =  device.deviceUid
      
        let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)

      
        print("Subscribing to new topic: \(deviceUniqueId ?? "nil")/HA/E/ack")
        subscribe_topic_function()

        requestLatestDeviceState()
        fetchDeviceScenes()

        if let oldTopic = previousDeviceUniqueId {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                print("Unsubscribing from old topic: \(oldTopic + "/HA/E/ack")")
                iotDataManager.unsubscribeTopic(oldTopic + "/HA/E/ack")
            }
        }

        if deviceUniqueId == nil {
            print("⚠️ Device uniqueId not found! Retrying in 2s...")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.requestLatestDeviceState()
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            print("Reloading devicesCollectionView with new device details")
            self.devicesCollectionView.reloadData()
        }

        // Store new device ID for future unsubscription
        previousDeviceUniqueId = deviceUniqueId
    }
    

    func connetion_aws_function() {
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType:AWS_REGION,
                                                                identityPoolId:IDENTITY_POOL_ID)
        initializeControlPlane(credentialsProvider: credentialsProvider)
        initializeDataPlane(credentialsProvider: credentialsProvider)
        
        if (connected == false) {
            handleConnectViaCert()
           
        } else {
           handleDisconnect()
            
        }
        
    }
    
    func handleDisconnect() {
        
        //        let iot_sample_vc = Iot_sample_ViewController()
        self.connectButton.isHidden = false
        self.connectIoTDataWebSocket.isHidden = false
       // activityIndicatorView.startAnimating()
        logTextView.text = "Disconnecting..."
        
        DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
            self.iotDataManager.disconnect();
            DispatchQueue.main.async {
                self.connected = false
                
                
            }
        }
    }
    
    func handleConnectViaCert() {
        
        let defaults = UserDefaults.standard
        let certificateId = defaults.string( forKey: "certificateId")
        if (certificateId == nil) {
            DispatchQueue.main.async {
                
            }
            let certificateIdInBundle = searchForExistingCertificateIdInBundle()
            
            if (certificateIdInBundle == nil) {
                DispatchQueue.main.async {
                    
                }
                createCertificateIdAndStoreinNSUserDefaults(onSuccess: {generatedCertificateId in
                    let uuid = UUID().uuidString
                    
                    self.iotDataManager.connect( withClientId: uuid, cleanSession:true, certificateId:generatedCertificateId, statusCallback: self.mqttEventCallback)
                }, onFailure: {error in
                    print("Received error: \(error)")
                })
            }
        } else {
            let uuid = UUID().uuidString;
           
            iotDataManager.connect( withClientId: uuid, cleanSession:true, certificateId:certificateId!, statusCallback: self.mqttEventCallback)
        }
    }
    
    func createCertificateIdAndStoreinNSUserDefaults(onSuccess:  @escaping (String)->Void,
                                                     onFailure: @escaping (Error) -> Void) {
        let defaults = UserDefaults.standard
        // Now create and store the certificate ID in NSUserDefaults
        let csrDictionary = [ "commonName": CertificateSigningRequestCommonName,
                              "countryName": CertificateSigningRequestCountryName,
                              "organizationName": CertificateSigningRequestOrganizationName,
                              "organizationalUnitName": CertificateSigningRequestOrganizationalUnitName]
        
        self.iotManager.createKeysAndCertificate(fromCsr: csrDictionary) { (response) -> Void in
            guard let response = response else {
                DispatchQueue.main.async {
                    self.connectButton.isEnabled = true
                   // self.activityIndicatorView.stopAnimating()
                    self.logTextView.text = "Unable to create keys and/or certificate, check values in Constants.swift"
                }
                onFailure(NSError(domain: "No response on iotManager.createKeysAndCertificate", code: -2, userInfo: nil))
                return
            }
            defaults.set(response.certificateId, forKey:"certificateId")
            defaults.set(response.certificateArn, forKey:"certificateArn")
            let certificateId = response.certificateId
            print("response: [\(String(describing: response))]")
            
            let attachPrincipalPolicyRequest = AWSIoTAttachPrincipalPolicyRequest()
            attachPrincipalPolicyRequest?.policyName = POLICY_NAME
            attachPrincipalPolicyRequest?.principal = response.certificateArn
            
            // Attach the policy to the certificate
            self.iot.attachPrincipalPolicy(attachPrincipalPolicyRequest!).continueWith (block: { (task) -> AnyObject? in
                if let error = task.error {
                    print("Failed: [\(error)]")
                    onFailure(error)
                } else  {
                    print("result: [\(String(describing: task.result))]")
                    DispatchQueue.main.asyncAfter(deadline: .now()+0.5, execute: {
                        if let certificateId = certificateId {
                            onSuccess(certificateId)
                        } else {
                            onFailure(NSError(domain: "Unable to generate certificate id", code: -1, userInfo: nil))
                        }
                    })
                }
                return nil
            })
        }
    }
    
    
    
    
    func mqttEventCallback( _ status: AWSIoTMQTTStatus ) {
        DispatchQueue.main.async {
            let iot_sample_vc = Iot_sample_ViewController()
            print("connection status = \(status.rawValue)")
            
            switch status {
            case .connecting:
                iot_sample_vc.mqttStatus = "Connecting..."
                print( iot_sample_vc.mqttStatus )
                
                
            case .connected:
                iot_sample_vc.mqttStatus = "Connected"
                
                self.connected = true
                
                let uuid = UUID().uuidString;
                let defaults = UserDefaults.standard
                let certificateId = defaults.string( forKey: "certificateId")
                
                
            case .disconnected:
                iot_sample_vc.mqttStatus = "Disconnected"
                
                print( iot_sample_vc.mqttStatus )
                
            case .connectionRefused:
                iot_sample_vc.mqttStatus = "Connection Refused"
                print( iot_sample_vc.mqttStatus )
                
            case .connectionError:
                iot_sample_vc.mqttStatus = "Connection Error"
                print( iot_sample_vc.mqttStatus )
                
            case .protocolError:
                iot_sample_vc.mqttStatus = "Protocol Error"
                print( iot_sample_vc.mqttStatus )
                
            default:
                iot_sample_vc.mqttStatus = "Unknown State"
                print("unknown state: \(status.rawValue)")
                
            }
            
            NotificationCenter.default.post( name: Notification.Name(rawValue: "connectionStatusChanged"), object: self )
        }
    }
    
    
    
    func searchForExistingCertificateIdInBundle() -> String? {
        let defaults = UserDefaults.standard
        // No certificate ID has been stored in the user defaults; check to see if any .p12 files
        // exist in the bundle.
        let myBundle = Bundle.main
        let myImages = myBundle.paths(forResourcesOfType: "p12" as String, inDirectory:nil)
        let uuid = UUID().uuidString
        
        guard let certId = myImages.first else {
            let certificateId = defaults.string(forKey: "certificateId")
            return certificateId
        }
        
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: certId)) else {
            print("[ERROR] Found PKCS12 File in bundle, but unable to use it")
            let certificateId = defaults.string( forKey: "certificateId")
            return certificateId
        }
        
        DispatchQueue.main.async {
            self.logTextView.text = "found identity \(certId), importing..."
        }
        if AWSIoTManager.importIdentity( fromPKCS12Data: data, passPhrase:"", certificateId:certId) {
            
            defaults.set(certId, forKey:"certificateId")
            defaults.set("from-bundle", forKey:"certificateArn")
            DispatchQueue.main.async {
                self.logTextView.text = "Using certificate: \(certId))"
                self.iotDataManager.connect( withClientId: uuid,
                                             cleanSession:true,
                                             certificateId:certId,
                                             statusCallback: self.mqttEventCallback)
            }
        }
        
        let certificateId = defaults.string( forKey: "certificateId")
        return certificateId
    }
    
    func initializeDataPlane(credentialsProvider: AWSCredentialsProvider) {
        
        
        let iotEndPoint = AWSEndpoint(urlString: IOT_ENDPOINT)
        
        
        let iotDataConfiguration = AWSServiceConfiguration(region: AWS_REGION,
                                                           endpoint: iotEndPoint,
                                                           credentialsProvider: credentialsProvider)
        
        AWSIoTDataManager.register(with: iotDataConfiguration!, forKey: AWS_IOT_DATA_MANAGER_KEY)
        iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
    }
    
    
    func initializeControlPlane(credentialsProvider: AWSCredentialsProvider) {
        
        let controlPlaneServiceConfiguration = AWSServiceConfiguration(region:AWS_REGION, credentialsProvider:credentialsProvider)
        
        
        AWSServiceManager.default().defaultServiceConfiguration = controlPlaneServiceConfiguration
        iotManager = AWSIoTManager.default()
        iot = AWSIoT.default()
    }
    
    
    func fetch_all_function() {
        guard let topic = deviceUniqueId else {
            print("Error: PUB_TOPIC_ is nil. Cannot subscribe to MQTT topic.")
            return
        }
        let fetch_all_params: Parameters = [
            "control": "fetch_all",
            "no": 0,
            "state": 0,
            "speed": 0,
            "from": "A",
            "topic": topic
        ]
        
        do {
            // Serialize parameters to JSON data
            let theJSONData = try JSONSerialization.data(withJSONObject: fetch_all_params, options: [])
            
            // Convert JSON data to UTF-8 string
            if let theJSONText = String(data: theJSONData, encoding: .utf8) { // Use UTF-8 encoding
                print("JSON at fetch all string = \(theJSONText)")
                
                // Publish the string to the topic
                let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
                iotDataManager.publishString(theJSONText, onTopic: "\(device_value_on_click ?? "")/HA/A/req", qoS: .messageDeliveryAttemptedAtMostOnce)
            } else {
                print("Error: Failed to convert JSON data to UTF-8 string.")
            }
        } catch {
            print("Error: JSON serialization failed with error: \(error)")
        }
    }
    
    func sceneSet( control_no: Int){
        publishScene(control_state: "scene_control", control_no: control_no)
        
    }
    
    
    func publishScene(control_state : String, control_no: Int) {
        guard let topic = deviceUniqueId else {
            print("Error: PUB_TOPIC_ is nil. Cannot subscribe to MQTT topic.")
            return
        }
        
        let scene_pub_parameters : Parameters = [
            "control" : control_state,
            "no" : control_no,
            "from": "A",
            "topic": topic
            
        ]
        
        if let theJSONData = try? JSONSerialization.data(withJSONObject: scene_pub_parameters,options: []) {
            
            let theJSONText = String(data: theJSONData,
                                     encoding: .ascii)
            print("JSON  scene string = \(theJSONText!)")
            
            
            let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
            
            let iot_sample_vc = Iot_sample_ViewController()
            
            iotDataManager.publishString(theJSONText!, onTopic: topic + "/HA/A/req", qoS:.messageDeliveryAttemptedAtMostOnce)
            
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            print("Reloading devicesCollectionView with new device details")
            self.devicesCollectionView.reloadData()
           
        }
    }
    
    
    
    func fetchgetButtonDetails() {
        let params: Parameters = [
            "deviceUid" : SelectedDeviecUid
        ]

        print("button details API: \(params)")

        AF.request("http://3.7.18.55:3000/skroman/buttondetails/getbuttons",
                   method: . post,
                   parameters: params,
                   encoding: JSONEncoding.default,
                   headers: nil)
            .response { response in
                debugPrint(response)

                switch response.result {
                case .success(let data):
                    do {
                        let jsonOne = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary
                        print("Response get buttons details  JSON: \(String(describing: jsonOne))")
                    } catch {
                        print("JSON Parsing Error: \(error.localizedDescription)")
                    }
                case .failure(let err):
                    print("API Request Error: \(err.localizedDescription)")
                }
            }.resume()
    }



   
    func applyGradientBackground() {
        let mainScreen = CAGradientLayer()
        mainScreen.frame = deviceBackGroundView.bounds

        if traitCollection.userInterfaceStyle == .dark {
            // Dark Mode: Futuristic Tech Theme (Deep Blue to Dark Gray)
            mainScreen.colors = [
                UIColor(red: 10/255, green: 25/255, blue: 50/255, alpha: 1).cgColor,  // #0A1932 (Deep Blue)
                UIColor(red: 46/255, green: 46/255, blue: 46/255, alpha: 1).cgColor   // #2E2E2E (Dark Gray)
            ]
        } else {
            // Light Mode: Futuristic Tech Theme (Soft Cyan to Light Silver)
            mainScreen.colors = [
                UIColor(red: 180/255, green: 240/255, blue: 255/255, alpha: 1).cgColor, // #B4F0FF (Soft Cyan)
                UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1).cgColor  // #E6E6E6 (Light Silver)
            ]
        }

        mainScreen.startPoint = CGPoint(x: 0, y: 0)  // Top-left corner
        mainScreen.endPoint = CGPoint(x: 1, y: 1)    // Bottom-right corner

        // Remove existing gradient layers before adding a new one
        deviceBackGroundView.layer.sublayers?.removeAll(where: { $0 is CAGradientLayer })
        
        deviceBackGroundView.layer.insertSublayer(mainScreen, at: 0)
    }
    func registerCells() {
        let deviceNib = UINib(nibName: "DeviceCollectionViewCell", bundle: nil)
        devicesCollectionView.register(deviceNib, forCellWithReuseIdentifier: "DeviceCollectionViewCell")

        let sceneNib = UINib(nibName: "SceneCollectionViewCell", bundle: nil)
        sceneCollectionView.register(sceneNib, forCellWithReuseIdentifier: "SceneCollectionViewCell")

        let buttonNib = UINib(nibName: "ButtonsCollectionViewCell", bundle: nil)
        buttonsCollectionView.register(buttonNib, forCellWithReuseIdentifier: "ButtonsCollectionViewCell")
    }
    func subscribe_topic_function() {
        guard let topic = deviceUniqueId else {
            print("Error: deviceUniqueId is nil. Cannot subscribe to MQTT topic.")
            return
        }

        let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
        let fullTopic = topic + "/HA/E/ack"

        print("Subscribing to topic: \(fullTopic)")

        iotDataManager.subscribe(toTopic: fullTopic, qoS: .messageDeliveryAttemptedAtMostOnce) { [weak self] (payload) -> Void in
            guard let self = self else { return }

            if let stringValue = String(data: payload, encoding: .utf8) {
                print("Received message: \(stringValue)")
                


                if let jsonData = stringValue.data(using: .utf8) {
                    do {
                        let basicCheck = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any]

                        // 🔹 Handle "ack" messages (e.g., "MQTT disconnects") and retry fetching
                        if let ackMessage = basicCheck?["ack"] as? String, ackMessage == "MQTT disconnects" {
                            print("⚠️ Device not ready, retrying in 0.2s...")
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                                self.requestLatestDeviceState()
                            }
                            return
                        }

                     
                        guard let uniqueId = basicCheck?["unique_id"] as? String, !uniqueId.isEmpty else {
                            print("⚠️ Ignoring message: Missing unique_id")
                            return
                        }

                        let deviceState = try JSONDecoder().decode(DeviceStateArray.self, from: jsonData)

                        DispatchQueue.main.async {
                            self.receivedDeviceStates.removeAll()
                            self.receivedDeviceStates.append(deviceState) // Store the latest state
                            self.updateButtonItems(with: deviceState)
                            print("✅ Updated UI with latest device state.")
                            self.updateOnlineStatus(isOnline: true)
                        }


                    } catch {
                        print("❌ Error decoding JSON: \(error)")
                    }
                }
            } else {
                print("❌ Failed to convert payload to String")
            }
        }

        // 🔹 Ensure we send a request for the latest state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.requestLatestDeviceState()
        }
    }


    func updateOnlineStatus(isOnline: Bool) {
        let color = isOnline ? UIColor.green : UIColor.red
        let title = isOnline ? "Online" : "Offline"

        isOnlineButton.backgroundColor = color
        isOnlineButton.setTitle(title, for: .normal)
        isOnlineButton.cornerRadius =  10
        isOnlineButton.clipsToBounds =  true

        if isOnline {
            connected = true  // Mark as connected
            wifiNetworkName.text = selectedDevice?.connectedSsid ?? "Unknown Network"
            wifiAnimationView?.stop()  // Stop animation
        } else {
            wifiNetworkName.text = "Not Connected"
            wifiAnimationView?.play()  // Play animation
        }
    }



    func requestLatestDeviceState() {
        guard let topic = deviceUniqueId else {
            print("Error: deviceUniqueId is nil. Cannot publish request for latest state.")
            return
        }

        let fetch_all_params: Parameters = [
            "control": "fetch_all",
            "no": 0,
            "state": 0,
            "speed": 0,
            "from": "A",
            "topic": topic
        ]

        if let jsonData = try? JSONSerialization.data(withJSONObject: fetch_all_params, options: []) {
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("Requesting latest state: \(jsonString)")

                let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
                iotDataManager.publishString(jsonString, onTopic: topic + "/HA/A/req", qoS: .messageDeliveryAttemptedAtMostOnce)
            }
        }
    }


    
   
    func mapAllValues(
        controlName: String, lightState: String, lightSpeed: String, destNumber: String, ChildLockLight: String, controlDimming: String,
        fanState: String, fanSpeed: String, childLockFan: String, master: Int, childLockMaster: String
    ) -> [[String: String]] {
        
        var mappedArray: [[String: String]] = []
        

        let charactersToRemove: Set<Character> = ["S", "W", "X", "G", "H", "I", "J"]
        let filteredCNM = controlName.filter { !charactersToRemove.contains($0) }

        let lightLength = min(filteredCNM.count, lightState.count, lightSpeed.count, ChildLockLight.count, controlDimming.count, destNumber.count)

        guard lightLength > 0, fanState.count == fanSpeed.count, fanState.count * 3 == childLockFan.count,
              String(master).count == childLockMaster.count else {
            print("Mismatch in data lengths or invalid data")
            return mappedArray
        }

        let masterString = String(master)

  
        for i in 0..<lightLength {
            let entry: [String: String] = [
                "cNm": String(filteredCNM[filteredCNM.index(filteredCNM.startIndex, offsetBy: i)]),
                "L_state": String(lightState[lightState.index(lightState.startIndex, offsetBy: i)]),
                "L_speed": String(lightSpeed[lightSpeed.index(lightSpeed.startIndex, offsetBy: i)]),
                "c_l": String(ChildLockLight[ChildLockLight.index(ChildLockLight.startIndex, offsetBy: i)]),
                "c_dim": String(controlDimming[controlDimming.index(controlDimming.startIndex, offsetBy: i)]),
                "d_no": String(destNumber[destNumber.index(destNumber.startIndex, offsetBy: i)])
            ]
            mappedArray.append(entry)
        }

        var fanCount = 0
        if !fanState.isEmpty {
            fanCount += 1
            let fanEntry: [String: String] = [
                "FState": String(fanState[fanState.index(fanState.startIndex, offsetBy: 0)]),
                "FSpeed": String(fanSpeed[fanSpeed.index(fanSpeed.startIndex, offsetBy: 0)]),
                "CF": String(childLockFan.prefix(3)),
                "d_no": String(fanCount)
            ]
            mappedArray.append(fanEntry)
        }

        
        for i in 0..<masterString.count {
            let masterEntry: [String: String] = [
                "Master": String(masterString[masterString.index(masterString.startIndex, offsetBy: i)]),
                "CM": String(childLockMaster[childLockMaster.index(childLockMaster.startIndex, offsetBy: i)]),
              
            ]
            mappedArray.append(masterEntry)
        }

        return mappedArray
    }

    
    func updateButtonItems(with deviceState: DeviceStateArray) {
        buttonItems.removeAll()
        mappedValues = mapAllValues(
            controlName: deviceState.cNm,
            lightState: deviceState.lightState,
            lightSpeed: deviceState.lightSpeed, 
            destNumber: deviceState.deviceNumber,
            ChildLockLight: deviceState.cL,
            controlDimming: deviceState.cDim,
            fanState: deviceState.fanState,
            fanSpeed: deviceState.fanSpeed,
            childLockFan: deviceState.cF,
            master: deviceState.master,
            childLockMaster: deviceState.cM
            
        )

        var lightIndex = 1
        var fanIndex = 1

        for cNmValue in deviceState.cNm {
            if ["L", "C", "O", "D", "Q", "Y"].contains(cNmValue) {
                buttonItems.append("\(cNmValue)\(lightIndex)")
                lightIndex += 1
            }
        }

        for _ in deviceState.fanState {
            buttonItems.append("F\(fanIndex)")
            fanIndex += 1
        }

        buttonItems.append("Master")

        DispatchQueue.main.async {
            print("Reloading buttonsCollectionView with updated buttonItems: \(self.buttonItems)")
            self.buttonsCollectionView.reloadData()
        }
    }

    func publish_button(control: String, no: Int, state: Int, speed: Int) {
        
        guard let topic = deviceUniqueId else {
          
            return
        }
        let fetch_all_params : Parameters = [
            
            "control": control,
            "no" : no,
            "state" : state,
            "speed" : speed,
            "from":"A",
            "topic": topic
            
        ]
        print("fetch all  at  publish parameter \(fetch_all_params)")
        
        
        
        
        if let theJSONData = try? JSONSerialization.data(withJSONObject: fetch_all_params,options: []) {
            
            let theJSONText = String(data: theJSONData,
                                     encoding: .ascii)
            print("JSON  at fetch all string = \(theJSONText!)")
            
            
            let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
            
            let iot_sample_vc = Iot_sample_ViewController()
            iotDataManager.publishString(theJSONText!, onTopic: topic + "/HA/A/req", qoS:.messageDeliveryAttemptedAtMostOnce)
            buttonsCollectionView.reloadData()
        }
        
    }
    
    @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            let touchPoint = gestureRecognizer.location(in: sceneCollectionView)
            
            if let indexPath = sceneCollectionView.indexPathForItem(at: touchPoint) {
                let selectedScene = deviceScene[indexPath.item]
                
                showCustomPopup(for: selectedScene)
            }
        }
    }

    func showCustomPopup(for scene: DeviceScene) {
        let popup = CustomPopupView(sceneName: scene.sceneName)
        
        guard let sceneNumber = Int(scene.sceneNo) else {
            print("Error: Scene number '\(scene.sceneNo)' is not a valid integer.")
            return
        }
        
      let sceneId = scene.sceneId
        
        popup.translatesAutoresizingMaskIntoConstraints = false
        popup.onClose = {
            popup.removeFromSuperview()
        }
        popup.onConfigure = { newName in
            self.updateScene(SceneName: newName, sceneNo: String(sceneNumber), SelectedsceneId: sceneId)
            self.publishScene(control_state: "scene_config", control_no: sceneNumber)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.showPopupScene()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1)
                {self.sceneCollectionView.reloadData()
                }
            }
            popup.removeFromSuperview()
        }
        
        view.addSubview(popup)
        
        NSLayoutConstraint.activate([
            popup.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            popup.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            popup.widthAnchor.constraint(equalToConstant: 300),
            popup.heightAnchor.constraint(equalToConstant: 200)
        ])
        sceneCollectionView.reloadData()
    }
    @objc func showPopupScene() {
        
        showPopupPresenter.showPopup1(on: self.view,
                                     animationName: "inProcess",
                                     title: "Success!",
                                     subtitle: "Scene Changing")
        
       
    }
    
    
    
    func updateScene(SceneName: String, sceneNo: String,  SelectedsceneId: String ) {
        // Safely access the first element of receivedDeviceStates
        guard let deviceState = receivedDeviceStates.first else {
            print("Error: No device states available")
            return
        }
        
        let scene_params: Parameters = [
            "sceneId": SelectedsceneId,
            "deviceUid": selectedDevice?.deviceUid ,
            "homeId": homeId ?? "",
            "roomId": roomId ?? "",
            "unique_id": selectedDevice?.uniqueId ?? "",
            "modelNo": selectedDevice?.deviceModelNo ?? "",
            "devicetype": selectedDevice?.deviceType ?? "",
            "sceneNo": sceneNo,
            "sceneName": SceneName,
            "fan_dest": "1",
            "dest_button": deviceState.deviceNumber,
            "config_dim": deviceState.cDim,
            "config_buttons": deviceState.cNm,
            "L_state": deviceState.lightState,
            "L_speed": deviceState.lightSpeed,
            "F_state": deviceState.fanState,
            "F_speed": deviceState.fanSpeed
        ]
        
        print("Scene Update Parameters: \(scene_params)")
        
        AF.request("http://3.7.18.55:3000/skroman/sceneupdate", method: .put, parameters: scene_params, encoding: JSONEncoding.default, headers: nil).response { response in
            debugPrint(response)
            
            switch response.result {
            case .success(let data):
                do {
                    if let data = data,
                       let jsonOne = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? NSDictionary {
                        print("jsonOne scene update ->", jsonOne)
                        
                        if let sceneName = jsonOne["sceneName"] as? String {
                            print("Updated Scene Name:", sceneName)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1)
                            {self.sceneCollectionView.reloadData()
                            }
                           
                        }
                    }
                } catch {
                    print("JSON Parsing Error: \(error.localizedDescription)")
                }
                
            case .failure(let error):
                print("Request Failed: \(error.localizedDescription)")
            }
        }.resume()
    }

    
    func add_device_state_api_func() {

        let add_device_state_params : Parameters = [
            
            "deviceUid": selectedDevice?.deviceUid ?? "",
            "unique_id": selectedDevice?.uniqueId ?? "",
            "POP": selectedDevice?.POP ?? "",
            "modelNo": selectedDevice?.deviceModelNo ?? "",
            "deviceType": selectedDevice?.deviceType ?? "",
            "ack":currentDeviceState?.ack  ?? "",
            "dest_button": currentDeviceState?.deviceNumber ?? "",
            "fan_dest": "",
            "config_dim": currentDeviceState?.cDim ,
            "config_buttons": currentDeviceState?.cNm ?? "",
            "working_mode": currentDeviceState?.workingMode ?? "",
            "child_lock_l": currentDeviceState?.cL ?? "",
            "child_lock_f": currentDeviceState?.cF ?? "",
            "child_lock_m": currentDeviceState ?? "",
            "master": currentDeviceState?.master ?? "",
            "L_state": currentDeviceState?.lightState ?? "",
            "L_speed": currentDeviceState?.lightSpeed ?? "",
            "F_state": currentDeviceState?.fanState ?? "",
            "F_speed": currentDeviceState?.fanSpeed ?? "",
            "connectivity":"",
            "control_from": currentDeviceState?.controlFrom ?? ""
            
            
        ]
      
        AF.request("http://3.7.18.55:3000/skroman/devicestate", method: .post, parameters: add_device_state_params, encoding: JSONEncoding.default, headers: nil).response { [self] response in
            debugPrint(response)
            
            switch response.result
            {
            case .success(let data) :
                do {
                    
                    
                    let jsonOne = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary
                    
                    print("jsonOne -- >>", jsonOne!)
                    
                }
                
                
                catch {
                    print(error.localizedDescription)
                }
                
                
            case .failure(let err):
                print(err.localizedDescription)
            }
            
        }.resume()
        
    }

}

extension DeviceViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == devicesCollectionView {
            return collectionView == devicesCollectionView ? devices.count : 0
        } else if collectionView == sceneCollectionView {
            return deviceScene.count
        } else if collectionView == buttonsCollectionView {
            return buttonItems.count
        }
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == devicesCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DeviceCollectionViewCell", for: indexPath) as! DeviceCollectionViewCell
            let device = devices[indexPath.item]
                           
                    cell.DeviceNumberLabel.text = " \(device.deviceName)"
            cell.DeviceNameLabel.text  = "  \(device.uniqueId)"
                    cell.backgroundColor = (device.uniqueId == selectedDevice?.uniqueId) ? .lightGray : .white

                    return cell
        } else if collectionView == sceneCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SceneCollectionViewCell", for: indexPath) as! SceneCollectionViewCell
            
            let scene = deviceScene[indexPath.item]
                   print(" Scene at index \(indexPath.item): \(scene.sceneName)")

                   cell.SceneNumberllabel.text = scene.sceneName
            cell.cellBackGroundView?.backgroundColor = (indexPath == selectedSceneIndex) ? .lightGray : .white
                   return cell
        

        } else if collectionView == buttonsCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ButtonsCollectionViewCell", for: indexPath) as! ButtonsCollectionViewCell
            let buttonText = buttonItems[indexPath.item]

          print ("buttonText atttt\(buttonText)")
            
            
            let lState = mappedValues.first(where: { $0["cNm"] == String(buttonText.prefix(1)) })?["L_state"] ?? ""
            let fState = mappedValues.first(where: { $0["FState"] != nil })?["FState"] ?? ""
            let masterState = mappedValues.first(where: { $0["Master"] != nil })?["Master"] ?? ""
            let oState = mappedValues.first(where: { $0["cNm"] == "O" })?["L_state"] ?? ""
            let cState = mappedValues.first(where: { $0["cNm"] == "C" })?["L_state"] ?? ""

            let dState = mappedValues.first(where: { $0["cNm"] == "D" })?["L_state"] ?? ""
           
            cell.configure(with: buttonText, index: indexPath.item, mappedValues: mappedValues)

            return cell
        }

        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == devicesCollectionView {
            let selected = devices[indexPath.item]
            setSelectedDevice(selected)
            return
        }
        
        if collectionView == sceneCollectionView {
            let selectedScene = deviceScene[indexPath.item]
            if let sceneNumber = Int(selectedScene.sceneNo) {
                sceneSet(control_no: sceneNumber)
                selectedSceneIndex = indexPath
                sceneCollectionView.reloadData()
            } else {
                print("❌ Error: Invalid scene number \(selectedScene.sceneNo)")
            }
            return
        }
        
        guard collectionView == buttonsCollectionView else { return }

        // Safely handle Master first
        if buttonItems[indexPath.item] == "Master" {
            let control = "M"
            let no = 1
            var state = Int(mappedValues.last?["Master"] ?? "0") ?? 0
            state = (state == 0) ? 1 : 0
            let speed = 0

            print("🔘 Master clicked: control=\(control), no=\(no), state=\(state), speed=\(speed)")
            publish_button(control: control, no: no, state: state, speed: speed)
            return
        }

        // Safety check to avoid crash
        guard indexPath.item < mappedValues.count else {
            print("❌ Index out of range for mappedValues")
            return
        }

        let mappedEntry = mappedValues[indexPath.item]
        var control = ""
        var no = 0
        var state = 0
        var speed = 0

        if let cNm = mappedEntry["cNm"], ["L", "O", "C", "Q", "Y", "D"].contains(cNm) {
            control = "L"
            no = Int(mappedEntry["d_no"] ?? "0") ?? 0
            state = Int(mappedEntry["L_state"] ?? "0") ?? 0
            speed = Int(mappedEntry["L_speed"] ?? "0") ?? 0
        } else if mappedEntry["FState"] != nil {
            control = "F"
            no = Int(mappedEntry["d_no"] ?? "0") ?? 0
            state = Int(mappedEntry["FState"] ?? "0") ?? 0
            speed = Int(mappedEntry["FSpeed"] ?? "0") ?? 0
        }

        state = (state == 0) ? 1 : 0
        print("📤 Publishing: control=\(control), no=\(no), state=\(state), speed=\(speed)")
        publish_button(control: control, no: no, state: state, speed: speed)
    }




    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == buttonsCollectionView {
            let numberOfColumns: CGFloat = 3
            let spacing: CGFloat = 20
            let totalSpacing = (numberOfColumns - 1) * spacing
            let itemWidth = (collectionView.frame.width - totalSpacing - 20) / numberOfColumns
            return CGSize(width: itemWidth, height: itemWidth)
        } else if collectionView == devicesCollectionView {
            return CGSize(width: collectionView.frame.width / 3 - 10, height: 50) // Adjust for devices
        } else if collectionView == sceneCollectionView {
            return CGSize(width: collectionView.frame.width / 3 - 10, height: 40) // Adjust for scenes
        } else {
            return CGSize(width: 100, height: 100) // Default fallback size
        }
    }


    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 20 // Horizontal spacing
    }

}



extension DeviceViewController: DimSetViewControllerDelegate {
    func didDismissDimSet() {
        if let unselectedImage = UIImage(named: "Unselect")?.resized(to: CGSize(width: 30, height: 30)) {
            allDimButton.setImage(unselectedImage, for: .normal)
        }
    }
}



extension UIColor {
    convenience init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0

        self.init(red: red, green: green, blue: blue, alpha: 0.5) // 50% opacity
    }
}
