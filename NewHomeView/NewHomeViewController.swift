//
//  NewHomeViewController.swift
//  SkromanIsra
//
//  Created by Admin on 28/03/25.
//


import UIKit
import SwiftKeychainWrapper
import AWSCore
import AWSIoT
import Alamofire
import AppIntents


class NewHomeViewController: UIViewController, UITabBarDelegate {
    
    var iotDataManager: AWSIoTDataManager!
    var iotManager: AWSIoTManager!
    var iot: AWSIoT!
    var dropdownTableView: UITableView!
    var logTextView: UITextView!
    var  SelectedDeviecUid : String?
    var connectButton: UIButton!
    var connectIoTDataWebSocket: UIButton!
    var connected = false
    @IBOutlet weak var backgroundLogo: UIImageView!
    
    @IBOutlet weak var userProfile: UIButton!
    var homes: [Home] = []
    var rooms: [Room] = []
    var devices: [Device] = []
    var isDropdownVisible = false
    @IBOutlet weak var homeDropDownView: UIView!
    @IBOutlet var mainView: UIView!
    @IBOutlet weak var roomCollectionView: UICollectionView!
    @IBOutlet weak var homenameLabel: UILabel!
    
    @IBOutlet weak var homeSceneCollectionView: UICollectionView!
    var isGeoFenceEnabled: Bool = true  
    static let roomDataShared  =  NewHomeViewController()
    var selectedHomeId: String?
    var loadingView: UIView?
    var homeBottomSheetView: UIView!
    var homeSettingLabel: UILabel!
    var closeHomeButton: UIButton!
    var editHomeButton: UIButton!
    var deleteHomeButton: UIButton!
    var sheetseparatorLine: UIView!
    var addLocationButton :UIButton!
    var homeName : String?
    var bottomSheetView: UIView!
    var roomSettingLabel: UILabel!
    var closeButton: UIButton!
    var editRoomButton: UIButton!
    var deleteRoomButton: UIButton!
    var separatorLine: UIView!
    var addDeviceButton : UIButton!
    var selectedRoomId: String?
  
    var selectedRoomName : String?
    var  homeScene:  [String] = ["Scene 1", "Scene 2", "Scene 3", "Scene 4"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        userProfile.setTitle("", for: .normal)
        connetion_aws_function()
        applyGradientBackground()
        SyncPostData()
        setupDropdownTable()
        showLoadingIndicator(with: "chromatic") // Optional image name

        

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.fetchHomesFromDatabase()
           
        }
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleDropdown))
        homeDropDownView.addGestureRecognizer(tapGesture)
        registerCell()
        setupWatermarkLogo()
        if let tabBar = self.tabBarController {
               tabBar.delegate = self
           }
       
       
        makeTabBarCapsuleStyle()
    }
   
    @objc func handleSiriCommand() {
       
        // You can call any function here
    }
    
    func makeTabBarCapsuleStyle() {
        guard let tabBar = self.tabBarController?.tabBar else { return }

        tabBar.backgroundImage = UIImage()
        tabBar.shadowImage = UIImage()
        tabBar.isTranslucent = true
        tabBar.backgroundColor = UIColor.clear

        // Remove previous custom layers if any
        if let oldShapeLayer = tabBar.layer.sublayers?.first(where: { $0.name == "CustomTabBarShape" }) {
            oldShapeLayer.removeFromSuperlayer()
        }

        let shapeLayer = CAShapeLayer()
        shapeLayer.name = "CustomTabBarShape"

        let bounds = tabBar.bounds.insetBy(dx: -10, dy: 5)
        let path = UIBezierPath(roundedRect: bounds, cornerRadius: bounds.height / 2)
        shapeLayer.path = path.cgPath
        shapeLayer.fillColor = UIColor.white.withAlphaComponent(0.25).cgColor  // Slightly transparent

        // Shadow (for floating effect)
        shapeLayer.shadowColor = UIColor.black.cgColor
        shapeLayer.shadowOffset = CGSize(width: 0, height: 3)
        shapeLayer.shadowOpacity = 0.2
        shapeLayer.shadowRadius = 8

        tabBar.layer.insertSublayer(shapeLayer, at: 0)
    }

   
    
    func applyGradientBackground() {
        let mainScreen = CAGradientLayer()
        mainScreen.frame = mainView.bounds

        mainScreen.colors = [
            UIColor(red: 163/255, green: 159/255, blue: 98/255, alpha: 1).cgColor,   // Gold
            UIColor(red: 141/255, green: 176/255, blue: 144/255, alpha: 1).cgColor,  // Green
            UIColor(red: 104/255, green: 155/255, blue: 181/255, alpha: 1).cgColor   // Blue
        ]

        mainScreen.locations = [0.0, 0.3, 0.8]  // Expands green & blue areas
        mainScreen.startPoint = CGPoint(x: 0.5, y: 0)   // Top center
        mainScreen.endPoint = CGPoint(x: 0.5, y: 1)     // Bottom center

     
        mainView.layer.sublayers?.removeAll(where: { $0 is CAGradientLayer })
        
        mainView.layer.insertSublayer(mainScreen, at: 0)
    }

   
    @IBAction func profileButton(_ sender: Any) {
        if homeBottomSheetView == nil {
            setupHomeBottomSheet()
        }
        showHomeBottomSheet()
    }

    
    
    
    let roomsIconType: [RoomIconType] = [
        RoomIconType(name: "Study Room", image: "study-room1"),
        RoomIconType(name: "Bed Room", image: "bedroom"),
        RoomIconType(name: "Theater", image: "theater"),
        RoomIconType(name: "Balcony", image: "balcony"),
        RoomIconType(name: "Dining Hall", image: "table"),
        RoomIconType(name: "Living Room", image: "living_room_1"),
        RoomIconType(name: "Other Room", image: "living_room_1"),
        RoomIconType(name: "Garden", image: "garden_2"),
        RoomIconType(name: "Gate", image: "gate"),
        RoomIconType(name: "Kitchen", image: "kitchen"),
        RoomIconType(name: "Lift", image: "lift_1"),
        RoomIconType(name: "Staircase", image: "staircase 1")
    ]
    
    
    
    func setupHomeBottomSheet() {
        let screenWidth = view.frame.width
        let bottomSheetHeight: CGFloat = 350

        homeBottomSheetView = UIView(frame: CGRect(x: 0, y: view.frame.height, width: screenWidth, height: bottomSheetHeight))
        homeBottomSheetView.backgroundColor = .white
        homeBottomSheetView.layer.cornerRadius = 12
        homeBottomSheetView.layer.shadowColor = UIColor.black.cgColor
        homeBottomSheetView.layer.shadowOpacity = 0.2
        homeBottomSheetView.layer.shadowOffset = CGSize(width: 0, height: -3)
        homeBottomSheetView.layer.shadowRadius = 5
        view.addSubview(homeBottomSheetView)

        // Labels & Buttons
        homeSettingLabel = UILabel()
        homeSettingLabel.text = "Home Settings"
        homeSettingLabel.font = UIFont.boldSystemFont(ofSize: 16)
        homeSettingLabel.textColor = .black
        homeSettingLabel.translatesAutoresizingMaskIntoConstraints = false
        homeBottomSheetView.addSubview(homeSettingLabel)

        closeHomeButton = UIButton()
        closeHomeButton.setTitle("✕", for: .normal)
        closeHomeButton.setTitleColor(.black, for: .normal)
        closeHomeButton.addTarget(self, action: #selector(closeHomeBottomSheet), for: .touchUpInside)
        closeHomeButton.translatesAutoresizingMaskIntoConstraints = false
        homeBottomSheetView.addSubview(closeHomeButton)

        sheetseparatorLine = UIView()
        sheetseparatorLine.backgroundColor = .lightGray
        sheetseparatorLine.translatesAutoresizingMaskIntoConstraints = false
        homeBottomSheetView.addSubview(sheetseparatorLine)

        // Action Buttons
        editHomeButton = createCustomHomeButton(title: "Edit Home", subtitle: "Edit home name & image", imageName: "pencile.fill")
        deleteHomeButton = createCustomHomeButton(title: "Delete Home", subtitle: "Remove this home", imageName: "trash.fill")
        
       
        let addLocationButton = createCustomHomeButton(title: "Add Home Location", subtitle: "Geo fencing", imageName: "mappin")
        
        // Create the Toggle Button
        let toggleButton = UISwitch()
        toggleButton.isOn = false
        toggleButton.translatesAutoresizingMaskIntoConstraints = false
        toggleButton.addTarget(self, action: #selector(toggleButtonChanged), for: .valueChanged)
        
        // Stack view for "Add Home Location" button and Toggle button
        let buttonWithToggleStackView = UIStackView(arrangedSubviews: [addLocationButton, toggleButton])
        buttonWithToggleStackView.axis = .horizontal
        buttonWithToggleStackView.spacing = 10
        buttonWithToggleStackView.alignment = .center
        buttonWithToggleStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Apply styles to buttons
        stylesheetButton(editHomeButton)
        stylesheetButton(deleteHomeButton)
        stylesheetButton(addLocationButton)

        // Actions for buttons
        editHomeButton.addTarget(self, action: #selector(editHomeAction), for: .touchUpInside)
        deleteHomeButton.addTarget(self, action: #selector(deleteHomeAction), for: .touchUpInside)
        addLocationButton.addTarget(self, action: #selector(addLocationBtn), for: .touchUpInside)

        // Stack View for all buttons (with "Add Home Location" + toggle)
        let stackView = UIStackView(arrangedSubviews: [editHomeButton, deleteHomeButton, buttonWithToggleStackView])
        stackView.axis = .vertical
        stackView.spacing = 15
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        homeBottomSheetView.addSubview(stackView)

        // Constraints
        NSLayoutConstraint.activate([
            homeSettingLabel.topAnchor.constraint(equalTo: homeBottomSheetView.topAnchor, constant: 10),
            homeSettingLabel.leadingAnchor.constraint(equalTo: homeBottomSheetView.leadingAnchor, constant: 20),

            closeHomeButton.centerYAnchor.constraint(equalTo: homeSettingLabel.centerYAnchor),
            closeHomeButton.trailingAnchor.constraint(equalTo: homeBottomSheetView.trailingAnchor, constant: -20),

            sheetseparatorLine.topAnchor.constraint(equalTo: homeSettingLabel.bottomAnchor, constant: 5),
            sheetseparatorLine.leadingAnchor.constraint(equalTo: homeBottomSheetView.leadingAnchor, constant: 20),
            sheetseparatorLine.trailingAnchor.constraint(equalTo: homeBottomSheetView.trailingAnchor, constant: -20),
            sheetseparatorLine.heightAnchor.constraint(equalToConstant: 1),

            stackView.topAnchor.constraint(equalTo: sheetseparatorLine.bottomAnchor, constant: 15),
            stackView.leadingAnchor.constraint(equalTo: homeBottomSheetView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: homeBottomSheetView.trailingAnchor, constant: -20)
        ])
    }

    @objc func toggleButtonChanged(sender: UISwitch) {
        if sender.isOn {
            print("Location is enabled")
            isGeoFenceEnabled = true
        } else {
            print("Location is disabled")
            isGeoFenceEnabled = false
        }
    }

    private func stylesheetButton(_ button: UIButton) {
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor.lightGray.cgColor
            button.layer.cornerRadius = 8
            button.clipsToBounds = true
        }

        func createCustomHomeButton(title: String, subtitle: String, imageName: String) -> UIButton {
            let button = UIButton()
            button.backgroundColor = .clear
            button.contentHorizontalAlignment = .left
            button.translatesAutoresizingMaskIntoConstraints = false

            let iconImageView = UIImageView(image: UIImage(named: imageName))
            iconImageView.contentMode = .scaleAspectFit
            iconImageView.translatesAutoresizingMaskIntoConstraints = false
            iconImageView.widthAnchor.constraint(equalToConstant: 24).isActive = true
            iconImageView.heightAnchor.constraint(equalToConstant: 24).isActive = true

            let titleLabel = UILabel()
            titleLabel.text = title
            titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
            titleLabel.textColor = .black

            let subtitleLabel = UILabel()
            subtitleLabel.text = subtitle
            subtitleLabel.font = UIFont.systemFont(ofSize: 12)
            subtitleLabel.textColor = .gray

            let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
            textStack.axis = .vertical
            textStack.spacing = 2
            textStack.alignment = .leading

            let mainStack = UIStackView(arrangedSubviews: [iconImageView, textStack])
            mainStack.axis = .horizontal
            mainStack.spacing = 10
            mainStack.alignment = .center
            mainStack.translatesAutoresizingMaskIntoConstraints = false
            mainStack.isUserInteractionEnabled = false

            button.addSubview(mainStack)

            NSLayoutConstraint.activate([
                mainStack.leadingAnchor.constraint(equalTo: button.leadingAnchor),
                mainStack.trailingAnchor.constraint(equalTo: button.trailingAnchor),
                mainStack.topAnchor.constraint(equalTo: button.topAnchor),
                mainStack.bottomAnchor.constraint(equalTo: button.bottomAnchor),
                button.heightAnchor.constraint(equalToConstant: 50)
            ])

            return button
        }

        func showHomeBottomSheet() {
            UIView.animate(withDuration: 0.3) {
                self.homeBottomSheetView.frame.origin.y = self.view.frame.height - 350
            }
        }

        @objc func closeHomeBottomSheet() {
            UIView.animate(withDuration: 0.3) {
                self.homeBottomSheetView.frame.origin.y = self.view.frame.height
            }
        }

        // Actions
        @objc func editHomeAction() {
            print("Edit Home Clicked")
            closeHomeBottomSheet()
        }

        @objc func deleteHomeAction() {
            print("Delete Home Clicked")
            closeHomeBottomSheet()
        }

    @objc func addLocationBtn() {
        print("Add Location Button Clicked")
        closeHomeBottomSheet()
        
        // Passing the toggle state to the GeofencViewController
        geoFenceVc(isGeoFenceEnabled: isGeoFenceEnabled)
    }
    
    
    func geoFenceVc(isGeoFenceEnabled: Bool) {
        let geoVc = storyboard?.instantiateViewController(identifier: "GeofencViewController") as! GeofencViewController
        geoVc.homeId = self.selectedHomeId
        geoVc.isGeoFenceEnabled = isGeoFenceEnabled  // Pass the value of isGeoFenceEnabled
        navigationController?.pushViewController(geoVc, animated: true)
    }
    
    
    func setupWatermarkLogo() {
        if backgroundLogo == nil {
            backgroundLogo = UIImageView(image: UIImage(named: "watermark_logo")) 
            backgroundLogo.contentMode = .scaleAspectFit
            backgroundLogo.translatesAutoresizingMaskIntoConstraints = false
            mainView.addSubview(backgroundLogo)
        }
        
        backgroundLogo.alpha = 0.3

     
        NSLayoutConstraint.activate([
            backgroundLogo.centerXAnchor.constraint(equalTo: mainView.centerXAnchor),
            backgroundLogo.centerYAnchor.constraint(equalTo: mainView.centerYAnchor),
            backgroundLogo.widthAnchor.constraint(equalTo: mainView.widthAnchor, multiplier: 0.5),
            backgroundLogo.heightAnchor.constraint(equalTo: backgroundLogo.widthAnchor)
        ])
        
        mainView.sendSubviewToBack(backgroundLogo)
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
    
    func  registerCell(){
        let roomNib = UINib(nibName: "NewRoomCollectionViewCell", bundle: nil)
           roomCollectionView.register(roomNib, forCellWithReuseIdentifier: "NewRoomCollectionViewCell")
           
           print("✅ Registered NewRoomCollectionViewCell")
        let sceneNib = UINib(nibName: "HomeSceneCollectionViewCell", bundle: nil)
        homeSceneCollectionView.register(sceneNib, forCellWithReuseIdentifier: "HomeSceneCollectionViewCell")
        
        
        
        homeSceneCollectionView.delegate = self
        homeSceneCollectionView.dataSource =  self
        roomCollectionView.delegate = self
        roomCollectionView.dataSource = self
   
    }
    func setupDropdownTable() {
        dropdownTableView = UITableView(frame: CGRect(x: homeDropDownView.frame.origin.x,
                                                      y: homeDropDownView.frame.maxY,
                                                      width: homeDropDownView.frame.width,
                                                      height: 150))
        dropdownTableView.delegate = self
        dropdownTableView.dataSource = self
        dropdownTableView.isHidden = true
//        dropdownTableView.layer.borderColor = UIColor.gray.cgColor
        dropdownTableView.layer.borderWidth = 1
        dropdownTableView.layer.cornerRadius = 5
//        homeDropDownView.layer.borderWidth = 1
        homeDropDownView.layer.cornerRadius = 5
        homeDropDownView.clipsToBounds =  true
        view.addSubview(dropdownTableView)
    }
    
    @objc func toggleDropdown() {
        isDropdownVisible.toggle()
        dropdownTableView.isHidden = !isDropdownVisible
        dropdownTableView.reloadData()
    }
    func fetchHomesFromDatabase() {
        SkromanIsraDatabaseHelper.shared.fetchAllHomes { fetchedHomes in
            self.homes = fetchedHomes.map { homeTuple in
                Home(
                    homeServerId: homeTuple.homeServerId,
                    homeName: homeTuple.homeName,
                    homeUrl: homeTuple.homeUrl, isFamilyHome: 0
                )
            }
            
            DispatchQueue.main.async {
                if self.homes.isEmpty {
                    self.homenameLabel.text = "No Homes Available"
                } else {
                    let firstHome = self.homes.first!
                    self.homenameLabel.text = firstHome.homeName
                    self.selectedHomeId = firstHome.homeServerId // ✅ Set selected home
                    self.fetchRoomsForSelectedHome(homeId: firstHome.homeServerId)
                }
                self.dropdownTableView.reloadData()
            }
        }
    }

    
    
    func fetchRoomsForSelectedHome(homeId: String) {
        SkromanIsraDatabaseHelper.shared.fetchRoomsByHomeId(homeServerId: homeId) { fetchedRooms in
            let mappedRooms = fetchedRooms.map { roomTuple in
                let matchingIcon = self.roomsIconType.first { $0.name == roomTuple.roomIconType }?.image ?? "default_image"
                return Room(
                    name: roomTuple.roomName,
                    imageName: matchingIcon,
                    roomId: roomTuple.roomId,
                    homeId: homeId
                )
            }

            DispatchQueue.main.async {
                self.rooms = mappedRooms
                self.roomCollectionView.reloadData()

                if let firstRoom = self.rooms.first {
                    self.selectedRoomId = firstRoom.roomId
                    self.selectedRoomName = firstRoom.name
                    self.fetchDevicesForSelectedRoom(roomId: firstRoom.roomId)
                }
                self.hideLoadingIndicator()
            }
        }
    }

    
    



    
    func fetchDevicesForSelectedRoom(roomId: String) {
        SkromanIsraDatabaseHelper.shared.fetchDevicesByRoomId(roomId: roomId) { [weak self] roomDevices in
            guard let self = self else { return }
            self.devices = roomDevices
            print("✅ Devices updated: \(self.devices.count), Devices: \(self.devices)")
          
            
            for device in devices {
                 
                   
               }
            if !self.devices.isEmpty {
            } else {
                print("No devices found for roomId: \(roomId)")
            }
        }
        
    }
    
    
    
    func publishScene(to uniqueId: String, controlNo: String) {
        let topic = uniqueId
        
        let scenePubParameters: Parameters = [
            "control": "scene_control",
            "no": Int(controlNo) ?? 0,
            "from": "A",
            "topic": topic
        ]

        if let theJSONData = try? JSONSerialization.data(withJSONObject: scenePubParameters, options: []),
           let theJSONText = String(data: theJSONData, encoding: .ascii) {

            print("📤 Publishing to \(topic)/HA/A/req:\n\(theJSONText)")
            
            let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
            iotDataManager.publishString(theJSONText, onTopic: topic + "/HA/A/req", qoS: .messageDeliveryAttemptedAtMostOnce)
        } else {
            print("Failed to create JSON for device:\(uniqueId)") 
        }
    }

    
   
    
    private func setupBottomSheet() {
           let screenWidth = view.frame.width
           let bottomSheetHeight: CGFloat = 300

         print("home Sheet show")
           bottomSheetView = UIView()
           bottomSheetView.backgroundColor = .white
           bottomSheetView.layer.cornerRadius = 12
           bottomSheetView.layer.shadowColor = UIColor.black.cgColor
           bottomSheetView.layer.shadowOpacity = 0.2
           bottomSheetView.layer.shadowOffset = CGSize(width: 0, height: -3)
           bottomSheetView.layer.shadowRadius = 5
           bottomSheetView.translatesAutoresizingMaskIntoConstraints = false
           view.addSubview(bottomSheetView)

           // Room Setting Label
           roomSettingLabel = UILabel()
           roomSettingLabel.text = "Room Settings"
           roomSettingLabel.font = UIFont.boldSystemFont(ofSize: 16)
           roomSettingLabel.textColor = .black

           // Close Button
           closeButton = UIButton(type: .system)
           closeButton.setTitle("✕", for: .normal)
           closeButton.setTitleColor(.black, for: .normal)
           closeButton.addTarget(self, action: #selector(closeBottomSheet), for: .touchUpInside)

          
           separatorLine = UIView()
           separatorLine.backgroundColor = .lightGray

           // Create Buttons
           editRoomButton = createCustomButton(title: "Edit Room", subtitle: "Modify room details", imageName: "edit_icon")
           deleteRoomButton = createCustomButton(title: "Delete Room", subtitle: "Remove this room", imageName: "delete_icon")
           addDeviceButton = createCustomButton(title: "Add Device", subtitle: "Add new device", imageName: "add_icon")

           // Button Actions
           editRoomButton.addTarget(self, action: #selector(editRoomAction), for: .touchUpInside)
           deleteRoomButton.addTarget(self, action: #selector(deleteRoomAction), for: .touchUpInside)
           addDeviceButton.addTarget(self, action: #selector(addDeviceAction), for: .touchUpInside)

           // Apply Styling
           styleButton(editRoomButton)
           styleButton(deleteRoomButton)
           styleButton(addDeviceButton)

           // Stack View for Buttons
           let stackView = UIStackView(arrangedSubviews: [editRoomButton, deleteRoomButton, addDeviceButton])
           stackView.axis = .vertical
           stackView.spacing = 15
           stackView.distribution = .fillEqually

           // Add Subviews
           bottomSheetView.addSubview(roomSettingLabel)
           bottomSheetView.addSubview(closeButton)
           bottomSheetView.addSubview(separatorLine)
           bottomSheetView.addSubview(stackView)

           // Constraints
           applyBottomSheetConstraints(stackView: stackView, bottomSheetHeight: bottomSheetHeight)

           // Hide Initially (For Animation)
        // Set initial position (hidden below screen)
        bottomSheetView.frame = CGRect(x: 0, y: view.frame.height, width: screenWidth, height: bottomSheetHeight)

        // Animate into view
        UIView.animate(withDuration: 0.3) {
            self.bottomSheetView.frame.origin.y = self.view.frame.height - bottomSheetHeight
        }

       }

    func createCustomButton(title: String, subtitle: String, imageName: String) -> UIButton {
        let button = UIButton()
        button.backgroundColor = .clear
        button.contentHorizontalAlignment = .left

        let iconImageView = UIImageView(image: UIImage(named: imageName))
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.widthAnchor.constraint(equalToConstant: 24).isActive = true
        iconImageView.heightAnchor.constraint(equalToConstant: 24).isActive = true

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        titleLabel.textColor = .black

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = UIFont.systemFont(ofSize: 12)
        subtitleLabel.textColor = .gray

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.alignment = .leading

        let mainStack = UIStackView(arrangedSubviews: [iconImageView, textStack])
        mainStack.axis = .horizontal
        mainStack.spacing = 10
        mainStack.alignment = .center
        mainStack.translatesAutoresizingMaskIntoConstraints = false
   
        mainStack.isUserInteractionEnabled = false // Prevent mainStack from blocking touches

        button.addSubview(mainStack)
        
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isUserInteractionEnabled = true

        // Set constraints to make the button fully cover the mainStack
        NSLayoutConstraint.activate([
            mainStack.leadingAnchor.constraint(equalTo: button.leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: button.trailingAnchor),
            mainStack.topAnchor.constraint(equalTo: button.topAnchor),
            mainStack.bottomAnchor.constraint(equalTo: button.bottomAnchor),

            button.heightAnchor.constraint(equalToConstant: 50) // Ensure enough height for tapping
        ])

        return button
    }
       private func styleButton(_ button: UIButton) {
           button.layer.borderWidth = 1
           button.layer.borderColor = UIColor.lightGray.cgColor
           button.layer.cornerRadius = 8
           button.clipsToBounds = true
       }

       private func applyBottomSheetConstraints(stackView: UIStackView, bottomSheetHeight: CGFloat) {
           bottomSheetView.translatesAutoresizingMaskIntoConstraints = false
           roomSettingLabel.translatesAutoresizingMaskIntoConstraints = false
           closeButton.translatesAutoresizingMaskIntoConstraints = false
           separatorLine.translatesAutoresizingMaskIntoConstraints = false
           stackView.translatesAutoresizingMaskIntoConstraints = false

           NSLayoutConstraint.activate([
               // Bottom Sheet Constraints
               bottomSheetView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
               bottomSheetView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
               bottomSheetView.heightAnchor.constraint(equalToConstant: bottomSheetHeight),
               bottomSheetView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: bottomSheetHeight),

               // Room Setting Label
               roomSettingLabel.topAnchor.constraint(equalTo: bottomSheetView.topAnchor, constant: 15),
               roomSettingLabel.leadingAnchor.constraint(equalTo: bottomSheetView.leadingAnchor, constant: 20),

               // Close Button
               closeButton.centerYAnchor.constraint(equalTo: roomSettingLabel.centerYAnchor),
               closeButton.trailingAnchor.constraint(equalTo: bottomSheetView.trailingAnchor, constant: -20),

               // Separator Line
               separatorLine.topAnchor.constraint(equalTo: roomSettingLabel.bottomAnchor, constant: 10),
               separatorLine.leadingAnchor.constraint(equalTo: bottomSheetView.leadingAnchor, constant: 20),
               separatorLine.trailingAnchor.constraint(equalTo: bottomSheetView.trailingAnchor, constant: -20),
               separatorLine.heightAnchor.constraint(equalToConstant: 1),

               // Stack View (Buttons)
               stackView.topAnchor.constraint(equalTo: separatorLine.bottomAnchor, constant: 15),
               stackView.leadingAnchor.constraint(equalTo: bottomSheetView.leadingAnchor, constant: 20),
               stackView.trailingAnchor.constraint(equalTo: bottomSheetView.trailingAnchor, constant: -20)
           ])
       }

    @objc func closeBottomSheet() {
        UIView.animate(withDuration: 0.3) {
            self.bottomSheetView.frame.origin.y = self.view.frame.height
        }
    }

    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            guard let cell = gesture.view as? UICollectionViewCell,
                  let indexPath = roomCollectionView.indexPath(for: cell),
                  indexPath.item < rooms.count else { return } // Ensure it's a valid room

            let selectedRoom = rooms[indexPath.item]
            
           
            selectedRoomId = selectedRoom.roomId
            selectedRoomName = selectedRoom.name
            selectedHomeId =  selectedRoom.homeId

            print("Long-pressed on room: \(selectedRoomName ?? "Unknown") (ID: \(selectedRoomId ?? "No ID"))" )

            showBottomSheet(for: selectedRoom)
        }
    }


    func showBottomSheet(for room: Room) {
        if bottomSheetView == nil {
            setupBottomSheet()  // Ensure bottom sheet is created
        }

        view.bringSubviewToFront(bottomSheetView)  // Ensure it's on top
        
        UIView.animate(withDuration: 0.3, animations: {
            self.bottomSheetView.frame.origin.y = self.view.frame.height - 300
        }) { _ in
            print("✅ Bottom sheet shown for room: \(room.name)")
        }
    }

    @objc private func editRoomAction() {
        print("Edit Room Clicked")
        closeBottomSheet()
        navigateToeditVc()
    }

    @objc private func deleteRoomAction() {
        print("Delete Room Clicked")
        closeBottomSheet()
        Delete_rooms()
    }

    @objc private func addDeviceAction() {
        print("Add Device Clicked")
        closeBottomSheet()
        navigateToVersionVc()
    }
 
 
 func navigateToVersionVc(){
     let  versionVc =   storyboard?.instantiateViewController(identifier: "SelectversionViewController") as!
     SelectversionViewController
     versionVc.selectedRoomId = self.selectedRoomId
         versionVc.selectedHomeId = self.selectedHomeId
         versionVc.selectedRoomName = self.selectedRoomName
     versionVc.homeName =  homeName
     
     
     navigationController?.pushViewController(versionVc, animated: true)
 }
 
    func navigateToeditVc(){
        let editVc =   storyboard?.instantiateViewController(identifier: "AddRoomViewController") as!
        AddRoomViewController
        editVc.selectedRoomId = self.selectedRoomId
        editVc.selectedHomeId = self.selectedHomeId
        editVc.selectedRoomName = self.selectedRoomName
        editVc.homeName =  homeName
        
        
        navigationController?.pushViewController(editVc, animated: true)
    }
    
 func Delete_rooms() {
     guard let rooms_id =  selectedRoomId else { return }
     
     print("API : ==== ",rooms_id)
     
     let room_delete_parameters : Image_Parameters = [
     
         "roomId" : rooms_id
         
     ]
     
     AF.request("http://3.7.18.55:3000/skroman/roomapi/roomdelete", method: .post, parameters: room_delete_parameters, encoding: JSONEncoding.default, headers: nil).response { response in
         debugPrint(response)
         
         switch response.result
         {
         case .success(let data) :
             do {
                  
                 
                 let jsonOne = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary
                 
                 if let parseJson = jsonOne,
                    let msg = parseJson["msg"] as? String
                    
                 {
                     if msg == "Delete the room successfully... " {
                         
                         self.showPopup()
                         
                        
                        // self.roomTableView.reloadData()
                         
                     }
                     
                     else if msg == "Present the data on room in device First Delete the Devices" {
                         
                         self.showAlert(title: "Device found in this room", message: "Please delete the device first, than try to delete room.")
                         
                     }

                 }
             }
             catch {
                 print(error.localizedDescription)
               
             }
             
             
         case .failure(let err):
             print(err.localizedDescription)
             
         }
         
     }.resume()
     
     
 }
 
 @objc func showPopup() {
     
//     showPopupPresenter.showPopup1(on: self.view,
//                                  animationName: "success",
//                                  title: "Success!",
//                                  subtitle: " Room Deleted successfully")
//     
    
 }
 
 func showAlert(title: String, message: String) {
     let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
     alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
     DispatchQueue.main.async {
         self.present(alertController, animated: true, completion: nil)
     }
 }
    
    
    
    
//    func donateSiriShortcutForRoom(room: Room) {
//        let activity = NSUserActivity(activityType: "com.skromanIsra.test")
//        activity.title = "on \(room.name)"
//        activity.userInfo = ["roomId": room.roomId, "roomName": room.name]
//        activity.isEligibleForSearch = true
//        activity.isEligibleForPrediction = true
//        activity.persistentIdentifier = NSUserActivityPersistentIdentifier(room.roomId)
//         
//        activity.suggestedInvocationPhrase = "On \(room.name)"
//        
//        self.userActivity = activity
//        activity.becomeCurrent()
//    }
//  
//    
//    func openRoomBySiri(roomId: String, roomName: String) {
//          if let room = rooms.first(where: { $0.roomId == roomId }) {
//              let vc = storyboard?.instantiateViewController(withIdentifier: "DeviceVcViewController") as! DeviceVcViewController
//              vc.roomId = room.roomId
//              vc.homeId = room.homeId
//              vc.roomName = room.name
//              print("room is open is open ")
//              navigationController?.pushViewController(vc, animated: true)
//          }
//      }
    
    
//    func donateSimpleShortcut() {
//        let activity = NSUserActivity(activityType: "com.skromanIsra.openMenu")
//        activity.title = "Open Menu"
//        activity.isEligibleForSearch = true
//        activity.isEligibleForPrediction = true
//        activity.suggestedInvocationPhrase = "Open the user  menu"
//
//        activity.becomeCurrent()
//    }

    
}


extension NewHomeViewController : UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return homes.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
        
        if indexPath.row < homes.count {
            // Regular home cell
            cell.textLabel?.text = homes[indexPath.row].homeName
            cell.textLabel?.textColor = .black
            cell.accessoryType = .disclosureIndicator
        } else {
            // Add new home cell
            cell.textLabel?.text = "+ Add New Home"
            cell.textLabel?.textColor = .systemBlue
            cell.textLabel?.textAlignment = .center
            cell.accessoryType = .none
        }
        
        return cell
    }

    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if indexPath.row < homes.count {
            // Existing home selected
            let selectedHome = homes[indexPath.row]
            print("Selected home: \(selectedHome.homeName)")

            homenameLabel.text = selectedHome.homeName
            selectedHomeId = selectedHome.homeServerId
            fetchRoomsForSelectedHome(homeId: selectedHome.homeServerId)

            isDropdownVisible = false
            dropdownTableView.isHidden = true
        } else {
            // Add New Home tapped
            if let addhomeVC = storyboard?.instantiateViewController(withIdentifier: "AddHomeViewController") as? AddHomeViewController {
                navigationController?.pushViewController(addhomeVC, animated: true)
            }
        }
    }


    
  

    func showLoadingIndicator(with imageName: String? = nil) {
        // Remove if already added
        loadingView?.removeFromSuperview()

        let overlay = UIView(frame: view.bounds)
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.2) // Lighter dim

        let container = UIView()
        container.backgroundColor = UIColor.white.withAlphaComponent(0.0) // Fully transparent
        container.layer.cornerRadius = 12
        container.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        if let name = imageName, let image = UIImage(named: name) {
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFit
            imageView.heightAnchor.constraint(equalToConstant: 60).isActive = true
            imageView.widthAnchor.constraint(equalToConstant: 60).isActive = true
            stack.addArrangedSubview(imageView)
        }

        let spinner = UIActivityIndicatorView(style: .large)
        spinner.color = .white
        spinner.startAnimating()
        stack.addArrangedSubview(spinner)

        container.addSubview(stack)
        overlay.addSubview(container)
        view.addSubview(overlay)

        NSLayoutConstraint.activate([
            container.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            container.centerYAnchor.constraint(equalTo: overlay.centerYAnchor),
            container.widthAnchor.constraint(equalToConstant: 140),
            container.heightAnchor.constraint(equalToConstant: 140),

            stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])

        loadingView = overlay
    }

    func hideLoadingIndicator() {
        loadingView?.removeFromSuperview()
        loadingView = nil
    }

    
    
    
    
}

extension NewHomeViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == roomCollectionView {
            return rooms.count + 1
        } else if collectionView == homeSceneCollectionView {
            return homeScene.count
        }
        return 0
    }

    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == roomCollectionView {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NewRoomCollectionViewCell", for: indexPath) as? NewRoomCollectionViewCell else {
                fatalError("🚨 Could not dequeue NewRoomCollectionViewCell!")
            }
            
            if indexPath.item == rooms.count {
               
                cell.roomNamelabel.text = "Add Room"
                cell.roomImageView.image = UIImage(named: "plus")?.resized(to: CGSize(width: 30, height: 30))
                cell.roomImageView.contentMode = .scaleAspectFit
//                cell.backgroundColor = .systemGray6
            } else {
                // Normal room cell
                let room = rooms[indexPath.row]
                cell.roomNamelabel.text = room.name
                cell.roomImageView.image = UIImage(named: room.imageName) ?? UIImage(named: "default_image")
            }
            
           
            let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
            cell.addGestureRecognizer(longPressGesture)

            return cell
        }
        
        
        if collectionView == homeSceneCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HomeSceneCollectionViewCell", for: indexPath) as! HomeSceneCollectionViewCell
            let scene = homeScene[indexPath.row]
            cell.SceneNamelabel.text = scene
            return cell
        }

        return UICollectionViewCell()
    }


    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == roomCollectionView {
            if indexPath.item == rooms.count {
                if let addRoomVC = storyboard?.instantiateViewController(withIdentifier: "AddRoomViewController") as? AddRoomViewController {
                    navigationController?.pushViewController(addRoomVC, animated: true)
                }
            } else {
                let vc = storyboard?.instantiateViewController(withIdentifier: "DeviceVcViewController") as! DeviceVcViewController
                let room = rooms[indexPath.row]
                vc.roomId = room.roomId
                vc.homeId = room.homeId
                vc.roomName = room.name
                vc.rooms =  self.rooms
                
               
                navigationController?.pushViewController(vc, animated: true)
            }
        } else if collectionView == homeSceneCollectionView {
            let controlNo = "\(indexPath.row + 1)"
            
            for room in rooms {
                SkromanIsraDatabaseHelper.shared.fetchDevicesByRoomId(roomId: room.roomId) { [weak self] roomDevices in
                    guard let self = self else { return }
                    
                    for device in roomDevices {
                        self.publishScene(to: device.uniqueId, controlNo: controlNo)
                    }
                }
            }
        }

    }


    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if collectionView == roomCollectionView {
            let numberOfColumns: CGFloat = 2
            let spacing: CGFloat = 20
            let totalSpacing = (numberOfColumns - 1) * spacing  // Total spacing between columns
            
            // Calculate width by subtracting spacing and dividing by the number of columns
            let itemWidth = (collectionView.frame.width - totalSpacing - 20) / numberOfColumns
            
            return CGSize(width: itemWidth, height: itemWidth)  // Square cells
        } else if collectionView == homeSceneCollectionView {
            return CGSize(width: 80, height: 40)
        }
        
        return CGSize(width: 0, height: 0)  // Default case
    }
    
}


extension NewHomeViewController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        
        // Check for DeviceVcViewController on 2nd tab (index 1)
        if let navController = tabBarController.viewControllers?[1] as? UINavigationController,
           let deviceVC = navController.viewControllers.first as? DeviceVcViewController {
            deviceVC.rooms = self.rooms
            deviceVC.roomName = self.rooms.first?.name
            deviceVC.roomId = self.rooms.first?.roomId
            print("Tab 1 (Device) clicked")
        }
        
        // Check for AllRoomsViewController on 4th tab (index 3)
        if let navController = tabBarController.viewControllers?[4] as? UINavigationController,
           let roomVC = navController.viewControllers.first as? AllRoomsViewController {
            roomVC.HomeId = self.selectedHomeId
           
            print("Tab 3 (Rooms) clicked")
        }
        
        return true
    }
}

extension NewHomeViewController {
    
    func SyncPostData() {
        print("✅ SyncPostData() called")
        SkromanIsraDatabaseHelper.shared.openDatabase()
        SkromanIsraDatabaseHelper.shared.createTables()
        
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
                                    self.insertHomeAndRoomsIntoDB(syncData: syncData)
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


    func insertHomeAndRoomsIntoDB(syncData: [[String: Any]]) {
        let database = SkromanIsraDatabaseHelper.shared
        
        for home in syncData {
            if let homeId = home["homeId"] as? String,
               let homeName = home["homeName"] as? String {
               let homeImage = home["homeImage"] as? String ?? ""
                 print("home url  at\(homeImage)  home   name  is\(homeName) ")
              
              
                database.insertHome(homeServerId: homeId, homeName: homeName, homeUrl: homeImage, tuyaHomeId: -1, isFamilyHome: 0)
                
                
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
                                                let isHomeFav = button["isHomeFav"] as? Int
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
                                                               let lState = scene["L_state"] as? String {
                                                                
                                                                database.insertScene(sceneId: sceneId, deviceUid: deviceUid, homeId: homeId, roomId: roomId, uniqueId: uniqueId, modelNo: deviceModelNo, deviceType: deviceType, sceneNo: sceneNo, sceneName: sceneName, destButton: destButton, configButtons:configButtons, configDim: configDim, LState: lState, LSpeed: lSpeed, FState: fState, FSpeed: fSpeed, fanDest: fanDest)
                                                            }
                                                        }
                                                        
                                                        if let schedules = device["timeShedules"] as? [[String: Any]] {
                                                            print("Found \(schedules.count) schedules for device \(uniqueId)")
                                                            
                                                            for schedule in schedules {
                                                                
                                                                let scheduleId = schedule["sheduleId"] as? String ?? UUID().uuidString
                                                                let scheduleNumber = schedule["sheduleNumber"] as? String ?? ""
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
      
        
        print("Sync data inserted into SQLite successfully!")
    }


    func insertFamilyHomeAndRoomsIntoDB(familyHomes: [[String: Any]], completion: @escaping () -> Void) {
        
        let database = SkromanIsraDatabaseHelper.shared
        
        DispatchQueue.global(qos: .background).async {
            
            for home in familyHomes {
                
                guard let homeId = home["homeId"] as? String,
                      let homeName = home["homeName"] as? String else { continue }
                
                let homeImage = home["homeImage"] as? String ?? ""
                
                print("🏠 FAMILY HOME → \(homeName)")

                
                database.insertHome(
                    homeServerId: homeId,
                    homeName: homeName,
                    homeUrl: homeImage, tuyaHomeId: -1,
                    isFamilyHome: 1
                )
                
                // INSERT ROOMS
                if let rooms = home["rooms"] as? [[String: Any]] {
                    for room in rooms {
                        
                        let roomId = room["roomId"] as? String ?? ""
                        let roomName = room["roomName"] as? String ?? ""
                        let roomIconId = room["roomIconId"] as? String ?? ""
                        let roomIconType = room["roomIconType"] as? String ?? ""
                        
                        database.insertRoom(
                            roomId: roomId,
                            roomName: roomName,
                            roomIconId: roomIconId,
                            roomIconType: roomIconType, tuyaRoomId: -1,
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



