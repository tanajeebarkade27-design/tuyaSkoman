//
//  ShortcutDeviceCollectionViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 26/03/25.
//


import UIKit
import SwiftKeychainWrapper
import AWSCore
import AWSIoT
import Alamofire
import AppIntents

protocol ShortcutDeviceCellDelegate: AnyObject {
    func didUpdateDeviceState(_ state: DeviceStateArray)
    func didUpdateDeviceScenes(_ scenes: [DeviceScene], for deviceUid: String)
    func navigateToDeviceMenu(device: Device, states: [DeviceStateArray], buttons: [String], devices: [Device], deviceScene: [DeviceScene], isDeviceCatgery: String?, selectedUniqueId : String?)
}
protocol ShortcutButtonDeviceCellDelegate: AnyObject {
    func didLongPressButton(with item: String, buttonNumber: Int, buttonDetail: ButtonDetails?)
    
}



class ShortcutDeviceCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var deviecNameLabel: UILabel!
    
    @IBOutlet weak var dveiceView: UIView!
    
    @IBOutlet weak var isOnlineImage: UIImageView!
    
    @IBOutlet weak var sHSceneCollectionView: UICollectionView!
    
    @IBOutlet weak var ShButtonCollectionView: UICollectionView!
    
    @IBOutlet weak var buttonView: UIView!
    
    @IBOutlet weak var devicemenuButton: UIButton!
    
    static let deviceCell  =  ShortcutDeviceCollectionViewCell()
    
    weak var delegate: ShortcutDeviceCellDelegate?
    weak var longpressdelgate :ShortcutButtonDeviceCellDelegate?
    
    var currentDeviceState: DeviceStateArray?
    var roomId: String?
    var homeId : String?
    var homes: [Home] = []
    var rooms: [Room] = []
    var devices: [Device] = []
    var selectedDevice: Device?
    var deviceScene: [DeviceScene] = []
    var iotDataManager: AWSIoTDataManager!
    var iotManager: AWSIoTManager!
    var iot: AWSIoT!
    var filteredButtonDetails: [ButtonDetails] = []
   // weak var parentViewController: UIViewController?

    
    var logTextView: UITextView!
    var  SelectedDeviecUid : String?
    var connectButton: UIButton!
    var currentDeviceScene :DeviceScene?
    var connectIoTDataWebSocket: UIButton!
    var connected = false
    var receivedDeviceStates: [DeviceStateArray] = []
    var buttonDetails: [ButtonDetails] = []
    var previousDeviceUniqueId: String?
    var mappedValues: [[String: String]] = []
    
    var deviceCataegary: String?
    
    var deviceUid: String?
    var deviceUniqueId: String?
    
    var switchItems: [SwitchItem] = []
    var buttonItems: [String] = [] {
        didSet {
            DispatchQueue.main.async {
                self.ShButtonCollectionView.reloadData()
                self.sHSceneCollectionView.reloadData()
            }
        }
    }
    
    
    
    
    var filteredButtons: [String] = [] {
        didSet {
            buttonItems = filteredButtons
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        //        subscribe_topic_function()
        connetion_aws_function()
        requestLatestDeviceState(topic: deviceUniqueId ?? "")
        print("buttons at cell details \(buttonDetails)")
        devicemenuButton.setTitle("", for: .normal)
        registerXIB()
        buttonView.cornerRadius =  10
        buttonView.clipsToBounds =  true
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        sHSceneCollectionView.addGestureRecognizer(longPressGesture)
     
    
    }
    
    func configure(with deviceUid: String, deviceUniqueId: String, buttonItems: [String]) {
        self.deviceUid = deviceUid
        self.deviceUniqueId = deviceUniqueId
        self.buttonItems = buttonItems
        deviecNameLabel.text = deviceUid
        print("deviceUid at.  \(deviceUid)")
      
    }
    
    func registerXIB(){
        
        let buttonNib = UINib(nibName: "shortButtonCollectionViewCell", bundle: nil)
        ShButtonCollectionView.register(buttonNib, forCellWithReuseIdentifier: "shortButtonCollectionViewCell")
        let sceneNib = UINib(nibName: "ShSceneCollectionViewCell", bundle: nil)
        sHSceneCollectionView.register(sceneNib, forCellWithReuseIdentifier: "ShSceneCollectionViewCell")
        
        ShButtonCollectionView.dataSource =  self
        ShButtonCollectionView.delegate =  self
        sHSceneCollectionView.delegate =  self
        sHSceneCollectionView.dataSource =  self
        
    }
    
    
   
    
    @IBAction func devicemenuButton(_ sender: Any) {
        guard let selected = devices.first else {
            print("No devices available btn")
            return
        }

        
        
        
        selectedDevice = selected
        SelectedDeviecUid = selected.deviceUid
        
         
        print("selectedDevice is  at.\(selectedDevice)")
        
        

        let stateArray: [DeviceStateArray] = currentDeviceState.map { [$0] } ?? []
        delegate?.navigateToDeviceMenu(
            device: selected,
            states: stateArray,
            buttons: self.buttonItems,
            devices: self.devices,
            deviceScene: self.deviceScene,
            isDeviceCatgery: self.deviceCataegary,
            selectedUniqueId: selected.uniqueId
        )

        print("✅ Navigated with selected device UID: \(selected.deviceUid) /// \(selected.uniqueId)")
    }

    
    
    
    func fetchDeviceScenes(selectdeviceUniqueid: String) {
        DispatchQueue.main.async {
            self.deviceScene.removeAll()
            self.sHSceneCollectionView.reloadData()
        }
        
        let fetchedScenes = SkromanIsraDatabaseHelper.shared.fetchScenesByUniqueId(uniqueId: selectdeviceUniqueid)
        
        let sortedScenes = fetchedScenes.sorted {
            (Int($0.sceneNo) ?? 0) < (Int($1.sceneNo) ?? 0)
        }
        
        DispatchQueue.main.async {
            self.deviceScene.append(contentsOf: sortedScenes)
            print("🔄 Appended Scenes: \(sortedScenes.map { "\($0.sceneNo): \($0.sceneName)" })")
            
            self.delegate?.didUpdateDeviceScenes(self.deviceScene, for: self.deviceUid ?? "")
            
            self.sHSceneCollectionView.reloadData()
        }
    }
    
    func updateOnlineStatus(for deviceState: DeviceStateArray) {
        let isOnline = deviceState.ack == "ONLINE"
        
        DispatchQueue.main.async {
            self.isOnlineImage.isHidden = false
            self.isOnlineImage.image = UIImage(named: isOnline ? "isSelected" : "")
            print(" \(deviceState.uniqueID) is \(isOnline ? "Online" : "Offline ")")
        }
    }
    
    

    
    func configureCell(device: Device, buttons: [ButtonDetails]) {
        self.selectedDevice = device
        self.buttonDetails = buttons
        
        ShButtonCollectionView.reloadData()
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
        self.connectButton.isHidden = false
        self.connectIoTDataWebSocket.isHidden = false
        
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
            // Connect to the AWS IoT data plane service w/ certificate
            iotDataManager.connect( withClientId: uuid, cleanSession:true, certificateId:certificateId!, statusCallback: self.mqttEventCallback)
        }
    }
    
    func createCertificateIdAndStoreinNSUserDefaults(onSuccess:  @escaping (String)->Void,
                                                     onFailure: @escaping (Error) -> Void) {
        let defaults = UserDefaults.standard
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
            
            if let stringValue = String(data: payload as! Data, encoding: .utf8) {
                print("Received after subscribe message: \(stringValue)")
                
                if let jsonData = stringValue.data(using: .utf8) {
                    do {
                        let deviceState = try JSONDecoder().decode(DeviceStateArray.self, from: jsonData)
                        
                        DispatchQueue.main.async {
                            if let index = self.receivedDeviceStates.firstIndex(where: { $0.uniqueID == deviceState.uniqueID }) {
                                self.receivedDeviceStates[index] = deviceState
                            } else {
                                self.receivedDeviceStates.append(deviceState)
                                self.fetchDeviceScenes(selectdeviceUniqueid: deviceState.uniqueID)
                                self.fetchButtonsDetails(SelectedUniqueUid: deviceState.uniqueID)
                                self.requestLatestDeviceState(topic: deviceState.uniqueID)
                               
                            }

                            self.updateButtonItems(with: deviceState)
                            self.currentDeviceState = deviceState
                            self.delegate?.didUpdateDeviceState(deviceState)
                            DispatchQueue.main.async {
                            
                                self.fetchButtonsDetails(SelectedUniqueUid: deviceState.uniqueID)

                                // Build the array
                                let switches = self.createSwitches(from: deviceState,
                                                                   buttonDetails: self.filteredButtonDetails)

                               
                                self.switchItems = switches

                              
                                self.ShButtonCollectionView.reloadData()

                             
                                self.sHSceneCollectionView.reloadData()

                                print("✅ switchItems assigned, count = \(self.switchItems.count)")
                            }

                            self.add_device_state_api_func() // ✅ Move here
                            print("✅ Updated UI with latest device state for \(deviceState).")
                        }

                        
                    } catch {
                        print("❌ Error decoding JSON: \(error)")
                    }
                }
            } else {
                print("❌ Failed to convert payload to String")
            }
        }
        
    
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
           
            self.ShButtonCollectionView.reloadData()
            self.sHSceneCollectionView.reloadData()
        }
    }


    func fetchButtonsDetails(SelectedUniqueUid: String) {
        buttonDetails.removeAll()
        filteredButtonDetails.removeAll() // clear it first
        self.deviceUniqueId = SelectedUniqueUid

        buttonDetails = SkromanIsraDatabaseHelper.shared.fetchButtonDetails(uniqueId: SelectedUniqueUid)

        if buttonDetails.isEmpty {
            print("⚠️ No button details found for deviceUid: \(SelectedUniqueUid)")
        } else {
            buttonDetails.sort { $0.buttonNo < $1.buttonNo }
            print("✅ Button details fetched & sorted: \(buttonDetails)")

            let invalidFirstChars: Set<Character> = ["S", "W", "X", "G", "H", "I", "J"]

            filteredButtonDetails = buttonDetails.filter { item in
                guard let firstChar = item.buttonControlName.uppercased().first else {
                    return false
                }
                return !invalidFirstChars.contains(firstChar)
            }

            print("✅ Filtered buttons at vc : \(filteredButtonDetails)")
        }
    }

    func createSwitches(from deviceState: DeviceStateArray, buttonDetails: [ButtonDetails]) -> [SwitchItem] {
        var switches: [SwitchItem] = []
        let lightRelevantChars: [Character] = ["L", "O", "C", "D", "Q", "Y"]
        var buttonIndex = 0

        // LIGHTS
        for (index, char) in deviceState.cNm.enumerated() {
            if lightRelevantChars.contains(char),
               index < deviceState.lightState.count,
               index < deviceState.cL.count {

                let lightChar = deviceState.lightState[deviceState.lightState.index(deviceState.lightState.startIndex, offsetBy: index)]
                let isOn = lightChar == "1" ? 1 : 0

                let lockChar = deviceState.cL[deviceState.cL.index(deviceState.cL.startIndex, offsetBy: index)]
                let isChildLocked = lockChar == "1" ? 1 : 0

                let configDimChar = index < deviceState.cDim.count
                    ? String(deviceState.cDim[deviceState.cDim.index(deviceState.cDim.startIndex, offsetBy: index)])
                    : nil

                let switchIndex = index + 1

                let buttonDetail = buttonIndex < buttonDetails.count ? buttonDetails[buttonIndex] : nil
                let isShortcut = buttonDetail?.isShortcut

                let switchItem = SwitchItem(
                    name: "L\(switchIndex)",
                    type: .light,
                    switchIndex: switchIndex,
                    isOnState: isOn,
                    isChildLocked: isChildLocked,
                    speed: nil,
                    uniqueID: deviceState.uniqueID,
                    buttonDetail: buttonDetail,
                    configDim: configDimChar,
                    destButton: switchIndex,
                    fanDest: nil,
                    isShortcut: isShortcut, rRegulator: deviceState.rRegulator    // <-- here
                )

                switches.append(switchItem)
                buttonIndex += 1
                print("switchItem at light: \(String(describing: switchItem.buttonDetail))")
                print("switchItem at light: \(switchItem)")
            }
        }

        // FANS
        for (index, fanChar) in deviceState.fanState.enumerated() {
            let isOn = fanChar == "1" ? 1 : 0

            let speedChar = deviceState.fanSpeed.count > index
                ? String(deviceState.fanSpeed[deviceState.fanSpeed.index(deviceState.fanSpeed.startIndex, offsetBy: index)])
                : nil

            let isChildLocked = deviceState.cF.count > index
                ? (deviceState.cF[deviceState.cF.index(deviceState.cF.startIndex, offsetBy: index)] == "1" ? 1 : 0)
                : 0

            let switchIndex = index + 1
            
            let buttonDetail = buttonIndex < buttonDetails.count ? buttonDetails[buttonIndex] : nil
            let isShortcut = buttonDetail?.isShortcut

            let switchItem = SwitchItem(
                name: "F\(switchIndex)",
                type: .fan,
                switchIndex: switchIndex,
                isOnState: isOn,
                isChildLocked: isChildLocked,
                speed: speedChar,
                uniqueID: deviceState.uniqueID,
                buttonDetail: buttonDetail,
                configDim: nil,
                destButton: nil,
                fanDest: switchIndex,
                isShortcut: isShortcut, rRegulator: deviceState.rRegulator  // <-- here
            )

            switches.append(switchItem)
            buttonIndex += 1
            print("switchItem at fan: \(String(describing: switchItem.buttonDetail))")
        }

        // MASTER
        if let masterChar = deviceState.cM.first {
            let isOn = deviceState.master == 1 ? 1 : 0
            let isChildLocked = masterChar == "1" ? 1 : 0
            
            let buttonDetail = buttonIndex < buttonDetails.count ? buttonDetails[buttonIndex] : nil
            let isShortcut = buttonDetail?.isShortcut

            let switchItem = SwitchItem(
                name: "Master",
                type: .master,
                switchIndex: 1,
                isOnState: isOn,
                isChildLocked: isChildLocked,
                speed: nil,
                uniqueID: deviceState.uniqueID,
                buttonDetail: buttonDetail,
                configDim: nil,
                destButton: nil,
                fanDest: nil,
                isShortcut: isShortcut, rRegulator: deviceState.rRegulator  // <-- here
            )

            switches.append(switchItem)
            buttonIndex += 1
        }

        debugLog("✅ All switches created: \(switches)")
        return switches
    }

   
    
    func requestLatestDeviceState(topic: String) {
        guard let topic = deviceUniqueId else {
            
            print("Error: deviceUniqueId is nil. Cannot publish request for latest state attttt.")
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
        controlName: String,
        lightState: String?,
        lightSpeed: String?,
        destNumber: String?,
        ChildLockLight: String?,
        controlDimming: String?,
        fanState: String?,
        fanSpeed: String?,
        childLockFan: String?,
        master: String?,
        childLockMaster: String?
    ) -> [[String: String]] {
        
        var mappedArray: [[String: String]] = []
        
        // Map light buttons
        if let lightState = lightState {
            let lightLength = min(lightState.count, lightSpeed?.count ?? 0, ChildLockLight?.count ?? 0, controlDimming?.count ?? 0, destNumber?.count ?? 0)
            
            for i in 0..<lightLength {
                let speed = (lightSpeed != nil && i < lightSpeed!.count) ? String(lightSpeed![lightSpeed!.index(lightSpeed!.startIndex, offsetBy: i)]) : "0"
                let entry: [String: String] = [
                    "cNm": String(controlName[controlName.index(controlName.startIndex, offsetBy: i)]),
                    "L_state": String(lightState[lightState.index(lightState.startIndex, offsetBy: i)]),
                    "L_speed": speed,
                    "c_l": String(ChildLockLight?[ChildLockLight!.index(ChildLockLight!.startIndex, offsetBy: i)] ?? "0"),
                    "c_dim": String(controlDimming?[controlDimming!.index(controlDimming!.startIndex, offsetBy: i)] ?? "0"),
                    "d_no": String(destNumber?[destNumber!.index(destNumber!.startIndex, offsetBy: i)] ?? "0")
                ]
                mappedArray.append(entry)
            }
        }
        
      
        if let fanState = fanState {
            let fanLength = min(fanState.count, fanSpeed?.count ?? 0, childLockFan?.count ?? 0)
            
            for i in 0..<fanLength {
                let speed = (fanSpeed != nil && i < fanSpeed!.count) ? String(fanSpeed![fanSpeed!.index(fanSpeed!.startIndex, offsetBy: i)]) : "0"
                let childLock = (childLockFan != nil && i < childLockFan!.count) ? String(childLockFan![childLockFan!.index(childLockFan!.startIndex, offsetBy: i)]) : "0"
                let entry: [String: String] = [
                    "FState": String(fanState[fanState.index(fanState.startIndex, offsetBy: i)]),
                    "FSpeed": speed,
                    "CF": childLock,
                    "d_no": String(i + 1)
                ]
                mappedArray.append(entry)
            }
        }
        
        // Add master buttons
        if let master = master {
            let masterString = String(master)
            for i in 0..<masterString.count {
                let masterState = String(masterString[masterString.index(masterString.startIndex, offsetBy: i)])
                let masterLock = (childLockMaster != nil && i < childLockMaster!.count) ? String(childLockMaster![childLockMaster!.index(childLockMaster!.startIndex, offsetBy: i)]) : "0"
                let entry: [String: String] = [
                    "Master": masterState,
                    "CM": masterLock
                ]
                mappedArray.append(entry)
            }
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
            master: String(deviceState.master),
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
            self.ShButtonCollectionView.reloadData()
            self.sHSceneCollectionView.reloadData()
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
    
    
    @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            let touchPoint = gestureRecognizer.location(in: sHSceneCollectionView)
            
            if let indexPath = sHSceneCollectionView.indexPathForItem(at: touchPoint) {
                let selectedScene = deviceScene[indexPath.item]
                showCustomPopup(for: selectedScene)
            }
        }
        
        
        
        
        
        
        func showCustomPopup(for scene: DeviceScene) {
            let popup = CustomPopupView(sceneName: scene.sceneName)
            
            guard let sceneNumber = Int(scene.sceneNo ?? "") else {
                print("Error: Scene number '\(scene.sceneNo ?? "")' is not a valid integer.")
                return
            }
            
            let sceneId = scene.sceneId
            
            popup.translatesAutoresizingMaskIntoConstraints = false
            popup.onClose = {
                popup.removeFromSuperview()
            }
            popup.onConfigure = { newName in
                self.updateScene(SceneName: newName, sceneNo: String(sceneNumber), SelectedsceneId: sceneId)
                self.publishScene(control_state: "scene_config", control_no: String(sceneNumber))
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                   // self.showPopupScene()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.sHSceneCollectionView.reloadData()
                    }
                }
                popup.removeFromSuperview()
            }
            
            if let topView = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController?.view {
                topView.addSubview(popup)
                
                NSLayoutConstraint.activate([
                    popup.centerXAnchor.constraint(equalTo: topView.centerXAnchor),
                    popup.centerYAnchor.constraint(equalTo: topView.centerYAnchor),
                    popup.widthAnchor.constraint(equalToConstant: 300),
                    popup.heightAnchor.constraint(equalToConstant: 200)
                ])
            }
        }
        
        
    }
    @objc func showPopupScene() {
        if let topView = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController?.view {
//            showPopupPresenter.showPopup1(on: topView,
//                                          animationName: "inProcess",
//                                          title: "Success!",
//                                          subtitle: "Scene Changing")
        }
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
                            {self.sHSceneCollectionView.reloadData()
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
        
        guard let selected = devices.first else {
            print("No devices available btn")
            return
        }
        
        
        
        
        selectedDevice = selected
        SelectedDeviecUid = selected.deviceUid
         print("SelectedDeviecUid is  api\(SelectedDeviecUid)")
        let add_device_state_params : Parameters = [
            
            
          
            
            "deviceUid": selectedDevice?.deviceUid ?? "",
            "unique_id": selectedDevice?.uniqueId ?? "",
           
            "modelNo": selectedDevice?.deviceModelNo ?? "",
            "deviceType": selectedDevice?.deviceType ?? "",
            "ack":currentDeviceState?.ack  ?? "",
            "dest_button": currentDeviceState?.deviceNumber ?? "",
            "fan_dest":  currentDeviceState?.fanState ?? "",
            "config_dim": currentDeviceState?.cDim  ?? "",
            "config_buttons": currentDeviceState?.cNm ?? "",
            "working_mode": currentDeviceState?.workingMode ?? "",
            "child_lock_l": currentDeviceState?.cL ?? "",
            "child_lock_f": currentDeviceState?.cF ?? "",
            "child_lock_m": currentDeviceState?.cM ?? "",
            "master": currentDeviceState?.master ?? "",
            "L_state": currentDeviceState?.lightState ?? "",
            "L_speed": currentDeviceState?.lightSpeed ?? "",
            "F_state": currentDeviceState?.fanState ?? "",
            "F_speed": currentDeviceState?.fanSpeed ?? ""
            
            
            
        ]
        
        
         print("paramter at  device state \(add_device_state_params)")
        AF.request("http://3.7.18.55:3000/skroman/devicestate", method: .post, parameters: add_device_state_params, encoding: JSONEncoding.default, headers: nil).response { [self] response in
            debugPrint(response)
            print("response at  nnn\(response)")
            switch response.result
            {
            case .success(let data) :
                do {
                    
                    
                    let jsonOne = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary
                    
                    print("jsonOne  of  device state  -- >>", jsonOne!)
                    
                }
                
                
                catch {
                    print(error.localizedDescription)
                   print(" error at  device state. \(error.localizedDescription)")
                }
                
                
            case .failure(let err):
                
                
                print("error at  device state \(err.localizedDescription)")
            }
            
        }.resume()
        
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
            
            
            ShButtonCollectionView.reloadData()
            sHSceneCollectionView.reloadData()
        }
        
    }
    
    
    func sceneSet( control_no: String){
        publishScene(control_state: "scene_control", control_no: control_no)
        
    }
    
    
    func publishScene(control_state : String, control_no: String) {
        guard let topic = deviceUniqueId else {
            print("Error: PUB_TOPIC_ is nil. Cannot subscribe to MQTT topic.")
            return
        }
        
        let scene_pub_parameters : Parameters = [
            "control" : control_state,
            "no" : Int(control_no),
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
            self.ShButtonCollectionView.reloadData()
            self.sHSceneCollectionView.reloadData()
            
        }
    }
   
    // MARK: - Long‑press
    @objc private func handleButtonLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }

        let point = gesture.location(in: ShButtonCollectionView)
        guard let indexPath = ShButtonCollectionView.indexPathForItem(at: point)
        else { return }

       
        let switchItem = switchItems[indexPath.item]
        print("🟡 Long‑pressed \(switchItem.name) at index \(indexPath.item)")

     

        let sb = UIStoryboard(name: "Main", bundle: nil)
        guard let editVC = sb.instantiateViewController(
                withIdentifier: "EditButtonViewController"
              ) as? EditButtonViewController else { return }
        editVC.selectedSwitchItem = switchItem
        editVC.devicestate = receivedDeviceStates
        editVC.isFromLongPress   = true
        editVC.modalPresentationStyle = .overFullScreen
        editVC.modalTransitionStyle   = .crossDissolve

        if let top = UIApplication.shared.windows.first?.rootViewController {
            var presenter = top
            while let presented = presenter.presentedViewController {
                presenter = presented
            }
            presenter.present(editVC, animated: true)
        }
    }

    

}

extension ShortcutDeviceCollectionViewCell : UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == ShButtonCollectionView {
            print("switchItems at\(switchItems.count)")
            return switchItems.count
           
        } else if collectionView == sHSceneCollectionView {
        
            return deviceScene.count
        }
        return 0
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == ShButtonCollectionView{
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "shortButtonCollectionViewCell", for: indexPath) as! shortButtonCollectionViewCell
            
            cell.deviceUid = deviceUid
            cell.deviceUniqueId = deviceUniqueId
            let switchItem = switchItems[indexPath.item]
               cell.configure(with: switchItem)
            
           
            let longPress = UILongPressGestureRecognizer(
                              target: self,
                              action: #selector(handleButtonLongPress(_:)))
            cell.addGestureRecognizer(longPress)


            print("buttonText at\(switchItem)")
          
            
            return cell
        }
        
        

        else if  collectionView == sHSceneCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ShSceneCollectionViewCell", for: indexPath) as! ShSceneCollectionViewCell
            let scene = deviceScene[indexPath.item]
            cell.sceneLabel.text = scene.sceneName
            
            return cell
        }
        return UICollectionViewCell()
    }
    
   

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if collectionView == ShButtonCollectionView{
            if buttonItems[indexPath.item] == "Master" {
                   let control = "M"
                   let no = 1
                   var state = Int(mappedValues.last?["Master"] ?? "0") ?? 0
                   state = (state == 0) ? 1 : 0
                   let speed = 0

                   print(" Master clicked: control=\(control), no=\(no), state=\(state), speed=\(speed)")
                   publish_button(control: control, no: no, state: state, speed: speed)
                   return
               }
            
            guard indexPath.item < mappedValues.count else {
                print("❌ mappedValues index out of bounds at \(indexPath.item)")
                return
            }
            let buttonLabel = buttonItems[indexPath.item]

            var mappedEntry: [String: String]? = nil
            var control = ""
            var no = 0
            var state = 0
            var speed = 0

            if buttonLabel == "Master" {
                control = "M"
                no = 1
                state = Int(mappedValues.last?["Master"] ?? "0") ?? 0
                speed = 0
            } else if buttonLabel.hasPrefix("F") {
                // Fan button (e.g., F1, F2)
                if let fanIndex = Int(buttonLabel.dropFirst()) {
                    control = "F"
                    no = fanIndex
                    mappedEntry = mappedValues.first(where: {
                        $0["FState"] != nil && $0["d_no"] == String(fanIndex)
                    })
                    state = Int(mappedEntry?["FState"] ?? "0") ?? 0
                    speed = Int(mappedEntry?["FSpeed"] ?? "0") ?? 0
                }
            } else {
                // Light-like button (e.g., L1, C1, O1, D1, Q1, Y1)
                let cNm = String(buttonLabel.prefix(1)) // L, C, O, etc.
                if let lightIndex = Int(buttonLabel.dropFirst()) {
                    control = "L"
                    no = lightIndex
                    mappedEntry = mappedValues.first(where: {
                        $0["cNm"] == cNm && $0["d_no"] == String(lightIndex)
                    })
                    state = Int(mappedEntry?["L_state"] ?? "0") ?? 0
                    speed = Int(mappedEntry?["L_speed"] ?? "0") ?? 0
                }
            }

            // Toggle state
            state = (state == 0) ? 1 : 0

            print("✅ Publishing: control=\(control), no=\(no), state=\(state), speed=\(speed)")
            publish_button(control: control, no: no, state: state, speed: speed)


        } else if collectionView == sHSceneCollectionView {
            let selectedScene = deviceScene[indexPath.item]
            let sceneNumber = selectedScene.sceneNo
            print("Selected Scene Number: \(sceneNumber)")
            sceneSet(control_no: sceneNumber)
        }


    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == ShButtonCollectionView {
            let numberOfColumns: CGFloat = 3
            let spacing: CGFloat = 10
            let totalSpacing = (numberOfColumns - 1) * spacing
            let itemWidth = (collectionView.frame.width - totalSpacing - 10) / numberOfColumns
            return CGSize(width: itemWidth, height: itemWidth)
        } else if collectionView == sHSceneCollectionView {
            return CGSize(width: 110, height: 35)
        }

      
        return CGSize(width: 50, height: 50)
    }

}
    


