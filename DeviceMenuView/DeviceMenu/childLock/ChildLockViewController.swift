import UIKit
import AWSCore
import AWSIoT
import Alamofire

class ChildLockViewController: UIViewController {
    @IBOutlet weak var closedButton: UIButton!
    @IBOutlet weak var chlidLockView: UIView!
    @IBOutlet var childLockBackgroundview: UIView!
    @IBOutlet weak var childCollectionView: UICollectionView!

    @IBOutlet weak var backgroundimage: UIImageView!
    var devicestate: [DeviceStateArray] = []
    var buttonItems: [(name: String, type: String, status: String)] = []  // (Display Name, Type, Status)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        backgroundimage.contentMode = .scaleAspectFill
        backgroundimage.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            backgroundimage.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundimage.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundimage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundimage.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        closedButton.setTitle("", for: .normal)

        registerXib()
        childCollectionView.dataSource = self
        childCollectionView.delegate = self
        
        
        chlidLockView.layer.cornerRadius = 8
        chlidLockView.clipsToBounds = true
        chlidLockView.layer.borderColor = UIColor.gray.cgColor
        chlidLockView.layer.borderWidth = 1
print("device at\(devicestate)")
        parseDeviceState()
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
    
    
    
    @IBAction func configureButton(_ sender: Any) {
        
        print("Configure Button Pressed")

        guard let device = devicestate.first else { return } // Get the first device
        
        let clvalue = device.cL
        let cFValue =  device.cF
        let cMvalue  =  device.cM
        let topic = device.uniqueID
        
        

     
        publish_child_lock(L_Lock_Value: clvalue, F_Lock_Value: cFValue, M_Lock_Value:cMvalue, topic: topic)

    
        let presentingVC = self.presentingViewController

      
        self.dismiss(animated: true) {
          
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if let strongVC = presentingVC {
                    showPopupPresenter.showPopup1(on: strongVC.view,
                                                  animationName: "success",
                                                  title: "Success!",
                                                  subtitle: "Dimming Changes Done")
                }
            }
        }
        
        
    }
    
    
    
    func parseDeviceState() {
        guard let device = devicestate.first else { return }

        // Remove unwanted characters from cNm
        let unwantedChars: Set<Character> = ["S", "W", "X", "G", "H", "I", "J"]
        let filteredcNm = device.cNm.filter { !unwantedChars.contains($0) }

       
        for (index, char) in filteredcNm.enumerated() {
            let lightStatus = (index < device.lightState.count) ?
                String(device.lightState[device.lightState.index(device.lightState.startIndex, offsetBy: index)]) : "0"

            switch char {
            case "L":
                buttonItems.append((name: "L \(index + 1)", type: "L", status: lightStatus))
            case "O":
                buttonItems.append((name: "O \(index + 1)", type: "O", status: lightStatus))
            case "C":
                buttonItems.append((name: "C \(index + 1)", type: "C", status: lightStatus))
            case "Y":
                buttonItems.append((name: "Y \(index + 1)", type: "Y", status: lightStatus))
            case "D":
                buttonItems.append((name: "D \(index + 1)", type: "D", status: lightStatus))
            case "Q":
                buttonItems.append((name: "Q \(index + 1)", type: "Q", status: lightStatus))
            default:
                print("Ignoring character: \(char)")
            }
        }

        // Handle cF (Fan)
        if device.fanState != "000" {
            for (index, char) in device.fanState.enumerated() {
                buttonItems.append((name: "Fan \(index + 3)", type: "F", status: "0"))
            }
        } else {
            buttonItems.append((name: "Fan", type: "F", status: "0"))
        }

        // Handle Master (Always add it)
        buttonItems.append((name: "Master", type: "M", status: String(device.master)))

        print("Parsed Buttons: \(buttonItems)")
        childCollectionView.reloadData()
    }



    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
         
    }

    
    
    
    
    func registerXib() {
        let uinib = UINib(nibName: "ChildLockuCollectionViewCell", bundle: nil)
        childCollectionView.register(uinib, forCellWithReuseIdentifier: "ChildLockuCollectionViewCell")
    }
}

extension ChildLockViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return buttonItems.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ChildLockuCollectionViewCell", for: indexPath) as! ChildLockuCollectionViewCell
        
        let item = buttonItems[indexPath.item]

        cell.deviceNameLabel.text = item.name

        // Set Image Based on Type
        switch item.type {
        case "L":
            cell.deviceImageView.image = UIImage(named: "bulb")
        case "O":
            cell.deviceImageView.image = UIImage(named: "curtains_Open")
        case "C":
            cell.deviceImageView.image = UIImage(named: "curtains_close")
        case "Q":
            cell.deviceImageView.image = UIImage(named: "curtains_Open")
        case "Y":
            cell.deviceImageView.image = UIImage(named: "curtains_close")
        case "D":
            cell.deviceImageView.image = UIImage(named: "lock-2")
        case "F":
            cell.deviceImageView.image = UIImage(named: "Fan1")
        case "M":
            cell.deviceImageView.image = UIImage(named: "AppIcon1")
        default:
            cell.deviceImageView.image = nil
        }

        let activeColor = UIColor(hex: "#44DB34")
        let inactiveColor = UIColor(hex: "#D3D3D3")

     
        var cellBackgroundColor = inactiveColor

       
        if let device = devicestate.first {
            print("Status: L: \(device.lightState), F: \(device.fanState), M: \(device.master)")

            switch item.type {
            case "L":
                let index = buttonItems.prefix(upTo: indexPath.item).filter { $0.type == "L" }.count
                if index < device.lightState.count {
                    let statusArray = Array(device.lightState)
                    let L_State = statusArray[index] == "1"
                    cellBackgroundColor = L_State ? activeColor : inactiveColor
                }

            case "F":
                let fanIndex = buttonItems.prefix(upTo: indexPath.item).filter { $0.type == "F" }.count
                let statusArray = Array(device.fanState)

                if fanIndex < statusArray.count / 3 {
                    let F_State = statusArray[fanIndex * 3] == "1"
                    cellBackgroundColor = F_State ? activeColor : inactiveColor
                } else {
                    cellBackgroundColor = inactiveColor
                }


            case "M":
                let M_State = device.master == 1
                cellBackgroundColor = M_State ? UIColor.red.withAlphaComponent(0.5) : inactiveColor

            default:
                cellBackgroundColor = inactiveColor
            }
        }

    
        cell.cellbackgroundView.backgroundColor = UIColor.clear // or your neutral background
        cell.cellbackgroundView.layer.borderWidth = 2
        cell.cellbackgroundView.layer.borderColor = cellBackgroundColor.cgColor
        cell.cellbackgroundView.layer.cornerRadius = 10
        cell.cellbackgroundView.clipsToBounds = true


        if let device = devicestate.first {
            let cL_Array = Array(device.cL)  // Convert "1000" -> ['1', '0', '0', '0']
            
            // Fan Handling
            let fanCount = device.cF.count / 3  // Calculate how many Fan cells (000 = 1, 000000 = 2)
            let cF_LockedArray = Array(device.cF) // Convert "111000" -> ['1', '1', '1', '0', '0', '0']

            let cM_Locked = device.cM.contains("1") // If `cM` has any "1", lock Master

            var isLocked = false

            switch item.type {
            case "L":
                let index = buttonItems.prefix(upTo: indexPath.item).filter { $0.type == "L" }.count
                if index < cL_Array.count {
                    isLocked = cL_Array[index] == "1"  // Check corresponding digit in `cL`
                }
                
            case "F":
                let fanIndex = buttonItems.prefix(upTo: indexPath.item).filter { $0.type == "F" }.count
                if fanIndex < fanCount {
                    let startIndex = fanIndex * 3
                    if startIndex + 2 < cF_LockedArray.count {
                        isLocked = cF_LockedArray[startIndex] == "1" ||
                                   cF_LockedArray[startIndex + 1] == "1" ||
                                   cF_LockedArray[startIndex + 2] == "1" // Check all 3 digits
                    }
                }
                
            case "M":
                isLocked = cM_Locked  // Lock Master if `cM` contains "1"

            default:
                isLocked = false
            }

            // **Debugging Print Statement**
            print("Device: \(item.name), Type: \(item.type), isLocked: \(isLocked), cL: \(device.cL), cF: \(device.cF), cM: \(device.cM)")

           
            cell.childLockImage.isHidden = !isLocked
            if isLocked {
                cell.childLockImage.image = UIImage(named: "childLock")
                cell.childLockImage.tintColor = .black
            } else {
                cell.childLockImage.image = nil
            }
        }
        return cell
    }
   
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let device = devicestate.first else { return }
        
        var cL_Array = Array(device.cL)
        var cF_Array = Array(device.cF)
        var cM_Value = device.cM

        let cNmArray = Array(device.cNm)
        
        var lightIndices: [Int] = []

        for (i, char) in cNmArray.enumerated() {
            if char == "L" { lightIndices.append(i) }
        }

        let item = buttonItems[indexPath.item]
        
        switch item.type {
        case "L":
            // Find the L index up to this item (not assuming indexPath.item is L index)
            let LIndex = buttonItems.prefix(upTo: indexPath.item).filter { $0.type == "L" }.count
            if LIndex < cL_Array.count {
                cL_Array[LIndex] = (cL_Array[LIndex] == "1") ? "0" : "1"
            }


        case "F":
            if device.cF != "NA" {
                let groupSize = 3
                let fanIndex = buttonItems.prefix(upTo: indexPath.item).filter { $0.type == "F" }.count
                let startIndex = fanIndex * groupSize
                let endIndex = startIndex + groupSize

                if endIndex <= cF_Array.count {
                    // Get the 3-bit segment for this fan
                    let currentGroup = Array(cF_Array[startIndex..<endIndex])
                    let isLocked = currentGroup.contains("1")  // If any '1', fan is locked
                    let newValue: Character = isLocked ? "0" : "1"

                    // Toggle only this fan’s 3 bits
                    for i in startIndex..<endIndex {
                        cF_Array[i] = newValue
                    }

                } else {
                    print("⚠️ Invalid fan index or cF format mismatch")
                }
            } else {
                print("⚠️ cF is NA, cannot toggle fan lock!")
            }



        case "M":
            cM_Value = (cM_Value == "1") ? "0" : "1"

        default:
            break
        }
        
       
        let previousCM = cM_Value
        if cL_Array.contains("1") || cF_Array.contains("1") {
            cM_Value = "1"
        } else {
            cM_Value = "0"
        }

        // MARK: - Create Updated Device State
        let updatedDevice = DeviceStateArray(
            uniqueID: device.uniqueID,
            modelNo: device.modelNo,
            deviceNumber: device.deviceNumber,
            cDim: device.cDim,
            cNm: device.cNm,
            cL: String(cL_Array),
            cF: String(cF_Array),
            cM: cM_Value,
            workingMode: device.workingMode,
            master: device.master,
            ack: device.ack,
            lightState: device.lightState,
            lightSpeed: device.lightSpeed,
            fanState: device.fanState,
            fanSpeed: device.fanSpeed,
            controlFrom: device.controlFrom, series: device.series, otaStatus: device.otaStatus, rRegulator: device.rRegulator
        )

        devicestate[0] = updatedDevice
        
        print("Updated Device: cL: \(updatedDevice.cL), cF: \(updatedDevice.cF), cM: \(updatedDevice.cM)")

       
        if previousCM != cM_Value {
            collectionView.reloadData()  // Reload all cells to update `childLockImage`
        } else {
            collectionView.reloadItems(at: [indexPath])  // Reload only the clicked cell
        }
    }


//    func publish_child_lock(L_Lock_Value: String, F_Lock_Value: String, M_Lock_Value: String, topic: String) {
//        let fetch_all_params: [String: Any] = [
//            "control": "child_lock",
//            "L": L_Lock_Value,
//            "F": F_Lock_Value,
//            "M": M_Lock_Value,
//            "from": "A",
//            "topic": topic
//        ]
//        
//        print("FETCH ALL PARAMS : >>> ", fetch_all_params)
//        
//        if let theJSONData = try? JSONSerialization.data(withJSONObject: fetch_all_params, options: []) {
//            if let theJSONText = String(data: theJSONData, encoding: .ascii) { // Use UTF-8 encoding
//                print("JSON string = \(theJSONText)")
//                
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { // Add 200ms delay
//                    let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
//                    iotDataManager.publishString(theJSONText, onTopic: "\(topic)/HA/A/req", qoS: .messageDeliveryAttemptedAtMostOnce)
//                    self.showPopupLock()
//                }
//            } else {
//                print("Error: Failed to convert JSON data to UTF-8 string.")
//            }
//        } else {
//            print("Error: JSON serialization failed.")
//        }
//    }

    
    func publish_child_lock(L_Lock_Value: String, F_Lock_Value: String, M_Lock_Value: String, topic: String) {
        // Build JSON string manually in fixed key order
        let jsonString = """
        {
            "control": "child_lock",
            "L": "\(L_Lock_Value)",
            "F": "\(F_Lock_Value)",
            "M": "\(M_Lock_Value)",
            "from": "A",
            "topic": "\(topic)"
        }
        """

        print("Ordered JSON string = \(jsonString)")

        // Publish with delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
            iotDataManager.publishString(jsonString, onTopic: "\(topic)/HA/A/req", qoS: .messageDeliveryAttemptedAtMostOnce)
            self.showPopupLock()
        }
    }

    
    @objc func showPopupLock() {
        
        showPopupPresenter.showPopup1(on: self.view,
                                     animationName: "lock",
                                     title: "Child Lock",
                                     subtitle: "Child Lock buttons are set.")
        
       
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let numberOfColumns: CGFloat = 3
        let spacing: CGFloat = 25
        let totalSpacing = (numberOfColumns - 1) * spacing
        let itemWidth = (collectionView.frame.width - totalSpacing - 10) / numberOfColumns
        return CGSize(width: itemWidth, height: itemWidth)
    }
}
