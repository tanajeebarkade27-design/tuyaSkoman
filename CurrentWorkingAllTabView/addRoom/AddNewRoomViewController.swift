//
//  AddNewRoomViewController.swift
//  SkromanIsra
//
//  Created by Admin on 29/05/25.
//

import UIKit
import Alamofire
import SwiftKeychainWrapper


class AddNewRoomViewController: UIViewController {
    
    
    @IBOutlet weak var selectedHomeName: UILabel!
    @IBOutlet weak var roomImageCollectionView: UICollectionView!
    
    @IBOutlet weak var roomTextView: UITextField!
    
    
    
    
    @IBOutlet weak var saveButton: UIButton!
    
    var activityIndicator: UIActivityIndicatorView!

    
    
    var HomeId : String?
    var selectedIndex: IndexPath?
    var isEditMode: Bool = false
    var roomToEdit: Room?
    var  homeName: String?

    var roomNames: [String] = []


    
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
   
   
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        selectedHomeName.text =  homeName
        roomTextView.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        if let image = UIImage(named: "okImage")?.resized(to: CGSize(width: 30, height: 30)) {
            saveButton.setImage(image, for: .normal)
        }
        

        
       
        print ("HomeId is \(HomeId)")
        roomImageCollectionView.dataSource = self
            roomImageCollectionView.delegate = self

           
            let nib = UINib(nibName: "addNewRoomCollectionViewCell", bundle: nil)
            roomImageCollectionView.register(nib, forCellWithReuseIdentifier: "addNewRoomCollectionViewCell")
        
        
        
        if isEditMode, let room = roomToEdit {
            roomTextView.text = room.name

            if let index = roomsIconType.firstIndex(where: { $0.image == room.imageName }) {
                selectedIndex = IndexPath(row: index, section: 0)
                roomImageCollectionView.selectItem(at: selectedIndex, animated: false, scrollPosition: [])
                roomImageCollectionView.reloadData()
            }
        }
        activityIndicator = UIActivityIndicatorView(style: .large)
            activityIndicator.center = view.center
            activityIndicator.hidesWhenStopped = true
            view.addSubview(activityIndicator)
        roomNames = roomsIconType.map { $0.name }
    }
    
    
    func showLoading() {
        DispatchQueue.main.async {
            self.activityIndicator.startAnimating()
            self.view.isUserInteractionEnabled = false
        }
    }

    func hideLoading() {
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
            self.view.isUserInteractionEnabled = true
        }
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
    
   

    @IBAction func saveButton(_ sender: Any) {
        // Check if room name is empty
        guard let roomNameText = roomTextView.text, !roomNameText.trimmingCharacters(in: .whitespaces).isEmpty else {
            showRoomNameAlert()
            return
        }
        
        
        if isEditMode {
            update_room_API_Func()
        } else {
            addRoomApi()
        }
    }

    func showRoomNameAlert() {
        let alert = UIAlertController(title: "Enter Room Name", message: "Please enter a room name before saving.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            // Clear the screen (reset fields & selections)
            self.clearRoomEntry()
        }))
        present(alert, animated: true, completion: nil)
    }

    func clearRoomEntry() {
        roomTextView.text = ""
        selectedIndex = nil
        roomImageCollectionView.reloadData()
    }

    
    func addRoomApi() {
        //showLoading()
        guard let homeId = HomeId,
              let userId = KeychainWrapper.standard.string(forKey: "userId"),
              let roomNameText = roomTextView.text, !roomNameText.isEmpty,
              let indexPath = selectedIndex else {
            print("Missing required fields.")
            return
        }

        let roomIconType = roomsIconType[indexPath.row].name

        let addRoomParameters: [String: Any] = [
            "homeId": homeId,
            "userId": userId,
            "roomIconType": roomIconType,
            "roomIconId": "", // not used
            "roomName": roomNameText
        ]

        print("Sending API Request with Parameters: \(addRoomParameters)")

        AF.request(MainApi.url("skroman/roomapi/rooms"),
                   method: .post,
                   parameters: addRoomParameters,
                   encoding: JSONEncoding.default)
            .responseJSON { response in
                debugPrint(response)

                switch response.result {
                case .success(let data):
                    print("API Response: \(data)")
                    self.hideLoading()
                    if let json = data as? [String: Any],
                       let msg = json["msg"] as? String,
                       let roomId = json["roomId"] as? String,
                       let roomName = json["roomName"] as? String,
                       let roomIconId = json["roomIconId"] as? String,
                       let roomIconType = json["roomIconType"] as? String,
                       let homeId = json["homeId"] as? String,
                       let userId = json["userId"] as? String {

                        if msg == "Success inert room" {
                            
                            SkromanIsraDatabaseHelper.shared.insertRoom(
                                roomId: roomId,
                                roomName: roomName,
                                roomIconId: roomIconId,
                                roomIconType: roomIconType, tuyaRoomId: -1,
                                homeId: homeId
                            )
                            print("Room inserted into SQLite successfully.")
                            self.showSuccessAndNavigate()
                        }
                    } else {
                        print("Unexpected Response Format: \(data)")
                    }
                case .failure(let error):
                    print("API Request Failed: \(error.localizedDescription)")
                }
            }
    }
    
    
    
    func showSuccessAndNavigate() {
        let alert = UIAlertController(
            title: "Success",
            message: "Room Added successfully.",
            preferredStyle: .alert
        )

        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            // Close this screen normally
            if let nav = self.navigationController {
                nav.popViewController(animated: true)
            } else {
                self.dismiss(animated: true)
            }

        }

        alert.addAction(okAction)
        present(alert, animated: true)
    }

    @objc func showPopup() {
        PopupPresenter.showPopup(
            on: self.view,
            animationName: "success",
            title: "Success!",
            subtitle: "Room Added successfully"
        )
    }
    
    
    func update_room_API_Func() {
        showLoading()
        // Safely unwrap all required values first
        guard
            let roomId = roomToEdit?.roomId,
            let homeId = roomToEdit?.homeId,
            let roomNameText = roomTextView.text, !roomNameText.isEmpty,
            let selectedIndex = selectedIndex
        else {
            print("Missing required fields.")
            return
        }

        let roomIconType = roomsIconType[selectedIndex.row].name

        let update_room_parameter: Image_Parameters = [
            "roomId": roomId,
            "roomName": roomNameText,
            "roomIconId": "",
            "roomIconType": roomIconType,
            "homeId": homeId
        ]

        AF.request(MainApi.url("skroman/roomapi/roomupdate"), method: .put, parameters: update_room_parameter, encoding: JSONEncoding.default, headers: nil).response { response in
            debugPrint(response)
            self.hideLoading()
            switch response.result {
            case .success(let data):
                do {
                    if let data = data,
                       let jsonOne = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let msg = jsonOne["msg"] as? String {

                        if msg == "Update Room Successfully" {
                            self.showPopupedit()
                            print("✅ Room updated successfully.")
                            SkromanIsraDatabaseHelper.shared.updateRoom(roomId: roomId,
                                       newRoomName: roomNameText,
                                       newRoomIconId: "",
                                                                        newRoomIconType: roomIconType, tuyaRoomId: -1,
                                       homeId: homeId)

                        } else {
                            print("❌ Server error: \(msg)")
                        }

                    } else {
                        print("❌ Invalid response format.")
                    }
                } catch {
                    print("❌ JSON decode error: \(error.localizedDescription)")
                }

            case .failure(let err):
                print("❌ API call failed: \(err.localizedDescription)")
            }
        }
    }

    @objc func showPopupedit() {
        PopupPresenter.showPopup(
            on: self.view,
            animationName: "success",
            title: "Success!",
            subtitle: "Room Edit successfully"
        )
    }
    
}
extension AddNewRoomViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return roomsIconType.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "addNewRoomCollectionViewCell", for: indexPath) as! addNewRoomCollectionViewCell

        let room = roomsIconType[indexPath.item]
        let roomname  =  roomNames[indexPath.row]
        cell.roomNamelabel.text =  roomname
        cell.roomImageView.image = UIImage(named: room.image)

        if selectedIndex == indexPath {
            cell.imageBackgroundView.backgroundColor = UIColor.green.withAlphaComponent(0.6)
        } else {
            cell.imageBackgroundView.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        }


        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedIndex = indexPath
        collectionView.reloadData()
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 75, height: 93)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let cellWidth: CGFloat = 100
        let spacing: CGFloat = 10
        let availableWidth = collectionView.bounds.width

        // Dynamically calculate how many cells can fit (at least 3)
        var cellsPerRow = floor((availableWidth + spacing) / (cellWidth + spacing))
        cellsPerRow = max(cellsPerRow, 3)

        let totalCellWidth = cellsPerRow * cellWidth
        let totalSpacing = (cellsPerRow - 1) * spacing
        let totalContentWidth = totalCellWidth + totalSpacing

        let sideInset = max((availableWidth - totalContentWidth) / 2, 0)

        return UIEdgeInsets(top: 8, left: sideInset, bottom: 8, right: sideInset)
    }


}

