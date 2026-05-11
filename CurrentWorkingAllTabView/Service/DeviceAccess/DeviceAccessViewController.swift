//
//  DeviceAccessViewController.swift
//  SkromanIsra
//
//  Created by Admin on 15/11/25.
//

import UIKit
import SwiftKeychainWrapper

class DeviceAccessViewController: UIViewController {

    var homes: [ExpandableHome] = []
    var selectedEmail: String?
    var rooms: [RoomItem] = []
    var fetchedDevices: [Device] = []
    var selectedDevices: [String: Bool] = [:]
    
    var selectedFamilyData: [String: Any]?
   
    
    var isLimited: Bool?

    @IBOutlet weak var timerView: UIView!
    
    @IBOutlet weak var homeListTableView: UITableView!
    var selectedHomeId: String?

    @IBOutlet weak var backgroundimage: UIImageView!
    
    @IBOutlet weak var startDateTimer: UIDatePicker!
    
    
    @IBOutlet weak var endDateTimer: UIDatePicker!
    
    var selecetdfamilyUserId: String?
    
    @IBOutlet weak var limitedViewHeight: NSLayoutConstraint!
    
    
    @IBOutlet weak var submitbutton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        timerView.backgroundColor =  UIColor.white.withAlphaComponent(0.10)
        timerView.cornerRadius =  15
        timerView.clipsToBounds =   true
       
        endDateTimer.backgroundColor = .white
        endDateTimer.cornerRadius =  10
        endDateTimer.clipsToBounds =  true
        
        startDateTimer.backgroundColor = .white
        startDateTimer.cornerRadius =  10
        startDateTimer.clipsToBounds =  true
       
        startDateTimer.setValue(UIColor.white, forKey: "textColor")
        endDateTimer.setValue(UIColor.white, forKey: "textColor")
        registerCell()
        backgroundimage.contentMode = .scaleAspectFill
        backgroundimage.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            backgroundimage.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundimage.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundimage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundimage.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        let allHomes = SkromanIsraDatabaseHelper.shared.fetchAllHomesData()

        homes = allHomes.map { home in
            ExpandableHome(
                home: home,
                isExpanded: false,
                isSelected: false,
                rooms: []
            )
        }

        homeListTableView.reloadData()
        
         print("selectedFamilyData\(selectedFamilyData)")
        guard let fullData = selectedFamilyData else { return }
        if let fullData = selectedFamilyData,
           let famId = fullData["familyUserId"] as? String {
            selecetdfamilyUserId = famId
        }
        let isLimited = fullData["isLimited"] as? Int ?? 0

        loadPreselectedDeviceIds()
        
        if let image = UIImage(named: "okImage")?.resized(to: CGSize(width: 35, height: 35)) {
            submitbutton.setImage(image, for: .normal)
        }
    }



    
    @IBAction func backButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
        
    }
    
    
    func registerCell() {
        homeListTableView.register(UINib(nibName: "HomeAccessTableViewCell", bundle: nil),
                                   forCellReuseIdentifier: "HomeAccessTableViewCell")

        homeListTableView.register(UINib(nibName: "RoomAccessTableViewCell", bundle: nil),
                                   forCellReuseIdentifier: "RoomAccessTableViewCell")

        homeListTableView.delegate = self
        homeListTableView.dataSource = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
       
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
        
    }


    func fetchDevicesForRoom(roomId: String, completion: @escaping ([Device]) -> Void) {
        SkromanIsraDatabaseHelper.shared.fetchDevicesByRoomId(roomId: roomId) { devices in
            print("Fetched devices for room: \(devices.count)")
            completion(devices)
        }
    }
    
    
    @IBAction func isLimitedToggleButton(_ sender: UISwitch) {
        isLimited = sender.isOn
        print("⏳ isLimited = \(isLimited)")
    }

    func validateTimeSlot() -> Bool {
        
        let start = startDateTimer.date
        let end = endDateTimer.date
        let now = Date()
        
        
        if start < now {
            showAlert("Invalid Start Time", "Start time cannot be in the past.")
            return false
        }

        
        if end < now {
            showAlert("Invalid End Time", "End time cannot be in the past.")
            return false
        }

        
        let calendar = Calendar.current
        if calendar.isDate(start, inSameDayAs: end) {
            if end <= start {
                showAlert("Invalid Time Slot", "End time must be greater than start time when both dates are same.")
                return false
            }
        } else {
           
            if end <= start {
                showAlert("Invalid Time Slot", "End date/time must be greater than start date/time.")
                return false
            }
        }
        
        return true
    }

    func showAlert(_ title: String, _ message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true)
    }

    func isoString(from date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }


    @IBAction func submitButton(_ sender: Any) {

       
        let selectedDeviceIds = selectedDevices.filter { $0.value }.map { $0.key }

        let userId = KeychainWrapper.standard.string(forKey: "userId") ?? ""
        let familyUserId = selecetdfamilyUserId ?? ""

        if !validateTimeSlot() {
               return
           }

           print("⏳ Time validation passed. Proceeding with API...")
           
        let startISO = isoString(from: startDateTimer.date)
        let endISO = isoString(from: endDateTimer.date)

        print("▶ Start Time:", startISO)
        print("▶ End Time:", endISO)

      
        let body: [String: Any] = [
            "userId": userId,
            "familyUserId": familyUserId,
            "allocatedDevices": [
                [
                    "primaryUserId": userId,
                    "devicesList": selectedDeviceIds
                ]
            ],
            "isLimited": isLimited,
            "timeSlot": [
                "from": startISO,
                "to": endISO
            ]
        ]


        print("📌 Final API Body:", body)

        // 4. Convert to JSON
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            print("❌ JSON encode error")
            return
        }

        // 5. API request
        guard let url = URL(string: MainApi.url("skroman/userapi/updateAllocateDevices")) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        URLSession.shared.dataTask(with: request) { data, response, error in

            if let error = error {
                print("❌ API Error:", error.localizedDescription)
                return
            }

            guard let data = data else {
                print("❌ No data received")
                return
            }

             
            if let rawString = String(data: data, encoding: .utf8) {
                print("🔍 RAW RESPONSE:")
                print(rawString)
            }

           
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                print("✅ Parsed JSON:", json)

                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Success",
                                                  message: "Devices updated successfully!",
                                                  preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default){ _ in
                        self.navigationController?.popViewController(animated: true)
                    })
                    self.present(alert, animated: true)
                }

            } catch {
                print("❌ JSON parse error:", error)
            }

        }.resume()

    }


    
    func loadPreselectedDeviceIds() {
        guard let fullData = selectedFamilyData else { return }
        guard let familyHomes = fullData["homes"] as? [[String: Any]] else { return }

        for home in familyHomes {
            if let rooms = home["rooms"] as? [[String: Any]] {
                for room in rooms {
                    if let devices = room["devices"] as? [[String: Any]] {
                        for device in devices {
                            if let uid = device["unique_id"] as? String {
                                selectedDevices[uid] = true   // PRESELECT DEVICE
                            }
                        }
                    }
                }
            }
        }

        print("🔥 Preselected uniqueIds:", selectedDevices)
    }


    let roomsIconType: [RoomIconType] = [
     
        RoomIconType(name: "Living Room", image: "livingRoom"),
        RoomIconType(name: "Living Room 1", image: "lLiving Room 1"),
        RoomIconType(name: "Living Room 2", image: "Living Room 2"),
      
       
        RoomIconType(name: "Bed Room", image: "Bed"),
        RoomIconType(name: "Bed Room 1", image: "Bed Room 1"),
        RoomIconType(name: "Bed Room 2", image: "Bed Room 2"),
        
        RoomIconType(name: "Study Room", image: "study"),
        RoomIconType(name: "Kitchen", image: "Kitchen"),
        RoomIconType(name: "Dining Hall", image: "Dining"),
       
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

        RoomIconType(name: "Other Room", image: "other"),
        
        
        
        
    ]

   
    
    

}


extension DeviceAccessViewController: UITableViewDataSource, UITableViewDelegate {

    // MARK: - Sections
    func numberOfSections(in tableView: UITableView) -> Int {
        return homes.count
    }

    // MARK: - Rows
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let homeData = homes[section]
        return homeData.isExpanded ? homeData.rooms.count + 1 : 1
    }

    // MARK: - Cells
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let homeData = homes[indexPath.section]

        if indexPath.row == 0 {

            let cell = tableView.dequeueReusableCell(
                withIdentifier: "HomeAccessTableViewCell",
                for: indexPath
            ) as! HomeAccessTableViewCell

            cell.homeNamelabel.text = homeData.home.homeName

            // ✔ Home selection image
            let isSelected = homeData.isSelected
            let imageName = isSelected ? "Select" : "deSelect"
            if let originalImage = UIImage(named: imageName)?.resized(to: CGSize(width: 24, height: 24)) {
                cell.isSelectedHome.setImage(originalImage, for: .normal)
            }

           
            let isExpanded = homeData.isExpanded
            let arrowName = isExpanded ? "chevron.compact.up" : "chevron.compact.down"
            cell.isExpandImage.image = UIImage(systemName: arrowName)
            cell.isExpandImage.tintColor = .white

          
            cell.onSelectHome = { [weak self] in
                guard let self = self else { return }

               
                self.homes[indexPath.section].isSelected.toggle()
                let isSelectedNow = self.homes[indexPath.section].isSelected

               
                for roomIndex in 0 ..< self.homes[indexPath.section].rooms.count {
                    self.homes[indexPath.section].rooms[roomIndex].isSelected = isSelectedNow

                   
                    let roomDevices = self.homes[indexPath.section].rooms[roomIndex].devices
 
                    for device in roomDevices {
                        self.selectedDevices[device.uniqueId] = isSelectedNow
                    }
                }

              
                tableView.reloadSections(IndexSet(integer: indexPath.section), with: .none)
            }

            return cell
        }

        // ROOM CELL
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "RoomAccessTableViewCell",
            for: indexPath
        ) as! RoomAccessTableViewCell
        cell.selectionStyle = .none
        let roomIndex = indexPath.row - 1
        let room = homeData.rooms[roomIndex]

        cell.roomNameLabel.text = room.roomName
        if let matchedIcon = roomsIconType.first(where: { $0.name == room.roomIconType }) {
            cell.roomIamgeView.image = UIImage(named: matchedIcon.image)
        } else {
            cell.roomIamgeView.image = UIImage(named: "other")  // fallback
        }

      
        cell.roomDevices = room.devices

        let isSelected = room.isSelected
        let selectedImage = UIImage(named: "Select")?.resized(to: CGSize(width: 20, height: 20))
        let deselectedImage = UIImage(named: "deSelect")?.resized(to: CGSize(width: 20, height: 20))

        cell.isRoomSelcted.setImage(isSelected ? selectedImage : deselectedImage, for: .normal)
        cell.parentVC = self

      

        
        cell.onSelectRoom = { [weak self] in
            guard let self = self else { return }

          
            self.homes[indexPath.section].rooms[roomIndex].isSelected.toggle()

           
            let allSelected = self.homes[indexPath.section].rooms.allSatisfy { $0.isSelected }

           
            let anyDeselected = self.homes[indexPath.section].rooms.contains { !$0.isSelected }

           
            self.homes[indexPath.section].isSelected = allSelected

            let roomDevices = self.homes[indexPath.section].rooms[roomIndex].devices
            let isSelectedNow = self.homes[indexPath.section].rooms[roomIndex].isSelected

          
            for device in roomDevices {
                self.selectedDevices[device.uniqueId] = isSelectedNow
            }

           
            tableView.reloadRows(at: [indexPath], with: .none)
            tableView.reloadSections(IndexSet(integer: indexPath.section), with: .none)
        }

        return cell

    }
    
    

    // MARK: - Row Selection (Expand / Collapse)
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let homeItem = homes[indexPath.section]

        if indexPath.row == 0 {

            var updatedHome = homeItem

            if updatedHome.isExpanded {
                updatedHome.isExpanded = false
                homes[indexPath.section] = updatedHome
                tableView.reloadSections(IndexSet(integer: indexPath.section), with: .automatic)
                return
            }

            let homeId = updatedHome.home.homeServerId ?? ""

            SkromanIsraDatabaseHelper.shared.fetchRoomsByHomeId(homeServerId: homeId) { fetchedRooms in

                
                var orderedRooms: [RoomItem] = fetchedRooms.map {
                    RoomItem(roomId: $0.roomId,
                             roomName: $0.roomName,
                             roomIconId: $0.roomIconId,
                             roomIconType: $0.roomIconType,
                             homeId: $0.homeId,
                             isSelected: updatedHome.isSelected)
                }

                let dispatchGroup = DispatchGroup()

               
                for (index, room) in orderedRooms.enumerated() {

                    dispatchGroup.enter()
                    self.fetchDevicesForRoom(roomId: room.roomId) { devices in
                       
                        orderedRooms[index].devices = devices

                       
                        print("DEBUG: roomId=\(room.roomId) fetched device ids:", devices.map { $0.uniqueId })
                        print("DEBUG: selectedDevices keys:", Array(self.selectedDevices.keys))


                         
                        for device in devices {
                            if self.selectedDevices[device.uniqueId] == true {
                                // already selected → do nothing
                            }
                        }

                        
                        let allSelected = devices.allSatisfy { self.selectedDevices[$0.uniqueId] ?? false }
                        orderedRooms[index].isSelected = allSelected

                        dispatchGroup.leave()
                    }

                }

                // 3️⃣ After ALL rooms have devices → update UI
                dispatchGroup.notify(queue: .main) {

                    print("DEBUG: dispatchGroup.notify — selectedDevices count:", self.selectedDevices.count)
                    for (i, r) in orderedRooms.enumerated() {
                        print("DEBUG: orderedRooms[\(i)].roomId=\(r.roomId) devices:", r.devices.map { $0.uniqueId })
                    }

                    for roomIndex in 0..<orderedRooms.count {
                        let devices = orderedRooms[roomIndex].devices

                        for device in devices {
                            if self.selectedDevices[device.uniqueId] == true {
                                // mark device as selected (already in dictionary)
                            }
                        }

                      
                        let allSelected = devices.allSatisfy { self.selectedDevices[$0.uniqueId] ?? false }
                        orderedRooms[roomIndex].isSelected = allSelected
                    }

                  
                    let allRoomsSelected = orderedRooms.allSatisfy { $0.isSelected }
                    updatedHome.isSelected = allRoomsSelected

                
                    for roomIndex in 0..<orderedRooms.count {
                        let devices = orderedRooms[roomIndex].devices
                        let allSelected = devices.allSatisfy { self.selectedDevices[$0.uniqueId] ?? false }
                        orderedRooms[roomIndex].isSelected = allSelected
                    }

                   

                    updatedHome.rooms = orderedRooms

                    updatedHome.isExpanded = true
                    self.homes[indexPath.section] = updatedHome

                    // 5️⃣ Reload UI
                    tableView.reloadSections(IndexSet(integer: indexPath.section), with: .automatic)
                }

            }

            return
        }

        let roomIndex = indexPath.row - 1
        var selectedRoom = homes[indexPath.section].rooms[roomIndex]

        fetchDevicesForRoom(roomId: selectedRoom.roomId) { devices in
            
            // Save devices to the RoomItem
            self.homes[indexPath.section].rooms[roomIndex].devices = devices

            // Reload this specific row to update deviceCollectionView
            tableView.reloadRows(at: [indexPath], with: .fade)
        }

    }


    // MARK: - Footer Spacing
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 12
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }

    // MARK: - Row Height
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        // Home cell height
        if indexPath.row == 0 {
            return 60
        }

        let roomIndex = indexPath.row - 1
        let room = homes[indexPath.section].rooms[roomIndex]

      
        if room.devices.isEmpty {
            return 60
        }

      
        return 140
    }

    
}


struct ExpandableHome {
    var home: Home
    var isExpanded: Bool
    var isSelected: Bool
    var rooms: [RoomItem]
}


struct RoomItem {
    var roomId: String
    var roomName: String
    var roomIconId: String
    var roomIconType: String
    var homeId: String
    var isSelected: Bool
    var devices: [Device] = []
}
