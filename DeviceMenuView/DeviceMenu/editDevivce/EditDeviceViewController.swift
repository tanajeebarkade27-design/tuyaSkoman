//
//  EditDeviceViewController.swift
//  SkromanIsra
//
//  Created by Admin on 17/03/25.
//

import UIKit
import AWSCore
import AWSIoT
import Alamofire

class EditDeviceViewController: UIViewController {
    @IBOutlet weak var editView: UIView!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var deviceCollectionView: UICollectionView!
    var devicestate: [DeviceStateArray] = []
   
    @IBOutlet var mainView: UIView!
    var deviceVc : DeviceViewController?
    var devices: [Device] = []
    var deviceUinqueId: String?
    var buttonDetails: [ButtonDetails] = []
   

var deviceUid: String?
    var buttonItems: [(name: String, type: String, status: String)] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        backButton.setTitle("", for: .normal)
        deleteButton.setTitle("", for: .normal)
        deleteButton.setTitleColor(.black, for: .normal)
        deviceCollectionView.dataSource =  self
        deviceCollectionView.delegate =  self
        applyGradientBackground()
        if let image = UIImage(named: "delete")?.resized(to: CGSize(width: 30, height: 30)) {
            deleteButton.setImage(image, for: .normal)
        }
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
            deviceCollectionView.addGestureRecognizer(longPressGesture)
        parseDeviceState()
        registerXib()
        if let firstDevice = devices.first {
            deviceUinqueId = firstDevice.uniqueId
            deviceUid =  firstDevice.deviceUid
        } else {
            deviceUinqueId = nil
        }

        fetchButtonsDetails()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    func applyGradientBackground() {
        let mainScreen = CAGradientLayer()
        mainScreen.frame = mainView.bounds

        mainScreen.colors = [
            UIColor(red: 163/255, green: 159/255, blue: 98/255, alpha: 1).cgColor,   // Gold
            UIColor(red: 141/255, green: 176/255, blue: 144/255, alpha: 1).cgColor,  // Green
            UIColor(red: 104/255, green: 155/255, blue: 181/255, alpha: 1).cgColor   // Blue
        ]

        mainScreen.locations = [0.0, 0.3, 0.8]  // Expands green & blue areas
        mainScreen.startPoint = CGPoint(x: 0.5, y: 0)   // Top center
        mainScreen.endPoint = CGPoint(x: 0.5, y: 1)     // Bottom center

     
        mainView.layer.sublayers?.removeAll(where: { $0 is CAGradientLayer })
        
        mainView.layer.insertSublayer(mainScreen, at: 0)
    }

    func fetchButtonsDetails() {
        buttonDetails.removeAll() // Clear old data

        guard let deviceUniqueId = deviceUinqueId else {
            print("❌ No deviceUniqueId available")
            return
        }

        buttonDetails = SkromanIsraDatabaseHelper.shared.fetchButtonDetails(uniqueId: deviceUniqueId)

        if buttonDetails.isEmpty {
            print("No button details found for deviceUid: \(deviceUniqueId)")
        } else {
            // ✅ Sorting by button number
            buttonDetails.sort { $0.buttonNo < $1.buttonNo }
           // print("✅ Button details fetched & sorted: \(buttonDetails)")
        }
    }

    
    func parseDeviceState() {
        guard let device = devicestate.first else { return }
         print("device att \(device)")

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

      
        if device.fanState != "000" {
            for (index, _) in device.fanState.enumerated() {
                buttonItems.append((name: "Fan \(index + 1)", type: "F", status: "0"))
            }
        } else {
            buttonItems.append((name: "Fan", type: "F", status: "0"))
        }

        // Handle Master (Always add it)
        buttonItems.append((name: "Master", type: "M", status: String(device.master)))

        print("Parsed edit Buttons: \(buttonItems)")
    }
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            let point = gesture.location(in: deviceCollectionView)

            if let indexPath = deviceCollectionView.indexPathForItem(at: point) {
                let selectedItem = buttonItems[indexPath.item]
                print("Long-pressed item: \(selectedItem)") // already here
                          print("Returning from EditButtonViewController, buttonItems = \(buttonItems)")
                
                
                if let selectedButtonNumber = extractButtonNumber(from: selectedItem.name) {
                    print(" Selected Button Number: \(selectedButtonNumber)")

                    let availableNumbers = buttonDetails.map { $0.buttonNo }
                    print("Available Button Numbers: \(availableNumbers)")

                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    if let editButtonVC = storyboard.instantiateViewController(withIdentifier: "EditButtonViewController") as? EditButtonViewController {
                        
                        editButtonVC.selectedButtonItem = selectedItem
                        editButtonVC.devicestate = self.devicestate
                        editButtonVC.devices = self.devices

                        if let buttonDetail = buttonDetails.first(where: { $0.buttonNo == selectedButtonNumber }) {
                            print("✅ Found Button Detail: \(buttonDetail)")
                            editButtonVC.buttonDetails = buttonDetail
                        } else {
                            print("⚠️ No matching button details found. Passing default details.")
                            editButtonVC.buttonDetails = nil
                        }

                        editButtonVC.parentVC = self 
                        editButtonVC.modalPresentationStyle = .overFullScreen
                        present(editButtonVC, animated: true, completion: nil)
                    }

                } else {
                    print("❌ Could not extract button number from name: \(selectedItem.name)")
                }
            }
        }
    }


    func extractButtonNumber(from name: String) -> Int? {
        let components = name.trimmingCharacters(in: .whitespaces).components(separatedBy: " ")
        if let numberString = components.last?.trimmingCharacters(in: .whitespaces),
           let number = Int(numberString) {
            return number
        }
        return nil
    }

    
    func registerXib() {
        let uinib = UINib(nibName: "EditDeviceCollectionViewCell", bundle: nil)
        deviceCollectionView.register(uinib, forCellWithReuseIdentifier: "EditDeviceCollectionViewCell")
    }
    @IBAction func deleteDeviecButton(_ sender: Any) {
        
    }
    
    func delete_device_api_func() {
        
        guard let device_u_id = deviceUid else { return }
        
        let delete_device_parameters : Image_Parameters = [
            
            "deviceUid" : device_u_id
            
        ]
        
        AF.request("http://3.7.18.55:3000/skroman/deviceapi/devicedelete/deviceUid", method: .post, parameters: delete_device_parameters, encoding: JSONEncoding.default, headers: nil).response { response in
            debugPrint(response)
            
            switch response.result
            {
            case .success(let data) :
                do {
                    
                    let jsonOne = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary
                    
                    if response.response?.statusCode == 200 {
                        print(jsonOne!)
                        
                        
                        if let parseJson = jsonOne, let msg = parseJson["msg"] as? String {
                            
                            if msg == "device delete successully" {
                                
                                self.All_Alert_Type(alertTitle: "Device Deleted Successfully", alertMessage: "")
                                
                            }
                        }
                    }
                    
                    else {
                        
                        print("Error")
                        
                        
                    }
                }
                
                catch {
                    print(error.localizedDescription)
                    
                }
                
                
            case .failure(let err):
                print(err.localizedDescription)
                
            }
        }.resume()
        
    }
    
    func All_Alert_Type(alertTitle : String, alertMessage : String) {
        
        let allAlertBox = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
        
        allAlertBox.view.tintColor = UIColor.white
        allAlertBox.view.subviews.first?.subviews.first?.subviews.first?.backgroundColor = UICOLOR_CONTAINER_BG
        
        allAlertBox.setValue(NSAttributedString(string: allAlertBox.title!, attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 20, weight: UIFont.Weight.heavy), NSAttributedString.Key.foregroundColor : UIColor.white]), forKey: "attributedTitle")
        
        
        self.present(allAlertBox, animated: true)
        
        let when = DispatchTime.now() + 3.0
        
        DispatchQueue.main.asyncAfter(deadline: when) {
            
            allAlertBox.dismiss(animated: true, completion: nil)
            
//            self.DeleteDeviceDataFunc()
            self.navigationController?.viewControllers.removeLast(2)
            //            self.navigationController?.popViewController(animated: true)
        }
        
        
    }
    
    @IBAction func backButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
   
}

extension EditDeviceViewController:  UICollectionViewDataSource,  UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return buttonItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = deviceCollectionView.dequeueReusableCell(withReuseIdentifier: "EditDeviceCollectionViewCell", for: indexPath) as! EditDeviceCollectionViewCell
        
        let item = buttonItems[indexPath.item]
        
        // Default to fallback name (e.g. "L 1", etc.)
        var buttonDisplayName = item.name
        
        // Try to get button name from buttonDetails if available
        if item.type != "F",
           let buttonNo = extractButtonNumber(from: item.name),
           let detail = buttonDetails.first(where: { $0.buttonNo == buttonNo }),
           !detail.buttonName.isEmpty {
            buttonDisplayName = detail.buttonName
        }
        
        cell.deviceLabel.text = buttonDisplayName

        // Get icon image for the device type
        let defaultIconName: String
        switch item.type {
        case "L":
            defaultIconName = "bulb"
        case "O":
            defaultIconName = "curtains_Open"
        case "C":
            defaultIconName = "curtains_close"
        case "Q":
            defaultIconName = "curtains_Open"
        case "Y":
            defaultIconName = "curtains_close"
        case "F":
            defaultIconName = "ceiling-fan"
        case "M":
            defaultIconName = "AppIcon1"
        default:
            defaultIconName = "default_icon"  // Fallback icon if none of the above matches
        }
        
        // Set image based on type, with fallback to the default icon
        cell.deviceImage.image = getIconImage(defaultName: defaultIconName, index: indexPath.item)
        
        // Set background color based on status (active or inactive)
        let activeColor = UIColor(hex: "#FAEDCB")
        let inactiveColor = UIColor(hex: "#D3D3D3")
        cell.backgroundColor = (item.status == "1") ? activeColor : inactiveColor
        
        return cell
    }

    private func getIconImage(defaultName: String, index: Int) -> UIImage? {
        // Try to get the icon name from buttonDetails if available
        if index < buttonDetails.count {
            let iconName = buttonDetails[index].buttonIconName
            if !iconName.isEmpty, UIImage(named: iconName) != nil {
                return UIImage(named: iconName)
            }
        }
        // Return the default icon if buttonIconName is empty or invalid
        return UIImage(named: defaultName)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let numberOfColumns: CGFloat = 3
        let spacing: CGFloat = 25
        let totalSpacing = (numberOfColumns - 1) * spacing
        let itemWidth = (collectionView.frame.width - totalSpacing - 10) / numberOfColumns
        return CGSize(width: itemWidth, height: itemWidth)
    }
}
