import UIKit
import SwiftKeychainWrapper
import AWSCore
import AWSIoT
import Alamofire

class MainShortCutViewController: UIViewController  {
    
    var homes: [Home] = []
    var rooms: [Room] = []
    var devices: [Device] = []
    var buttonItems: [String] = []
    var roomId: String?
    var homeId : String?
    var dropdownTableView: UITableView!
    var isDropdownVisible = false
    var iotDataManager: AWSIoTDataManager!
    var iotManager: AWSIoTManager!
    var iot: AWSIoT!
    var selectedDevice: Device?
    var logTextView: UITextView!
    var  SelectedDeviecUid : String?
    var connectButton: UIButton!
    var  deviceUniqueId: String?
    var connectIoTDataWebSocket: UIButton!
    var connected = false
    var receivedDeviceStates: [DeviceStateArray] = []
    var previousDeviceUniqueId: String?
    var mappedValues: [[String: String]] = []
    
    @IBOutlet weak var homeDropDownView: UIView!
    @IBOutlet weak var homenameLabel: UILabel!
    

    @IBOutlet var mainView: UIView!
    @IBOutlet weak var roomView: UIView!
    @IBOutlet weak var roomCollectionView: UICollectionView!
    
    @IBOutlet weak var shortcutDeviceCollcetionView: UICollectionView!
    
    @IBOutlet weak var deviceView: UIView!
    
    @IBOutlet weak var shortButtonCollectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupDropdownTable()
       // fetchHomesFromDatabase()
        registerCell()
       
        applyGradientBackground()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleDropdown))
        homeDropDownView.addGestureRecognizer(tapGesture)
    }
    
    
    
    func applyGradientBackground() {
        let mainScreen = CAGradientLayer()
        mainScreen.frame = mainView.bounds

        if traitCollection.userInterfaceStyle == .dark {
            // Dark Mode: Gradient from #2E6164 (Dark Teal) to #6D97B1 (Light Blue)
            mainScreen.colors = [
                UIColor(red: 46/255, green: 97/255, blue: 100/255, alpha: 1).cgColor,  // #2E6164
                UIColor(red: 109/255, green: 151/255, blue: 177/255, alpha: 1).cgColor // #6D97B1
            ]
        } else {
            // Light Mode: Gradient from #6D97B1 (Light Blue) to #2E6164 (Dark Teal)
            mainScreen.colors = [
                UIColor(red: 109/255, green: 151/255, blue: 177/255, alpha: 1).cgColor, // #6D97B1
                UIColor(red: 46/255, green: 97/255, blue: 100/255, alpha: 1).cgColor  // #2E6164
            ]
        }

        mainScreen.startPoint = CGPoint(x: 0, y: 0)  // Top-left corner
        mainScreen.endPoint = CGPoint(x: 1, y: 1)    // Bottom-right corner

        // Remove existing gradient layers before adding a new one
        mainView.layer.sublayers?.removeAll(where: { $0 is CAGradientLayer })
        
        mainView.layer.insertSublayer(mainScreen, at: 0)
    }

    func setupDropdownTable() {
        dropdownTableView = UITableView(frame: CGRect(x: homeDropDownView.frame.origin.x,
                                                      y: homeDropDownView.frame.maxY,
                                                      width: homeDropDownView.frame.width,
                                                      height: 150))
        dropdownTableView.delegate = self
        dropdownTableView.dataSource = self
        dropdownTableView.isHidden = true
        dropdownTableView.layer.borderColor = UIColor.gray.cgColor
        dropdownTableView.layer.borderWidth = 1
        dropdownTableView.layer.cornerRadius = 5
        homeDropDownView.layer.borderWidth = 1
        homeDropDownView.layer.cornerRadius = 5
        homeDropDownView.clipsToBounds =  true
        view.addSubview(dropdownTableView)
    }
    
    @objc func toggleDropdown() {
        isDropdownVisible.toggle()
        dropdownTableView.isHidden = !isDropdownVisible
        dropdownTableView.reloadData()
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
    
    
    
    func  registerCell(){
        let roomNib = UINib(nibName: "roomShortCollectionViewCell", bundle: nil)
        roomCollectionView.register(roomNib, forCellWithReuseIdentifier: "roomShortCollectionViewCell")
        let deviceNib = UINib(nibName: "ShortcutDeviceCollectionViewCell", bundle: nil)
        shortcutDeviceCollcetionView.register(deviceNib, forCellWithReuseIdentifier: "ShortcutDeviceCollectionViewCell")
        

        roomCollectionView.delegate = self
        roomCollectionView.dataSource = self
        shortcutDeviceCollcetionView.delegate = self
        shortcutDeviceCollcetionView.dataSource =  self
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
                    // ✅ Auto-select first home
                    let firstHome = self.homes.first!
                    self.homenameLabel.text = firstHome.homeName
                    
                    // ✅ Fetch rooms for the first home
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
                    // ✅ Auto-select first room and fetch devices
                    self.fetchDevicesForSelectedRoom(roomId: firstRoom.roomId)
                }
            }
        }
    }

    func fetchDevicesForSelectedRoom(roomId: String) {
        SkromanIsraDatabaseHelper.shared.fetchDevicesByRoomId(roomId: roomId) { [weak self] roomDevices in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.devices = roomDevices
                self.shortcutDeviceCollcetionView.reloadData()
                
                print("✅ Devices updated: \(self.devices.count), Devices: \(self.devices)")
                
                if !self.devices.isEmpty {
                   
                } else {
                    print("⚠️ No devices found for roomId: \(roomId)")
                }
            }
        }
    }


//    func fetchDeviceStatesForAllDevices() {
//        let dispatchGroup = DispatchGroup()
//        var allDeviceStates: [DeviceStateArray] = []
//
//        for device in devices {
//            print("🔍 Fetching state for device UID: \(device.deviceUid)")
//
//            dispatchGroup.enter()
//            DispatchQueue.global(qos: .background).async {
//                let deviceStates = SkromanIsraDatabaseHelper.shared.fetchDeviceStatesByDeviceUid(deviceUid: device.deviceUid)
//
//                DispatchQueue.main.async {
//                    if deviceStates.isEmpty {
//                        print("⚠️ No states found for device UID: \(device.deviceUid)")
//                    } else {
//                        print("✅ Found \(deviceStates.count) states for device UID: \(device.deviceUid)")
//                    }
//
//                    let mappedStates = deviceStates.map { deviceState in
//                        return DeviceStateArray(
//                             // Include deviceUid
//                            uniqueID: deviceState.uniqueId,
//                            modelNo: Int(deviceState.master) ?? 0,
//                            deviceNumber: deviceState.deviceStateUid,
//                            cDim: deviceState.configDim,
//                            cNm: deviceState.configButtons,
//                            cL: deviceState.childLockL,
//                            cF: deviceState.childLockF,
//                            cM: deviceState.childLockM,
//                            workingMode: deviceState.workingMode,
//                            master: Int(deviceState.master) ?? 0,
//                            ack: deviceState.connectivity,
//                            lightState: deviceState.lState,
//                            lightSpeed: deviceState.lSpeed,
//                            fanState: deviceState.fState,
//                            fanSpeed: deviceState.fSpeed,
//                            controlFrom: deviceState.destButton
//                        )
//                    }
//
//                    allDeviceStates.append(contentsOf: mappedStates)
//                    dispatchGroup.leave()
//                }
//            }
//        }
//
//        dispatchGroup.notify(queue: .main) {
//            self.receivedDeviceStates = allDeviceStates
//            print("✅ All device states fetched: \(self.receivedDeviceStates.count)")
//        }
//    }

    



   
}


extension MainShortCutViewController : UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return homes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
        cell.textLabel?.text = homes[indexPath.row].homeName
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedHome = homes[indexPath.row]
        print("Selected home: \(selectedHome.homeName)")
        
        homenameLabel.text = selectedHome.homeName
      
        fetchRoomsForSelectedHome(homeId: selectedHome.homeServerId)
        isDropdownVisible = false
        dropdownTableView.isHidden = true
    }
}


// MARK: - UICollectionView DataSource & Delegate
extension MainShortCutViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if collectionView == shortcutDeviceCollcetionView {
            return collectionView == shortcutDeviceCollcetionView ? devices.count : 0
        } else if collectionView == roomCollectionView {
            return rooms.count
        }
        
        return 0
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if collectionView == roomCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "roomShortCollectionViewCell", for: indexPath) as! roomShortCollectionViewCell
            let room = rooms[indexPath.row]
            cell.roomNamelabel.text = room.name
            
            if let image = UIImage(named: room.imageName) {
                cell.roomImageView.image = image
            } else {
                cell.roomImageView.image = UIImage(named: "default_image") // Fallback image
            }
            return cell
            
        } else if collectionView == shortcutDeviceCollcetionView {
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ShortcutDeviceCollectionViewCell", for: indexPath) as! ShortcutDeviceCollectionViewCell
            
            let device = devices[indexPath.item]
            
            
            cell.deviceUid = device.deviceUid
            cell.deviceUniqueId = device.uniqueId
            cell.deviecNameLabel.text = "\(device.deviceName)"
           
          
            cell.requestLatestDeviceState(topic: device.uniqueId)
            cell.subscribe_topic_function()
            
            return cell
        }
        
        return UICollectionViewCell()
    }

   
        
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == shortcutDeviceCollcetionView {
            return CGSize(width: 370, height: 452)
        } else {
            return CGSize(width: 100, height: 200)
        }
    }

    }
    



