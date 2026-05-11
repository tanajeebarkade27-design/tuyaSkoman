//
//  HomeScreenViewController.swift
//  SkromanIsra
//
//  Created by Admin on 01/02/25.
//

import UIKit
  import SwiftKeychainWrapper
import Alamofire

class HomeScreenViewController: UIViewController {

    @IBOutlet weak var menuBar: UIView!
    @IBOutlet var homeBackgroundView: UIView!
  
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var addHomeButton: UIButton!
    
    @IBOutlet weak var homeColllectionView: UICollectionView!
    @IBOutlet weak var scrollBackroundView: UIView!
   
    var homeName: [String] = ["home1","home2","home3","home4"]
    var bottomSheetView: UIView!
        var homeSettingLabel: UILabel!
        var closeButton: UIButton!
        var editHomeButton: UIButton!
        var deleteHomeButton: UIButton!
        var separatorLine: UIView!
    var wifiProvisioningButton :UIButton!
    var homes: [Home] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        menuButton.setTitle("", for: .normal)
        addHomeButton.setTitle("", for: .normal)
//        homeReusableacell()
        homecollectionViewReusableacell()
//        HomeTableView.dataSource =  self
//        HomeTableView.delegate = self
        homeColllectionView.dataSource =  self
        homeColllectionView.delegate = self
//        HomeTableView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
       setupBottomSheet()
       
        styleButton(editHomeButton)
        styleButton(deleteHomeButton)
        buttonImages()
        fetchHomesFromDatabase()
        SyncPostData()
        applyGradientBackground()
   

    
    }
   

    func applyGradientBackground() {
        let mainScreen = CAGradientLayer()
        mainScreen.frame = homeBackgroundView.bounds

        if traitCollection.userInterfaceStyle == .dark {
            // Dark Mode: #181818 (Dark Gray) to #313131 (Darker Gray)
            mainScreen.colors = [
                UIColor(red: 24/255, green: 24/255, blue: 24/255, alpha: 1).cgColor,  // #181818
                UIColor(red: 49/255, green: 49/255, blue: 49/255, alpha: 1).cgColor   // #313131
            ]
        } else {
            // Light Mode: #CCCCCC (Light Gray) to #F6F6F6 (Near White)
            mainScreen.colors = [
                UIColor(red: 204/255, green: 204/255, blue: 204/255, alpha: 1).cgColor, // #CCCCCC
                UIColor(red: 246/255, green: 246/255, blue: 246/255, alpha: 1).cgColor  // #F6F6F6
            ]
        }

        mainScreen.startPoint = CGPoint(x: 0, y: 0)  // Top-left corner
        mainScreen.endPoint = CGPoint(x: 1, y: 1)    // Bottom-right corner

        
        homeBackgroundView.layer.sublayers?.removeAll(where: { $0 is CAGradientLayer })
        
        homeBackgroundView.layer.insertSublayer(mainScreen, at: 0)
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
//               / self.HomeTableView.reloadData()
                self.homeColllectionView.reloadData()// Reload table view with new data
            }
        }
    }

    
    @IBAction func ShortCutButton(_ sender: Any) {
        let addHomeVc = storyboard?.instantiateViewController(withIdentifier: "NewHomeViewController") as! NewHomeViewController
        navigationController?.pushViewController(addHomeVc, animated: true)
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        fetchHomesFromDatabase()
    }

    @IBAction func addHomeButton(_ sender: Any) {
        let addHomeVc = storyboard?.instantiateViewController(withIdentifier: "AddHomeViewController") as! AddHomeViewController
        navigationController?.pushViewController(addHomeVc, animated: true)
    }

    
    
    
    @IBAction func menuButton(_ sender: Any) {
        //navigatemenuVc()
        
    }
    
    
    
    
    func navigatemenuVc(){
        let menuVc =  storyboard?.instantiateViewController(identifier: "MenuViewController") as! MenuViewController
        navigationController?.pushViewController(menuVc, animated: true)
    }
    
//    func homeReusableacell(){
//        
//        let uiNib = UINib(nibName: "HomeTableViewCell", bundle: nil)
//        HomeTableView.register(uiNib, forCellReuseIdentifier: "HomeTableViewCell")
//    }
//    
    
    
    func homecollectionViewReusableacell(){
        
        let uiNib = UINib(nibName: "HomeScreenCollectionViewCell", bundle: nil)
        homeColllectionView.register(uiNib, forCellWithReuseIdentifier: "HomeScreenCollectionViewCell")
    }
    
    
    
    
    
    func setupBottomSheet() {
        let screenWidth = view.frame.width
        let bottomSheetHeight: CGFloat = 350

        bottomSheetView = UIView()
        bottomSheetView.frame = CGRect(x: 0, y: view.frame.height, width: screenWidth, height: bottomSheetHeight)
        bottomSheetView.backgroundColor = .white
        bottomSheetView.layer.cornerRadius = 12
        bottomSheetView.layer.shadowColor = UIColor.black.cgColor
        bottomSheetView.layer.shadowOpacity = 0.2
        bottomSheetView.layer.shadowOffset = CGSize(width: 0, height: -3)
        bottomSheetView.layer.shadowRadius = 5
        view.addSubview(bottomSheetView)

        homeSettingLabel = UILabel()
        homeSettingLabel.text = "Home Settings"
        homeSettingLabel.font = UIFont.boldSystemFont(ofSize: 16)
        homeSettingLabel.textColor = .black
        bottomSheetView.addSubview(homeSettingLabel)

        closeButton = UIButton()
        closeButton.setTitle("✕", for: .normal)
        closeButton.setTitleColor(.black, for: .normal)
        closeButton.addTarget(self, action: #selector(closeBottomSheet), for: .touchUpInside)
        bottomSheetView.addSubview(closeButton)

        separatorLine = UIView()
        separatorLine.backgroundColor = .lightGray
        bottomSheetView.addSubview(separatorLine)

        editHomeButton = createCustomButton(title: "Edit Home", subtitle: "Edit home name & image", imageName: "google")
        deleteHomeButton = createCustomButton(title: "Delete Home", subtitle: "Remove this home", imageName: "google")
        wifiProvisioningButton = createCustomButton(title: "Wi-Fi Provisioning", subtitle: "Provide internet access", imageName: "google")

        editHomeButton.addTarget(self, action: #selector(editHomeAction), for: .touchUpInside)
        deleteHomeButton.addTarget(self, action: #selector(deleteHomeAction), for: .touchUpInside)
        wifiProvisioningButton.addTarget(self, action: #selector(wifiProvisioningAction), for: .touchUpInside)

        let stackView = UIStackView(arrangedSubviews: [editHomeButton, deleteHomeButton, wifiProvisioningButton])
        stackView.axis = .vertical
        stackView.spacing = 15
        stackView.distribution = .fillEqually
        bottomSheetView.addSubview(stackView)

        applyBottomSheetConstraints(stackView: stackView)

        // ✅ Set button width constraints here (after adding to bottomSheetView)
        NSLayoutConstraint.activate([
            editHomeButton.widthAnchor.constraint(equalTo: bottomSheetView.widthAnchor, constant: -40),
            deleteHomeButton.widthAnchor.constraint(equalTo: bottomSheetView.widthAnchor, constant: -40),
            wifiProvisioningButton.widthAnchor.constraint(equalTo: bottomSheetView.widthAnchor, constant: -40)
        ])
    }

    

    @objc func editHomeAction() {
        print("Edit Home Clicked")
        closeBottomSheet()
    }

    @objc func deleteHomeAction() {
        print("Delete Home Clicked")
        closeBottomSheet()
    }

    @objc func wifiProvisioningAction() {
        print("Wi-Fi Provisioning Clicked")
        closeBottomSheet()
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


    @objc private func addDeviceAction() {
        print("Add Device Clicked")
        closeBottomSheet()
    }


    func applyBottomSheetConstraints(stackView: UIStackView) {
        homeSettingLabel.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Home Setting Label (Top-Left) - Reduce top padding
            homeSettingLabel.topAnchor.constraint(equalTo: bottomSheetView.topAnchor, constant: 10), // Reduced from 15 to 10
            homeSettingLabel.leadingAnchor.constraint(equalTo: bottomSheetView.leadingAnchor, constant: 20),

            // Close Button (Top-Right)
            closeButton.centerYAnchor.constraint(equalTo: homeSettingLabel.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: bottomSheetView.trailingAnchor, constant: -20),

            // Separator Line (Below Label) - Reduce space between label and line
            separatorLine.topAnchor.constraint(equalTo: homeSettingLabel.bottomAnchor, constant: 5), // Reduced from 10 to 5
            separatorLine.leadingAnchor.constraint(equalTo: bottomSheetView.leadingAnchor, constant: 20),
            separatorLine.trailingAnchor.constraint(equalTo: bottomSheetView.trailingAnchor, constant: -20),
            separatorLine.heightAnchor.constraint(equalToConstant: 1),

            // Edit Home Button (Below Separator) - Adjust spacing
            editHomeButton.topAnchor.constraint(equalTo: separatorLine.bottomAnchor, constant: 15), // Keep this 15
            editHomeButton.centerXAnchor.constraint(equalTo: bottomSheetView.centerXAnchor),

            // Delete Home Button (Below Edit Button)
            deleteHomeButton.topAnchor.constraint(equalTo: editHomeButton.bottomAnchor, constant: 15),
            deleteHomeButton.centerXAnchor.constraint(equalTo: bottomSheetView.centerXAnchor)
        ])
        

    }
    private func styleButton(_ button: UIButton) {
        button.layer.borderWidth = 1  // Set border width
        button.layer.borderColor = UIColor.lightGray.cgColor  // Set border color
        button.layer.cornerRadius = 8  // Set corner radius for rounded edges
        button.clipsToBounds = true  // Ensures the border and radius are applied properly
    }


    func showBottomSheet() {
        UIView.animate(withDuration: 0.3) {
            self.bottomSheetView.frame.origin.y = self.view.frame.height - 300
        }
    }
    @objc func closeBottomSheet() {
        UIView.animate(withDuration: 0.3) {
            self.bottomSheetView.frame.origin.y = self.view.frame.height
        }
    }
    
    func buttonImages() {
        // Set addHomeButton image
        if let originalImage = UIImage(named: "plus") {
            let targetSize = addHomeButton.bounds.size
            if let resizedImage = resizeImage(image: originalImage, targetSize: targetSize) {
                addHomeButton.setImage(resizedImage, for: .normal)
                addHomeButton.imageView?.contentMode = .scaleAspectFit
            }
        } else {
            print("plus image not found!")
        }

        // Set menuButton image
        if let menuImage = UIImage(named: "menu") {
            let targetSize1 = menuButton.bounds.size
            if let resizedMenuImage = resizeImage(image: menuImage, targetSize: targetSize1) {
                menuButton.setImage(resizedMenuImage, for: .normal)
                menuButton.imageView?.contentMode = .scaleAspectFit  // Fixed typo here
            }
        } else {
            print("menu_1 image not found!")
        }
    }

    
    
    
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage? {
        let size = image.size
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        var newSize: CGSize
        if widthRatio > heightRatio {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
  

}




extension HomeScreenViewController : UICollectionViewDataSource, UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return homes.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HomeScreenCollectionViewCell", for: indexPath) as! HomeScreenCollectionViewCell
        cell.parentVC = self
        let home = homes[indexPath.row]
           cell.configure(with: home)
           return cell
        
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 250, height: 190)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let roomVc = storyboard?.instantiateViewController(withIdentifier: "RoomViewController") as!
        RoomViewController
        let home = homes[indexPath.row]
        roomVc.homeSeriverId = home.homeServerId
        roomVc.homeName = home.homeName
        
        navigationController?.pushViewController(roomVc, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
           return 40 // Adjust for more/less spacing
       }

       // Space between items in the same row (horizontally)
       func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
           return 15 // Adjust as needed
       }

}


extension HomeScreenViewController{
     
    
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
                                print("Parsed sync JSON database: \(json)")
                                
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
              
                database.insertHome(homeServerId: homeId, homeName: homeName, homeUrl: homeImage, tuyaHomeId: -1, isFamilyHome: 0 )
                
                if let rooms = home["rooms"] as? [[String: Any]] {
                    for room in rooms {
                        if let roomId = room["roomId"] as? String,
                           let roomName = room["roomName"] as? String,
                           let roomIconId = room["roomIconId"] as? String,
                           let roomIconType = room["roomIconType"] as? String {
                            
                            database.insertRoom(roomId: roomId, roomName: roomName, roomIconId: roomIconId, roomIconType: roomIconType, tuyaRoomId: -1, homeId: homeId)
                            
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



            
        
    }
