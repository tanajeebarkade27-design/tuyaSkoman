//
//  DimmingViewController.swift
//  SkromanIsra
//
//  Created by Admin on 13/02/25.
//

import UIKit
import AWSCore
import AWSIoT
import Alamofire

class DimmingViewController: UIViewController {

    @IBOutlet weak var closedButton: UIButton!
    
    
    @IBOutlet weak var backgroundimage: UIImageView!
    
    @IBOutlet var dimmingBckgrounView: UIView!
    @IBOutlet weak var settingButton: UIButton!
    @IBOutlet weak var dimmDevicecollectionView: UICollectionView!
    @IBOutlet var dimmBckgrounView: UIView!
    var buttonItems: [(text: String, isActive: Bool, isDim: Bool)] = []
    var devices: [Device] = []
    var devicestate: [DeviceStateArray] = []
    var filteredButtonDetails: [ButtonDetails] = []
    let activeColor = UIColor(hex: "#FAEDCB")
    let inactiveColor = UIColor(hex: "#FFFFFF")
    
    @IBOutlet weak var collectionbackgroundView: UIView!
    
    
    var selectedDevice: Device?
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
       print("filteredButtonDetails\(filteredButtonDetails)")
        print ("devicestate at \(devicestate)")
        registerXib()
        filterDeviceState()
    }
    
    func registerXib(){
        let uinib =  UINib(nibName: "DimmingCollectionViewCell", bundle: nil)
        dimmDevicecollectionView.register(uinib, forCellWithReuseIdentifier: "DimmingCollectionViewCell")
        dimmDevicecollectionView.delegate =  self
        dimmDevicecollectionView.dataSource =  self
      
        dimmBckgrounView.clipsToBounds =  true
        collectionbackgroundView.clipsToBounds =  true
        collectionbackgroundView.cornerRadius = 15
        dimmBckgrounView.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        dimmBckgrounView.cornerRadius = 15
        
        print("devices at dim\(devices)")
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

    
    @IBAction func settingButton(_ sender: Any) {
      
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "DiimingSettingViewController") as? DiimingSettingViewController {
            
            
           
            vc.selectedDevice = self.selectedDevice
             

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
    
   
    
    @IBAction func ConfigureButton(_ sender: Any) {
        configureAction()
    }
    
    func filterDeviceState() {
        guard let device = devicestate.first else { return }
        
        let cNmArray = Array(device.cNm)
        let cDimArray = Array(device.cDim)
        let lightStateArray = Array(device.lightState)
        print("cDimArrayn is \(cDimArray)")

        buttonItems = []
        
        for (index, char) in cNmArray.enumerated() {
            if char == "L" {
                let isActive = (index < lightStateArray.count && lightStateArray[index] == "1")
                let isDim = (index < cDimArray.count && cDimArray[index] == "1")
                let label = "L \(index + 1)"
                
                print("Index \(index): Label=\(label), isActive=\(isActive), isDim=\(isDim)")
                
                buttonItems.append((label, isActive, isDim))
            }
        }

    }

    func configureAction() {
        print("Configure Button Pressed")

        guard let device = devicestate.first else { return } // Get the updated device
        
        let cDimValue = device.cDim
        let topic = device.uniqueID

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

    
    @objc func showPopupdimming() {
        showPopupPresenter.showPopup1(on: self.view,
                                     animationName: "brightness-2",
                                     title: "Success!",
                                     subtitle: "Dimming Changes Done.")
        
        
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
            showPopupdimming()
            let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
            iotDataManager.publishString(theJSONText!, onTopic: topic + "/HA/A/req", qoS: .messageDeliveryAttemptedAtMostOnce)
        }
    }
   
    

}

extension DimmingViewController : UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return  buttonItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DimmingCollectionViewCell", for: indexPath) as! DimmingCollectionViewCell
       
        
        let buttonData = buttonItems[indexPath.item]
        print("Cell \(indexPath.item): text=\(buttonData.text), isDim=\(buttonData.isDim)")
        cell.configure(imageName: "sun.max", text: buttonData.text, isDim: buttonData.isDim)

      //  cell.backgroundColor = buttonData.isActive ? activeColor : inactiveColor

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard var device = devicestate.first else { return }
        
       
        var cDimArray = Array(device.cDim)

       
        let actualIndex = indexPath.item

    
        if cDimArray.indices.contains(actualIndex) {
            cDimArray[actualIndex] = (cDimArray[actualIndex] == "1") ? "0" : "1"
        }
        
        // Convert back to String
        let updatedCDim = String(cDimArray)
        
        // Create new updated DeviceStateArray
        let updatedDevice = DeviceStateArray(
            uniqueID: device.uniqueID,
            modelNo: device.modelNo,
            deviceNumber: device.deviceNumber,
            cDim: updatedCDim,  // ✅ Updated cDim here
            cNm: device.cNm,
            cL: device.cL,
            cF: device.cF,
            cM: device.cM,
            workingMode: device.workingMode,
            master: device.master,
            ack: device.ack,
            lightState: device.lightState,
            lightSpeed: device.lightSpeed, fanState: device.fanState,
            fanSpeed: device.fanSpeed,
            controlFrom: device.controlFrom, series: device.series, otaStatus: device.otaStatus, rRegulator: device.rRegulator
        )
        
        devicestate[0] = updatedDevice // ✅ Save back
        
        print("Updated cDim: \(updatedCDim)")

        // Also update your buttonItems array
        buttonItems[indexPath.item].isDim.toggle()

        // Reload clicked cell only
        collectionView.reloadItems(at: [indexPath])
    }

    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let numberOfColumns: CGFloat = 3
        let spacing: CGFloat = 25
        let totalSpacing = (numberOfColumns - 1) * spacing
        let itemWidth = (collectionView.frame.width - totalSpacing - 10) / numberOfColumns
        return CGSize(width: itemWidth, height: itemWidth)
    }
    
    
    
}
