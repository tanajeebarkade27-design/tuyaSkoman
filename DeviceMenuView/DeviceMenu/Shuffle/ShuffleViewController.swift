//
//  ShuffleViewController.swift
//  SkromanIsra
//
//  Created by Admin on 13/02/25.
//

import UIKit
import AWSCore
import AWSIoT
import Alamofire

class ShuffleViewController: UIViewController {
    @IBOutlet var shuffleBackGroundview: UIView!
    @IBOutlet weak var configureButton: UIButton!
    @IBOutlet weak var shuffleView: UIView!
    @IBOutlet weak var sortDestNumberCollectionView: UICollectionView!
    
    @IBOutlet weak var destNumberCollectionView: UICollectionView!
    
    @IBOutlet weak var closedButton: UIButton!
    
    @IBOutlet weak var deviceview: UIView!
    var selectedDevice: Device?
    var devicestate: [DeviceStateArray] = []
    var deviceVc : DeviceViewController?
    var devices: [Device] = []
  
    var deviceScene: [DeviceScene] = []
    var characterArray: [String] = []
    var selectedLight: String? = nil
    var selectedItem: DeviceButtonItem?
    var selectedDeviceNumber: String?

    var buttons: [String] = ["light 1","light 2","light 2","light 4","light ","light 1","light 1","light 1","light 1","light 1","light 1"]
 
    @IBOutlet weak var selectshuffleView: UIView!
    
    @IBOutlet weak var shuffleDeviceView: UIView!
    var buttonItems: [DeviceButtonItem] = []
    var lightButtonItems: [DeviceButtonItem] = []
    var sortedDestArray: [String] = []
   
    var selectedIsDimmable: Bool?
    var selectedIndexPath: IndexPath?
   

    @IBOutlet weak var backgroundimage: UIImageView!
    
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
        //closedButton.setImage(UIImage(named: "close"), for: .normal)
        sortDestNumberCollectionView.delegate = self
               sortDestNumberCollectionView.dataSource = self
               destNumberCollectionView.delegate = self
               destNumberCollectionView.dataSource = self
       print("device at shuffle \(devicestate)")
      //  print("devices at shuffle \(devices)")
        lightButtonItems = buttonItems.filter { $0.type == "L" }
        parseDeviceState()
        registerXib()
        selectshuffleView.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        selectshuffleView.cornerRadius = 10
        shuffleDeviceView.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        shuffleDeviceView.cornerRadius = 10
        
    
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }

    
    
    func parseDeviceState() {
        buttonItems.removeAll() // Clear previous data

        let customDeviceOrder = devicestate.map { $0.deviceNumber } // Example: ["2134"]
        var characterArray: [String] = [] // ✅ Define it in scope

        if let firstDevice = customDeviceOrder.first {
            characterArray = firstDevice.map { String($0) }
            print("characterArray\(characterArray)")
          
            let sortedDestArray = characterArray.sorted()
             print("characterArray\(sortedDestArray)")
            buttonItems.sort {
                guard let firstIndex = sortedDestArray.firstIndex(of: $0.deviceNumber),
                      let secondIndex = sortedDestArray.firstIndex(of: $1.deviceNumber) else { return false }
                return firstIndex < secondIndex
            }

            print("Sorted button items: \(buttonItems)")

        }

        print("Custom Device Order: \(characterArray)")
        for device in devicestate {
            let unwantedChars: Set<Character> = ["S", "W", "X", "G", "H", "I", "J"]
            let filteredcNm = device.cNm.filter { !unwantedChars.contains($0) } // Remove unwanted chars
            
            print("Filtered cNm: \(filteredcNm)") // Debugging
            
            for (index, char) in filteredcNm.enumerated() {
                let type: String
                switch char {
                case "L": type = "L" // Light
                case "O": type = "O" // Open Curtain
                case "C": type = "C" // Close Curtain
                case "D": type = "D" // Lock
                default: continue // Ignore unknown characters
                }
                
                
                
                let lightStatus = (index < device.lightState.count) ?
                String(device.lightState[device.lightState.index(device.lightState.startIndex, offsetBy: index)]) : "0"
                
                let isDimmable = (index < device.cDim.count) ?
                (device.cDim[device.cDim.index(device.cDim.startIndex, offsetBy: index)] == "1") : false
                
                buttonItems.append(DeviceButtonItem(
                    name: "\(type) \(index + 1)",
                    type: type,
                    status: lightStatus,
                    isDimmable: isDimmable,
                    deviceNumber: device.deviceNumber
                ))
            }
            print("Paitemsrsed button : \(buttonItems)") // Debugging
            sortDestNumberCollectionView.reloadData()
        }
       
        lightButtonItems = buttonItems
            .filter { ["L", "O", "C", "D"].contains($0.type) } // ✅ Correct filtering
            .sorted {
                guard let firstIndex = characterArray.firstIndex(of: $0.name.split(separator: " ").last.map(String.init) ?? ""),
                      let secondIndex = characterArray.firstIndex(of: $1.name.split(separator: " ").last.map(String.init) ?? "")
                else { return false }
                
                print("characterArray.\(characterArray)")
                return firstIndex < secondIndex
            }


        print("Sorted Lights: \(lightButtonItems)")
        destNumberCollectionView.reloadData()
    }


    func registerXib(){
        let deviceNib = UINib(nibName: "ShuffleDeviceCollectionViewCell", bundle: nil)
        sortDestNumberCollectionView.register(deviceNib, forCellWithReuseIdentifier: "ShuffleDeviceCollectionViewCell")
        let deviceNib1 = UINib(nibName: "SelectShuffleCollectionViewCell", bundle: nil)
        destNumberCollectionView.register(deviceNib1, forCellWithReuseIdentifier: "SelectShuffleCollectionViewCell")
    }

    
    @IBAction func closedButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    

    @IBAction func configureButton(_ sender: Any) {
        let extractedNumbers = extractNumbersFromLightButtonItems()
        
        // Check for duplicates
        let duplicates = findDuplicates(in: extractedNumbers)
        
        if !duplicates.isEmpty {
            let duplicateString = duplicates.map { String($0) }.joined(separator: ", ")
            showAlertduplicate(title: "Duplicate Numbers Found", message: "The following numbers are repeated: \(duplicateString). Please ensure unique assignments.")
            return
        }
        
        // Convert array [2, 1, 4, 3] → "2143"
        let extractedString = extractedNumbers.map { String($0) }.joined()
        
        print("📌 Extracted String to Pass: \(extractedString)") 
        
        publish_shuffle_config(extractArray: extractedString)
    }

    // ✅ Function to extract numbers from lightButtonItems
    func extractNumbersFromLightButtonItems() -> [Int] {
        var extractedNumbers: [Int] = []
        
        for item in lightButtonItems {
            let components = item.name.split(separator: " ") // Split by space
            if let lastComponent = components.last, let number = Int(lastComponent) {
                extractedNumbers.append(number) // Store extracted number
            }
        }
        
        return extractedNumbers
    }

    // ✅ Function to Find Duplicates
    func findDuplicates(in array: [Int]) -> [Int] {
        var seen: Set<Int> = []
        var duplicates: Set<Int> = []
        
        for num in array {
            if seen.contains(num) {
                duplicates.insert(num) // Found a duplicate
            } else {
                seen.insert(num)
            }
        }
        
        return Array(duplicates)
    }


    // 🔹 Alert Function
    func showAlertduplicate (title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }

    
    @objc func showPopupScene() {
        
        showPopupPresenter.showPopup1(on: self.view,
                                     animationName: "shuffle",
                                     title: "Success!",
                                     subtitle: "Scene Added Sucessfully!")
        
       
    }
    func shuffleLightButtonItems() {
        guard lightButtonItems.count > 1 else { return } // Ensure there's something to shuffle

        var shuffledItems = lightButtonItems
        
        repeat {
            shuffledItems.shuffle() // Perform a shuffle
        } while !isValidShuffle(original: lightButtonItems, shuffled: shuffledItems) // Validate shuffle

        lightButtonItems = shuffledItems
        destNumberCollectionView.reloadData()
    }

    // ✅ Function to validate the shuffled list
    func isValidShuffle(original: [DeviceButtonItem], shuffled: [DeviceButtonItem]) -> Bool {
        for (index, item) in shuffled.enumerated() {
            let originalItem = original[index]
            
            // ✅ Condition 1: Only shuffle same type (L with L, D with D, etc.)
            if item.type != originalItem.type {
                return false
            }

            // ✅ Condition 2: At least one item in swap must be dimmable
            if !(item.isDimmable || originalItem.isDimmable) {
                return false
            }
        }
        return true
    }

    
    func publish_shuffle_config(extractArray : String) {
        guard let device = devicestate.first else { return }
          let topic  = device.uniqueID
       
        let shuffle_params : Parameters = [
         
            "control":"config_shuffle",
            "dest": extractArray,
            "from": "A",
            "topic": topic
        ]
        
        
        if let theJSONData = try? JSONSerialization.data(withJSONObject: shuffle_params,options: []) {
            
            let theJSONText = String(data: theJSONData,
                                     encoding: .ascii)
            print("JSON string = \(theJSONText!)")
            
            showPopupScene()
        
            print("pub_topic -->>>>", topic)
            
            let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
            
            let iot_sample_vc = Iot_sample_ViewController()
            
            iotDataManager.publishString(theJSONText!, onTopic: (topic ?? "") + "/HA/A/req", qoS:.messageDeliveryAttemptedAtMostOnce)
        }
    }
    
    
    
    
}


extension ShuffleViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == sortDestNumberCollectionView {
                return buttonItems.count
            } else if collectionView == destNumberCollectionView {
                return lightButtonItems.count // Only lights
            }
            return 0
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == sortDestNumberCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ShuffleDeviceCollectionViewCell", for: indexPath) as! ShuffleDeviceCollectionViewCell

            let item = buttonItems[indexPath.item] // Ensure correct indexing

            // ✅ Ensure all 'L' devices are displayed
            guard item.type == "L" else {
                cell.isHidden = true
                return cell
            }
            
            cell.deviceNamelabel.text = item.name

            if let sortedIndex = sortedDestArray.firstIndex(of: item.deviceNumber) {
                cell.deviceNamelabel.text = "L \(sortedIndex + 1)" // Ensures correct order display
            }

            cell.deviceImageView.image = UIImage(named: "bulb") // Light Icon

            // 🔹 Background & Text Color Setup
            let activeColor = UIColor(hex: "#FAEDCB") // Light Yellow
            let inactiveColor = UIColor(hex: "#D3D3D3") // Light Gray
            var cellBackgroundColor = inactiveColor
            var textColor: UIColor = .darkGray

            if let device = devicestate.first {
                let lightOnlyItems = buttonItems.filter { $0.type == "L" } // Get only 'L' items
                if let index = lightOnlyItems.firstIndex(where: { $0.name == item.name }) {
                    if index < device.lightState.count {
                        let statusArray = Array(device.lightState)
                        let L_State = statusArray[index] == "1"
                       
                       
                    }
                }
            }

            // 🔹 Apply Final UI Updates
//            cell.cellbackgroundview.backgroundColor = cellBackgroundColor
//            cell.deviceNamelabel.textColor = textColor

            // ✅ Ensure Dimming Logic Works
            if item.isDimmable {
                cell.dimImageView.image = UIImage(named: "brightness-2")
                cell.dimImageView.isHidden = false
            } else {
                cell.dimImageView.isHidden = true
            }
            return cell
        }

        
        else if collectionView == destNumberCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SelectShuffleCollectionViewCell", for: indexPath) as! SelectShuffleCollectionViewCell
            
            let item = lightButtonItems[indexPath.item]
            var imageName: String? = nil
            
            switch item.type {
            case "L":
                imageName = "bulb"
            case "O":
                imageName = "curtains_Open"
            case "C":
                imageName = "curtains_close"
            case "D":
                imageName = "lock-2"
            default:
                imageName = nil
            }

            if let img = imageName {
                cell.cellImageView.image = UIImage(named: img)
            } else {
                cell.cellImageView.image = nil
            }
            
            if indexPath.item < characterArray.count {
                let orderNumber = characterArray[indexPath.item] // ✅ Get the correct order
                cell.shuffleDeviceNamelabel.text = "L \(orderNumber)" // ✅ Show "L 2", "L 1", etc.
            } else {
                cell.shuffleDeviceNamelabel.text = item.name
            }
            if item.isDimmable {
                   cell.diimimgImage.image = UIImage(named: "brightness-2")
                cell.diimimgImage.isHidden = false
               } else {
                   cell.diimimgImage.isHidden = true
               }

               if indexPath.item < characterArray.count {
                   let orderNumber = characterArray[indexPath.item]
                   cell.shuffleDeviceNamelabel.text = "L \(orderNumber)"
               } else {
                   cell.shuffleDeviceNamelabel.text = item.name
               }
            print("Displaying \(cell.shuffleDeviceNamelabel.text!) for device \(item.deviceNumber) at index \(indexPath.item)")
            
            if indexPath == selectedIndexPath {
                cell.layer.borderColor = UIColor.blue.cgColor // Change to desired color
                cell.layer.borderWidth = 2.0
                cell.layer.cornerRadius = 10.0
                cell.clipsToBounds = true
            } else {
                cell.layer.borderColor = UIColor.clear.cgColor
                cell.layer.borderWidth = 0
                cell.layer.cornerRadius = 10.0  
                cell.clipsToBounds = true
            }
            
            return cell
        }

        return UICollectionViewCell()
    }

    
    func printLightButtonItems() {
        print("Current lightButtonItems state:")

        var extractedNumbers: [Int] = [] // Create an array to store extracted numbers

        for (index, item) in lightButtonItems.enumerated() {
            print("  [\(index)] Name: \(item.name), Dimmable: \(item.isDimmable)")

            // Extract numbers from item.name
            let components = item.name.split(separator: " ") // Split by space
            if let lastComponent = components.last, let number = Int(lastComponent) {
                extractedNumbers.append(number) // Insert extracted number into the array
            }
        }

        print("Extracted Numbers Array: \(extractedNumbers)")
    }

       
        func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            if collectionView == destNumberCollectionView {
                selectedIndexPath = indexPath
                print("Selected destNumberCollectionView cell at index \(indexPath.item)")
                collectionView.reloadData()
            }
            else if collectionView == sortDestNumberCollectionView, let selectedIndexPath = selectedIndexPath {
                
                print("🔹 Before update:")
                printLightButtonItems() // ✅ Function is defined, so no error

                let selectedSortItem = buttonItems[indexPath.item]
                let selectedDestItem = lightButtonItems[selectedIndexPath.item]

                if selectedSortItem.isDimmable == selectedDestItem.isDimmable {
                    if let selectedSortCell = collectionView.cellForItem(at: indexPath) as? ShuffleDeviceCollectionViewCell,
                       let textToPass = selectedSortCell.deviceNamelabel.text {
                        
                        lightButtonItems[selectedIndexPath.item].name = textToPass

                        print("✅ Updated destNumberCollectionView at \(selectedIndexPath.item) with \(textToPass)")

                        print("🔹 After update:")
                        printLightButtonItems() // ✅ Function works correctly

                        destNumberCollectionView.reloadItems(at: [selectedIndexPath])
                        sortDestNumberCollectionView.reloadItems(at: [indexPath])
                    }
                } else {
                    showAlert(title: "Invalid Selection", message: "You can only replace dimmable devices with another dimmable device.")
                }
            }
        }

    // 🔹 Alert Function
    func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }



   
    

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let numberOfColumns: CGFloat = 3
        let spacing: CGFloat = 25
        let totalSpacing = (numberOfColumns - 1) * spacing
        let itemWidth = (collectionView.frame.width - totalSpacing - 10) / numberOfColumns
        return CGSize(width: itemWidth, height: itemWidth)
    }
}
struct DeviceButtonItem {
    var name: String
    let type: String
    let status: String
    let isDimmable: Bool
    let deviceNumber : String
}
