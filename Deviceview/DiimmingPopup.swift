//
//  DiimmingPopup.swift
//  SkromanIsra
//
//  Created by Admin on 27/02/25.
//

import UIKit
import AWSCore
import AWSIoT
import Alamofire
class DimmingPopupViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    var collectionView: UICollectionView!
    let activeColor = UIColor(hex: "#FAEDCB") // Light cream color
    let inactiveColor = UIColor(hex: "#D3D3D3")
    var devices: [Device] = []
    var devicestate: [DeviceStateArray] = [] 
    var buttonItems: [(text: String, isActive: Bool)] = []
    var deviceVc : DeviceViewController?
    
    let items = [("lightbulb", "Light 1"), ("lightbulb", "Light 2"), ("lightbulb", "Light 3")] // Sample data
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Background setup
        view.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        
        // Popup Container
        let popupView = UIView()
        popupView.backgroundColor = .white
        popupView.layer.cornerRadius = 12
        popupView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(popupView)
        
        // Collection View Setup
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 80, height: 100)
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(CustomCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        // Close Button
        // Close Button (with 'X' icon)
        let closeButton = UIButton()
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal) // 'X' icon
        closeButton.tintColor = .black
        closeButton.addTarget(self, action: #selector(closePopup), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false

        // Settings Button (with gear icon + label)
        let settingsButton = UIButton()
        settingsButton.setImage(UIImage(systemName: "gear"), for: .normal) // Gear icon
        settingsButton.setTitle("Settings", for: .normal) // Label
        settingsButton.setTitleColor(.orange, for: .normal)
        settingsButton.tintColor = .orange
        settingsButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        settingsButton.semanticContentAttribute = .forceLeftToRight // Ensures icon is on the left
        settingsButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -5, bottom: 0, right: 5) // Adjust spacing
        settingsButton.addTarget(self, action: #selector(openSettings), for: .touchUpInside)
        settingsButton.translatesAutoresizingMaskIntoConstraints = false

        // Configure Button
        let configureButton = UIButton()
        configureButton.setTitle("Configure", for: .normal)
        configureButton.backgroundColor = .systemBlue
        configureButton.layer.cornerRadius = 8
        settingsButton.addTarget(self, action: #selector(openSettings), for: .touchUpInside)
        configureButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Add subviews
        popupView.addSubview(closeButton)
        popupView.addSubview(settingsButton)
        popupView.addSubview(collectionView)
        popupView.addSubview(configureButton)
        
        // Constraints
        NSLayoutConstraint.activate([
            popupView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            popupView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            popupView.widthAnchor.constraint(equalToConstant: 300),
            popupView.heightAnchor.constraint(equalToConstant: 400),
            
            closeButton.topAnchor.constraint(equalTo: popupView.topAnchor, constant: 10),
            closeButton.trailingAnchor.constraint(equalTo: popupView.trailingAnchor, constant: -10),
            
            settingsButton.topAnchor.constraint(equalTo: popupView.topAnchor, constant: 10),
            settingsButton.leadingAnchor.constraint(equalTo: popupView.leadingAnchor, constant: 10),
            
            collectionView.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 20),
            collectionView.leadingAnchor.constraint(equalTo: popupView.leadingAnchor, constant: 10),
            collectionView.trailingAnchor.constraint(equalTo: popupView.trailingAnchor, constant: -10),
            collectionView.heightAnchor.constraint(equalToConstant: 250),
            
            configureButton.bottomAnchor.constraint(equalTo: popupView.bottomAnchor, constant: -20),
            configureButton.centerXAnchor.constraint(equalTo: popupView.centerXAnchor),
            configureButton.widthAnchor.constraint(equalToConstant: 120),
            configureButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        print("items data : \(devicestate)")
        filterDeviceState()
       
    }
    
    func filterDeviceState() {
           guard let device = devicestate.first else { return } // Assuming single device data
           
           let cNmArray = Array(device.cNm)  // Convert cNm to array
           let cLArray = Array(device.cL)    // Convert cL to array
           let lightStateArray = Array(device.lightState) // Convert lightState to array

           buttonItems = [] // Clear old data
           
           for (index, char) in cNmArray.enumerated() {
               if char == "L" { // Check if 'L' is present
                   let isActive = (lightStateArray[index] == "1") // Check if light is ON
                   let label = "L \(index + 1)" // Label dynamically
                   buttonItems.append((label, isActive))
               }
           }
       }
    
    @objc func closePopup() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func openSettings() {
        print("Settings Button Pressed")
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "DiimingSettingViewController") as? DiimingSettingViewController {
            
            
           
            vc.devices = self.devices

            if let navController = navigationController {
                print("✅ Pushing view controller onto navigation stack")
                navController.pushViewController(vc, animated: true)
            } else {
                print("⚠️ No navigation controller found. Presenting modally.")
                vc.modalPresentationStyle = .fullScreen
                present(vc, animated: true, completion: nil)
            }
        } else {
            print("❌ ERROR: Could not instantiate DiimingSettingViewController. Check Storyboard ID and storyboard name.")
        }
    }

  

   

    
    

   
    @objc func configureAction() {
        print("Configure Button Pressed")

        guard let device = devicestate.first else { return } // Get the first device
        
        let cDimValue = device.cDim // Get the updated cDim value
        let topic = device.uniqueID // Use uniqueID as pub_topic

     
        publish_button(val: cDimValue, topic: topic)

    
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

    // MARK: CollectionView Delegates
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return  buttonItems.count

    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! CustomCell
        
        let buttonData = buttonItems[indexPath.item]
        
        // Convert cDim to an array of characters
        if let device = devicestate.first {
            let cDimArray = Array(device.cDim) // Convert String to Array<Character>
            
            // Check if index is within bounds before accessing
            let isDim = indexPath.item < cDimArray.count && cDimArray[indexPath.item] == "1"

            cell.configure(imageName: "brightness-2", text: buttonData.text, isDim: isDim)
        } else {
            cell.configure(imageName: "brightness-2", text: buttonData.text, isDim: false)
        }

        cell.backgroundColor = buttonData.isActive ? activeColor : inactiveColor // Set color based on lightState
        
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let device = devicestate.first else { return } // Get the first device
        var cDimArray = Array(device.cDim) // Convert cDim string to array of characters
        let cNmArray = Array(device.cNm)   // Convert cNm string to array of characters

        // Find the actual index in `cDim` based on the 'L' positions in `cNm`
        var lightIndices: [Int] = []
        for (i, char) in cNmArray.enumerated() {
            if char == "L" { lightIndices.append(i) }
        }

        guard indexPath.item < lightIndices.count else { return } // Ensure index is within bounds

        let actualIndex = lightIndices[indexPath.item] // Get actual index in `cDim`
        
        // Toggle value (0 ↔ 1)
        cDimArray[actualIndex] = (cDimArray[actualIndex] == "1") ? "0" : "1"

        let updatedCDim = String(cDimArray) // Convert back to String

        // Assign back to a new DeviceStateArray instance
        let updatedDevice = DeviceStateArray(
            uniqueID: device.uniqueID,
            modelNo: device.modelNo,
            deviceNumber: device.deviceNumber,
            cDim: updatedCDim,  // ✅ Only cDim changes at the correct index
            cNm: device.cNm,
            cL: device.cL,
            cF: device.cF,
            cM: device.cM,
            workingMode: device.workingMode,
            master: device.master,
            ack: device.ack,
            lightState: device.lightState,
            lightSpeed: device.lightSpeed,
            fanState: device.fanState,
            fanSpeed: device.fanSpeed,
            controlFrom: device.controlFrom, series: device.series, otaStatus: device.otaStatus, rRegulator: device.rRegulator
        )

        // Update the device state
        devicestate[0] = updatedDevice

        print("Updated cDim: \(updatedCDim)")

        // Reload only the clicked cell
        collectionView.reloadItems(at: [indexPath])
        
        // ✅ Corrected function call
       // publish_button(val: updatedCDim, topic: device.uniqueID)
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
            print("JSON string = \(theJSONText!)")

            let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
            iotDataManager.publishString(theJSONText!, onTopic: topic + "/HA/A/req", qoS: .messageDeliveryAttemptedAtMostOnce)
        }
    }
    
   
    // UIPickerView Delegate & Data Source
    class PickerDelegate: NSObject, UIPickerViewDelegate, UIPickerViewDataSource {
        var data: [String]

        init(data: [String]) {
            self.data = data
        }

        func numberOfComponents(in pickerView: UIPickerView) -> Int {
            return 1
        }

        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            return data.count
        }

        func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
            return data[row]
        }
    }


    

}

class CustomCell: UICollectionViewCell {
    
    let imageView = UIImageView()
    let label = UILabel()
    let isdimImageView = UIImageView() // New image view
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        // Apply border and corner radius
        contentView.layer.borderWidth = 2
        contentView.layer.borderColor = UIColor.white.cgColor
        contentView.layer.cornerRadius = 10
        contentView.clipsToBounds = true
        
        // Main Image (Center)
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(systemName: "lightbulb")
        imageView.tintColor = .white
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Small Top-Left Image
        isdimImageView.contentMode = .scaleAspectFit
        isdimImageView.image = UIImage(systemName: "brightness-2") // New image
        isdimImageView.tintColor = .gray // Default color
        isdimImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Label
        label.textColor = .black
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        // Add subviews
        contentView.addSubview(imageView)
        contentView.addSubview(label)
        contentView.addSubview(isdimImageView) // Add new imageView
        
        // Constraints
        NSLayoutConstraint.activate([
            // Main Image
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            imageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 60),
            imageView.heightAnchor.constraint(equalToConstant: 60),
            
            // Label
            label.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 5),
            label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            // New Top-Left Image
            isdimImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            isdimImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 5),
            isdimImageView.widthAnchor.constraint(equalToConstant: 20),
            isdimImageView.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(imageName: String, text: String, isDim: Bool) {
        if let image = UIImage(systemName: imageName)?.withRenderingMode(.alwaysTemplate) {
            imageView.image = image
            imageView.tintColor = .black
        }
        
        label.text = text
        
        // Toggle visibility of isdimImageView based on isDim
        isdimImageView.isHidden = !isDim
        isdimImageView.tintColor = isDim ? .systemOrange : .gray
    }


}


