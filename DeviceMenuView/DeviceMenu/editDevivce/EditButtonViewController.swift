//
//  EditButtonViewController.swift
//  SkromanIsra
//
//  Created by Admin on 17/03/25.
//

import UIKit
import AWSCore
import AWSIoT
import Alamofire

class EditButtonViewController: UIViewController {

    @IBOutlet weak var editButton: UIView!
    
    @IBOutlet var backgroundView: UIView!
    @IBOutlet weak var wattageText: UITextField!
    @IBOutlet weak var selectedButtonName: UILabel!
    
    @IBOutlet weak var setcolorButton: UIImageView!
    @IBOutlet weak var dimmingImageView: UIImageView!
    @IBOutlet weak var childLockImage: UIImageView!
    @IBOutlet weak var selectedImage: UIImageView!
    @IBOutlet weak var buttonNameText: UITextField!
    @IBOutlet weak var selecetdView: UIView!
    var selectedIconName: String?
    @IBOutlet weak var favouriteButton: UIButton!
    @IBOutlet weak var buttonCollectionView: UICollectionView!
    var selectedButtonItem: (name: String, type: String, status: String)?
    @IBOutlet weak var buttonView: UIView!
    var devicestate: [DeviceStateArray] = []
    var deviceVc : DeviceViewController?
    var devices: [Device] = []
    weak var parentVC: EditDeviceViewController?
    var lightArray: [String] = []
    var lightNames: [String: String] = [:]
    var deviceUid: String?
    var buttonDetails: ButtonDetails?
    var getbuttondetails : [ButtonDetails] = []
    var selectedButtonDetail: [String: String]?
    var deviceUinqueId: String?
    var isFromLongPress: Bool = false
    var selectedBtnNumber: Int?
    var selectedSwitchItem: SwitchItem?
    private var workingCL: String = ""
    
    
    override func viewDidLoad() {
        applyGradientBackground()
        super.viewDidLoad()

        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        buttonCollectionView.dataSource = self
        buttonCollectionView.delegate = self
        devicecornerView()
        registerXib()
        print("device at state \(devicestate)")
        dimmingImageView.isHidden = true
        childLockImage.isHidden = true
        setcolorButton.isHidden =  true
        setupSelectedButtonItem()
        updateUIForLongPress()
        if let firstScene = devices.first {
            deviceUid = firstScene.deviceUid
        } else {
            deviceUid = nil
        }

        print("selectedButtonItem at \(selectedSwitchItem)")

        if let firstDevice = devices.first {
            deviceUinqueId = firstDevice.uniqueId
            deviceUid = firstDevice.deviceUid
        } else {
            deviceUinqueId = nil
        }
        favouriteButton.addTarget(self, action: #selector(toggleFavourite), for: .touchUpInside)
        

        dimmingImageView.isUserInteractionEnabled = true
           let dimTapGesture = UITapGestureRecognizer(target: self, action: #selector(dimmingImageTapped))
           dimmingImageView.addGestureRecognizer(dimTapGesture)
        childLockImage.isUserInteractionEnabled = true
           let lockTapGesture = UITapGestureRecognizer(target: self, action: #selector(childLockImageTapped))
        childLockImage.addGestureRecognizer(lockTapGesture)
        
        setcolorButton.isUserInteractionEnabled = true
            let colorTapGesture = UITapGestureRecognizer(target: self, action: #selector(openColorPickerWithSetButton))
            setcolorButton.addGestureRecognizer(colorTapGesture)
        if let item   = selectedSwitchItem,
           let device = devicestate.first(where: { $0.uniqueID == item.uniqueID }) {
            workingCL = device.cL              // cache the original value
        }

    }

    
    func updateUIForLongPress() {
        if isFromLongPress {
            childLockImage.isHidden = false
            setcolorButton.isHidden = false
            
            guard let buttonItem = selectedSwitchItem else { return }
            buttonNameText.text = buttonItem.buttonDetail?.buttonName
            
            switch buttonItem.buttonDetail?.buttonControlName {
            case "L":
                lightArray = ["light", "kp_light_3", "kp_light_4", "kp_light_5", "kp_socket", "kp_ac_1", "kp_ac_2", "kp_ac_4"]
                lightNames = [
                    "light": "Light", "kp_light_3": "Light",
                    "kp_light_4": "Light", "kp_light_5": "Light", "kp_socket": "Socket",
                    "kp_ac_1": "AC", "kp_ac_2": "AC", "kp_ac_4": "AC"
                ]
                
                // Show dimmingImageView for lights only
                dimmingImageView.isHidden = false
                
                if buttonItem.configDim == "1" {
                    dimmingImageView.image = UIImage(named: "brightness-2")
                } else {
                    dimmingImageView.image = UIImage(named: "brightness-control")
                    
                }
            
            case "D":
                lightArray = ["lock-1", "lock-3", "lock0"]
                lightNames = ["lock-1": "Lock", "lock-3": "Lock", "lock0": "Lock"]
                dimmingImageView.isHidden = true
                
            case "C":
                lightArray = ["curtains_close2", "curtains_close"]
                lightNames = ["curtains_close2": "Curtain Close", "curtains_close": "Curtain Close"]
                dimmingImageView.isHidden = true
                
            case "O":
                lightArray = ["curtains-2", "curtains_Open"]
                lightNames = ["curtains-2": "Curtain Open", "curtains_Open": "Curtain Open"]
                dimmingImageView.isHidden = true
                
            case "F":
                lightArray = ["fan2", "ceiling-fan"]
                lightNames = ["fan2": "Fan", "ceiling-fan": "Fan"]
                dimmingImageView.isHidden = true
            case "D":
                lightArray = ["lock-1", "lock-3", "lock0"]
                lightNames = ["lock-1": "Lock", "lock-3": "Lock", "lock0": "Lock"]
                dimmingImageView.isHidden = true
       
            default:
                lightArray = []
                lightNames = [:]
                dimmingImageView.isHidden = true
            }
            
            // Show icon image fallback
            if let iconName = buttonItem.buttonDetail?.buttonIconName, iconName != "Unknown" {
                selectedImage.image = UIImage(named: iconName)
            } else if let fallbackIconName = lightArray.first {
                selectedImage.image = UIImage(named: fallbackIconName)
            } else {
                selectedImage.image = nil
            }
            
        } else {
            dimmingImageView.isHidden = true
            childLockImage.isHidden = true
            setcolorButton.isHidden = true
            selectedImage.image = nil
        }
    }

    
    @objc func dimmingImageTapped() {
        guard var buttonItem = selectedSwitchItem else { return }
        let switchIndex = buttonItem.switchIndex

        let index = switchIndex - 1

       
        guard let device = devicestate.first(where: { $0.uniqueID == buttonItem.uniqueID }) else { return }

       
        var cDimArray = Array(device.cDim)

        // Toggle configDim and update image
        if buttonItem.configDim == "1" {
            dimmingImageView.image = UIImage(named: "brightness-control")
            buttonItem.configDim = "0"
            cDimArray[index] = "0"
        } else {
            dimmingImageView.image = UIImage(named: "brightness-2")
            buttonItem.configDim = "1"
            cDimArray[index] = "1"
        }

        // Store and print the updated cDim string
        let updatedCDim = String(cDimArray)
        print("Updated cDim: \(updatedCDim)")

        publish_button(val: updatedCDim, topic: buttonItem.uniqueID)
        selectedSwitchItem = buttonItem
    }

    
    @objc func childLockImageTapped() {
        guard var buttonItem = selectedSwitchItem else { return }
        guard let item = selectedSwitchItem,
              let controlName = item.buttonDetail?.buttonControlName,
              ["L", "O", "C", "Q", "Y"].contains(controlName) else { return }

        let idx = item.switchIndex - 1
        guard idx >= 0 && idx < workingCL.count else { return }

        guard let device = devicestate.first(where: { $0.uniqueID == buttonItem.uniqueID }) else { return }

        var chars = Array(workingCL)
        let cFvalue = device.cF
        let cMvalue  = device.cM
        chars[idx] = (chars[idx] == "1") ? "0" : "1"

        workingCL = String(chars)

        childLockImage.image = UIImage(named: chars[idx] == "1" ? "locked" : "unlocked")

        print("Updated cL: \(workingCL)")

        publish_child_lock(
            L_Lock_Value: workingCL,
            F_Lock_Value: cFvalue,
            M_Lock_Value: cMvalue,
            topic: buttonItem.uniqueID
        )
    }
    
    func applyGradientBackground() {
        let mainScreen = CAGradientLayer()
        mainScreen.frame = backgroundView.bounds

        mainScreen.colors = [
            UIColor(red: 163/255, green: 159/255, blue: 98/255, alpha: 1).cgColor,
            UIColor(red: 141/255, green: 176/255, blue: 144/255, alpha: 1).cgColor,
            UIColor(red: 104/255, green: 155/255, blue: 181/255, alpha: 1).cgColor
        ]

        mainScreen.locations = [0.0, 0.3, 0.8]  // Expands green & blue areas
        mainScreen.startPoint = CGPoint(x: 0.5, y: 0)   // Top center
        mainScreen.endPoint = CGPoint(x: 0.5, y: 1)     // Bottom center

     
        backgroundView.layer.sublayers?.removeAll(where: { $0 is CAGradientLayer })
        
        backgroundView.layer.insertSublayer(mainScreen, at: 0)
    }
    
    func setupSelectedButtonItem() {
        guard let buttonItem = selectedButtonItem else { return }
        favouriteButton.setTitle("", for: .normal)

        // Determine which heart image to show based on isFavourite
        let heartImageName: String
        if let details = buttonDetails {
            
            print("Button at vc Details: \(details.isFavourite)")
            buttonNameText.text = details.buttonName
            selectedButtonName.text = details.buttonName
            wattageText.text = "\(details.power)"
            
            // Set the button icon image
            if !details.buttonIconName.isEmpty, let image = UIImage(named: details.buttonIconName) {
                selectedImage.image = image
            } else {
                selectedImage.image = getImageForType(buttonItem.type) // fallback
            }

            // Determine heart image
            heartImageName = (details.isFavourite == 1) ? "heart-2" : "like"
        } else {
          
            heartImageName = "like"
        }

        if let heartImage = UIImage(named: heartImageName)?.resized(to: CGSize(width: 30, height: 30)) {
            favouriteButton.setImage(heartImage, for: .normal)
        }
    

       


        switch buttonItem.type {
      
        case "L":
            lightArray = ["light", "kp_light_3", "kp_light_4", "kp_light_5", "kp_socket", "kp_ac_1", "kp_ac_2", "kp_ac_4"]
            lightNames = [
                "light": "Light", "kp_light_3": "Light",
                "kp_light_4": "Light", "kp_light_5": "Light", "kp_socket": "Socket",
                "kp_ac_1": "AC", "kp_ac_2": "AC", "kp_ac_4": "AC"
            ]

        case "D":
            lightArray = ["lock-1", "lock-3", "lock0"]
            lightNames = ["lock-1": "Lock", "lock-3": "Lock", "lock0": "Lock"]
        case "C":
            lightArray = ["curtains_close2", "curtains_close"]
            lightNames = ["curtains_close2": "Curtain Close", "curtains_close": "Curtain Close"]
        case "O":
            lightArray = ["curtains-2", "curtains_Open"]
            lightNames = ["curtains-2": "Curtain Open", "curtains_Open": "Curtain Open"]
        default:
            lightArray = []
            lightNames = [:]
        }
        
        guard let buttonItem = selectedButtonItem else { return }
        
       
       
        
        
        buttonCollectionView.reloadData()
    }
    
    @objc func toggleFavourite() {
        guard var details = buttonDetails else { return }

        details.isFavourite = (details.isFavourite == 1) ? 0 : 1
        buttonDetails = details

        let heartImageName = (details.isFavourite == 1) ? "heart-2" : "like"
        if let heartImage = UIImage(named: heartImageName)?.resized(to: CGSize(width: 30, height: 30)) {
            favouriteButton.setImage(heartImage, for: .normal)
        }

        print("Toggled favourite state: \(details.isFavourite)")
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if let parentVC = parentVC {
            print("Returning from EditButtonViewController, buttonItems in parent = \(parentVC.buttonItems)")
        } else {
            print("❌ parentVC is nil")
        }
    }




   
    func getImageForType(_ type: String) -> UIImage? {
        switch type {
        case "L":
            return UIImage(named: "bulb")
        case "O":
            return UIImage(named: "curtains_open")
        case "C":
            return UIImage(named: "curtains_close")
        case "Q":
            return UIImage(named: "curtains_Open")
        case "Y":
            return UIImage(named: "curtains_close")
        case "F":
            return UIImage(named: "ceiling-fan")
        case "M":
            return UIImage(named: "AppIcon")
        default:
            return nil
        }
    }
   

    
    func publish_button(val: String, topic: String) {
        
        let fetch_all_params: Parameters = [
            "control": "config_dim",
            "val": val,
            "from": "A",
            "topic": topic
        ]

        if let theJSONData = try? JSONSerialization.data(withJSONObject: fetch_all_params, options: []) {
            let theJSONText = String(data: theJSONData, encoding: .ascii)
            print("JSON dimm string = \(theJSONText!)")
            showPopupdimming()
            let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
            iotDataManager.publishString(theJSONText!, onTopic: topic + "/HA/A/req", qoS: .messageDeliveryAttemptedAtMostOnce)
        }
    }
   
    @objc func showPopupdimming() {
        showPopupPresenter.showPopup1(on: self.view,
                                       animationName: "light",
                                       title: "Success!",
                                       subtitle: "Dimming Changes Done.")

        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { 
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    
    func publish_child_lock(L_Lock_Value: String, F_Lock_Value: String, M_Lock_Value: String, topic: String) {
        let fetch_all_params: [String: Any] = [
            "control": "child_lock",
            "L": L_Lock_Value,
            "F": F_Lock_Value,
            "M": M_Lock_Value,
            "from": "A",
            "topic": topic
        ]
        
        print("FETCH ALL PARAMS : >>> ", fetch_all_params)
        
        if let theJSONData = try? JSONSerialization.data(withJSONObject: fetch_all_params, options: []) {
            if let theJSONText = String(data: theJSONData, encoding: .ascii) { // Use UTF-8 encoding
                print("JSON string = \(theJSONText)")
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { // Add 200ms delay
                    let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
                    iotDataManager.publishString(theJSONText, onTopic: "\(topic)/HA/A/req", qoS: .messageDeliveryAttemptedAtMostOnce)
                    self.showPopupLock()
                }
            } else {
                print("Error: Failed to convert JSON data to UTF-8 string.")
            }
        } else {
            print("Error: JSON serialization failed.")
        }
    }

    @objc func showPopupLock() {
        
        showPopupPresenter.showPopup1(on: self.view,
                                     animationName: "lock",
                                     title: "Child Lock",
                                     subtitle: "Child Lock buttons are set.")
        
       
    }
    
    
    @objc func openColorPickerWithSetButton() {
        let parentVC = UIViewController()
        parentVC.view.backgroundColor = .systemBackground

        // Color Picker
        let colorPicker = UIColorPickerViewController()
        colorPicker.supportsAlpha = false
        colorPicker.selectedColor = .white

        parentVC.addChild(colorPicker)
        parentVC.view.addSubview(colorPicker.view)
        colorPicker.view.translatesAutoresizingMaskIntoConstraints = false
        colorPicker.didMove(toParent: parentVC)

        // Set Color Button
        let setColorButton = UIButton(type: .system)
        setColorButton.setTitle("Set Color", for: .normal)
        setColorButton.backgroundColor = .systemBlue
        setColorButton.setTitleColor(.white, for: .normal)
        setColorButton.layer.cornerRadius = 10
        setColorButton.translatesAutoresizingMaskIntoConstraints = false
        setColorButton.addTarget(nil, action: #selector(handleColorSetButtonTapped(_:)), for: .touchUpInside)

        parentVC.view.addSubview(setColorButton)

        // Close Button
        let closeButton = UIButton(type: .system)
        closeButton.setTitle("✕", for: .normal)
        closeButton.setTitleColor(.black, for: .normal)
        closeButton.titleLabel?.font = .systemFont(ofSize: 24, weight: .bold)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(nil, action: #selector(handleCloseButtonTapped(_:)), for: .touchUpInside)

        parentVC.view.addSubview(closeButton)

        // Constraints
        NSLayoutConstraint.activate([
            colorPicker.view.topAnchor.constraint(equalTo: parentVC.view.topAnchor),
            colorPicker.view.leadingAnchor.constraint(equalTo: parentVC.view.leadingAnchor),
            colorPicker.view.trailingAnchor.constraint(equalTo: parentVC.view.trailingAnchor),
            colorPicker.view.bottomAnchor.constraint(equalTo: setColorButton.topAnchor, constant: -12),

            setColorButton.bottomAnchor.constraint(equalTo: parentVC.view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            setColorButton.centerXAnchor.constraint(equalTo: parentVC.view.centerXAnchor),
            setColorButton.widthAnchor.constraint(equalToConstant: 160),
            setColorButton.heightAnchor.constraint(equalToConstant: 44),

            closeButton.topAnchor.constraint(equalTo: parentVC.view.safeAreaLayoutGuide.topAnchor, constant: 10),
            closeButton.trailingAnchor.constraint(equalTo: parentVC.view.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30)
        ])

        // Store for later
        objc_setAssociatedObject(setColorButton, &AssociatedKeys.colorPicker, colorPicker, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(setColorButton, &AssociatedKeys.parentVC, parentVC, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(closeButton, &AssociatedKeys.parentVC, parentVC, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        present(parentVC, animated: true)
    }
    @objc func handleCloseButtonTapped(_ sender: UIButton) {
        if let parentVC = objc_getAssociatedObject(sender, &AssociatedKeys.parentVC) as? UIViewController {
            parentVC.dismiss(animated: true)
        }
    }

    @objc func handleColorSetButtonTapped(_ sender: UIButton) {
        guard
            let colorPicker = objc_getAssociatedObject(sender, &AssociatedKeys.colorPicker) as? UIColorPickerViewController,
            let parentVC = objc_getAssociatedObject(sender, &AssociatedKeys.parentVC) as? UIViewController
        else { return }

        let selectedColor = colorPicker.selectedColor
        print("Selected color: \(selectedColor)")

      
        triggerColorUpdate(with: selectedColor)

        // Close the popup
        parentVC.dismiss(animated: true)
    }


    private struct AssociatedKeys {
        static var colorPicker = "AssociatedColorPicker"
        static var parentVC = "AssociatedParentVC"
    }
    
    
    func triggerColorUpdate(with color: UIColor) {
        guard let detail = selectedSwitchItem?.buttonDetail else {
                print("❌ buttonDetail is nil"); return
            }

           
            let topic  = detail.uniqueId                 // ‹topic›
            let specialTypes   = detail.buttonControlName        // ‹T›
            let selectedNumber = detail.buttonNo
        let controlName    = detail.buttonControlName
     


        let lightTypes: Set<String> = ["L","O","C","D","Q","Y"]
          let tValue = lightTypes.contains(controlName) ? "L_ST" : "F_ST"

        let colorComponents = color.cgColor.components ?? [1, 1, 1]
        let red = colorComponents.count > 0 ? colorComponents[0] : 1.0
        let green = colorComponents.count > 1 ? colorComponents[1] : 1.0
        let blue = colorComponents.count > 2 ? colorComponents[2] : 1.0

        let all_params: Parameters = [
            "control": "ctrl_board_button_rgb_color",
            "T": tValue,
            "N": selectedNumber,
            "R": red * 100,
            "G": green * 100,
            "B": blue * 100,
            "H": "255",
            "from": "A",
            "topic": topic
        ]

        print("MQTT Params: \(all_params)")

        if let theJSONData = try? JSONSerialization.data(withJSONObject: all_params, options: []) {
            let theJSONText = String(data: theJSONData, encoding: .ascii)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
                iotDataManager.publishString(
                    theJSONText!,
                    onTopic: topic + "/HA/A/req",
                    qoS: .messageDeliveryAttemptedAtMostOnce
                )
            }
        }
    }

    
    func devicecornerView() {
        let views = [selecetdView,  buttonView]
        
        for view in views {
            view?.cornerRadius = 10
            view?.clipsToBounds = true
            view?.borderWidth = 1
            view?.borderColor = .gray
        }
    }
    
    @IBAction func cancleButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func updateButton(_ sender: Any) {
        fetchApiButtonDetail()
    }
    func registerXib() {
        let uinib = UINib(nibName: "EditButtonCollectionViewCell", bundle: nil)
        buttonCollectionView.register(uinib, forCellWithReuseIdentifier: "EditButtonCollectionViewCell")
    }
    
    @IBAction func favouriteButtonTapped(_ sender: UIButton) {
        animateHearts(from: sender)
    }

    func animateHearts(from button: UIButton) {
        let heartImages = ["love"]
        let numberOfHearts = 6

        for _ in 0..<numberOfHearts {
            let heartImageView = UIImageView(image: UIImage(named: heartImages.randomElement()!))
            heartImageView.frame = CGRect(x: 0, y: 0, width: 30, height: 30) // Adjust size
            heartImageView.center = button.superview?.convert(button.center, to: view) ?? button.center
            view.addSubview(heartImageView)

            let randomXOffset = CGFloat.random(in: -40...40)
            let randomY = CGFloat.random(in: -150...(-100))  

            let finalPosition = CGPoint(x: heartImageView.center.x + randomXOffset, y: heartImageView.center.y + randomY)

            UIView.animate(withDuration: 1.2, delay: 0, options: [.curveEaseOut], animations: {
                heartImageView.center = finalPosition
                heartImageView.alpha = 0 // Fade out effect
            }) { _ in
                heartImageView.removeFromSuperview()
            }
        }
    }

    
    func fetchApiButtonDetail() {
        guard let buttonDetails = buttonDetails, let buttonItem = selectedButtonItem else {
            print("Error: No button details or selected button item available")
            return
        }

        guard let buttonIconName = selectedIconName else {
            print("Error: No selected icon from collection view")
            return
        }

        let isFavourite: Bool
            if let currentImage = favouriteButton.image(for: .normal)?.accessibilityIdentifier {
                isFavourite = (currentImage == "heart-2")
            } else {
                // Fallback to using the actual details property
                isFavourite = (buttonDetails.isFavourite == 1)
            }
        
        let edit_params: Parameters = [
            "deviceServerId": buttonDetails.deviceServerId,
            "buttonName": buttonNameText.text ?? "",
            "power": Int(wattageText.text ?? "") ?? 0,
            "buttonIconId": 1,
            "buttonControlName": buttonItem.type,
            "buttonIconName": buttonIconName,
            "isFavourite":isFavourite
        ]

        print("button details API: \(edit_params)")

        AF.request("http://3.7.18.55:3000/skroman/buttondetails/buttonupdate",
                   method: .put,
                   parameters: edit_params,
                   encoding: JSONEncoding.default,
                   headers: nil)
            .response { response in
                debugPrint(response)

                switch response.result {
                case .success(let data):
                    do {
                        let jsonOne = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary
                        if let msg = jsonOne?["msg"] as? String, msg == "Success update button details" {
                            self.dismiss(animated: true)
                        }
                    } catch {
                        print("Error parsing response: \(error.localizedDescription)")
                    }

                case .failure(let err):
                    print("Request failed: \(err.localizedDescription)")
                }
            }.resume()
    }

    func Get_Button_Names_Api_Func() {
        guard let buttonDetails = buttonDetails, let buttonItem = selectedButtonItem else {
            print("Error: No button details or selected button item available")
            return
        }
        
        let get_button_name_params : Parameters = [
            
            "deviceUid": buttonDetails.deviceUid ?? ""
            
        ]
        
        AF.request("http://3.7.18.55:3000/skroman/buttondetails/getbuttons", method: .post, parameters: get_button_name_params, encoding: JSONEncoding.default, headers: nil).response { [self] response in
            debugPrint(response)
            
            switch response.result
            {
            case .success(let data) :
                do {
                    
                    
                    let jsonOne = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary
                    
                    print("jsonOne -- >>", jsonOne!)
                    
                    if let parse_json = jsonOne!["result"] as? [[String : AnyObject]] {
                        
                        
                       
                        for button_name_list in parse_json {
                            
                            let buttonName = button_name_list["buttonName"] as? String
                            let deviceServerId = button_name_list["deviceServerId"] as? String
                            let modelNo = button_name_list["modelNo"] as? String
                            let buttonControlName = button_name_list["buttonControlName"] as? String
                            
//
                            print("buttonName :: >>", buttonName!)
                            
                        }
                        
                     
                        
                        
                    }
                    
                    
                    
                }
                
                
                catch {
                    print(error.localizedDescription)
                }
                
                
            case .failure(let err):
                print(err.localizedDescription)
            }
            
        }.resume()
        
        func customComparator(_ a: String, _ b: String) -> Bool {

            let numA = Int(a.dropFirst()) ?? 0
            let numB = Int(b.dropFirst()) ?? 0
            return numA < numB

        }

        func letterComparator(_ a: String, _ b: String) -> Bool {
            let letterA = String(a.prefix(1))
            let letterB = String(b.prefix(1))
            return letterA > letterB
        }
        
    }


}


extension EditButtonViewController: UICollectionViewDataSource,  UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return lightArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = buttonCollectionView.dequeueReusableCell(withReuseIdentifier: "EditButtonCollectionViewCell", for: indexPath) as! EditButtonCollectionViewCell
        
        let imageName = lightArray[indexPath.item]
           cell.buttonImage.image = UIImage(named: imageName)
           cell.buttonNameLabel.text = lightNames[imageName] ?? "Unknown"
        return cell
        
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let numberOfColumns: CGFloat = 3
        let spacing: CGFloat = 25
        let totalSpacing = (numberOfColumns - 1) * spacing
        let itemWidth = (collectionView.frame.width - totalSpacing - 10) / numberOfColumns
        return CGSize(width: itemWidth, height: itemWidth)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedImageName = lightArray[indexPath.item]
        selectedImage.image = UIImage(named: selectedImageName)
        
        selectedIconName = lightArray[indexPath.item]
                print("Selected icon: \(selectedIconName ?? "None")")
       
    }


    
}
extension EditButtonViewController: UIColorPickerViewControllerDelegate {
    func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
        let selectedColor = viewController.selectedColor
        // Update the bulb image's tint color with the selected color
        selectedImage.tintColor = selectedColor
    selectedImage.image = selectedImage.image?.withRenderingMode(.alwaysTemplate)
    }

    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        // Optionally handle actions after the color picker is dismissed
    }
}
