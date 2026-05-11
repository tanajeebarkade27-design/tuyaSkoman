//
//  ShowScheduleViewController.swift
//  SkromanIsra
//
//  Created by Admin on 11/03/25.
//

import UIKit
import AWSCore
import AWSIoT
import Alamofire


class ShowScheduleViewController: UIViewController {
   
    @IBOutlet weak var backButton: UIButton!
    
    @IBOutlet weak var sceneButton: UISwitch!
    var devicestate: [DeviceStateArray] = []
    var deviceVc : DeviceViewController?
    var devices: [Device] = []
    var deviceScene: [DeviceScene] = []
    var buttonItems1: [String] = []
    var deviceUid: String?
    var deviceUniqueId: String?
    var selectedDevice: Device?
    var buttonItems: [(name: String, type: String, status: String)] = []
    var updatedDeviceStates: [(name: String, type: String, status: String)] = []
    @IBOutlet weak var scheduleCollevtioonView: UICollectionView!
    
    @IBOutlet weak var sceneCollectionView: UICollectionView!
    @IBOutlet weak var sceneView: UIView!
    
    @IBOutlet weak var sceneheight: NSLayoutConstraint!
    var schduleNumber : String?
    
    @IBOutlet weak var nextbutton: UIButton!
    
    @IBOutlet weak var schuleView: UIView!
    var selectedSceneIndex: IndexPath?
    
    @IBOutlet weak var backgroundimage: UIImageView!
    
    @IBOutlet var backgroundView: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()
        let buttons: [UIButton] = [ backButton,nextbutton ]
        for button in buttons {
            button.backgroundColor = .white
            button.setTitleColor(.black, for: .normal)
            button.layer.cornerRadius = 20
            button.layer.masksToBounds = true
        }
        backgroundimage.contentMode = .scaleAspectFill
        backgroundimage.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            backgroundimage.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundimage.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundimage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundimage.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        backButton.setTitleColor(.black, for: .normal)
        
        if let image = UIImage(named: "close")?.resized(to: CGSize(width: 20, height: 20)) {
            backButton.setImage(image, for: .normal)
        }
        //schuleView.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        schuleView.cornerRadius = 15
        sceneButton.isOn = false
        registerXib()
        scheduleCollevtioonView.dataSource =  self
        scheduleCollevtioonView.delegate =  self
        sceneCollectionView.dataSource =  self
        sceneCollectionView.delegate =  self
        parseDeviceState()
        print("buttonItems atd \(devicestate)")
        
        sceneView.isHidden =  true
        sceneCollectionView.isHidden =  true
        if let firstState = devicestate.first {
               deviceUid = firstState.deviceNumber
               deviceUniqueId = firstState.uniqueID
           } else {
               deviceUid = nil
               deviceUniqueId = nil
           }
        
        sceneheight.constant = 0
        fetchDeviceScenes()
        print ("deviceScene  at \(deviceScene)")
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
        nextbutton.tintColor = .white
        backButton.tintColor =  .white
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    
   
    func toggleSceneView(show: Bool) {
           UIView.animate(withDuration: 0.3) {
             
               self.sceneheight.constant = show ? 50 : 0
               self.view.layoutIfNeeded()
           }
       }
    
    func parseDeviceState() {
        guard let device = devicestate.first else { return }

        buttonItems.removeAll()
        updatedDeviceStates.removeAll()

        let unwantedChars: Set<Character> = ["S", "W", "X", "G", "H", "I", "J"]
        let filteredcNm = device.cNm.filter { !unwantedChars.contains($0) }

        for (index, char) in filteredcNm.enumerated() {
            let type: String
            let name: String
            let status: String

            switch char {
            case "L":
                type = "L"
                name = "Light \(index + 1)"
                status = (index < device.lightState.count) ?
                         String(device.lightState[device.lightState.index(device.lightState.startIndex, offsetBy: index)]) : "0"
            case "O":
                type = "O"
                name = "Curtains Open"
                status = "0"
            case "C":
                type = "C"
                name = "Curtains Close"
                status = "0"
            case "D":
                type = "D"
                name = "Door Lock"
                status = "0"
            default:
                continue
            }

            let item = (name: name, type: type, status: status)
            buttonItems.append(item)
            updatedDeviceStates.append(item)
        }

        if device.fanState != "000" {
            for (index, char) in device.fanState.enumerated() {
                let item = (name: "Fan \(index + 3)", type: "F", status: "0")
                buttonItems.append(item)
                updatedDeviceStates.append(item)
            }
        } else {
            let item = (name: "Fan", type: "F", status: "0")
            buttonItems.append(item)
            updatedDeviceStates.append(item)
        }



        scheduleCollevtioonView.reloadData()
    }

    
    
    func fetchDeviceScenes() {
        guard let uniqueId = deviceUniqueId, !uniqueId.isEmpty else {
              print("❌ deviceUniqueId is nil or empty")
              return
          }

print("uniqueid att \(uniqueId)")
        DispatchQueue.main.async {
            self.deviceScene.removeAll()
            self.sceneCollectionView.reloadData()
        }

        let fetchedScenes = SkromanIsraDatabaseHelper.shared.fetchScenesByUniqueId(uniqueId: uniqueId )

        // ✅ Sort scenes by `sceneNo` (converted to Int)
        let sortedScenes = fetchedScenes.sorted {
            (Int($0.sceneNo) ?? 0) < (Int($1.sceneNo) ?? 0)
        }
        print("fetchedScenes\(fetchedScenes)")

        DispatchQueue.main.async {
            self.deviceScene = sortedScenes
            print("✅ Sorted Scene List: \(self.deviceScene.map { "\($0.sceneNo): \($0.sceneName) " })")
            print("all scene data\(self.deviceScene)")
            self.sceneCollectionView.reloadData()
        }
    }

    func updateDeviceStates(from scene: DeviceScene) {
        guard let device = devicestate.first else {
            print("⚠️ No device state available.")
            return
        }

        print("🔄 Updating device states for scene: \(scene.sceneName)")

        buttonItems.removeAll()
        updatedDeviceStates.removeAll()

        // --- Handle Lights ---
        let lightStates = Array(scene.LState)
        let cNmArray = Array(device.cNm)
        let unwantedChars: Set<Character> = ["S", "W", "X", "G", "H", "I", "J"]

        for (index, char) in cNmArray.enumerated() {
            guard !unwantedChars.contains(char) else { continue }

            var status = "0"
            if char == "L", index < lightStates.count {
                status = String(lightStates[index])
            }

            var type = String(char)
            var name = ""
            switch type {
            case "L": name = "Light \(index + 1)"
            case "O": name = "Curtains Open"
            case "C": name = "Curtains Close"
            case "F": name = "Fan"
            case "D": name = "Door Lock"
            default: continue
            }

            let item = (name: name, type: type, status: status)
            buttonItems.append(item)
            updatedDeviceStates.append(item)
        }

        // --- Handle Fans ---
        if !scene.FState.isEmpty {
            let fanStates = Array(scene.FState)
            for (index, state) in fanStates.enumerated() {
                let fanItem = (name: "Fan \(index + 1)", type: "F", status: String(state))
                buttonItems.append(fanItem)
                updatedDeviceStates.append(fanItem)
            }
        }

        print("✅ Updated buttonItems for scene \(scene.sceneNo): \(buttonItems.map { "\($0.name): \($0.status)" })")

        // ✅ Reload schedule collection to reflect new scene states
        DispatchQueue.main.async {
            self.scheduleCollevtioonView.reloadData()
        }
    }




    @IBAction func backButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
        
    }
    
    
    

    @IBAction func schdeuleSceneButton(_ sender: UIButton) {
            sender.isSelected.toggle()
            
            let showScene = sender.isSelected
            
            sceneView.isHidden = !showScene
            sceneCollectionView.isHidden = !showScene
            
            toggleSceneView(show: showScene)
        }

    
    @IBAction func nextButton(_ sender: Any) {
        passUpdatedStates()
    }
    
    @IBAction func previousButton(_ sender: Any) {
        
        navigationController?.popViewController(animated: true)
    }
    
    func registerXib(){
        let uinib =  UINib(nibName: "schdeuleCollectionViewCell", bundle: nil)
        scheduleCollevtioonView.register(uinib, forCellWithReuseIdentifier: "schdeuleCollectionViewCell")
        let uinib1 =  UINib(nibName: "SceneScheduleCollectionViewCell", bundle: nil)
        sceneCollectionView.register(uinib1, forCellWithReuseIdentifier: "SceneScheduleCollectionViewCell")
      
        
    }
    
    func passUpdatedStates() {
        let newVC = storyboard?.instantiateViewController(withIdentifier: "schdeuleTypeViewController") as! schdeuleTypeViewController
        newVC.schdeuleNumber = self.schduleNumber
        newVC.updatedDeviceStates = self.updatedDeviceStates
        newVC.buttonItems =  self.buttonItems
        newVC.devicestate = self.devicestate
        newVC.selectedDevice =  self.selectedDevice
        
        self.navigationController?.pushViewController(newVC, animated: true)
    }

    
}

extension ShowScheduleViewController : UICollectionViewDataSource, UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == sceneCollectionView {
                  return deviceScene.count
              } else if collectionView == scheduleCollevtioonView {
                  return buttonItems.count
              }
               return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == sceneCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SceneScheduleCollectionViewCell", for: indexPath) as! SceneScheduleCollectionViewCell
            
            let scene = deviceScene[indexPath.item]
            print(" Scene at index \(indexPath.item): \(scene.sceneName)")
            
            cell.sceneLabel.text = scene.sceneName
            
            cell.cellbackgroundVew?.backgroundColor = (indexPath == selectedSceneIndex) ? UIColor.lightGray : UIColor.clear

            
            return cell
        } else if collectionView == scheduleCollevtioonView {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "schdeuleCollectionViewCell",
                for: indexPath
            ) as! schdeuleCollectionViewCell

            let item = buttonItems[indexPath.item]
            cell.deviceName.text = item.name

            // 🔹 Set icon image based on type
            switch item.type {
            case "L":
                cell.devicImage.image = UIImage(named: "bulb")
            case "O":
                cell.devicImage.image = UIImage(named: "curtains_open")
            case "C":
                cell.devicImage.image = UIImage(named: "curtains_close")
            case "F":
                cell.devicImage.image = UIImage(named: "ceiling-fan")
            case "D":
                cell.devicImage.image = UIImage(named: "lock-2")
            default:
                cell.devicImage.image = nil
            }

            // 🔹 Define active/inactive styles
            let activeBorderColor = UIColor(hex: "#44DB34").cgColor
            let inactiveBorderColor = UIColor(hex: "#D3D3D3").cgColor
            let activeBackground = UIColor.white.withAlphaComponent(0.15)
            let inactiveBackground = UIColor.white.withAlphaComponent(0.05)

            // 🔹 Use current item.status to decide UI
            let isActive = item.status == "1"

            cell.layer.borderColor = isActive ? activeBorderColor : inactiveBorderColor
            cell.layer.borderWidth = 2.0
            cell.layer.cornerRadius = 8.0
            cell.backgroundColor = isActive ? activeBackground : inactiveBackground

            // 🔹 Optional: change icon tint if your image is a template image
            cell.devicImage.tintColor = isActive ? UIColor(hex: "#44DB34") : UIColor.lightGray

            return cell
        }

        
        return UICollectionViewCell()
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == sceneCollectionView {
                selectedSceneIndex = indexPath
                let selectedScene = deviceScene[indexPath.item]
                updateDeviceStates(from: selectedScene)
                sceneCollectionView.reloadData()
            } else if collectionView == scheduleCollevtioonView {
            // Existing toggle logic for manual update
            var item = buttonItems[indexPath.item]
            item.status = (item.status == "0") ? "1" : "0"
            buttonItems[indexPath.item] = item
            updatedDeviceStates[indexPath.item] = item
            
            print("🔄 Updated Status for \(item.name): \(item.status)")

            // Reload only that cell for performance
            scheduleCollevtioonView.reloadItems(at: [indexPath])
        }
    }


    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == scheduleCollevtioonView {
            let numberOfColumns: CGFloat = 3
            let spacing: CGFloat = 25
            let totalSpacing = (numberOfColumns - 1) * spacing
            let itemWidth = (collectionView.frame.width - totalSpacing - 10) / numberOfColumns
            return CGSize(width: itemWidth, height: itemWidth)
        } else {
            return CGSize(width: 100, height: 40)
        }
    }
    
}
