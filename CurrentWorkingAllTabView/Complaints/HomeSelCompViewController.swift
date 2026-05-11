//
//  HomeSelCompViewController.swift
//  SkromanIsra
//
//  Created by Admin on 28/11/25.
//

import UIKit

class HomeSelCompViewController: UIViewController {
    
    
    var homes: [ExpandableHome] = []
    var rooms: [RoomItem] = []
    var fetchedDevices: [Device] = []
    var selectedDevices: [String: Bool] = [:]
    var currentButtonDetails: [ButtonDetails] = []
    var activeHomeIndex: Int? = nil

    @IBOutlet weak var HomeTableView: UITableView!
    
    @IBOutlet weak var buttonCollectionView: UICollectionView!
    
    @IBOutlet weak var register: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let allHomes = SkromanIsraDatabaseHelper.shared.fetchAllHomesData()

        homes = allHomes.map { home in
            ExpandableHome(
                home: home,
                isExpanded: false,
                isSelected: false,
                rooms: []
            )
        }
        registerCell()
        setupButtonCollectionView()
        
        // Outlet is storyboard-wired; keep this guarded to avoid crashing if miswired.
        if let register {
            register.setTitleColor(.white, for: .normal)
            register.setTitleColor(.white, for: .highlighted)
            register.tintColor = .white
            register.adjustsImageWhenHighlighted = false
        } else {
            assertionFailure("`register` outlet not connected in storyboard")
        }

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
    
    func registerCell() {
        HomeTableView.register(UINib(nibName: "HomeSelCompTableViewCell", bundle: nil),
                                   forCellReuseIdentifier: "HomeSelCompTableViewCell")

        HomeTableView.register(UINib(nibName: "RoomSelCompTableViewCell", bundle: nil),
                                   forCellReuseIdentifier: "RoomSelCompTableViewCell")

        HomeTableView.delegate = self
        HomeTableView.dataSource = self
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
    
    func fetchDevicesForRoom(roomId: String, completion: @escaping ([Device]) -> Void) {
        SkromanIsraDatabaseHelper.shared.fetchDevicesByRoomId(roomId: roomId) { devices in
            print("Fetched devices for room: \(devices.count)")
            completion(devices)
        }
    }
    func setupButtonCollectionView() {
        buttonCollectionView.dataSource = self
        buttonCollectionView.delegate = self
print("buttons list")
        let nib = UINib(nibName: "CompDeviceButtonCollectionViewCell", bundle: nil)
        buttonCollectionView.register(nib, forCellWithReuseIdentifier: "CompDeviceButtonCollectionViewCell")
        
       
        buttonCollectionView.isHidden = true
    }
    
    
    @IBAction func RegisterButton(_ sender: Any) {

        guard let vc = navigationController?.storyboard?.instantiateViewController(
            identifier: "CompRegisterViewController"
        ) as? CompRegisterViewController else { return }

    
        var selectedHome = homes.first(where: { $0.isSelected })
        

        // 2️⃣ If user selected only rooms/devices → NO home selected
        if selectedHome == nil {

            // Find the home which contains selected rooms/devices
            for home in homes {
                let roomHasSelection = home.rooms.contains { room in
                    // If room selected OR any device selected → treat as selected
                    room.isSelected || room.devices.contains { selectedDevices[$0.uniqueId] == true }
                }

                if roomHasSelection {
                    selectedHome = home   // Assign automatically
                    break
                }
            }
        }

        // Still no home? Nothing selected
        guard let finalHome = selectedHome else {
            print("❌ No home or room/device selected")
            return
        }

        // Always pass homeId
        vc.selectedHomeId = finalHome.home.homeServerId ?? ""
        vc.complaintCategory = "HOME_AUTOMATION"

        var selectedRoomData: [SelectedRoomData] = []

        for room in finalHome.rooms {

            // Only include rooms that have a selected device OR room is selected
            let roomHasDeviceSelected = room.devices.contains { selectedDevices[$0.uniqueId] == true }

            if room.isSelected || roomHasDeviceSelected {

                for device in room.devices where selectedDevices[device.uniqueId] == true {

                    let buttons = SkromanIsraDatabaseHelper.shared.fetchButtonDetails(uniqueId: device.uniqueId)

                    selectedRoomData.append(
                        SelectedRoomData(
                            roomName: room.roomName,
                            deviceName: device.uniqueId,
                            buttonDetails: buttons
                        )
                    )
                }
            }
        }

        vc.selectedRoomDeviceButtonList = selectedRoomData

        navigationController?.pushViewController(vc, animated: true)
    }

    

}


extension HomeSelCompViewController: UITableViewDataSource, UITableViewDelegate {

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
                withIdentifier: "HomeSelCompTableViewCell",
                for: indexPath
            ) as! HomeSelCompTableViewCell
            
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
                
                // Set THIS home as the ONLY active home
                self.activeHomeIndex = indexPath.section
                
                // Clear selections for all other homes
                for i in 0..<self.homes.count {
                    if i != indexPath.section {
                        self.homes[i].isSelected = false
                        for r in 0..<self.homes[i].rooms.count {
                            self.homes[i].rooms[r].isSelected = false
                            for dev in self.homes[i].rooms[r].devices {
                                self.selectedDevices[dev.uniqueId] = false
                            }
                        }
                    }
                }
                
                // Mark this home selected
                self.homes[indexPath.section].isSelected = true
                
                // Mark all rooms & devices selected
                for r in 0..<self.homes[indexPath.section].rooms.count {
                    self.homes[indexPath.section].rooms[r].isSelected = true
                    for dev in self.homes[indexPath.section].rooms[r].devices {
                        self.selectedDevices[dev.uniqueId] = true
                    }
                }
                tableView.reloadData()
            }


            return cell
            
            
        }
        // ROOM CELL
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "RoomSelCompTableViewCell",
            for: indexPath
        ) as! RoomSelCompTableViewCell
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

        cell.onDeviceCellTapped = { [weak self] buttonDetails in
            guard let self = self else { return }

            // update data source
            self.currentButtonDetails = buttonDetails

            // show/hide collection view depending on data
            self.buttonCollectionView.isHidden = buttonDetails.isEmpty

            // reload on main thread
            DispatchQueue.main.async {
                self.buttonCollectionView.reloadData()
                
               
                if !buttonDetails.isEmpty {
                    self.buttonCollectionView.setContentOffset(.zero, animated: true)
                }
            }
        }

        
        cell.onSelectRoom = { [weak self] in
            guard let self = self else { return }

            // Set active home if not already set
            if self.activeHomeIndex == nil {
                self.activeHomeIndex = indexPath.section
            }
            
            // If user tries to select room from OTHER home → block it
            if self.activeHomeIndex != indexPath.section {
                print("❌ Cannot select room from another home!")
                return
            }
            
            // Normal selection logic
            self.homes[indexPath.section].rooms[roomIndex].isSelected.toggle()
            
            let roomDevices = self.homes[indexPath.section].rooms[roomIndex].devices
            let nowSelected = self.homes[indexPath.section].rooms[roomIndex].isSelected
            
            for dev in roomDevices {
                self.selectedDevices[dev.uniqueId] = nowSelected
            }
            
            // If all rooms selected → home becomes selected
            let allSelected = self.homes[indexPath.section].rooms.allSatisfy { $0.isSelected }
            self.homes[indexPath.section].isSelected = allSelected
            tableView.reloadData()
        }


        return cell

    }
    
    
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
extension HomeSelCompViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return currentButtonDetails.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "CompDeviceButtonCollectionViewCell",
            for: indexPath
        ) as! CompDeviceButtonCollectionViewCell

        let button = currentButtonDetails[indexPath.item]

        cell.buttonName.text = button.buttonName
        
        if let image = UIImage(named: button.buttonIconName) {
            cell.ButtonImage.image = image
        } else {
            cell.ButtonImage.image = UIImage(named: "bulb")
        }

        cell.cellBackgroundCell.layer.cornerRadius = 10
        cell.cellBackgroundCell.clipsToBounds = true

        return cell
    }


    // size: adjust per your UI
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 70, height: 70)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let button = currentButtonDetails[indexPath.item]
        print("Tapped button cell:", button.buttonName)
        // handle tap (trigger action, open detail, etc)
    }
}


struct SelectedRoomData {
    let roomName: String
    let deviceName: String
    let buttonDetails: [ButtonDetails]
}
