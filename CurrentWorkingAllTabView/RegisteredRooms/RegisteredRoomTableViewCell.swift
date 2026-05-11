//
//  RegisteredRoomTableViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 23/06/25.
//

 

import UIKit
import SwiftKeychainWrapper
import AWSCore
import AWSIoT
import Alamofire



class RegisteredRoomTableViewCell: UITableViewCell {
    
    @IBOutlet weak var backgorundView: UIView!
    
    @IBOutlet weak var roomLabel: UILabel!
    @IBOutlet weak var engeryLabel: UILabel!
    
    @IBOutlet weak var DeviceNumberslabel: UILabel!
    
    @IBOutlet weak var deviceCollectionView: UICollectionView!
 
    weak var bottomSheetDelegate: BottomSheetActionDelegate?
    private var isGradientApplied = false

    var roomId : String?
    var loaderView: UIView?
    var showBottomSheet: (() -> Void)?

    var onSceneTapped: (() -> Void)?
    var onSceneSelected: ((String) -> Void)?
    var devices: [Device] = []
    var receivedDeviceStates: [DeviceStateArray] = []
    var ButtonList =  [ "Lights","curtains", "Scene" ,"Climate","Settings"]
    var buttonImages = [ "LightBulb", "curtain-filled", "Scene", "AcImage","deviceSetting"]
    
    @IBOutlet weak var roomView: UIView!
    
    
    @IBOutlet weak var roomMasterButtonImage: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        
        roomView.cornerRadius = 37.5
        
        roomView.clipsToBounds =  true
       
        backgorundView.cornerRadius =  15
        backgorundView.clipsToBounds = true
        roomView.cornerRadius = roomView.frame.height / 2
        roomView.clipsToBounds = true
        backgorundView.backgroundColor = UIColor.white.withAlphaComponent(0.10)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleRoomViewTap))
        roomView.addGestureRecognizer(tapGesture)
        roomView.isUserInteractionEnabled = true

       

        
        
        deviceCollectionView.borderWidth = 0.5
        deviceCollectionView.borderColor =  UIColor.white.withAlphaComponent(0.20)
        
        registerxib()
    }
    
    func configure(with room: Room, devices: [Device], energy: Double) {
        roomLabel.text = room.name
        roomId = room.roomId
        roomMasterButtonImage.image = UIImage(named: room.imageName) ?? UIImage(named: "default_image")
        DeviceNumberslabel.text = "\(devices.count) Devices"
        self.devices = devices
          print ("devices........\(devices)")
        engeryLabel.text = String(format: "%.2f kWh", energy)
        deviceCollectionView.reloadData()
        subscribeToAllDevices()
    }
    @objc private func handleRoomViewTap() {
        if isGradientApplied {
            removeGradientBorder(from: roomView)
            print("❌ Removed gradient border")
           
        } else {
            applyGradientBorder(to: roomView, colors: [UIColor.green.cgColor, UIColor.systemGreen.cgColor], width: 5)
            print("✅ Applied gradient border")
            
        }
        isGradientApplied.toggle()
        
        // ✅ Gather master values from devices in this room
        let masters = receivedDeviceStates.map { $0.master }

        guard !masters.isEmpty else {
            print("⚠️ No devices found for room")
            return
        }

        let hasZero = masters.contains(0)
        let hasOne = masters.contains(1)

        // ✅ Determine state to publish
        let finalState: Int
        if hasZero && hasOne {
            finalState = 1
        } else if hasOne && !hasZero {
            finalState = 0 // all ON → turn OFF
        } else {
            finalState = 1 // all OFF → turn ON
        }

        // ✅ Publish to each device in the room
        for device in devices {
            publish_button_to_topic(
                control: "M",
                no: 1,
                state: finalState,
                speed: 0,
                topic: device.uniqueId
            )
        }

        print("📤 Published M command with state = \(finalState) to \(devices.count) devices")
    }


    
 

    func showPleaseWaitPopup() {
        let loader = UIView(frame: self.window?.bounds ?? UIScreen.main.bounds)
        loader.backgroundColor = UIColor.black.withAlphaComponent(0.4)

        let activity = UIActivityIndicatorView(style: .large)
        activity.startAnimating()
        activity.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = "Please wait..."
        label.textColor = .white
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: [activity, label])
        stack.axis = .vertical
        stack.spacing = 10
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false

        loader.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: loader.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: loader.centerYAnchor)
        ])

        UIApplication.shared.keyWindow?.addSubview(loader)

        loaderView = loader
    }
    func hidePleaseWaitPopup() {
        loaderView?.removeFromSuperview()
        loaderView = nil
    }
     
    private func applyGradientBorder(to view: UIView, colors: [CGColor], width: CGFloat) {
        removeGradientBorder(from: view) // Clean any existing
        roomMasterButtonImage.tintColor =  .systemGreen
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = colors
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.frame = view.bounds
        gradientLayer.cornerRadius = view.layer.cornerRadius

        let shape = CAShapeLayer()
        shape.lineWidth = width
        shape.path = UIBezierPath(roundedRect: view.bounds, cornerRadius: view.layer.cornerRadius).cgPath
        shape.fillColor = UIColor.clear.cgColor
        shape.strokeColor = UIColor.black.cgColor

        gradientLayer.mask = shape
        gradientLayer.name = "GradientBorderLayer"

        view.layer.addSublayer(gradientLayer)
    }

    private func removeGradientBorder(from view: UIView) {
        view.layer.sublayers?.removeAll(where: { $0.name == "GradientBorderLayer" })
        roomMasterButtonImage.tintColor =  .white
    }

    
    private func updateRoomGradientBasedOnDeviceStates() {
        // Get all uniqueIds for devices in this room
        let roomDeviceIds = devices.map { $0.uniqueId }

        
        let matchingStates = receivedDeviceStates.filter { roomDeviceIds.contains($0.uniqueID) }

        // Check if all matched states have master == 1
        let allMastersAreOne = matchingStates.count == roomDeviceIds.count &&
                               matchingStates.allSatisfy { $0.master == 1 }

        if allMastersAreOne {
            applyGradientBorder(to: roomView, colors: [UIColor.green.cgColor, UIColor.systemGreen.cgColor], width: 5)
            isGradientApplied = true
           
            
        } else {
            removeGradientBorder(from: roomView)
            isGradientApplied = false
            roomMasterButtonImage.tintColor =  .white
        }
    }


    override func layoutSubviews() {
        super.layoutSubviews()
        
       
        if let _ = roomView.layer.sublayers?.first(where: { $0.name == "GradientBorderLayer" }) {
            applyGradientBorder(to: roomView, colors: [UIColor.green.cgColor, UIColor.systemGreen.cgColor], width: 5)
            roomMasterButtonImage.tintColor =  .systemGreen
        }
    }

    
    func subscribeToAllDevices() {
        for device in devices {
            print("🔔 Preparing to subscribe for device: \(device.deviceName) (\(device.uniqueId))")
            subscribeToTopic(for: device.uniqueId)
        }
    }

   

    
    
    
    func subscribeToTopic(for uniqueId: String) {
        let fullTopic = uniqueId + "/HA/E/ack"
        let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)

        print("📡 Subscribing to topic: \(fullTopic)")

        iotDataManager.subscribe(toTopic: fullTopic, qoS: .messageDeliveryAttemptedAtMostOnce) { [weak self] payload in
            guard let self = self else { return }
          
            guard let data = payload as? Data,
                  let stringValue = String(data: data, encoding: .utf8) else {
                print("⚠️ Unable to decode payload for topic: \(fullTopic)")
                return
            }

            print("📥 Received from \(fullTopic): \(stringValue)")

            guard let jsonData = stringValue.data(using: .utf8) else {
                print("⚠️ Invalid JSON string for topic: \(fullTopic)")
                return
            }

            do {
                let deviceState = try JSONDecoder().decode(DeviceStateArray.self, from: jsonData)

                DispatchQueue.main.async {
                    if let index = self.receivedDeviceStates.firstIndex(where: { $0.uniqueID == deviceState.uniqueID }) {
                        self.receivedDeviceStates[index] = deviceState
                    } else {
                        self.receivedDeviceStates.append(deviceState)
                       

                    }
                    self.deviceCollectionView.reloadData()
                    self.updateRoomGradientBasedOnDeviceStates()
                    if let prettyData = try? JSONEncoder().encode(deviceState),
                       let prettyString = String(data: prettyData, encoding: .utf8) {
                        print("🆕 Updated DeviceStateArray:\n\(prettyString)")
                    } else {
                        print("⚠️ Failed to encode updated device state.")
                    }
                   
                    
                }


            } catch {
                print("❌ JSON decode error for topic \(fullTopic): \(error)")
            }
        }

       
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.requestLatestDeviceState(topic: uniqueId)
            
        }
    }
    
    func requestLatestDeviceState(topic: String) {
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
                print("📤 Requesting latest state: \(jsonString)")

                let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
                iotDataManager.publishString(jsonString, onTopic: topic + "/HA/A/req", qoS: .messageDeliveryAttemptedAtMostOnce)
            }
        }
    }
    
    func registerxib()
    {
        let uiNib = UINib(nibName: "roomsDeviceCollectionViewCell", bundle: nil)
        deviceCollectionView.register(uiNib, forCellWithReuseIdentifier: "roomsDeviceCollectionViewCell")
        deviceCollectionView.delegate =  self
        deviceCollectionView.dataSource =  self
        
    }
    func publish_button_to_topic(control: String, no: Int, state: Int, speed: Int, topic: String) {
        let parameters: Parameters = [
            "control": control,
            "no": no,
            "state": state,
            "speed": speed,
            "from": "A",
            "topic": topic
        ]

        print("📤 Publishing to \(topic)/HA/A/req: \(parameters)")

        if let jsonData = try? JSONSerialization.data(withJSONObject: parameters, options: []),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            
            let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
            iotDataManager.publishString(jsonString, onTopic: topic + "/HA/A/req", qoS: .messageDeliveryAttemptedAtMostOnce)
        }
    }
    
    
    func publishScene(to uniqueId: String, controlNo: String) {
        let topic = uniqueId
        let scenePubParameters: [String: Any] = [
            "control": "scene_control",
            "no": Int(controlNo) ?? 0,
            "from": "A",
            "topic": topic
        ]

        if let theJSONData = try? JSONSerialization.data(withJSONObject: scenePubParameters, options: []),
           let theJSONText = String(data: theJSONData, encoding: .utf8) {

            print("📤 Publishing to \(topic)/HA/A/req:\n\(theJSONText)")
//            showPopupUpdate()
            let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
            iotDataManager.publishString(theJSONText, onTopic: topic + "/HA/A/req", qoS: .messageDeliveryAttemptedAtMostOnce)
        } else {
            print("❌ Failed to create JSON for device scene: \(uniqueId)")
        }
    }
   
    
    
}

 


extension RegisteredRoomTableViewCell: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return ButtonList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "roomsDeviceCollectionViewCell", for: indexPath) as! roomsDeviceCollectionViewCell

        let buttonTitle = ButtonList[indexPath.item]
        let imageName = buttonImages[indexPath.item]

        // 🔁 Pass both devices and receivedDeviceStates
        cell.configure(buttonTitle: buttonTitle,
                       imageName: imageName,
                       devices: devices,
                       deviceStates: receivedDeviceStates)
        
        

        return cell
    }


    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.isUserInteractionEnabled = false  

        let selectedButton = ButtonList[indexPath.item]
        print("🖱️ Collection cell tapped: \(selectedButton)")

        if selectedButton == "Scene" {
            onSceneTapped?()
        }else if  selectedButton == "Settings" {
           
            showBottomSheet?()
                
            }

        else if selectedButton == "Lights" {
            print("💡 Lights tapped: Preparing to publish individual 'L' controls")

            var allLightsAreOn = true
            guard !devices.isEmpty else {
                showNoDevicePopup()
                return
            }

               guard !receivedDeviceStates.isEmpty else {
                   print("⚠️ Device states not received yet")
                   return
               }

            for device in devices {
                guard let state = receivedDeviceStates.first(where: { $0.uniqueID == device.uniqueId }) else { continue }

                let cNm = state.cNm
                let cL = state.lightState
                let cM = state.cM
                var lightSpeed = state.lightSpeed

                guard cNm.count == cL.count else { continue }

                for (index, (cChar, lChar)) in zip(cNm.indices, zip(cNm, cL)) {
                    if cChar == "L" && lChar != "1" {
                        allLightsAreOn = false
                    }
                }

                
            }

            let targetState = allLightsAreOn ? 0 : 1

            for device in devices {
                guard let state = receivedDeviceStates.first(where: { $0.uniqueID == device.uniqueId }) else { continue }

                let cNm = state.cNm
                let cL = state.lightState
                let topic = device.uniqueId
                let lightSpeedString = state.lightSpeed  // ✅ Extract the string once per device

                guard cNm.count == cL.count else { continue }

                for (i, (cChar, _)) in zip(cNm.indices, zip(cNm, cL)) {
                    if cChar == "L" {
                        let no = cNm.distance(from: cNm.startIndex, to: i) + 1

                       
                        let index = cNm.distance(from: cNm.startIndex, to: i)
                        var speed = 0
                        if index < lightSpeedString.count {
                            let speedChar = lightSpeedString[lightSpeedString.index(lightSpeedString.startIndex, offsetBy: index)]
                            speed = Int(String(speedChar)) ?? 0
                        }

                        publish_button_to_topic(
                            control: "L",
                            no: no,
                            state: targetState,
                            speed: speed,
                            topic: topic
                        )
                    }
                }
            }

        }else if selectedButton == "curtains" {
            print("🪟 Curtains tapped: bidirectional toggle between 'O' and 'C'")

            for device in devices {
                guard let state = receivedDeviceStates.first(where: { $0.uniqueID == device.uniqueId }) else { continue }

                let cNm = state.cNm
                let lightState = state.lightState
                let topic = device.uniqueId
                let lightSpeed = state.lightSpeed

                guard cNm.count == lightState.count else { continue }

                // Find first 'O' and 'C' index
                if let oIndex = cNm.firstIndex(of: "O"),
                   let cIndex = cNm.firstIndex(of: "C") {

                    let oInt = cNm.distance(from: cNm.startIndex, to: oIndex)
                    let cInt = cNm.distance(from: cNm.startIndex, to: cIndex)

                    let oState = lightState[lightState.index(lightState.startIndex, offsetBy: oInt)]
                    let cState = lightState[lightState.index(lightState.startIndex, offsetBy: cInt)]

                    // O == "1" → send to C's index
                    if oState == "1" {
                        let speedChar = lightSpeed.count > cInt
                            ? lightSpeed[lightSpeed.index(lightSpeed.startIndex, offsetBy: cInt)]
                            : "0"
                        let speed = Int(String(speedChar)) ?? 0

                        publish_button_to_topic(
                            control: "L",
                            no: cInt + 1,
                            state: 1,
                            speed: speed,
                            topic: topic
                        )

                        print("🪟 O is 1 → Sent to C → no: \(cInt + 1), state: 1, speed: \(speed)")
                    }

                    // C == "1" → send to O's index
                    if cState == "1" {
                        let speedChar = lightSpeed.count > oInt
                            ? lightSpeed[lightSpeed.index(lightSpeed.startIndex, offsetBy: oInt)]
                            : "0"
                        let speed = Int(String(speedChar)) ?? 0

                        publish_button_to_topic(
                            control: "L",
                            no: oInt + 1,
                            state: 1,
                            speed: speed,
                            topic: topic
                        )

                        print("🪟 C is 1 → Sent to O → no: \(oInt + 1), state: 1, speed: \(speed)")
                    }
                }
            }
        }


       
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            collectionView.isUserInteractionEnabled = true
        }
        
    }

    func showNoDevicePopup() {
        let alert = UIAlertController(
            title: "No Devices",
            message: "There are no devices in this room.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        if let vc = UIApplication.shared.keyWindow?.rootViewController {
            vc.present(alert, animated: true)
        }
    }


    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
       
        let rightInset: CGFloat = 8
        let spacing: CGFloat = 8
        let columns: CGFloat = 5

        let totalSpacing =  rightInset + spacing * (columns - 1)
        let availableWidth = collectionView.bounds.width - totalSpacing
        let cellWidth = availableWidth / columns

        return CGSize(width: cellWidth, height: 80)
    }
    
   

}

