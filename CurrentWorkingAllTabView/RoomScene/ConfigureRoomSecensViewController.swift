//
//  ConfigureRoomSecensViewController.swift
//  SkromanIsra
//
//  Created by Admin on 18/08/25.
//

import UIKit
import Alamofire
import AWSCore
import AWSIoT



class ConfigureRoomSecensViewController: UIViewController {
    
    var sceneName : String?
    var sceneIndex: Int?
    var sceneIconName: String?
    
    @IBOutlet weak var selectedsceneView: UIView!
    
    @IBOutlet weak var sceneIamgeview: UIView!
    
    @IBOutlet weak var sceneImage: UIImageView!
    
    
    @IBOutlet weak var selecetedScenename: UILabel!
    
    @IBOutlet weak var deviceTableView: UITableView!
    var devices: [Device] = []
    var receivedDeviceStates: [DeviceStateArray] = []
    var expandedIndexPath: IndexPath? = nil
    var deviceSwitches: [String: [SwitchItem]] = [:]  // uniqueId → switches

 

    override func viewDidLoad() {
        super.viewDidLoad()

        selectedsceneView.backgroundColor =  UIColor.white.withAlphaComponent(0.15)
        selectedsceneView.cornerRadius =  10
        selectedsceneView.clipsToBounds =  true
        sceneIamgeview.cornerRadius =  10
        sceneIamgeview.clipsToBounds =  true
        
        sceneIamgeview.backgroundColor =  UIColor.white.withAlphaComponent(0.20)
        selecetedScenename.text =  sceneName
        if let iconName = sceneIconName {
               sceneImage.image = UIImage(named: iconName)
           }
        
        for device in devices {
            let details = fetchButtonDetails(uniqueId: device.uniqueId)
            if let state = receivedDeviceStates.first(where: { $0.uniqueID == device.uniqueId }) {
                let switches = createSwitches(from: state, buttonDetails: details)
                deviceSwitches[device.uniqueId] = switches
            }
        }
        for device in devices {
            let deviecScene = SkromanIsraDatabaseHelper.shared.fetchScenesByUniqueId(uniqueId: device.uniqueId)
            print("device at scene\(deviecScene)")
        }

        print("✅ Final switchList: \(deviceSwitches)")
        print ("devices at roomscene.......\(devices)")
        print ("receivedDeviceStates at roomscene....\(receivedDeviceStates)")
        registerFile()
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
    
    
    @IBAction func ViewSceneButton(_ sender: Any) {
        if let sceneVc = navigationController?.storyboard?.instantiateViewController(
            withIdentifier: "ViewRoomSceneViewController"
        ) as? ViewRoomSceneViewController {
            sceneVc.devices =  devices
            sceneVc.sceneIndex =  sceneIndex
          
            
            self.navigationController?.pushViewController(sceneVc, animated: true)
        }
    }

    
    
    @IBAction func editSceneButton(_ sender: Any) {
        
        if let editVC = storyboard?.instantiateViewController(withIdentifier: "EditRoomsSceneViewController") as? EditRoomsSceneViewController {
            editVC.devices =  devices
            editVC.sceneIndex =  sceneIndex
            navigationController?.pushViewController(editVC, animated: true)
        }
    }
    func registerFile(){
        let uinib =  UINib(nibName: "ConfigureRoomSecensTableViewCell", bundle: nil)
        deviceTableView.register(uinib, forCellReuseIdentifier: "ConfigureRoomSecensTableViewCell")
        deviceTableView.dataSource =  self
        deviceTableView.delegate =  self
        
    }
    
    func fetchButtonDetails(uniqueId: String) -> [ButtonDetails] {
        return SkromanIsraDatabaseHelper.shared.fetchButtonDetails(uniqueId: uniqueId)
    }
    
    @IBAction func sumbitSceneButton(_ sender: Any) {
        guard let sceneName = sceneName,
              let sceneIndex = sceneIndex else {
            print("❌ Missing scene name or index")
            return
        }

        let finalSceneNo = String(sceneIndex + 1)

        for device in devices {
            guard let deviceState = receivedDeviceStates.first(where: { $0.uniqueID == device.uniqueId }) else {
                print("⚠️ No state found for device \(device.uniqueId)")
                continue
            }

            if deviceState.series == "AVR_V9_NORMAL" {
                if let index = devices.firstIndex(where: { $0.uniqueId == device.uniqueId }),
                   let cell = deviceTableView.cellForRow(at: IndexPath(row: index, section: 0)) as? ConfigureRoomSecensTableViewCell {

                    let (redundantL, redundantF) = cell.buildRedundantStrings()
                    self.sendSceneRedundantPayload(for: device, redundantL: redundantL, redundantF: redundantF)

                    let existingScenes = SkromanIsraDatabaseHelper.shared.fetchScenesByUniqueId(uniqueId: device.uniqueId)

                    print("🎯 finalSceneNo: \(finalSceneNo)")
                    for scene in existingScenes {
                        print("🔹 DB Scene No: \(scene.sceneNo)")
                    }

                    if let existingScene = existingScenes.first(where: { "\($0.sceneNo)" == finalSceneNo }) {
                        print("✅ Updating existing scene \(existingScene.sceneNo)")
                        updateScene(device: device,
                                    deviceState: deviceState,
                                    sceneNo: finalSceneNo,
                                    sceneName: sceneName,
                                    sceneId: existingScene.sceneId,
                                    L_redundant: redundantL,
                                    F_redundant: redundantF)
                    } else {
                        print("🆕 Adding new scene \(finalSceneNo)")
                        AddScene(device: device,
                                 deviceState: deviceState,
                                 sceneNo: finalSceneNo,
                                 sceneName: sceneName,
                                 L_redundant: redundantL,
                                 F_redundant: redundantF)
                    }
                }

            } else {
                let existingScenes = SkromanIsraDatabaseHelper.shared.fetchScenesByUniqueId(uniqueId: device.uniqueId)

                if let existingScene = existingScenes.first(where: { "\($0.sceneNo)" == finalSceneNo }) {
                    updateScene(device: device,
                                deviceState: deviceState,
                                sceneNo: finalSceneNo,
                                sceneName: sceneName,
                                sceneId: existingScene.sceneId)
                } else {
                    AddScene(device: device,
                             deviceState: deviceState,
                             sceneNo: finalSceneNo,
                             sceneName: sceneName)
                }
            }
        }

    }



  
    
    
    func createSwitches(from deviceState: DeviceStateArray, buttonDetails: [ButtonDetails]) -> [SwitchItem] {
        var switches: [SwitchItem] = []
        let lightRelevantChars: [Character] = ["L", "O", "C", "D", "Q", "Y"]

        // ------------------------
        // 1️⃣ Create LIGHT switches
        // ------------------------
        let lightButtons = buttonDetails.filter { lightRelevantChars.contains(Character($0.buttonControlName ?? "")) }

        for (index, char) in deviceState.cNm.enumerated() {
            guard lightRelevantChars.contains(char),
                  index < deviceState.lightState.count,
                  index < deviceState.cL.count else { continue }

            let isOn = deviceState.lightState[deviceState.lightState.index(deviceState.lightState.startIndex, offsetBy: index)] == "1" ? 1 : 0
            let isChildLocked = deviceState.cL[deviceState.cL.index(deviceState.cL.startIndex, offsetBy: index)] == "1" ? 1 : 0

            let configDimChar = index < deviceState.cDim.count
                ? String(deviceState.cDim[deviceState.cDim.index(deviceState.cDim.startIndex, offsetBy: index)])
                : nil

            let speedChar = index < deviceState.lightSpeed.count
                ? String(deviceState.lightSpeed[deviceState.lightSpeed.index(deviceState.lightSpeed.startIndex, offsetBy: index)])
                : nil

            let buttonDetail = lightButtons.count > index ? lightButtons[index] : nil

            switches.append(SwitchItem(
                name: "L\(index + 1)",
                type: .light,
                switchIndex: index + 1,
                isOnState: isOn,
                isChildLocked: isChildLocked,
                speed: speedChar,
                uniqueID: deviceState.uniqueID,
                buttonDetail: buttonDetail,
                configDim: configDimChar,
                destButton: index + 1,
                fanDest: nil,
                isShortcut: buttonDetail?.isShortcut, rRegulator: deviceState.rRegulator
            ))
        }

        // ---------------------
        // 2️⃣ Create FAN switches (match buttonControlName == "F")
        // ---------------------
        let fanButtons = buttonDetails
            .filter { $0.buttonControlName == "F" }
            .sorted { $0.buttonNo < $1.buttonNo }

        for (index, fanChar) in deviceState.fanState.enumerated() {
            let isOn = fanChar == "1" ? 1 : 0

            let speedChar = index < deviceState.fanSpeed.count
                ? String(deviceState.fanSpeed[deviceState.fanSpeed.index(deviceState.fanSpeed.startIndex, offsetBy: index)])
                : nil

            let isChildLocked = index < deviceState.cF.count
                ? (deviceState.cF[deviceState.cF.index(deviceState.cF.startIndex, offsetBy: index)] == "1" ? 1 : 0)
                : 0

            let buttonDetail = fanButtons.count > index ? fanButtons[index] : nil

            switches.append(SwitchItem(
                name: "F\(index + 1)",
                type: .fan,
                switchIndex: index + 1,
                isOnState: isOn,
                isChildLocked: isChildLocked,
                speed: speedChar,
                uniqueID: deviceState.uniqueID,
                buttonDetail: buttonDetail,
                configDim: nil,
                destButton: nil,
                fanDest: index + 1,
                isShortcut: buttonDetail?.isShortcut, rRegulator: deviceState.rRegulator
            ))
        }

        // -------------------------
        // 3️⃣ Create MASTER switch
        // -------------------------
        if let masterChar = deviceState.cM.first {
            let isOn = (deviceState.master == 1) ? 1 : 0
            let isChildLocked = (masterChar == "1") ? 1 : 0
            let masterButton = buttonDetails.first { $0.buttonControlName == "M" }

            switches.append(SwitchItem(
                name: "Master",
                type: .master,
                switchIndex: 1,
                isOnState: isOn,
                isChildLocked: isChildLocked,
                speed: nil,
                uniqueID: deviceState.uniqueID,
                buttonDetail: masterButton,
                configDim: nil,
                destButton: nil,
                fanDest: nil,
                isShortcut: masterButton?.isShortcut, rRegulator: deviceState.rRegulator
            ))
        }

        debugLog("✅ All switches created: \(switches)")
        return switches
    }
    
    
    func AddScene(device: Device,
                  deviceState: DeviceStateArray,
                  sceneNo: String,
                  sceneName: String,
                  L_redundant: String? = nil,
                  F_redundant: String? = nil) {

        var scene_params: Parameters = [
            "deviceUid": device.deviceUid,
            "homeId": device.homeId,
            "roomId": device.roomId,
            "unique_id": device.uniqueId,
            "modelNo": device.deviceModelNo,
            "devicetype": device.deviceType,
            "sceneNo": sceneNo,
            "sceneName": sceneName,
            "fan_dest": "1",
            "dest_button": deviceState.deviceNumber,
            "config_dim": deviceState.cDim,
            "config_buttons": deviceState.cNm,
            "L_state": deviceState.lightState,
            "L_speed": deviceState.lightSpeed,
            "F_state": deviceState.fanState,
            "F_speed": deviceState.fanSpeed
        ]

        // ✅ Add redundant keys if provided
        if let L_redundant = L_redundant { scene_params["L_redundant"] = L_redundant }
        if let F_redundant = F_redundant { scene_params["F_redundant"] = F_redundant }

        print("✅ scene_params for API: \(scene_params)")

        AF.request("http://3.7.18.55:3000/skroman/scene",
                   method: .post,
                   parameters: scene_params,
                   encoding: JSONEncoding.default).response { response in
            debugPrint(response)
            switch response.result {
            case .success(let data):
                do {
                    if let jsonOne = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary {
                        print("📥 API Response: \(jsonOne)")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            self.showPopupAdd()
                        }
                    }
                } catch {
                    print("❌ JSON Error: \(error.localizedDescription)")
                }
            case .failure(let err):
                print("❌ API Error: \(err.localizedDescription)")
            }
        }.resume()
    }


    func updateScene(device: Device,
                     deviceState: DeviceStateArray,
                     sceneNo: String,
                     sceneName: String,
                     sceneId: String,
                     L_redundant: String? = nil,
                     F_redundant: String? = nil) {

        var scene_params: Parameters = [
            "sceneId": sceneId,
            "deviceUid": device.deviceUid,
            "homeId": device.homeId,
            "roomId": device.roomId,
            "unique_id": device.uniqueId,
            "modelNo": device.deviceModelNo,
            "devicetype": device.deviceType,
            "sceneNo": sceneNo,
            "sceneName": sceneName,
            "fan_dest": "1",
            "dest_button": deviceState.deviceNumber,
            "config_dim": deviceState.cDim,
            "config_buttons": deviceState.cNm,
            "L_state": deviceState.lightState,
            "L_speed": deviceState.lightSpeed,
            "F_state": deviceState.fanState,
            "F_speed": deviceState.fanSpeed
        ]

        if let L_redundant = L_redundant { scene_params["L_redundant"] = L_redundant }
        if let F_redundant = F_redundant { scene_params["F_redundant"] = F_redundant }

        print("Scene Update Parameters: \(scene_params)")

        AF.request("http://3.7.18.55:3000/skroman/sceneupdate",
                   method: .put,
                   parameters: scene_params,
                   encoding: JSONEncoding.default).response { response in
            debugPrint(response)
            switch response.result {
            case .success(let data):
                do {
                    if let data = data,
                       let jsonOne = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? NSDictionary {
                        print("jsonOne scene update ->", jsonOne)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { self.showPopupUpdate() }
                    }
                } catch {
                    print("JSON Parsing Error: \(error.localizedDescription)")
                }
            case .failure(let error):
                print("Request Failed: \(error.localizedDescription)")
            }
        }.resume()
    }

    
    func publishScene(topic: String, sceneNo: String) {
        let scene_pub_parameters: Parameters = [
            "control": "scene_config",
            "no": Int(sceneNo),
            "from": "A",
            "topic": topic
        ]
        
        print("📡 Publishing Scene Payload \(scene_pub_parameters)")
        
        if let theJSONData = try? JSONSerialization.data(withJSONObject: scene_pub_parameters, options: []),
           let theJSONText = String(data: theJSONData, encoding: .utf8) {
            
            print("📡 JSON scene string = \(theJSONText)")
            
            let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
            
            iotDataManager.publishString(
                theJSONText,
                onTopic: topic + "/HA/A/req",
                qoS: .messageDeliveryAttemptedAtMostOnce
            )
        }
    }
    
    @objc func showPopupAdd() {
        showPopupPresenter.showPopup1(
            on: self.view,
            animationName: "coffee 2",
            title: "scene Set",
            subtitle: "Secen add successfully."
        )
    }
    @objc func showPopupUpdate() {
        showPopupPresenter.showPopup1(
            on: self.view,
            animationName: "coffee 2",
            title: "scene Update",
            subtitle: "Secen Updated successfully."
        )
    }

   
}

extension  ConfigureRoomSecensViewController : UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       return devices.count
       
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ConfigureRoomSecensTableViewCell", for: indexPath) as! ConfigureRoomSecensTableViewCell
        let device = devices[indexPath.row]
       
            
        if let matchingState = receivedDeviceStates.first(where: { $0.uniqueID == device.uniqueId }) {
               cell.receivedDeviceStates = [matchingState]
           } else {
               cell.receivedDeviceStates = []
           }
           
            
        cell.deviceNameLabel.text = device.uniqueId
        cell.device = device
        cell.delegate =  self
        cell.switches = deviceSwitches[device.uniqueId] ?? []
        cell.sceneButtonCollectionView.reloadData()


        return cell
    }


    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if expandedIndexPath == indexPath {
            // Collapse if already expanded
            expandedIndexPath = nil
        } else {
            // Expand tapped cell
            expandedIndexPath = indexPath
        }
        
       
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if expandedIndexPath == indexPath {
            return 450 
        } else {
            return 60
        }
    }

    
}


extension ConfigureRoomSecensViewController: ConfigureRoomSecensTableViewCellDelegate {
    func sendSceneRedundantPayload(for device: Device, redundantL: String, redundantF: String) {
        let topic = device.uniqueId
     
       guard  let sceneIndex = sceneIndex else {
      print("❌ Missing scene name or index")
      return
  }
        let finalSceneNo = sceneIndex + 1
        
        let payload: [String: Any] = [
            "control": "scene_redundant",
            "no": finalSceneNo ,
            "redundant_l": redundantL,
            "redundant_f": redundantF,
            "from": "A",
            "topic": topic
        ]
        
        if let theJSONData = try? JSONSerialization.data(withJSONObject: payload, options: []),
           let theJSONText = String(data: theJSONData, encoding: .utf8) {
            
            print("📡 JSON scene string = \(theJSONText)")
            
            let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
            
            iotDataManager.publishString(
                theJSONText,
                onTopic: topic + "/HA/A/req",
                qoS: .messageDeliveryAttemptedAtMostOnce
            )
        }
    }
}
