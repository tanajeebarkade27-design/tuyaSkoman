//
//  AddRoomViewController.swift
//  SkromanIsra
//
//  Created by Admin on 17/02/25.
//

import UIKit
import Alamofire
import SwiftKeychainWrapper

class AddRoomViewController: UIViewController {
    
    @IBOutlet weak var homeNmae: NSLayoutConstraint!
    @IBOutlet weak var roomNameText: UITextField!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var roomIconCollectionView: UICollectionView!
    
    @IBOutlet weak var backgroundImageView: UIImageView!
    
    @IBOutlet weak var saveButton: UIButton!
    
    @IBOutlet weak var homeNameLabel: UILabel!
    
    var userID : String!
    
    var selectedRoomId : String?
    var selectedHomeId: String?
    var selectedRoomName: String?
    var homeName: String?
      
    
    var roomNames: [String] = ["Study Room", "Bed Room", "Theater", "Balcony", "Dining Hall", "Living Room", "Other Room", "Garden", "Gate", "Kitchen", "Lift", "Staircase"]
    
    var roomImage = ["study_room", "bed_room_1", "Theater_2", "balcony_2", "dinning_1", "living_room_1", "living_room_1", "garden_2", "gate_1", "kitchen_2", "lift_1", "staircase"]
  
    
   
  
    var selectedIndex: IndexPath?
    var  homeServerId: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let image = UIImage(named: "okImage")?.resized(to: CGSize(width: 30, height: 30)) {
            saveButton.setImage(image, for: .normal)
        }
        backButton.setTitle("", for: .normal)
        registerixb()
        roomIconCollectionView.dataSource =  self
        roomIconCollectionView.delegate =  self
        
        let savedUserID = KeychainWrapper.standard.string(forKey: "userId")
        print("Saved User ID : =====", savedUserID!)
        
        if savedUserID != nil {
            
            userID = savedUserID
        }
        
        backgroundImageView.contentMode = .scaleAspectFill
            backgroundImageView.image = UIImage(named: "Screen Background")
            backgroundImageView.clipsToBounds = true
        
        print("homeServerId at add room\(homeServerId)")
        
        homeNameLabel.text = homeName
    }
    
    func registerixb() {
        let uiNib = UINib(nibName: "AddRoomCollectionViewCell", bundle: nil)
        roomIconCollectionView.register(uiNib, forCellWithReuseIdentifier: "AddRoomCollectionViewCell")
    }
    
    @IBAction func backButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func saveButton(_ sender: Any) {
        // Check if a room is selected and the room name is entered
        guard let indexPath = selectedIndex else {
            showPopupError()
            return
        }

        guard let roomNameText = roomNameText.text, !roomNameText.isEmpty else {
            showPopupRoomNameeError()
            return
        }

        // Retrieve the selected room name and image name
        let roomName = roomNames[indexPath.row]
        let roomImageName = roomImage[indexPath.row]

         //Show the success popup
        showPopup()
        addRoomApi()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            // Perform the segue or navigate to the RoomViewController directly
            if let roomViewController = self.storyboard?.instantiateViewController(withIdentifier: "RoomViewController") as? RoomViewController {
                roomViewController.roomName = roomNameText // Pass the room name from the text field
                roomViewController.roomImageName = roomImageName

               
//               let newRoom = Room(name: roomNameText, imageName: roomImageName)
//               roomViewController.rooms.append(newRoom) // This ensures the new room is inserted, not removed

                self.navigationController?.pushViewController(roomViewController, animated: true)
            }
        }
    }



    
    @objc func showPopupError() {
        PopupPresenter.showPopup(
            on: self.view,
            animationName: "errors",
            title: "Select Room",
            subtitle: "please select a Room."
        )
    }
    @objc func showPopupRoomNameeError() {
        PopupPresenter.showPopup(
            on: self.view,
            animationName: "errors",
            title: "Room Name",
            subtitle: "Enter a Room Name."
        )
    }
    
    @objc func showPopup() {
        PopupPresenter.showPopup(
            on: self.view,
            animationName: "success",
            title: "Success!",
            subtitle: "Room Added successfully"
        )
    }
}

extension AddRoomViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return roomNames.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AddRoomCollectionViewCell", for: indexPath) as! AddRoomCollectionViewCell
        
        cell.roomNameLabel.text = roomNames[indexPath.row]
        let imageName = roomImage[indexPath.row]
        cell.roomImage.image = UIImage(named: imageName)
        
        // Handle the selection state for each cell
        if selectedIndex == indexPath {
            cell.isSelectedRoom.isHidden = false
        } else {
            cell.isSelectedRoom.isHidden = true 
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let numberOfColumns: CGFloat = 3
        let spacing: CGFloat = 25
        let totalSpacing = (numberOfColumns - 1) * spacing
        let itemWidth = (collectionView.frame.width - totalSpacing - 10) / numberOfColumns
        return CGSize(width: itemWidth, height: itemWidth)
    }
    
    // Detect when a cell is selected
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // If the same cell is selected, deselect it
        if selectedIndex == indexPath {
            selectedIndex = nil
        } else {
            // Otherwise, update the selected index
            selectedIndex = indexPath
        }
        
       
        collectionView.reloadData()
    }
    
    func addRoomApi() {
        guard let homeId = homeServerId,
              let userId = KeychainWrapper.standard.string(forKey: "userId"),
              let roomNameText = roomNameText.text, !roomNameText.isEmpty,
              let indexPath = selectedIndex else {
           // showPopupError()
            return
        }

        let roomIconType = roomNames[indexPath.row] // Use selected room name as roomIconType

        let addRoomParameters: [String: Any] = [
            "homeId": homeId,
            "userId": userId,
            "roomIconType": roomIconType,
            "roomIconId": "",
            "roomName": roomNameText
        ]

        print("Sending API Request with Parameters: \(addRoomParameters)")

        AF.request("http://3.7.18.55:3000/skroman/roomapi/rooms",
                   method: .post,
                   parameters: addRoomParameters,
                   encoding: JSONEncoding.default,
                   headers: nil)
            .responseJSON { response in
                debugPrint(response) // Print full response for debugging
                
                switch response.result {
                case .success(let data):
                    print("API Response: \(data)")

                    if let json = data as? [String: Any],
                       let msg = json["msg"] as? String,
                       let roomId = json["roomId"] as? String,
                       let roomName = json["roomName"] as? String,
                       let roomIconId = json["roomIconId"] as? String,
                       let roomIconType = json["roomIconType"] as? String,
                       let homeId = json["homeId"] as? String,
                       let userId = json["userId"] as? String {

                        print("Response Message: \(msg)")

                        if msg == "Success inert room" {
                           // self.showPopup() // Show success popup
                            
                            // Insert into SQLite database
                            SkromanIsraDatabaseHelper.shared.insertRoom(
                                roomId: roomId,
                                roomName: roomName,
                                roomIconId: roomIconId,
                                roomIconType: roomIconType, tuyaRoomId: -1,
                                homeId: homeId
                              
                            )
                            print("Room inserted into SQLite successfully.")
                        }
                    } else {
                        print("Unexpected Response Format: \(data)")
                    }
                case .failure(let error):
                    print("API Request Failed: \(error.localizedDescription)")
                }
            }
    }


     
}

