//
//  EditRoomsSceneViewController.swift
//  SkromanIsra
//
//  Created by Admin on 14/08/25.
//

import UIKit
 import Alamofire

class EditRoomsSceneViewController: UIViewController {
    var sceneIndex: Int?
    var devices: [Device] = []
    var selectedSceneIconName: String?

    @IBOutlet weak var selectedsceneView: UIView!
    
    
    
    
    @IBOutlet weak var scenebackView: UIView!
    
    
    @IBOutlet weak var sceneImageView: UIImageView!
    
    
    @IBOutlet weak var SceneiconCollectionView: UICollectionView!
    @IBOutlet weak var scenename: UILabel!
    
    @IBOutlet weak var sceneNametext: UITextField!
    var expandedIndexPath: IndexPath? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        selectedsceneView.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        selectedsceneView.layer.cornerRadius = 10
        selectedsceneView.clipsToBounds = true
        sceneImageView.backgroundColor = UIColor.white.withAlphaComponent(0.20)
        
        scenebackView.layer.cornerRadius = 15
        scenebackView.clipsToBounds = true
         
        SceneiconCollectionView.dataSource = self
        SceneiconCollectionView.delegate = self
        SceneiconCollectionView.register(
            UINib(nibName: "RoomSceneIconCollectionViewCell", bundle: nil),
            forCellWithReuseIdentifier: "RoomSceneIconCollectionViewCell"
        )
         print ("devices at edit\(devices)")
        print("sceneIndex\(sceneIndex)")
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
    
    let sceneIconsList: [SceneIconModel] = [
        SceneIconModel(name: "Morning", imageName: "scene_morning"),
        SceneIconModel(name: "Evening", imageName: "scene_evening"),
        SceneIconModel(name: "Away", imageName: "scene_away"),
        SceneIconModel(name: "Home", imageName: "scene_home"),
        SceneIconModel(name: "Dinner", imageName: "scene_dinner"),
        SceneIconModel(name: "Bed", imageName: "scene_bed"),
        SceneIconModel(name: "Movie", imageName: "scene_movie"),
        SceneIconModel(name: "Party", imageName: "scene_party"),
        SceneIconModel(name: "Read", imageName: "scene_read"),
        SceneIconModel(name: "Game", imageName: "scene_game"),
        SceneIconModel(name: "Focus", imageName: "scene_focus"),
        SceneIconModel(name: "Gym", imageName: "scene_gym"),
        SceneIconModel(name: "Secure", imageName: "scene_secure"),
        SceneIconModel(name: "Panic", imageName: "scene_panic"),
        SceneIconModel(name: "Alert", imageName: "scene_alert"),
        SceneIconModel(name: "Guard", imageName: "scene_guard"),
        SceneIconModel(name: "Vacation", imageName: "scene_vacation"),
        SceneIconModel(name: "Lock", imageName: "scene_lock"),
        SceneIconModel(name: "Clean", imageName: "scene_clean"),
        SceneIconModel(name: "Water", imageName: "scene_water"),
        SceneIconModel(name: "Guest", imageName: "scene_guest"),
        SceneIconModel(name: "Lawn", imageName: "scene_lawn"),
        SceneIconModel(name: "Energy", imageName: "scene_energy"),
        SceneIconModel(name: "Park", imageName: "scene_park")
    ]

    @IBAction func submitButton(_ sender: Any) {
        guard let sceneIndex = sceneIndex else {
            print("❌ sceneIndex is nil")
            return
        }
        guard !devices.isEmpty else {
            print("❌ No devices available")
            return
        }
        guard let sceneNameText = sceneNametext.text, !sceneNameText.isEmpty else {
            print("❌ Scene name is empty")
            return
        }
        guard let sceneIconName = selectedSceneIconName else {
            print("❌ Scene icon not selected")
            return
        }

        let roomId = devices.first?.roomId ?? ""
        let sceneNo = String(sceneIndex + 1)

        let parameters: [String: Any] = [
            "roomId": roomId,
            "sceneNo": sceneNo,
            "sceneName": sceneNameText,
            "sceneIcon": sceneIconName   // ✅ send imageName instead of label text
        ]

        print("📤 Sending parameters: \(parameters)")
        
        let url = "http://3.7.18.55:3000/skroman/roomapi/updateRoomScene"
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default)
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    print("✅ API Success: \(value)")
                    SkromanIsraDatabaseHelper.shared.updateRoomScene(
                        roomId: roomId,
                        sceneNo: sceneNo,
                        newName: sceneNameText,
                        newIcon: sceneIconName
                    )
                    DispatchQueue.main.async {
                        self.showPopupUpdate()
                        
                    }
                case .failure(let error):
                    print("❌ API Error: \(error.localizedDescription)")
                    if let data = response.data,
                       let str = String(data: data, encoding: .utf8) {
                        print("🔍 Server response: \(str)")
                    }
                }
            }
    }

    @objc func showPopupUpdate() {
        showPopupPresenter.showPopup1(
            on: self.view,
            animationName: "coffee 2",
            title: "scene Icon Update",
            subtitle: "Secen Icon Updated successfully."
        )
    }
    
    @IBAction func cancelButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
}
extension EditRoomsSceneViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return sceneIconsList.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "RoomSceneIconCollectionViewCell",
            for: indexPath
        ) as! RoomSceneIconCollectionViewCell
        
        let item = sceneIconsList[indexPath.item]
        
        // Configure UI
        cell.sceneNameLabel.text = item.name
        cell.sceneImage.image = UIImage(named: item.imageName)
        
      
      
        
        return cell
    }
    
   
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let numberOfColumns: CGFloat = 3
        let spacing: CGFloat = 15
        let totalSpacing = (numberOfColumns - 1) * spacing
        let itemWidth = (collectionView.frame.width - totalSpacing - 10) / numberOfColumns
        return CGSize(width: itemWidth, height: itemWidth)
    }
    

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = sceneIconsList[indexPath.item]
        print("✅ Selected Scene: \(item.name), image: \(item.imageName)")
        
        scenename.text = item.name
        sceneImageView.image = UIImage(named: item.imageName)
        sceneNametext.text = item.name
        
        // 🔹 Save imageName for API
        selectedSceneIconName = item.imageName
    }

    
    
    
    
    func updateSceneNames(with serverIds: [String]) {
        let url = "http://3.7.18.55:3000/roomapi/updateRoomScene"

       
        let shortcutsPayload: [[String: Any]] = serverIds.map { serverId in
            [
                "roomId":"",
                "sceneNo":"",
                "sceneName":"",
                "sceneIcon": ""
            ]
        }

        let parameters: [String: Any] = [
            "shortcuts": shortcutsPayload
        ]

        print("📤 Sending parameters: \(parameters)")

        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default)
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    print("✅ API Success: \(value)")

                case .failure(let error):
                    print("❌ API Error: \(error.localizedDescription)")
                    if let data = response.data,
                       let str = String(data: data, encoding: .utf8) {
                        print("🔍 Server response: \(str)")
                    }
                }
            }
    }

    

}



struct SceneIconModel {
    let name: String
    let imageName: String
}
