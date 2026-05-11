//
//  SpecailButtonViewController.swift
//  SkromanIsra
//
//  Created by Admin on 14/02/25.
//
import UIKit
import AWSCore
import AWSIoT
import Alamofire

class SpecialButtonViewController: UIViewController {

    @IBOutlet weak var specailButtonView: UIView!
    
    @IBOutlet var specailButtonbackgroundView: UIView!
    
    @IBOutlet weak var buttonsview: UIView!
    @IBOutlet weak var buttonsCollectionView: UICollectionView!
    
    @IBOutlet weak var lockPinHeight: NSLayoutConstraint!
    @IBOutlet weak var configureButton: UIButton!
    @IBOutlet weak var closedButton: UIButton!
    
    @IBOutlet weak var lockPinView: UIView!
    @IBOutlet weak var configureButtons: UIButton!
    
    @IBOutlet weak var doorUnlockText: UITextField!
    
    @IBOutlet weak var doorlockConfrimText: UITextField!
    
    @IBOutlet weak var backgroundimage: UIImageView!
    
    var selectedDevice: Device?
    @IBOutlet weak var VcBackGroundView: UIView!
    var devicestate: [DeviceStateArray] = []
    var deviceVc : DeviceViewController?
    var devices: [Device] = []
    var deviceUinqueId: String?
    var deviecesState: String?
    var updatedButtonTypes: [String] = []
    
    
    
    var buttonItems: [(name: String, type: String, status: String, dimmingState: String, deviceNumber: String)] = []
    var selectedSpecialButtonIndex: Int?
    
@IBOutlet weak var specailButtonCollectionView: UICollectionView!
    var buttons: [String] = ["light 1","light 2","light 2","light 4","light ","light 1","light 1","light 1","light 1","light 1","light 1"]
    var specailButtons : [String] = ["Light","Curtain 1","Curtain 2", "Door Lock" ]
    var specailButtonsIcon :[String] = [""]
    
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
        closedButton.setTitleColor(.black, for: .normal) // Set text color
        
        if let image = UIImage(named: "close")?.resized(to: CGSize(width: 30, height: 30)) {
            closedButton.setImage(image, for: .normal)
        }
       

        specailButtonCollectionView.dataSource = self
        specailButtonCollectionView.delegate = self
        buttonsCollectionView.dataSource = self
        buttonsCollectionView.delegate = self
        buttonsview.layer.borderWidth = 1
        buttonsview.layer.borderColor = UIColor.gray.cgColor
        registerXib()

        print("devicestate at \(devicestate)")
        print("devices\(devices)")

        let firstScene = selectedDevice?.uniqueId
        
        doorlockConfrimText.keyboardType = .numberPad
           doorUnlockText.keyboardType = .numberPad

        updateLockPinViewVisibility()
        parseDeviceState()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
           NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
  
    @objc func keyboardWillShow(_ notification: Notification) {
        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            let keyboardHeight = keyboardFrame.height
            let bottomMargin: CGFloat = 10  // Extra spacing

            // Move the view UP by keyboard height
            self.view.frame.origin.y = -keyboardHeight + bottomMargin
        }
    }

    @objc func keyboardWillHide(_ notification: Notification) {
        self.view.frame.origin.y = 0 // Reset view position
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true) // Dismiss keyboard when tapping outside
    }
    func updatePinAPI(pin: String) {
        guard let device = devicestate.first else {
            print("❌ No device found.")
            return
        }

        let parameters: [String: Any] = [
            "unique_id": device.uniqueID,  // Ensure this is a valid string
            "pin": pin,  // Ensure this is a 4-digit string
            "type": "D"
        ]

        let url = "http://3.7.18.55:3000/skroman/updatepin"

        print("📡 Sending PIN update request to: \(url)")
        print("📤 Parameters: \(parameters)")

        AF.request(url, method: .put, parameters: parameters, encoding: JSONEncoding.default)
            .validate()  // ✅ Ensure the response is valid
            .responseJSON { response in
                switch response.result {
                case .success(let data):
                    print("✅ PIN Update Success: \(data)")
                case .failure(let error):
                    print("❌ PIN Update Failed: \(error)")
                    
                    if let data = response.data {
                        let errorString = String(data: data, encoding: .utf8) ?? "No response data"
                        print("🔍 Server Response: \(errorString)")
                    }
                }
            }
    }

    func showAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    func parseDeviceState() {
        guard let device = devicestate.first else {
            print("No device state found!")
            return
        }
        print("device  at without \(device.cNm)")
        deviecesState = device.cNm
         print("deviecesState  are\(deviecesState)")
        
        let unwantedChars: Set<Character> = ["S", "W", "X", "G", "H", "I", "J"]
        let filteredcNm = device.cNm.filter { !unwantedChars.contains($0) }
        
        let dimmingStateString = device.cDim  // Example: "001000"
        let deviceNumberString = device.deviceNumber  // Example: "123456"

        print("dimmingState at \(dimmingStateString) ----- deviceNumber\(deviceNumberString)")

        buttonItems.removeAll()

        for (index, char) in filteredcNm.enumerated() {
            let lightStatus = (index < device.lightState.count) ?
                String(device.lightState[device.lightState.index(device.lightState.startIndex, offsetBy: index)]) : "0"

        
            let dimmingState = (index < dimmingStateString.count) ?
                String(dimmingStateString[dimmingStateString.index(dimmingStateString.startIndex, offsetBy: index)]) : "0"

         
            let deviceNumber = (index < deviceNumberString.count) ?
                String(deviceNumberString[deviceNumberString.index(deviceNumberString.startIndex, offsetBy: index)]) : "0"

            buttonItems.append((name: "\(char) \(index + 1)", type: String(char), status: lightStatus, dimmingState: dimmingState, deviceNumber: deviceNumber))
        }

        print("Parsed Buttons: \(buttonItems)")

        DispatchQueue.main.async {
            self.specailButtonCollectionView.reloadData()
        }
    }


    func registerXib(){
        let uinib =  UINib(nibName: "SpecailButtonCollectionViewCell", bundle: nil)
        specailButtonCollectionView.register(uinib, forCellWithReuseIdentifier: "SpecailButtonCollectionViewCell")
        let uinib1 =  UINib(nibName: "ButtonCollectionViewCell", bundle: nil)
        buttonsCollectionView.register(uinib1, forCellWithReuseIdentifier: "ButtonCollectionViewCell")

        
    }

    @IBAction func closedButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    func updateLockPinViewVisibility() {
        let lockExists = buttonItems.contains { $0.type == "D" }
        lockPinView.isHidden = !lockExists
        lockPinHeight.constant = lockExists ? 95 : 0
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded() // Smooth animation
        }
    }


    
    func publish_special_button_function(dest : String) {
        
        guard let device = devicestate.first else { return }
          let topic  = device.uniqueID
        
        let scene_pub_parameters : Parameters = [
            
            "control" : "config_button",
            "dest" : dest,
            "from": "A",
            "topic": topic
            
            
        ]
        
        if let theJSONData = try? JSONSerialization.data(withJSONObject: scene_pub_parameters,options: []) {
            
            let theJSONText = String(data: theJSONData,
                                     encoding: .ascii)
            print("JSON string = \(theJSONText!)")
            print("scene_pub_parameters at \(scene_pub_parameters)")
            
            let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
            
            let iot_sample_vc = Iot_sample_ViewController()
            
            iotDataManager.publishString(theJSONText!, onTopic: (topic ?? "") + "/HA/A/req", qoS:.messageDeliveryAttemptedAtMostOnce)
            
            
        }
    }
    
    @IBAction func configureButton(_ sender: Any) {
        print("🔹 Configure button pressed")

        
        printButtonItems()
        showPopup()
     
        if buttonItems.contains(where: { $0.type == "D" }) {
            print("🔹 Door Lock detected, validating PIN...")

        
            guard let unlockPin = doorUnlockText.text,
                  let confirmPin = doorlockConfrimText.text,
                  unlockPin.count == 4,
                  confirmPin.count == 4,
                  unlockPin == confirmPin else {
                
                showAlert(message: "Invalid PIN. Please enter a matching 4-digit PIN.")
                doorUnlockText.text = ""
                doorlockConfrimText.text = ""
                return
            }

            print("✅ PIN validated successfully, calling updatePinAPI...")
            
          
            updatePinAPI(pin: unlockPin)
        }
        
       
    }
    
    @objc func showPopup() {
        
        showPopupPresenter.showPopup1(on: self.view,
                                     animationName: "curtain_close",
                                     title: "Success!",
                                     subtitle: "Special Buttons set ")
        
       
    }
    

}


extension SpecialButtonViewController : UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == specailButtonCollectionView {
            return buttonItems.count
        } else  if collectionView == buttonsCollectionView {
            return specailButtons.count
            
        }
        return 0
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == specailButtonCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SpecailButtonCollectionViewCell", for: indexPath) as! SpecailButtonCollectionViewCell

            let buttonItem = buttonItems[indexPath.item]
            
          
            let isCustomName = !["L", "O", "C", "D", "Q", "Y"].contains(buttonItem.type)

            var displayName = buttonItem.name
            var imageName = getImageForSpecialButton(buttonItem.name) // Get image

            if !isCustomName {
                switch buttonItem.type {
                case "L":
                    displayName = "L \(indexPath.item + 1)"
                    imageName = "bulb"
                case "O":
                    displayName = "O \(indexPath.item + 1)"
                    imageName = "curtain-filled"
                case "C":
                    displayName = "C \(indexPath.item + 1)"
                    imageName = "curtains_close"
                case "D":
                    displayName = " Lock \(indexPath.item + 1)"
                    imageName = "lock-2"
                    
                case "Q":
                    displayName = "O \(indexPath.item + 1)"
                    imageName = "curtain-filled"
                case "Y":
                    displayName = "C \(indexPath.item + 1)"
                    imageName = "curtains_close"
                default:
                    break
                }
            }

            if buttonItem.dimmingState == "1" {
                        cell.dimmingImage.image = UIImage(named: "brightness-2")
                        cell.dimmingImage.isHidden = false
                    } else {
                        cell.dimmingImage.isHidden = true
                    }
        
               
                cell.deviceNameLabel.text = displayName
                cell.deviceImageView.image = UIImage(named: imageName)

                // ✅ Highlight selected button
                cell.layer.borderColor = (indexPath.item == selectedSpecialButtonIndex) ? UIColor.blue.cgColor : UIColor.clear.cgColor
            cell.cornerRadius =  8
            cell.clipsToBounds =  true
                cell.layer.borderWidth = (indexPath.item == selectedSpecialButtonIndex) ? 2 : 1


                print("Displaying item: \(displayName), Image: \(imageName)--\(buttonItem)")

            return cell
        }
        else if collectionView == buttonsCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ButtonCollectionViewCell", for: indexPath) as! ButtonCollectionViewCell
            
            let buttonType = specailButtons[indexPath.item]
            var imageName = ""

            switch buttonType {
            case "Light":
                imageName = "spBulb"
            case "Curtain 1", "Curtain 2":
                imageName = "spCurtion"
            case "Door Lock":
                imageName = "spLock"
            default:
                imageName = ""
            }

            cell.specailButtonNameLabel.text = buttonType
            cell.specialButtonImageView.image = UIImage(named: imageName)
            
            print("Button: \(buttonType), Image: \(imageName)")

            return cell
        }
        return UICollectionViewCell()
    }
    

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == specailButtonCollectionView {
            selectedSpecialButtonIndex = indexPath.item
            print("Selected special button at index \(indexPath.item)")
            collectionView.reloadData()
        }
        else if collectionView == buttonsCollectionView, let selectedIndex = selectedSpecialButtonIndex {
            let selectedDeviceName = specailButtons[indexPath.item]

            if buttonItems[selectedIndex].dimmingState == "1" {
                showAlert(title: "Action Not Allowed", message: "Dimmable lights cannot be changed.")
                return
            }

            if buttonItems[selectedIndex].deviceNumber != "\(selectedIndex + 1)" {
                showAlert(title: "Shuffle Button", message: "This button cannot be set as a special button.")
                return
            }

            if selectedDeviceName == "Door Lock" {
                buttonItems[selectedIndex].name = "Door Lock \(selectedIndex + 1)"
                buttonItems[selectedIndex].type = "D"

                print("✅ Converted \(selectedIndex) to Door Lock")

                DispatchQueue.main.async {
                    self.specailButtonCollectionView.reloadItems(at: [
                        IndexPath(item: selectedIndex, section: 0)
                    ])
                    self.updateLockPinViewVisibility()  // ✅ Check lock presence
                }
            }

            if (selectedDeviceName == "Curtain 1" || selectedDeviceName == "Curtain 2") &&
               (buttonItems[selectedIndex].type == "O" || buttonItems[selectedIndex].type == "C") {
                showAlert(title: "Cannot Set Curtain", message: "Curtain is already set. You can only convert Lights to Curtains.")
                return
            }

            if selectedDeviceName == "Light" {
                if selectedIndex > 0, buttonItems[selectedIndex - 1].type == "O" {
                    buttonItems[selectedIndex - 1].name = "Light \(selectedIndex)"
                    buttonItems[selectedIndex - 1].type = "L"
                }
                if selectedIndex + 1 < buttonItems.count, buttonItems[selectedIndex + 1].type == "C" {
                    buttonItems[selectedIndex + 1].name = "Light \(selectedIndex + 2)"
                    buttonItems[selectedIndex + 1].type = "L"
                }

                buttonItems[selectedIndex].name = "Light \(selectedIndex + 1)"
                buttonItems[selectedIndex].type = "L"

                print("✅ Converted Curtain 1/Curtain 2 back to Light at \(selectedIndex)")

                DispatchQueue.main.async {
                    self.specailButtonCollectionView.reloadItems(at: [
                        IndexPath(item: selectedIndex, section: 0),
                        IndexPath(item: selectedIndex - 1, section: 0),
                        IndexPath(item: selectedIndex + 1, section: 0)
                    ])
                }
            }
            else if selectedDeviceName == "Curtain 1" || selectedDeviceName == "Curtain 2" {
                let nextIndex = selectedIndex + 1

                if nextIndex >= buttonItems.count {
                    showAlert(title: "Cannot Set Curtain", message: "Not enough space to set Curtain Closed.")
                    return
                }

                if buttonItems[nextIndex].dimmingState == "1" {
                    showAlert(title: "Cannot Set Curtain", message: "Next device is dimmable and cannot be converted to Curtain Closed.")
                    return
                }

                if buttonItems[nextIndex].deviceNumber != "\(nextIndex + 1)" {
                    showAlert(title: "Cannot Set Curtain", message: "Next device number does not match. Curtain cannot be set.")
                    return
                }

                // ✅ Check if it's Curtain 1 or Curtain 2 and assign the correct type
                if selectedDeviceName == "Curtain 1" {
                    buttonItems[selectedIndex].name = "Curtain Open"
                    buttonItems[selectedIndex].type = "O"
                    buttonItems[nextIndex].name = "Curtain Closed"
                    buttonItems[nextIndex].type = "C"
                } else { // Curtain 2
                    buttonItems[selectedIndex].name = "Curtain Open"
                    buttonItems[selectedIndex].type = "Q"  // ✅ Set to "Q"
                    buttonItems[nextIndex].name = "Curtain Closed"
                    buttonItems[nextIndex].type = "Y"  // ✅ Set to "Y"
                }

                print("✅ Converted \(selectedIndex) to Curtain Open and \(nextIndex) to Curtain Closed")

                DispatchQueue.main.async {
                    self.specailButtonCollectionView.reloadItems(at: [
                        IndexPath(item: selectedIndex, section: 0),
                        IndexPath(item: nextIndex, section: 0)
                    ])
                }
            }
            else if selectedDeviceName == "Door Lock" {
                buttonItems[selectedIndex].name = "Door Lock \(selectedIndex + 1)"
                buttonItems[selectedIndex].type = "D"

                print("✅ Converted \(selectedIndex) to Door Lock")

                DispatchQueue.main.async {
                    self.specailButtonCollectionView.reloadItems(at: [
                        IndexPath(item: selectedIndex, section: 0)
                    ])
                }
            }
            
            print("🔹 Updated buttonItems state:")
            printButtonItems()
        }
    }


    func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }

    func getImageForSpecialButton(_ name: String) -> String {
        switch name {
        case "Light":
            return "spBulb"
        case "Curtain 1", "Curtain 2":
            return "spCurtion"
        case "Door Lock":
            return "spLock"
        default:
            return "defaultImage"
        }
    }


    func printButtonItems() {
       
        updatedButtonTypes = buttonItems.map { $0.type }
        
        print("🔹 Updated button types array: \(updatedButtonTypes)")
        
        // Get old device state
        guard let deviecesState = devicestate.first?.cNm else {
            print("No device state available!")
            return
        }
        
        print("deviecesState old: \(deviecesState)")

        // Unwanted characters that should be preserved
        let unwantedChars: Set<Character> = ["S", "W", "X", "G", "H", "I", "J"]

        var finalUpdatedState: [String] = []
        var typeIndex = 0 // Index for updatedButtonTypes

        // Iterate over old device state and construct final array
        for char in deviecesState {
            if unwantedChars.contains(char) {
                // Preserve unwanted characters
                finalUpdatedState.append(String(char))
            } else {
                // Replace with updated button type
                if typeIndex < updatedButtonTypes.count {
                    finalUpdatedState.append(updatedButtonTypes[typeIndex])
                    typeIndex += 1
                }
            }
        }

        // Convert finalUpdatedState array to a single string
        let finalUpdatedStateString = finalUpdatedState.joined()

       publish_special_button_function(dest: finalUpdatedStateString)
        print("🔹 Final updated state string for API: \(finalUpdatedStateString)")
    }




    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {

        // ✅ Fixed cell size 80x80 for both collections
        return CGSize(width: 80, height: 80)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {

        if collectionView == specailButtonCollectionView {
           
            return UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        } else {
           
            return UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        }
    }


    
}
