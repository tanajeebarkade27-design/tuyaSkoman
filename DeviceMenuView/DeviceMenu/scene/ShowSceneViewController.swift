//
//  ShowSceneViewController.swift
//  SkromanIsra
//
//  Created by Admin on 14/02/25.
//

import UIKit
import AWSCore
import AWSIoT
import Alamofire

class ShowSceneViewController: UIViewController {
    
    @IBOutlet weak var closedButton: UIButton!
    @IBOutlet weak var sceneSelectionView: UICollectionView!
    
    @IBOutlet weak var sceneCollectionView: UICollectionView!
    @IBOutlet weak var sceneViewHeight: NSLayoutConstraint!
    
    @IBOutlet weak var showSceneHeight: UIView!
    @IBOutlet weak var sceneshowView: UIView!
    @IBOutlet weak var sceneView: UIView!
    var devicestate: [DeviceStateArray] = []
    var deviceVc : DeviceViewController?
    var devices: [Device] = []
    var deviceScene: [DeviceScene] = []
    var sceneNumber : String?
    var selectedSceneIndex: IndexPath?
   
 
    var buttonItems: [(name: String, type: String, status: String)] = []
    var deviceUinqueId : String?
    override func viewDidLoad() {
        super.viewDidLoad()
        closedButton.setTitle("", for: .normal)
        closedButton.setTitleColor(.black, for: .normal)
        
        if let image = UIImage(named: "close")?.resized(to: CGSize(width: 30, height: 30)) {
            closedButton.setImage(image, for: .normal)
        }
        sceneView.borderColor =  .gray
        sceneView.layer.cornerRadius = 8
        sceneView.clipsToBounds = true
       
        registerCells()
        if let firstScene = devices.first {
            deviceUinqueId = firstScene.uniqueId
            print("firstScene\(firstScene)")
        } else {
            deviceUinqueId = nil
        }
        sceneViewHeight.constant = 150
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    @IBAction func closedButton(_ sender: Any) {
           navigationController?.popViewController(animated: true)
    }
    
    func registerCells() {
        let deviceNib = UINib(nibName: "SceneNumberCollectionViewCell", bundle: nil)
        sceneSelectionView.register(deviceNib, forCellWithReuseIdentifier: "SceneNumberCollectionViewCell")

        let sceneNib = UINib(nibName: "ScenesCollectionViewCell", bundle: nil)
        sceneCollectionView.register(sceneNib, forCellWithReuseIdentifier: "ScenesCollectionViewCell")
        sceneCollectionView.dataSource =  self
        sceneCollectionView.delegate =  self
        sceneSelectionView.dataSource = self
        sceneSelectionView.delegate = self
    }
    func updateDeviceStates(from scene: DeviceScene) {
        guard let firstDevice = devicestate.first else {
            print("No device state found!")
            return
        }

        print("Updating device states for scene: \(scene)")

        let unwantedChars: Set<Character> = ["S", "W", "X", "G", "H", "I", "J"]
        
        var updatedButtonItems: [(name: String, type: String, status: String)] = []

        // **Handling L State Buttons**
        let statusArray = Array(scene.LState)
        let configButtonsArray = Array(scene.configButtons ?? "")

        for (index, button) in configButtonsArray.enumerated() {
            guard index < statusArray.count else { continue } // Prevent index out of range

            let status = String(statusArray[index]) // ✅ Convert Character to String
            let filteredName = String(button).filter { !unwantedChars.contains($0) }

            // **Only add if the button is not in unwanted characters**
            if !filteredName.isEmpty {
                updatedButtonItems.append((name: filteredName, type: String(button), status: status))
            }
        }

       
        if scene.fanDest == "1" {
            let fanStatus = statusArray.first.map { String($0) } ?? "0"

            updatedButtonItems.append((name: "Fan", type: "F", status: fanStatus))
        }

        // Assign updated list to buttonItems
        buttonItems = updatedButtonItems

        print("Updated buttonItems: \(buttonItems)")

        DispatchQueue.main.async {
            self.sceneCollectionView.reloadData()
        }
    }


   
    
}


extension ShowSceneViewController :  UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == sceneCollectionView {
            print("Scene Collection Count: \(buttonItems.count)")
            return buttonItems.count
        } else if collectionView == sceneSelectionView {
            return deviceScene.count
        }
        return 0
    }

    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == sceneCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ScenesCollectionViewCell", for: indexPath) as! ScenesCollectionViewCell

            var item = buttonItems[indexPath.item]
            print("Configuring cell at index \(indexPath.item) with data: \(item)")

            // **Remove unwanted characters from name**
            let unwantedChars: Set<Character> = ["S", "W", "X", "G", "H", "I", "J"]
            let filteredName = item.name.filter { !unwantedChars.contains($0) }

            // Display type + index
            cell.deviceNamelabel.text = "\(filteredName)\(indexPath.item + 1)"

            // Set image based on type
            switch item.type {
            case "L":
                cell.deviceImageView.image = UIImage(named: "bulb")
            case "O":
                cell.deviceImageView.image = UIImage(named: "curtains_open")
            case "C":
                cell.deviceImageView.image = UIImage(named: "curtains_close")
            case "Q":
                cell.deviceImageView.image = UIImage(named: "curtains_Open")
            case "Y":
                cell.deviceImageView.image = UIImage(named: "curtains_close")
            case "F":
                cell.deviceImageView.image = UIImage(named: "ceiling-fan")
            case "D":
                cell.deviceImageView.image = UIImage(named: "lock-2")
            default:
                cell.deviceImageView.image = nil
            }

            // **Set background color based on status**
            let activeColor = UIColor(hex: "#FAEDCB")
            let inactiveColor = UIColor(hex: "#D3D3D3")

          
            cell.cellbackgroundview.backgroundColor = (item.status == "1") ? activeColor : inactiveColor

            return cell
        }
     
    
 else  if collectionView == sceneSelectionView {
     let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SceneNumberCollectionViewCell", for: indexPath) as! SceneNumberCollectionViewCell

     let sceneData = deviceScene[indexPath.item]
     cell.sceneNumberLabel.text = sceneData.sceneName

     // **Set background color for selected cell**
     if selectedSceneIndex == indexPath {
         cell.sceneBackgroundview?.backgroundColor = .systemOrange
     } else {
         cell.sceneBackgroundview?.backgroundColor = .clear
     }

     return cell
 }
        return UICollectionViewCell()
    }

    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == sceneSelectionView {
            selectedSceneIndex = indexPath  // Store selected index
            let selectedScene = deviceScene[indexPath.item]
            print("Selected Scene: \(selectedScene)")

            updateDeviceStates(from: selectedScene)
            print("Updated buttonItems: \(buttonItems)")

            DispatchQueue.main.async {
                self.sceneCollectionView.reloadData()
                self.sceneSelectionView.reloadData()  // Reload sceneSelectionView to update colors
                self.sceneViewHeight.constant = 570
            }
        }
    }


    

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if collectionView == sceneCollectionView {
            let numberOfColumns: CGFloat = 3
            let spacing: CGFloat = 25
            let totalSpacing = (numberOfColumns - 1) * spacing
            let itemWidth = (collectionView.frame.width - totalSpacing - 10) / numberOfColumns
            return CGSize(width: itemWidth, height: itemWidth)
        }else if collectionView == sceneSelectionView {
            
            return CGSize(width: 90, height: 50)
        }
        else {
            return CGSize(width: 100, height: 100)
        }
    }
}
