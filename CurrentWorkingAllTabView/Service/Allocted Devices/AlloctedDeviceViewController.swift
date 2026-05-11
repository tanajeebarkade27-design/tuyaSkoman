//
//  AlloctedDeviceViewController.swift
//  SkromanIsra
//
//  Created by Admin on 19/11/25.
//

import UIKit
import SwiftKeychainWrapper

class AlloctedDeviceViewController: UIViewController {
    
    
    @IBOutlet weak var backButton: UIButton!
    
    @IBOutlet weak var optionButton: UIButton!
    var popupView: UIView!

    var selectedEmail : String?
    
    var selectedFamilyData: [String: Any]?
    var homesArray: [[String: Any]] = []
    var expandedHomes: [Bool] = []
    var selecetdfamilyUserId : String?
    
    @IBOutlet weak var starttimeLabel: UILabel!
    
    @IBOutlet weak var alloctedtimeView: UIView!
    
    @IBOutlet weak var endTimeLabel: UILabel!
    
    
    @IBOutlet weak var allcotedHomesTableview: UITableView!
    
    
    @IBOutlet weak var startTime: UILabel!
    
    
    @IBOutlet weak var endtime: UILabel!
    
    
    @IBOutlet weak var islimitedView: UIView!
    
    
    @IBOutlet weak var limitedTimeHeight: NSLayoutConstraint!
    
    @IBOutlet weak var accessTimeHeight: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        alloctedtimeView.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        alloctedtimeView.cornerRadius =  15
        alloctedtimeView.clipsToBounds =  true
        addFullWidthLineBelowStartTime()
        if let fullData = selectedFamilyData {
            print("Full Data for selected member: \(fullData)")
            
            if let homes = fullData["homes"] as? [[String: Any]] {
                print("Homes: \(homes)")
            }
            
            if let allocatedDevices = fullData["allocatedDevices"] as? [[String: Any]] {
                print("Allocated Devices: \(allocatedDevices)")
            }
            
            if let email = fullData["familyUserEmail"] as? String {
                selectedEmail = email
            }
            if let familyUserId =  fullData["familyUserId"] as? String{
                
                selecetdfamilyUserId = familyUserId
            }
            
            let isLimited = fullData["isLimited"] as? Int ?? 0

            if isLimited == 0 {
                // Limited = FALSE → Hide both views
                islimitedView.isHidden = true
                alloctedtimeView.isHidden = true

                limitedTimeHeight.constant = 0
                accessTimeHeight.constant = 0

            } else {
                // Limited = TRUE → Show both views
                islimitedView.isHidden = false
                alloctedtimeView.isHidden = false

                limitedTimeHeight.constant = 40
                accessTimeHeight.constant = 140
            }

        }
        if let fullData = selectedFamilyData,
           let homes = fullData["homes"] as? [[String: Any]] {

            self.homesArray = homes
            self.expandedHomes = Array(repeating: false, count: homes.count)
            allcotedHomesTableview.reloadData()
        }
        
        if let fullData = selectedFamilyData,
           let timeSlot = fullData["timeSlot"] as? [String: Any] {

            let fromString = timeSlot["from"] as? String ?? ""
            let toString = timeSlot["to"] as? String ?? ""

            self.startTime.text = convertISOToReadable(fromString)
            self.endtime.text = convertISOToReadable(toString)
        }

        registerCell()

    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }

    
    @IBAction func backButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func optionButton(_ sender: Any) {
        showOptionsPopup()
    }
    func convertISOToReadable(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = formatter.date(from: isoString) {
            let output = DateFormatter()
            output.dateFormat = "dd MMM yyyy, hh:mm a"
            return output.string(from: date)
        }

        return isoString
    }

    func showOptionsPopup() {
        popupView?.removeFromSuperview()
        popupView = UIView(frame: CGRect(x: optionButton.frame.maxX - 150,
                                         y: optionButton.frame.maxY + 10,
                                         width: 150,
                                         height: 100))
        popupView.backgroundColor = .white
        popupView.layer.cornerRadius = 12
        popupView.layer.borderWidth = 1
        popupView.layer.borderColor = UIColor.white.withAlphaComponent(0.4).cgColor
        popupView.clipsToBounds = true
        popupView.isUserInteractionEnabled = true

      
        let deleteBtn = UIButton(frame: CGRect(x: 0, y: 0, width: 150, height: 50))
        deleteBtn.setTitle("Delete Member", for: .normal)
        deleteBtn.setTitleColor(.black, for: .normal)
        
        deleteBtn.addTarget(self, action: #selector(deleteMemberTapped), for: .touchUpInside)

       
        let divider = UIView(frame: CGRect(x: 10, y: 50, width: 130, height: 1))
        divider.backgroundColor = UIColor.white.withAlphaComponent(0.3)

        let editBtn = UIButton(frame: CGRect(x: 0, y: 50, width: 150, height: 50))
        editBtn.setTitle("Edit Allotment", for: .normal)
        editBtn.setTitleColor(.black, for: .normal)
        editBtn.addTarget(self, action: #selector(editAllotmentTapped), for: .touchUpInside)

        // Add all views
        popupView.addSubview(deleteBtn)
        popupView.addSubview(divider)
        popupView.addSubview(editBtn)

        // Add popup to main view
        self.view.addSubview(popupView)
    }
    @objc func deleteMemberTapped() {
        print("Delete Member tapped")
        popupView.removeFromSuperview()
    }

    @objc func editAllotmentTapped() {
        print("Edit Allotment tapped")
        navigateToAllocteDevice()
        popupView.removeFromSuperview()
    }
    func addFullWidthLineBelowStartTime() {

        let line = UIView()
        line.translatesAutoresizingMaskIntoConstraints = false
        line.backgroundColor = UIColor.white.withAlphaComponent(0.3)

        view.addSubview(line)

        NSLayoutConstraint.activate([
            line.topAnchor.constraint(equalTo: starttimeLabel.bottomAnchor, constant: 8),
            line.leadingAnchor.constraint(equalTo: starttimeLabel.leadingAnchor),
            line.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20), // small padding
            line.heightAnchor.constraint(equalToConstant: 1)
        ])
    }
    
    func navigateToAllocteDevice(){
        
        let vc = storyboard?.instantiateViewController(withIdentifier: "DeviceAccessViewController") as! DeviceAccessViewController
        
        vc.selectedEmail = selectedEmail
        vc.selectedFamilyData =  selectedFamilyData
        
        
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func registerCell() {
        allcotedHomesTableview.register(UINib(nibName: "AlloctedHomeViewCell", bundle: nil),
                                   forCellReuseIdentifier: "AlloctedHomeViewCell")

        allcotedHomesTableview.register(UINib(nibName: "AlloctedRoomViewCell", bundle: nil),
                                   forCellReuseIdentifier: "AlloctedRoomViewCell")

        allcotedHomesTableview.delegate = self
        allcotedHomesTableview.dataSource = self
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

extension AlloctedDeviceViewController : UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var total = 0

        for (index, home) in homesArray.enumerated() {
            total += 1  // home row
            
            if expandedHomes[index],
                let rooms = home["rooms"] as? [[String: Any]] {
                total += rooms.count  // add room rows
            }
        }
        return total
    }

    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        var row = indexPath.row

        for (homeIndex, home) in homesArray.enumerated() {

            // HOME CELL
            if row == 0 {
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: "AlloctedHomeViewCell",
                    for: indexPath
                ) as! AlloctedHomeViewCell
                cell.selectionStyle = .none
                cell.homeNameLabel.text = home["homeName"] as? String ?? "Home"

                return cell
            }

            row -= 1

            // ROOM CELLS (if expanded)
            if expandedHomes[homeIndex],
               let rooms = home["rooms"] as? [[String : Any]] {

                if row < rooms.count {
                    let room = rooms[row]

                    let cell = tableView.dequeueReusableCell(
                        withIdentifier: "AlloctedRoomViewCell",
                        for: indexPath
                    ) as! AlloctedRoomViewCell
                    cell.selectionStyle = .none
                     
                    cell.roomNameLabel.text = room["roomName"] as? String ?? "Room"

                    let iconType = room["roomIconType"] as? String ?? ""

                    if let matchedIcon = roomsIconType.first(where: { $0.name == iconType }) {
                        cell.roomIamge.image = UIImage(named: matchedIcon.image)
                    } else {
                        cell.roomIamge.image = UIImage(named: "other")  // fallback
                    }

                    if let devices = room["devices"] as? [[String: Any]] {
                        cell.devices = devices
                    } else {
                        cell.devices = []
                    }

                    cell.AllotedDeviceCollection.reloadData()

                    return cell
                }
            }

        }

        return UITableViewCell()
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        var row = indexPath.row

        for (homeIndex, home) in homesArray.enumerated() {

            // HOME selected
            if row == 0 {
                expandedHomes[homeIndex].toggle()
                tableView.reloadData()
                return
            }

            row -= 1

            // ROOM selected
            if expandedHomes[homeIndex],
               let rooms = home["rooms"] as? [[String: Any]] {

                if row < rooms.count {
                    let roomData = rooms[row]
                    print("Room tapped = \(roomData)")
                    return
                }

                row -= rooms.count
            }
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {

        var row = indexPath.row

        for (homeIndex, home) in homesArray.enumerated() {

            // HOME ROW
            if row == 0 {
                return 60   // HEIGHT FOR HOME CELL
            }

            row -= 1

          
            if expandedHomes[homeIndex],
               let rooms = home["rooms"] as? [[String: Any]] {

                if row < rooms.count {
                    return 140
                }

                row -= rooms.count
            }
        }

        return 60
    }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 12
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }
    
}

 

 
