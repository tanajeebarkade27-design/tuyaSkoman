import UIKit
import DropDown
import Alamofire
import AVFoundation
 import SwiftKeychainWrapper


class ScanQRViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate, UITextFieldDelegate{

    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var sacnnerbuuton: UIButton!
    @IBOutlet weak var manuallButton: UIButton!
    @IBOutlet weak var scannerView: UIView!
    @IBOutlet weak var manualView: UIView!
    @IBOutlet weak var HomeNameLabel: UILabel!
    @IBOutlet weak var roomNamelabel: UILabel!
    @IBOutlet weak var uniqueIdText: NoSelectTextField!
    @IBOutlet weak var POPtextField: NoSelectTextField!
    @IBOutlet weak var DropDownType: UIView!
    @IBOutlet weak var modelDropDown: UIView!
    
    @IBOutlet weak var scannerImageView: UIImageView!
    @IBOutlet weak var buttonstackView: UIStackView!
    @IBOutlet weak var selectedModelName: UILabel!
    @IBOutlet weak var selectedTypeName: UILabel!
    
    @IBOutlet weak var backgroundimage: UIImageView!
    
    var raw_topic: String?
    var ble_pop: String?
    var type: String?
    var module: String?
    var esp_no: String?
    var client: String?
    var version : String?
    var uniqueId: String?
    
    @IBOutlet weak var scannerbackgroundView: UIView!
    var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var versionType: String?
    var roomId: String?
    var homeId: String?
    var roomName: String?
    var homeName: String?
    var userID : String!
    var deviceTypeArray = ["Switch Box", "Mood Switch", "Manual Box", "IR Blaster", "Human Detector"]
    
    // Model list will be updated based on selected type.
    var modelTypeArray: [String] = []
    
    private let modelsByType: [String: [String]] = [
        "Manual Box": ["11000", "22000", "33000", "44000", "66000", "88000"],
        "Mood Switch": ["13000"],
        "Switch Box": ["23000", "20000", "33010", "34000", "44010", "45000",
                       "46000", "65010", "67000", "66010", "68000",
                       "87010", "89000", "88010", "80000", "88020"],
        "IR Blaster": ["11111"],
        "Human Detector": ["22222"]
    ]

    let modelDropdown = DropDown()
    let typeDropdown = DropDown()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        backgroundimage.contentMode = .scaleAspectFill
        backgroundimage.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            backgroundimage.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundimage.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundimage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundimage.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    
        //""scannerbackgroundView.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        scannerbackgroundView.cornerRadius = 15
        backButton.setTitle("", for: .normal)
        scannerView.isHidden = false
        manualView.isHidden = true

        setupModelDropDown()
        setupTypeDropDown()
        
        // Ensure selected labels are visible on dark UI
        selectedModelName.textColor = .white
        selectedTypeName.textColor = .white
        selectedModelName.text = selectedModelName.text ?? ""
        selectedTypeName.text = selectedTypeName.text ?? ""
        
        setupQRScanner()
        DispatchQueue.global(qos: .background).async {
                self.captureSession?.startRunning()
            }
        print("versionType is \(versionType ?? "N/A")")
        
        let savedUserID = KeychainWrapper.standard.string(forKey: "userId")
        print("Saved User ID : =====", savedUserID!)
        
        if savedUserID != nil {
            
            userID = savedUserID
        }
        
        uniqueIdText.delegate = self
        POPtextField.delegate = self
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Keep camera preview sized correctly.
        previewLayer?.frame = scannerView.bounds
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        UIMenuController.shared.hideMenu()
    }
    func setupUI() {

        // TextFields
        uniqueIdText.layer.cornerRadius = 8
        POPtextField.layer.cornerRadius = 8

        uniqueIdText.layer.borderWidth = 1
        POPtextField.layer.borderWidth = 1

        

        uniqueIdText.clipsToBounds = true
        POPtextField.clipsToBounds = true

        // Dropdown Views
        DropDownType.layer.cornerRadius = 8
        modelDropDown.layer.cornerRadius = 8

        DropDownType.layer.borderWidth = 1
        modelDropDown.layer.borderWidth = 1

      

        DropDownType.clipsToBounds = true
        modelDropDown.clipsToBounds = true
        
        // Modern capsule style
        uniqueIdText.applyCapsuleStyle(height: 44, textColor: UIColor.white)
        POPtextField.applyCapsuleStyle(height: 44, textColor: UIColor.white)

        // Placeholder Color
        uniqueIdText.attributedPlaceholder = NSAttributedString(
            string: "Enter Unique ID",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.white.withAlphaComponent(0.6)]
        )

        POPtextField.attributedPlaceholder = NSAttributedString(
            string: "Enter POP",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.white.withAlphaComponent(0.6)]
        )
        
        // Scanner UI polish
        scannerView.layer.cornerRadius = 18
        scannerView.clipsToBounds = true
        scannerView.layer.borderWidth = 1
        scannerView.layer.borderColor = UIColor.white.withAlphaComponent(0.12).cgColor
        
        // Frame/overlay image styling
        scannerImageView.layer.cornerRadius = 18
        scannerImageView.clipsToBounds = true
        scannerImageView.layer.borderWidth = 1.5
        scannerImageView.layer.borderColor = UIColor.systemYellow.withAlphaComponent(0.75).cgColor
        scannerImageView.backgroundColor = UIColor.clear
        
        // Background card styling
        scannerbackgroundView.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        scannerbackgroundView.layer.cornerRadius = 16
        scannerbackgroundView.layer.shadowColor = UIColor.black.cgColor
        scannerbackgroundView.layer.shadowOpacity = 0.25
        scannerbackgroundView.layer.shadowRadius = 10
        scannerbackgroundView.layer.shadowOffset = CGSize(width: 0, height: 6)
        scannerbackgroundView.layer.masksToBounds = false
    }
    
    func setupQRScanner() {
           captureSession = AVCaptureSession()

           guard let videoCaptureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
               print("No camera found")
               return
           }

           do {
               let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
               if captureSession!.canAddInput(videoInput) {
                   captureSession!.addInput(videoInput)
               } else {
                   print("Failed to add input")
                   return
               }
           } catch {
               print("Error accessing camera: \(error)")
               return
           }

           let metadataOutput = AVCaptureMetadataOutput()
           if captureSession!.canAddOutput(metadataOutput) {
               captureSession!.addOutput(metadataOutput)
               metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
               metadataOutput.metadataObjectTypes = [.qr]
           } else {
               print("Failed to add metadata output")
               return
           }

           previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
           previewLayer!.frame = scannerView.layer.bounds
           previewLayer!.videoGravity = .resizeAspectFill
           scannerView.layer.addSublayer(previewLayer!)

           // Start capture session in the background
           DispatchQueue.global(qos: .background).async {
               self.captureSession?.startRunning()
           }
       }

       // MARK: - QR Code Detection
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
           if let metadataObject = metadataObjects.first,
              let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
              let qrCodeValue = readableObject.stringValue {

               print("Scanned QR Code: \(qrCodeValue)")

               // Convert JSON String to Struct
               if let jsonData = qrCodeValue.data(using: .utf8) {
                   do {
                       if versionType == "skroman_new" {
                           let qrData = try JSONDecoder().decode(NewDeviceData.self, from: jsonData)
                           updateUIWithNewDeviceData(qrData)
                       } else  if versionType == "skroman_old"{
                           let qrData = try JSONDecoder().decode(OldDeviceData.self, from: jsonData)
                           updateUIWithOldDeviceData(qrData)
                       }
                       else {
                           
                       }
                   }
                       catch let DecodingError.dataCorrupted(context) {
                           print("❌ Data corrupted:", context.debugDescription)
                           print("codingPath:", context.codingPath)
                       } catch let DecodingError.keyNotFound(key, context) {
                           print("❌ Missing key:", key.stringValue, "in", context.debugDescription)
                           print("codingPath:", context.codingPath)
                       } catch let DecodingError.typeMismatch(type, context) {
                           print("❌ Type mismatch for type:", type, "in", context.debugDescription)
                           print("codingPath:", context.codingPath)
                       } catch let DecodingError.valueNotFound(value, context) {
                           print("❌ Value not found for:", value, "in", context.debugDescription)
                           print("codingPath:", context.codingPath)
                       } catch {
                           print("❌ Other decoding error:", error)
                       }

                   
               }

               captureSession?.stopRunning()
               DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                   self.addDevice()
               }
           }
       }

       // MARK: - UI Update Methods
       func updateUIWithNewDeviceData(_ data: NewDeviceData) {
           DispatchQueue.main.async {
               self.module = data.module
               self.type = data.type
               self.uniqueId = data.raw_topic
               self.ble_pop = data.ble_pop
               
               
           }
       }

       func updateUIWithOldDeviceData(_ data: OldDeviceData) {
           DispatchQueue.main.async {
               self.module = data.ModelNo
               self.type = data.DeviceType
               self.uniqueId = data.unique_id
               self.ble_pop = data.POP
               
           }
       }
    func setupModelDropDown() {
        modelDropdown.anchorView = modelDropDown
        modelDropdown.dataSource = modelTypeArray
        modelDropdown.direction = .bottom

        modelDropdown.backgroundColor = UIColor(white: 0.10, alpha: 1.0)
        modelDropdown.selectionBackgroundColor = UIColor.white.withAlphaComponent(0.12)
        modelDropdown.textColor = .white
        modelDropdown.selectedTextColor = .white
        modelDropdown.separatorColor = UIColor.white.withAlphaComponent(0.10)
        modelDropdown.layer.cornerRadius = 12
        modelDropdown.layer.masksToBounds = true
        modelDropdown.clipsToBounds = true
        modelDropdown.customCellConfiguration = { _, _, cell in
            cell.optionLabel.textColor = .white
            cell.optionLabel.backgroundColor = .clear
        }

        modelDropdown.selectionAction = { [weak self] (index: Int, item: String) in
            self?.selectedModelName.text = item
            self?.selectedModelName.textColor = .white
        }

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(showModelDropdown))
        modelDropDown.addGestureRecognizer(tapGesture)
    }
    
    func setupTypeDropDown() {
        typeDropdown.anchorView = DropDownType
        typeDropdown.dataSource = deviceTypeArray
        typeDropdown.direction = .bottom

        typeDropdown.backgroundColor = UIColor(white: 0.10, alpha: 1.0)
        typeDropdown.selectionBackgroundColor = UIColor.white.withAlphaComponent(0.12)
        typeDropdown.textColor = .white
        typeDropdown.selectedTextColor = .white
        typeDropdown.separatorColor = UIColor.white.withAlphaComponent(0.10)
        typeDropdown.layer.cornerRadius = 12
        typeDropdown.layer.masksToBounds = true
        typeDropdown.customCellConfiguration = { _, _, cell in
            cell.optionLabel.textColor = .white
            cell.optionLabel.backgroundColor = .clear
        }

        typeDropdown.selectionAction = { [weak self] (index: Int, item: String) in
            guard let self else { return }
            self.selectedTypeName.text = item
            self.selectedTypeName.textColor = .white
            
            // Update models based on selected type
            self.modelTypeArray = self.modelsByType[item] ?? []
            self.modelDropdown.dataSource = self.modelTypeArray
            self.selectedModelName.text = self.modelTypeArray.first ?? ""
            self.selectedModelName.textColor = .white
        }

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(showTypeDropdown))
        DropDownType.addGestureRecognizer(tapGesture)
    }
    
    @objc func showModelDropdown() {
        modelDropdown.show()
    }
    
    @objc func showTypeDropdown() {
        typeDropdown.show()
    }
    
    @IBAction func backButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }

    @IBAction func ScanQRButton(_ sender: Any) {
        scannerView.isHidden = false
        manualView.isHidden = true
        
        DispatchQueue.global(qos: .background).async {
            self.captureSession?.startRunning()
        }

        manuallButton.tintColor = .white
        sacnnerbuuton.tintColor = .gray
    }

    @IBAction func manualAddButton(_ sender: Any) {
        manualView.isHidden = false
        scannerView.isHidden = true
        manuallButton.tintColor = .gray
            sacnnerbuuton.tintColor = .white
    }

    @IBAction func NextButton(_ sender: Any) {
        let uniqueIdManual = uniqueIdText.text ?? ""
        let popManual = POPtextField.text ?? ""
        let modelManual = selectedModelName.text ?? ""
        let typeManual = selectedTypeName.text ?? ""

        if uniqueIdManual.isEmpty || popManual.isEmpty || modelManual.isEmpty || typeManual.isEmpty {
            showAlert(title: "Error", message: "Please fill all fields before proceeding.")
            return
        }

        // Save to properties for reuse
        self.uniqueId = uniqueIdManual
        self.ble_pop = popManual
        self.module = modelManual
        self.type = typeManual

        addDevice()
       // verifyIfExistingDevice(unique_id: uniqueIdManual, pop: popManual, model: modelManual, type: typeManual)
    }

    
    func addDevice() {
        let parameters: [String: Any] = [
            "roomId": roomId ?? "",
            "homeId": homeId ?? "",
            "unique_id": uniqueId ?? "",
            "POP": ble_pop ?? "",
            "userId": userID ?? "",
            "deviceName": "SwitchBox",
            "deviceMacAddress": "deviceMacAddress",
            "deviceType": type ?? "",
            "deviceModelNo": module ?? "",
            "connectedSsid": "NA",
            "connectedPassword": "NA",
            "deviceCategory": versionType ?? "",
            "deviceDimmingType": "zcd"
        ]

        print("📤 Sending Device Add API with: \(parameters)")

        AF.request("http://3.7.18.55:3000/skroman/deviceapi/device",
                   method: .post,
                   parameters: parameters,
                   encoding: JSONEncoding.default,
                   headers: nil).response { response in

            print("📥 Response Status: \(response.response?.statusCode ?? 0)")

            switch response.result {
            case .success(let data):
                if let data = data,
                   let jsonResponse = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    print("✅ Add Device Response: \(jsonResponse)")

                    if let msg = jsonResponse["msg"] as? String {
                        DispatchQueue.main.async {
                            if msg.lowercased() == "success" {
                                self.showAlert(title: "Success", message: msg)

                                let deviceUid = UUID().uuidString
                                let roomId = self.roomId ?? ""
                                let homeId = self.homeId ?? ""
                                let userId = self.userID ?? ""
                                let deviceName = self.type ?? ""
                                let uniqueId = self.uniqueId ?? ""
                                let pop = self.ble_pop ?? ""
                                let model = self.module ?? ""
                                let dimmingType = "zcd"
                                let deviceType = self.type ?? ""
                                let ssid = "NA"
                                let password = "NA"
                                let category = self.versionType ?? ""



                                SkromanIsraDatabaseHelper.shared.insertDevice(
                                    deviceUid: deviceUid,
                                    roomId: roomId,
                                    homeId: homeId,
                                    userId: userId,
                                    deviceName: deviceName,
                                    uniqueId: uniqueId,
                                    POP: pop,
                                    deviceModelNo: model,
                                    deviceDimmingType: dimmingType,
                                    deviceType: deviceType,
                                    connectedSsid: ssid,
                                    connectedPassword: password,
                                    deviceCategory: category
                                )
                                
                                self.SyncPostData()
                            } else if msg.lowercased().contains("deivice is already exists.") {
                                self.showAlert(title: "Alert", message: msg)
                            } else {
                                self.showAlert(title: "Success", message: msg)
                            }
                        }
                    }
                } else {
                    print("❌ Invalid response format.")
                }

            case .failure(let error):
                print("❌ Failed to add device: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.showAlert(title: "Error", message: "Failed to add device.")
                }
            }
        }
    }



    
}




extension ScanQRViewController {

    func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.SyncPostData()
            }
            if let navController = self.navigationController {
                // If already in a navigation stack, go back or push
                for controller in navController.viewControllers {
                    if controller is MainHomeViewController {
                        navController.popToViewController(controller, animated: true)
                        return
                    }
                }
              
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                if let homeVC = storyboard.instantiateViewController(withIdentifier: "MainHomeViewController") as? MainHomeViewController {
                    
                    navController.pushViewController(homeVC, animated: true)
                }
            } else {
                // If not using navigation controller, present modally
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                if let homeVC = storyboard.instantiateViewController(withIdentifier: "MainHomeViewController") as? MainHomeViewController {
                     
                    homeVC.modalPresentationStyle = .fullScreen
                    self.present(homeVC, animated: true, completion: nil)
                }
            }
        }

        alertController.addAction(okAction)

        DispatchQueue.main.async {
            self.present(alertController, animated: true, completion: nil)
        }
    }
}




struct NewDeviceData: Decodable {
    let raw_topic: String
    let ble_pop: String
    let type: String
    let module: String
    let esp_no: String
    let client: String?
    let version: String?
    
    enum CodingKeys: String, CodingKey {
        case raw_topic
        case ble_pop
        case type
        case module
        case esp_no
        case client
        case version
        
       
        case unique_id
        case POP
        case DeviceType
        case ModelNo
        case ESP_NO
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // ✅ Fallback decoding — new key OR old key
        if let rawTopicValue = try? container.decode(String.self, forKey: .raw_topic) {
            raw_topic = rawTopicValue
        } else if let oldRawTopic = try? container.decode(String.self, forKey: .unique_id) {
            raw_topic = oldRawTopic
        } else {
            throw DecodingError.keyNotFound(CodingKeys.raw_topic, .init(codingPath: decoder.codingPath, debugDescription: "Missing raw_topic or unique_id"))
        }

        if let blePopValue = try? container.decode(String.self, forKey: .ble_pop) {
            ble_pop = blePopValue
        } else if let oldBlePop = try? container.decode(String.self, forKey: .POP) {
            ble_pop = oldBlePop
        } else {
            throw DecodingError.keyNotFound(CodingKeys.ble_pop, .init(codingPath: decoder.codingPath, debugDescription: "Missing ble_pop or POP"))
        }

        if let typeValue = try? container.decode(String.self, forKey: .type) {
            type = typeValue
        } else if let oldType = try? container.decode(String.self, forKey: .DeviceType) {
            type = oldType
        } else {
            throw DecodingError.keyNotFound(CodingKeys.type, .init(codingPath: decoder.codingPath, debugDescription: "Missing type or DeviceType"))
        }

        if let moduleValue = try? container.decode(String.self, forKey: .module) {
            module = moduleValue
        } else if let oldModule = try? container.decode(String.self, forKey: .ModelNo) {
            module = oldModule
        } else {
            throw DecodingError.keyNotFound(CodingKeys.module, .init(codingPath: decoder.codingPath, debugDescription: "Missing module or ModelNo"))
        }

        if let espNoValue = try? container.decode(String.self, forKey: .esp_no) {
            esp_no = espNoValue
        } else if let oldEspNo = try? container.decode(String.self, forKey: .ESP_NO) {
            esp_no = oldEspNo
        } else {
            throw DecodingError.keyNotFound(CodingKeys.esp_no, .init(codingPath: decoder.codingPath, debugDescription: "Missing esp_no or ESP_NO"))
        }

        client = try? container.decode(String.self, forKey: .client)
        version = try? container.decode(String.self, forKey: .version)
    }
}



struct OldDeviceData: Decodable {
    let unique_id: String
    let POP: String
    let DeviceType: String
    let ModelNo: String
    let ESP_NO: String
}


extension ScanQRViewController {
    
    func SyncPostData() {

        SkromanIsraDatabaseHelper.shared.deleteAllTablesData { success in
            if success {
                print("✅ Deleted old data")
                self.syncServer()
            } else {
                print("❌ Failed to delete old data")
            }
        }
    }
    
    
    
    
    func syncServer() {
        let userId = KeychainWrapper.standard.string(forKey: "userId") ?? "Nothing"
        
        let syncDataParameters: [String: Any] = [
            "userId": userId
        ]
        print("call api ")
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

                                    self.insertHomeAndRoomsIntoDB(syncData: syncData) {

                                        DispatchQueue.main.async {
                                            print("✅ Sync completed, navigating...")
                                            self.navigateToHome()
                                        }
                                    }
                                }
                                
                                if let familySync = json["familySync"] as? [[String: Any]] {
                                    print("📌 Found Family Sync")
                                    
                                    for familyEntry in familySync {
                                        if let homes = familyEntry["homes"] as? [[String: Any]] {
                                            
                                            
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
                    
                    database.insertHome(
                        homeServerId: homeId,
                        homeName: homeName,
                        homeUrl: homeImage, tuyaHomeId: tuyaHomeId,
                        isFamilyHome: 0)
                    
                    if let rooms = home["rooms"] as? [[String: Any]] {
                        for room in rooms {
                            if let roomId = room["roomId"] as? String,
                               let roomName = room["roomName"] as? String {
                                
                                let roomIconId = room["roomIconId"] as? String ?? ""
                                let roomIconType = room["roomIconType"] as? String ?? ""
                                
                                database.insertRoom(
                                    roomId: roomId,
                                    roomName: roomName,
                                    roomIconId: roomIconId,
                                    roomIconType: roomIconType, tuyaRoomId: -1,
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
    
    func navigateToHome() {

        if let navController = self.navigationController {
            
            for controller in navController.viewControllers {
                if controller is MainHomeViewController {
                    navController.popToViewController(controller, animated: true)
                    return
                }
            }

            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let homeVC = storyboard.instantiateViewController(withIdentifier: "MainHomeViewController") as? MainHomeViewController {
                navController.pushViewController(homeVC, animated: true)
            }

        } else {

            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let homeVC = storyboard.instantiateViewController(withIdentifier: "MainHomeViewController") as? MainHomeViewController {
                homeVC.modalPresentationStyle = .fullScreen
                self.present(homeVC, animated: true)
            }
        }
    }
}

extension UITextField {
    func setLeftPaddingPoints(_ amount:CGFloat){
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.size.height))
        self.leftView = paddingView
        self.leftViewMode = .always
    }
}
class NoSelectTextField: UITextField {

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return false
    }

}
