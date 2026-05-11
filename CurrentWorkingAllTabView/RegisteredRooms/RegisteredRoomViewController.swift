//
//  RegisteredRoomViewController.swift
//  SkromanIsra

//  Created by Admin on 23/06/25.

import UIKit
import SwiftKeychainWrapper
import AWSCore
import AWSIoT
import Alamofire

 
protocol BottomSheetActionDelegate: AnyObject {
    func didTapEditRoom(_ room: Room)
    func didTapDeleteRoom(_ room: Room)
    func didTapAddDevice(_ room: Room)
}


class RegisteredRoomViewController: UIViewController {
    
    @IBOutlet weak var backButton: UIButton!
    
    @IBOutlet weak var roomsTableView: UITableView!
    var bottomSheetBottomConstraint: NSLayoutConstraint!
    
    weak var bottomSheetActionDelegate: BottomSheetActionDelegate?

    var selectedRoomId: String?

    var bottomSheetView: UIView!
    var roomSettingLabel: UILabel!
    var closeButton: UIButton!
    var editRoomButton: UIButton!
    var deleteRoomButton: UIButton!
    var separatorLine: UIView!
    var addDeviceButton : UIButton!
    var devicesByRoomId: [String: [Device]] = [:]
    var selectedRoom: Room?
    weak var delegate: BottomSheetActionDelegate?

    var rooms: [Room] = []
    var slectedHomeId :  String?
    var devices: [Device] = []
    var roomEnergyData: [String: Double] = [:]
    override func viewDidLoad() {
        super.viewDidLoad()
        roomsTableView.dataSource =  self
        roomsTableView.delegate =  self
        registerCell()
        fetchRoomsForSelectedHome(homeId: slectedHomeId ?? "")
        fetchLiveEnergyConsumption(for: slectedHomeId ?? "") { [weak self] response in
            guard let self = self else { return }
            guard let response = response else { return }

            for room in response.roomEnergyConsumption {
                self.roomEnergyData[room.roomId] = room.totalRoomEnergyConsumption
            }

            DispatchQueue.main.async {
                self.roomsTableView.reloadData()
            }
        }
    }

    func registerCell (){
        let uiNib = UINib(nibName: "RegisteredRoomTableViewCell", bundle: nil)
        roomsTableView.register(uiNib, forCellReuseIdentifier: "RegisteredRoomTableViewCell")

        
        roomsTableView.backgroundColor =  .clear
    }

    @IBAction func BackBtn(_ sender: Any) {
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
   
    
    
   
    let roomsIconType: [RoomIconType] = [
     
        RoomIconType(name: "Living Room", image: "Living Room"),
        RoomIconType(name: "Living Room 1", image: "Living Room 1"),
        RoomIconType(name: "Living Room 2", image: "Living Room 2"),
      
       
        RoomIconType(name: "Bed Room", image: "Bed"),
        RoomIconType(name: "Bed Room 1", image: "Bed Room 1"),
        RoomIconType(name: "Bed Room 2", image: "Bed Room 2"),
        
        RoomIconType(name: "Study Room", image: "study"),
        RoomIconType(name: "Kitchen", image: "Kitchen"),
        RoomIconType(name: "DiningHall", image: "Dining"),
       
        RoomIconType(name: "Wash Room", image: "Wash Room"),
        RoomIconType(name: "Wash Room 1", image: "Wash Room 1"),
        RoomIconType(name: "Wash Room 2", image: "Wash Room 2"),
        
        RoomIconType(name: "Toilet", image: "Wash Room"),
        RoomIconType(name: "Patio", image: "Patio"),
        RoomIconType(name: "Lobby", image: "lobby"),
        
        RoomIconType(name: "Balcony", image: "Balcony"),
        RoomIconType(name: "Garden", image: "garden"),
        RoomIconType(name: "Varanda", image: "Varanda"),
        
      
        RoomIconType(name: "Theater", image: "theater"),
        RoomIconType(name: "Lift", image: "lift"),
        RoomIconType(name: "Staircase", image: "Staircase"),
        
        RoomIconType(name: "Gate", image: "gate"),

        RoomIconType(name: "Other Room", image: "other")
        
    ]
    
    func fetchRoomsForSelectedHome(homeId: String) {
        SkromanIsraDatabaseHelper.shared.fetchRoomsByHomeId(homeServerId: homeId) { [weak self] fetchedRooms in
            guard let self = self else { return }

            print("fetchedRooms:", fetchedRooms)

            // Map room data to Room model
            let mappedRooms = fetchedRooms.map { roomTuple -> Room in
                let matchingIcon = self.roomsIconType
                    .first { $0.name == roomTuple.roomIconType }?
                    .image ?? "default_image"

                print("🛋️ Mapping room:", roomTuple.roomName, "icon:", roomTuple.roomIconType)

                return Room(
                    name: roomTuple.roomName,
                    imageName: matchingIcon,
                    roomId: roomTuple.roomId,
                    homeId: homeId
                )
            }

            DispatchQueue.main.async {
                self.rooms = mappedRooms
                self.roomsTableView.reloadData()
                
            }

            
            for room in mappedRooms {
                print("📥 Fetching devices for room ID:", room.roomId)

                SkromanIsraDatabaseHelper.shared.fetchDevicesByRoomId(roomId: room.roomId) { [weak self] roomDevices in
                    guard let self = self else { return }

                    DispatchQueue.main.async {
                        print("📦 Devices for Room ID: \(room.roomId)")
                        for device in roomDevices {
                            print("🔹 \(device.deviceName) (\(device.uniqueId)) Type: \(device.deviceType)")
                        }

                        self.devicesByRoomId[room.roomId] = roomDevices

                        if let index = self.rooms.firstIndex(where: { $0.roomId == room.roomId }) {
                            let indexPath = IndexPath(row: 0, section: index)
                            self.roomsTableView.reloadRows(at: [indexPath], with: .automatic)
                        }
                    }
                }
            }

        }
    }
    
    
    
    func fetchLiveEnergyConsumption(for homeId: String, completion: @escaping (HomeEnergyResponse?) -> Void) {
        let urlString = MainApi.url("skroman/liveEnergyConsumptionForHomeRoomDevice/\(homeId)")

        AF.request(urlString, method: .get)
            .validate()
            .responseDecodable(of: HomeEnergyResponse.self) { response in
                switch response.result {
                case .success(let data):
                    print("✅ Energy Data: \(data)")
                    completion(data)
                case .failure(let error):
                    print("❌ Error: \(error.localizedDescription)")
                    completion(nil)
                }
            }
    }
    
    func fetchDevicesForSelectedRoom() {
        guard let roomId = selectedRoomId else { return }
        SkromanIsraDatabaseHelper.shared.fetchDevicesByRoomId(roomId: roomId) { [weak self] devices in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.devicesByRoomId[roomId] = devices
                print("📦 Loaded \(devices.count) devices for room \(roomId)")
            }
        }
    }

    private func setupBottomSheet() {
        
        
           let screenWidth = view.frame.width
           let bottomSheetHeight: CGFloat = 300

         print("home Sheet show")
           bottomSheetView = UIView()
           bottomSheetView.backgroundColor =  UIColor.white
           bottomSheetView.layer.cornerRadius = 12
           bottomSheetView.layer.shadowColor = UIColor.black.cgColor
           bottomSheetView.layer.shadowOpacity = 0.2
           bottomSheetView.layer.shadowOffset = CGSize(width: 0, height: -3)
           bottomSheetView.layer.shadowRadius = 5
           bottomSheetView.translatesAutoresizingMaskIntoConstraints = false
           view.addSubview(bottomSheetView)

           // Room Setting Label
           roomSettingLabel = UILabel()
       

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
           editRoomButton = createCustomButton(title: "Edit Room", subtitle: "Modify room details", imageName: "square.and.pencil")
           deleteRoomButton = createCustomButton(title: "Delete Room", subtitle: "Remove this room", imageName: "delete")
           addDeviceButton = createCustomButton(title: "Add Device", subtitle: "Add new device", imageName: "device")

           // Button Actions
           editRoomButton.addTarget(self, action: #selector(editRoomTapped), for: .touchUpInside)
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

            button.heightAnchor.constraint(equalToConstant: 50)
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
        // Turn off autoresizing mask translation
        bottomSheetView.translatesAutoresizingMaskIntoConstraints = false
        roomSettingLabel.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false

        // Create and store the bottom constraint to animate later
        bottomSheetBottomConstraint = bottomSheetView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: bottomSheetHeight)

        NSLayoutConstraint.activate([
            // Bottom Sheet Constraints
            bottomSheetView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomSheetView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomSheetView.heightAnchor.constraint(equalToConstant: bottomSheetHeight),
            bottomSheetBottomConstraint, // activate here

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

           
            stackView.topAnchor.constraint(equalTo: separatorLine.bottomAnchor, constant: 15),
            stackView.leadingAnchor.constraint(equalTo: bottomSheetView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: bottomSheetView.trailingAnchor, constant: -20)
        ])
    }

    func showBottomSheet(for room: Room) {
        
        
//        if view.viewWithTag(998) == nil {
//            let backgroundImageView = UIImageView(frame: view.bounds)
//            backgroundImageView.backgroundColor = UIColor.white.withAlphaComponent(0.15)
//            backgroundImageView.image = UIImage(named: "Screen Background")
//            backgroundImageView.contentMode = .scaleAspectFill
//            backgroundImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//            backgroundImageView.tag = 998
//            view.addSubview(backgroundImageView)
//        }

        
        if bottomSheetView == nil {
            setupBottomSheet()
        }

        // ✅ Set delegate
        bottomSheetActionDelegate = self

        view.bringSubviewToFront(bottomSheetView)
        roomSettingLabel.text = "Room Settings - \(room.name)"
        bottomSheetBottomConstraint.constant = 0

        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }



    @objc private func editRoomTapped() {
        if let room = selectedRoom {
            print("🧭 Edit tapped for room: \(room.name)")
            bottomSheetActionDelegate?.didTapEditRoom(room)  // ✅ NOT 'delegate'
        }
    }



    @objc private func deleteRoomAction() {
        print("🗑️ Delete Room Clicked")

        if let room = selectedRoom {
            print("🧭 Edit tapped for room: \(room.name)")
            bottomSheetActionDelegate?.didTapDeleteRoom(room) // ✅ NOT 'delegate'
        }
       
        closeBottomSheet()
        
    }


    @objc private func addDeviceAction() {
        print("Add Device Clicked")
        closeBottomSheet()
        if let room = selectedRoom {
            print("🧭 Edit tapped for room: \(room.name)")
            bottomSheetActionDelegate?.didTapAddDevice(room) 
        }
        
    }
   

    @objc private func closeBottomSheet() {
        // Animate the bottom sheet down
        UIView.animate(withDuration: 0.3, animations: {
            self.bottomSheetView.frame.origin.y = self.view.frame.height
        }) { _ in
            // Remove background overlay view if it exists
            if let bgView = self.view.viewWithTag(998) {
                bgView.removeFromSuperview()
            }

            // Optionally: reset selection or cleanup
            self.selectedRoom = nil
        }
    }

    func showScenePopup(onSceneSelected: @escaping (String) -> Void) {
        let popupWidth: CGFloat = 400
        let popupHeight: CGFloat = 200

        // Background
        let backgroundImageView = UIImageView(frame: view.bounds)
        backgroundImageView.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        backgroundImageView.image = UIImage(named: "Screen Background")
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backgroundImageView.tag = 998
        view.addSubview(backgroundImageView)

        let overlay = UIView(frame: view.bounds)
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        overlay.tag = 997
        view.addSubview(overlay)

        let popupView = UIView(frame: CGRect(
            x: (view.frame.width - popupWidth) / 2,
            y: (view.frame.height - popupHeight) / 2,
            width: popupWidth,
            height: popupHeight
        ))
        popupView.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        popupView.layer.cornerRadius = 12
        popupView.clipsToBounds = true
        popupView.tag = 999
        popupView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(popupView)

        // Title
        let titleLabel = UILabel()
        titleLabel.text = "Select Scene"
        titleLabel.font = .boldSystemFont(ofSize: 18)
        titleLabel.textColor = .white

        let closeButton = UIButton(type: .system)
        closeButton.setTitle("✕", for: .normal)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.addTarget(self, action: #selector(closePopup), for: .touchUpInside)

        let headerStack = UIStackView(arrangedSubviews: [titleLabel, closeButton])
        headerStack.axis = .horizontal
        headerStack.alignment = .center
        headerStack.distribution = .equalSpacing
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        popupView.addSubview(headerStack)

        let verticalStack = UIStackView()
        verticalStack.axis = .vertical
        verticalStack.spacing = 10
        verticalStack.distribution = .fillEqually
        verticalStack.translatesAutoresizingMaskIntoConstraints = false

        var buttonIndex = 1

        for _ in 0..<2 {
            let horizontalStack = UIStackView()
            horizontalStack.axis = .horizontal
            horizontalStack.spacing = 10
            horizontalStack.distribution = .fillEqually

            for _ in 0..<4 {

                let sceneNo = buttonIndex   // ✅ capture correct value

                let button = UIButton(type: .system)
                button.setTitle("Scene \(sceneNo)", for: .normal)
                button.tag = sceneNo
                button.setTitleColor(.white, for: .normal)
                button.backgroundColor = UIColor.white.withAlphaComponent(0.20)
                button.layer.cornerRadius = 10

                button.addAction(UIAction { _ in
                    onSceneSelected("\(sceneNo)")   // ✅ use captured value
                    self.closePopup()
                }, for: .touchUpInside)

                horizontalStack.addArrangedSubview(button)

                buttonIndex += 1
            }

            verticalStack.addArrangedSubview(horizontalStack)
        }
        popupView.addSubview(verticalStack)

        NSLayoutConstraint.activate([
            popupView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            popupView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            popupView.widthAnchor.constraint(equalToConstant: popupWidth),
            popupView.heightAnchor.constraint(equalToConstant: popupHeight),

            headerStack.topAnchor.constraint(equalTo: popupView.topAnchor, constant: 10),
            headerStack.leadingAnchor.constraint(equalTo: popupView.leadingAnchor, constant: 15),
            headerStack.trailingAnchor.constraint(equalTo: popupView.trailingAnchor, constant: -15),
            headerStack.heightAnchor.constraint(equalToConstant: 30),

            verticalStack.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 10),
            verticalStack.leadingAnchor.constraint(equalTo: popupView.leadingAnchor, constant: 10),
            verticalStack.trailingAnchor.constraint(equalTo: popupView.trailingAnchor, constant: -10),
            verticalStack.bottomAnchor.constraint(equalTo: popupView.bottomAnchor, constant: -10)
        ])
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
           let theJSONText = String(data: theJSONData, encoding: .ascii) {

            print("📤 Publishing to \(topic)/HA/A/req:\n\(theJSONText)")
            showPopupUpdate()
            let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
            iotDataManager.publishString(theJSONText, onTopic: topic + "/HA/A/req", qoS: .messageDeliveryAttemptedAtMostOnce)
        } else {
            print("❌ Failed to create JSON for device: \(uniqueId)")
        }
    }
    @objc func showPopupUpdate() {
        showPopupPresenter.showPopup1(
            on: self.view,
            animationName: "coffee 2",
            title: "scene Set",
            subtitle: "Secen Set successfully."
        )
    }

    // MARK: - Call this when a scene button is tapped
    func triggerScene(for sceneNo: String) {
        guard let roomId = selectedRoomId else {
            print("❌ No room selected")
            return
        }
        
        guard let devices = devicesByRoomId[roomId] else {
            print("⚠️ No devices found for room \(roomId)")
            return
        }
        
        print("🎬 Triggering Scene \(sceneNo) for Room \(roomId) with \(devices.count) devices")
        
        for device in devices {
            print("📤 Publishing scene \(sceneNo) to device \(device.deviceName) [\(device.uniqueId)]")
            publishScene(to: device.uniqueId, controlNo: sceneNo)
        }
    }



    @objc private func sceneButtonTapped(_ sender: UIButton) {
        let sceneNumber = String(sender.tag) // button.tag = scene no
        

        print("🎬 Scene button \(sceneNumber) tapped ")
       triggerScene(for: sceneNumber)
    }

    @objc func closePopup() {
        // Remove popup
        view.viewWithTag(999)?.removeFromSuperview()

        // Remove overlay (semi-transparent blocker)
        view.viewWithTag(997)?.removeFromSuperview()

        // Remove background image view
        view.viewWithTag(998)?.removeFromSuperview()
    }
    
    
   
    func deleteRoom(_ room: Room) {
        print("🗑️ Deleting room with ID: \(room.roomId)")
        guard let homeId = slectedHomeId else {
            print("❌ homeId missing")
            return
        }

        let selectedRoomId = room.roomId
        let deleteRoomParameters: [String: Any] = [
            "roomId": selectedRoomId
        ]
        
        AF.request(
            "http://3.7.18.55:3000/skroman/roomapi/roomdelete",
            method: .post,
            parameters: deleteRoomParameters,
            encoding: JSONEncoding.default
        ).response { response in
            debugPrint(response)
            
            switch response.result {
            case .success(let data):
                guard let data = data else { return }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let rawMsg = json["msg"] as? String {
                        
                        let msg = rawMsg.trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        if msg == "Delete the room successfully..." {
                            print("✅ Room deleted successfully")
                            self.showPopupedit()
                            self.deleteroomnaviagte()
                           
                            SkromanIsraDatabaseHelper.shared.deleteRoomFromLocal(
                                roomId: selectedRoomId,
                                homeId: homeId
                            )

                        }
                        else if msg == "Present the data on room in device First Delete the Devices" {
                            print("⚠️ Room still contains devices — show popup")
                            self.showPopupForDevicesPresent()
                        }
                        else {
                            print("ℹ️ Unknown response: \(msg)")
                        }
                    } else {
                        print("❌ Invalid response format.")
                    }
                } catch {
                    print("❌ JSON Parsing Error: \(error.localizedDescription)")
                }
                
            case .failure(let err):
                print("❌ API call failed: \(err.localizedDescription)")
            }
        }
    }

    func showPopupForDevicesPresent() {
        let alert = UIAlertController(
            title: "Cannot Delete Room",
            message: "This room contains devices. Please delete all devices in this room before deleting it.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        DispatchQueue.main.async {
            self.present(alert, animated: true)
        }
    }

    @objc func showPopupedit() {
        PopupPresenter.showPopup(
            on: self.view,
            animationName: "success",
            title: "Success!",
            subtitle: "Room Delete successfully"
        )
    }
    func deleteroomnaviagte(){
        navigationController?.popViewController(animated: true)
    }

}
extension RegisteredRoomViewController : UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return rooms.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RegisteredRoomTableViewCell", for: indexPath) as! RegisteredRoomTableViewCell
        
        let room = rooms[indexPath.section]
        let roomDevices = devicesByRoomId[room.roomId] ?? []
        cell.selectionStyle = .none
        let energy = roomEnergyData[room.roomId] ?? 0
        print("🛏️ Room: \(room.name) (ID: \(room.roomId))")
        print("📱 Devices at room: \(roomDevices.map { $0.uniqueId })")

        cell.configure(with: room, devices: roomDevices, energy: energy)

        cell.onSceneTapped = { [weak self] in
            guard let self = self else { return }
            guard let roomId = cell.roomId else { return }

            self.showScenePopup { sceneNumber in
                // 👉 Get all devices for that room
                if let devices = self.devicesByRoomId[roomId] {
                    for device in devices {
                        self.publishScene(to: device.uniqueId, controlNo: sceneNumber)
                    }
                } else {
                    print("⚠️ No devices found for room \(roomId)")
                }
            }
        

        }





        cell.showBottomSheet = { [weak self] in
            guard let self = self else { return }
            self.selectedRoom = room
            self.showBottomSheet(for: room)
        }



        return cell
    }




    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 200
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 12 // spacing between cells
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let spacer = UIView()
        spacer.backgroundColor = .clear
        return spacer
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedRoom = rooms[indexPath.section]
        print("selectedRoom did select \(selectedRoom)")

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let allRoomsVC = storyboard.instantiateViewController(withIdentifier: "AllRoomsViewController") as? AllRoomsViewController {
            allRoomsVC.selectedRoomId = selectedRoom.roomId
            allRoomsVC.HomeId = selectedRoom.homeId
            
            self.navigationController?.pushViewController(allRoomsVC, animated: true)
        }
    }

}
extension RegisteredRoomViewController: BottomSheetActionDelegate {
    func didTapEditRoom(_ room: Room) {
            print("Navigating to edit for room: \(room.name)")
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let editVC = storyboard.instantiateViewController(withIdentifier: "AddNewRoomViewController") as? AddNewRoomViewController {
                editVC.isEditMode = true
                editVC.roomToEdit = room
                self.navigationController?.pushViewController(editVC, animated: true)
            }
        }


    func didTapDeleteRoom(_ room: Room) {
        
         print ("delete room")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }

            let alertController = UIAlertController(
                title: "Confirm Deletion",
                message: "Are you sure you want to delete the room \"\(room.name)\"?",
                preferredStyle: .alert
            )

            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
                print("❌ Deletion canceled.")
            
            }

            let deleteAction = UIAlertAction(title: "OK", style: .destructive) { _ in
                print("✅ Proceeding to delete room: \(room.name)")
                self.deleteRoom(room)
            }

            alertController.addAction(cancelAction)
            alertController.addAction(deleteAction)

            self.present(alertController, animated: true, completion: nil)
        }
    }



    func didTapAddDevice(_ room: Room) {
        
      
        print("selectedRoom did select \(selectedRoom)")

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let addDevice = storyboard.instantiateViewController(withIdentifier: "SelectversionViewController") as? SelectversionViewController {
            addDevice.selectedRoomId = room.roomId
            addDevice.homeId = room.homeId
            self.navigationController?.pushViewController(addDevice, animated: true)
        }
    }
       
}
