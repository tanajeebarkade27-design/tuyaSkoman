//
//  DeviceMenuViewController.swift
//  SkromanIsra
//
//  Created by Admin on 13/02/25.
//

import UIKit


class DeviceMenuViewController: UIViewController {

    @IBOutlet var deviceMenuBackgroundView: UIView!
    
    @IBOutlet weak var menuCollectionView: UICollectionView!
    
    @IBOutlet weak var backgroundLogo: UIImageView!
    var devicestate: [DeviceStateArray] = []
    var deviceVc : DeviceViewController?
    var buttonItems: [String] = []
    var devices: [Device] = []
    var selectedDevice: Device?
    var deviceScene: [DeviceScene] = []
    var isDeviceCatgery : String?
    var selectedUniqueId : String?
    var selecetdDevicePOP: String?
    
    
    var menuOptions: [String] = [ "Edit Device", "Wi-Fi Provision", "Special Buttons", "Child lock","Shuffle","Dimming","Scenes","Schedule & Timers", "Colors & Theams","Repilca", "Firmware Update", "Offline BLE", "System Reset"]
    
    var menuIcons: [String] = [ "edit", "Wi-Fi Provision", "Specailbutton", "Child Lock","Shuffle","Dimming","Scenes","Schedule & Timers", "Colors & Themes","Repilca", "firmware", "ble", "System Reset"]
    @IBOutlet weak var backButton: UIButton!
    
    
    var menuIcon:[String] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        
        registerXib()
        menuCollectionView.dataSource = self
        menuCollectionView.delegate = self
        applyGradientBackground()
        setupWatermarkLogo()
        print("device at..\(devicestate)")
        print("button Items at menu\(buttonItems)")
        print("devices at menu//\(selecetdDevicePOP)")
        
        print("device at....\(devices)")
        
       
        if isDeviceCatgery != "skroman_new" {
            if let index = menuOptions.firstIndex(of: "System Reset") {
                menuOptions.remove(at: index)
                menuIcons.remove(at: index)
            }
        }
    }
  
    
   
    @IBAction func backButton(_ sender: Any) {
        
        navigationController?.popViewController(animated: true)
    }
    
    func registerXib(){
        let uinib =  UINib(nibName: "DeviceMenuCollectionViewCell", bundle: nil)
        menuCollectionView.register(uinib, forCellWithReuseIdentifier: "DeviceMenuCollectionViewCell")
    }
    
    
    
    func applyGradientBackground() {
        let mainScreen = CAGradientLayer()
        mainScreen.frame = deviceMenuBackgroundView.bounds

        mainScreen.colors = [
            UIColor(red: 163/255, green: 159/255, blue: 98/255, alpha: 1).cgColor,   // Gold
            UIColor(red: 141/255, green: 176/255, blue: 144/255, alpha: 1).cgColor,  // Green
            UIColor(red: 104/255, green: 155/255, blue: 181/255, alpha: 1).cgColor   // Blue
        ]

        mainScreen.locations = [0.0, 0.3, 0.8]  // Expands green & blue areas
        mainScreen.startPoint = CGPoint(x: 0.5, y: 0)   // Top center
        mainScreen.endPoint = CGPoint(x: 0.5, y: 1)     // Bottom center

     
        deviceMenuBackgroundView.layer.sublayers?.removeAll(where: { $0 is CAGradientLayer })
        
        deviceMenuBackgroundView.layer.insertSublayer(mainScreen, at: 0)
    }
    
    func setupWatermarkLogo() {
        if backgroundLogo == nil {
            backgroundLogo = UIImageView(image: UIImage(named: "watermark_logo"))
            backgroundLogo.contentMode = .scaleAspectFit
            backgroundLogo.translatesAutoresizingMaskIntoConstraints = false
            deviceMenuBackgroundView.addSubview(backgroundLogo)
        }
        
        backgroundLogo.alpha = 0.3  // Reducing intensity by 70%

        // Ensure the watermark logo is centered
        NSLayoutConstraint.activate([
            backgroundLogo.centerXAnchor.constraint(equalTo: deviceMenuBackgroundView.centerXAnchor),
            backgroundLogo.centerYAnchor.constraint(equalTo: deviceMenuBackgroundView.centerYAnchor),
            backgroundLogo.widthAnchor.constraint(equalTo: deviceMenuBackgroundView.widthAnchor, multiplier: 0.5),
            backgroundLogo.heightAnchor.constraint(equalTo: backgroundLogo.widthAnchor)
        ])
        
        deviceMenuBackgroundView.sendSubviewToBack(backgroundLogo) // Send to back to avoid UI overlap
    }


}




extension DeviceMenuViewController : UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return menuOptions.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DeviceMenuCollectionViewCell", for: indexPath) as! DeviceMenuCollectionViewCell
        cell.menuOptionLabel.text = menuOptions[indexPath.item]
        let imageName = menuIcons[indexPath.item]
        cell.menuImageView.image = UIImage(named: imageName)
        return cell
    }

    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {

        let numberOfColumns: CGFloat = 2
        let spacing: CGFloat = 20
        let totalSpacing = (numberOfColumns - 1) * spacing

        let itemWidth = (collectionView.frame.width - totalSpacing - 10) / numberOfColumns

        let itemHeight = itemWidth * 0.75

        return CGSize(width: itemWidth, height: itemHeight)
    }


    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedOption = menuOptions[indexPath.item]

        switch selectedOption {
        case "Edit Device":
            let vc = storyboard?.instantiateViewController(withIdentifier: "EditDeviceViewController")  as! EditDeviceViewController
            vc.devicestate =  self.devicestate
            vc.devices =  self.devices
            
            navigationController?.pushViewController(vc, animated: true)

        case "Wi-Fi Provision":
            let device_type_vc : DeviceTypeViewController = self.storyboard?.instantiateViewController(withIdentifier: "deviceTypeVC") as! DeviceTypeViewController
            device_type_vc.prov_flag = false
            device_type_vc.devices =  self.devices
            device_type_vc.uniqueId =  self.selectedUniqueId
            device_type_vc.devicePop = self.selecetdDevicePOP
            
            self.navigationController?.pushViewController(device_type_vc, animated: true)

        case "Special Buttons":
            let vc = storyboard?.instantiateViewController(withIdentifier: "SpecialButtonViewController")  as! SpecialButtonViewController
            
            vc.devicestate =  self.devicestate
            vc.devices =  self.devices
            navigationController?.pushViewController(vc, animated: true)
        case "Child lock":
            let vc = storyboard?.instantiateViewController(withIdentifier: "ChildLockViewController")  as! ChildLockViewController
           vc.devicestate = self.devicestate
          
            
            navigationController?.pushViewController(vc, animated: true)
//
        case "Shuffle":
            let vc = storyboard?.instantiateViewController(withIdentifier: "ShuffleViewController")  as! ShuffleViewController
            vc.devicestate =  self.devicestate
            vc.devices =  self.devices
            vc.deviceScene =  self.deviceScene
          
            navigationController?.pushViewController(vc, animated: true)

        case "Dimming":
            let vc = storyboard?.instantiateViewController(withIdentifier: "DimmingViewController")  as! DimmingViewController
            vc.devicestate =  self.devicestate
            vc.devices =  self.devices
            
            navigationController?.pushViewController(vc, animated: true)
//            let popupVC = DimmingPopupViewController()
//            popupVC.modalPresentationStyle = .overFullScreen
//            popupVC.modalTransitionStyle = .crossDissolve
//            
//
//
//
//            popupVC.devicestate = self.devicestate 
//            popupVC.devices =  self.devices

         //   present(popupVC, animated: true)

        case "Scenes":
            let vc = storyboard?.instantiateViewController(withIdentifier: "SceneViewController")  as! SceneViewController
            vc.devicestate =  self.devicestate
            vc.devices =  self.devices
            vc.deviceScene =  self.deviceScene
          
            navigationController?.pushViewController(vc, animated: true)

        case "Schedule & Timers":
            let vc = storyboard?.instantiateViewController(withIdentifier: "ScheduleViewController")  as!
            ScheduleViewController
            vc.buttonItems =  self.buttonItems
            vc.devicestate =  self.devicestate
            vc.devices =  self.devices
            vc.deviceScene =  self.deviceScene
          
            navigationController?.pushViewController(vc, animated: true)
            
        case "Colors & Theams":
            
            if isDeviceCatgery == "skroman_new"{
                let vc = storyboard?.instantiateViewController(withIdentifier: "NewBoardBrightnessViewController")  as!
                NewBoardBrightnessViewController
                
                vc.devicestate =  self.devicestate
                vc.devices =  self.devices
                navigationController?.pushViewController(vc, animated: true)
            } else {
                
                let vc = storyboard?.instantiateViewController(withIdentifier: "OldDevBrightnessViewController")  as!
                OldDevBrightnessViewController
                
                vc.devicestate =  self.devicestate
                vc.devices =  self.devices
                navigationController?.pushViewController(vc, animated: true)
                
            }

        case "Repilca":
         
            
            let vc = storyboard?.instantiateViewController(withIdentifier: "RepilcaViewController")  as! RepilcaViewController
            vc.devicestate =  self.devicestate
            vc.devices =  self.devices
            vc.deviceScene =  self.deviceScene
          
            navigationController?.pushViewController(vc, animated: true)
//
        case "Firmware Update":
            
            let vc = storyboard?.instantiateViewController(withIdentifier: "FirmwareViewController")  as! FirmwareViewController
            vc.devicestate =  self.devicestate
            vc.devices =  self.devices
           
          
            navigationController?.pushViewController(vc, animated: true)
//
//        case "Offline BLE":
//            let vc = OfflineBLEViewController() // Replace with actual ViewController
//            navigationController?.pushViewController(vc, animated: true)
//
      case "System Reset":
            
            let vc = storyboard?.instantiateViewController(withIdentifier: "SystemResetViewController")  as! SystemResetViewController
            vc.devicestate =  self.devicestate
            vc.devices =  self.devices
           
          
            navigationController?.pushViewController(vc, animated: true)

        default:
            print("No ViewController assigned for \(selectedOption)")
        }
    }

    }


