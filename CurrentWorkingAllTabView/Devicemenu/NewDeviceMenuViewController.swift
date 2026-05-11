//
//  NewDeviceMenuViewController.swift
//  SkromanIsra
//
//  Created by Admin on 25/07/25.
//

import UIKit
import Alamofire
class NewDeviceMenuViewController: UIViewController {
    var selectedDevice: Device?
    var filteredButtonDetails: [ButtonDetails] = []
    var receivedDeviceStates: [DeviceStateArray] = []
    var deviceScenes: [DeviceScene] = []
    var isDeviceCatgery : String?
    var uniqueId : String?
    
    
    
    @IBOutlet weak var backgroundimage: UIImageView!
    
    @IBOutlet weak var deleteDeviceButton: UIButton!
    
    @IBOutlet weak var menuCollectionView: UICollectionView!
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
        
        registerXib()
        self.hidesBottomBarWhenPushed = true
        print("  selected device \(selectedDevice)")
       print(" selected filteredButtonDetails \(filteredButtonDetails)")
        print("  selected receivedDeviceStates \(receivedDeviceStates)")
        
        isDeviceCatgery = selectedDevice?.deviceCategory
       
       if isDeviceCatgery != "skroman_new" {
           if let index = menuOptions.firstIndex(of: "System Reset") {
               menuOptions.remove(at: index)
               menuImages.remove(at: index)
           }
       }
        
        if let image = UIImage(named: "delete")?.resized(to: CGSize(width: 30, height: 30)) {
            deleteDeviceButton.setImage(image, for: .normal)
        }
        uniqueId = selectedDevice?.uniqueId
        fetchSceneByUniqueid(uniqueId: uniqueId ?? "")
        isDeviceCatgery = selectedDevice?.deviceCategory
        if selectedDevice?.deviceType == "manualBox" {

            let itemsToRemove = [
                "Special Buttons",
                "Child lock",
                "Shuffle",
                "Dimming",
                "Scenes",
                "Schedule & Timers",
                "Colors & Theams",
                "Repilca"
            ]

            
            menuOptions.removeAll { itemsToRemove.contains($0) }

            // remove from menuImages (same titles used for image names)
            menuImages.removeAll { itemsToRemove.contains($0) }
            
            print("Updated menuOptions for manualBox:", menuOptions)
        }
        let isHumanDevice =
            selectedDevice?.uniqueId.uppercased().contains("RADAR") == true
        if isHumanDevice {

            print("🚨 Human Detection Device → Show only WiFi option")

            menuOptions = ["Wi-Fi   Provision"]
            menuImages = ["Wi-Fi   Provision"]
        }

    }

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }

    
    
    @IBAction func backbutton(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }

    
    
    var menuOptions: [String] = ["Wi-Fi   Provision", "Special Buttons", "Shuffle","Dimming","Scenes","Schedule & Timers", "Colors & Theams","Repilca", "Firmware Update",   "System   Reset"]
    
    
    var menuImages: [String]  = [ "Wi-Fi   Provision", "Special Buttons","Shuffle","Dimming","Scenes","Schedule & Timers", "Colors & Theams","Repilca", "Firmware Update",   "System Reset"]
    
    
    
   

    func registerXib() {
        let nib = UINib(nibName: "NewDeviceMenuCollectionViewCell", bundle: nil)
        menuCollectionView.register(nib, forCellWithReuseIdentifier: "NewDeviceMenuCollectionViewCell")
        menuCollectionView.dataSource =  self
        menuCollectionView.delegate =  self
    }
    
    @IBAction func deleteDeviceButton(_ sender: Any) {
        let alert = UIAlertController(
            title: "Delete Device",
            message: "Are you sure you want to delete this device?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        alert.addAction(UIAlertAction(title: "OK", style: .destructive, handler: { _ in
            self.deleteDevice()
        }))
        
        present(alert, animated: true, completion: nil)
    }

    
    
    func deleteDevice() {
        guard let deviceUid = selectedDevice?.deviceUid else { return }

        let parameters: [String: Any] = [
            "deviceUid": deviceUid
        ]

        let url = "http://3.7.18.55:3000/skroman/deviceapi/devicedelete/deviceUid"

        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default)
            .validate(statusCode: 200..<300)
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    if let json = value as? [String: Any],
                       let message = json["msg"] as? String {
                        
                        print("✅ Response: \(message)")
                        
                        if message == "device delete successully" {

                            print("✅ Device deleted.")

                            if let uniqueId = self.selectedDevice?.uniqueId {
                                SkromanIsraDatabaseHelper.shared.deleteDevice(uniqueId: uniqueId)
                            }

                            NotificationCenter.default.post(name: NSNotification.Name("DeviceDeleted"), object: nil)

                            self.showPopupdelete()

                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                self.navigationController?.popViewController(animated: true)
                            }
                        }
                        else {
                            print("⚠️ Unexpected message: \(message)")
                        }
                    } else {
                        print("⚠️ Unable to parse JSON")
                    }

                case .failure(let error):
                    print("❌ Request failed: \(error.localizedDescription)")
                }
            }
    }
    @objc func showPopupdelete() {
        showPopupPresenter.showPopup1(
            on: self.view,
            animationName: "delete 2",
            title: "Deleted!",
            subtitle: "Device was deleted successfully."
        )
    }

    
    
    
    func fetchSceneByUniqueid(uniqueId: String) {
        print("🔍 Fetching scenes for uniqueId = \(uniqueId)")
        let selectedDevicesecne = SkromanIsraDatabaseHelper.shared.fetchScenesByUniqueId(uniqueId: uniqueId)
        print("📦 Fetched scenes = \(selectedDevicesecne)")
    }

}

extension NewDeviceMenuViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return menuOptions.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NewDeviceMenuCollectionViewCell", for: indexPath) as! NewDeviceMenuCollectionViewCell
        
        let title = menuOptions[indexPath.item]
        let menuImage = menuImages[indexPath.item]
        cell.menulabel.text = title
        cell.menuImage.image = UIImage(named: menuImage)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let padding: CGFloat = 8  // Total padding between cells
        let numberOfItemsPerRow: CGFloat = 2

        let totalSpacing = padding * (numberOfItemsPerRow + 1)
        let availableWidth = collectionView.frame.width - totalSpacing
        let width = availableWidth / numberOfItemsPerRow

        return CGSize(width: width, height: 90)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedOption = menuOptions[indexPath.item]

        switch selectedOption {
       
           

        case "Wi-Fi   Provision":
            print("Navigate to Wi-Fi Provision screen")
          
                    let device_type_vc : DeviceTypeViewController = self.storyboard?.instantiateViewController(withIdentifier: "deviceTypeVC") as! DeviceTypeViewController
                device_type_vc.prov_flag = false
            device_type_vc.selectedDevice =  self.selectedDevice
            device_type_vc.uniqueId =  self.selectedDevice?.uniqueId
            device_type_vc.devicePop = self.selectedDevice?.POP
            
                    self.navigationController?.pushViewController(device_type_vc, animated: true)

        case "Special Buttons":
            print("Navigate to Special Buttons screen")
            let vc = storyboard?.instantiateViewController(withIdentifier: "SpecialButtonViewController") as! SpecialButtonViewController
            vc.selectedDevice = self.selectedDevice
            
            if let selectedId = self.selectedDevice?.uniqueId {
                let filteredStates = self.receivedDeviceStates.filter { $0.uniqueID == selectedId }
                vc.devicestate = filteredStates
                print("✅ Passing filtered devicestate: \(filteredStates)")
            } else {
                vc.devicestate = []
                print("⚠️ No selected device ID found, devicestate cleared")
            }
            print("📤 Passing devicestate: \(self.receivedDeviceStates)")
            navigationController?.pushViewController(vc, animated: true)

        case "Child lock":
            print("Navigate to Child Lock screen")
            let vc = storyboard?.instantiateViewController(withIdentifier: "ChildLockViewController") as! ChildLockViewController
            
            
            if let selectedId = self.selectedDevice?.uniqueId {
                let filteredStates = self.receivedDeviceStates.filter { $0.uniqueID == selectedId }
                vc.devicestate = filteredStates
                print("✅ Passing filtered devicestate to ChildLockViewController: \(filteredStates)")
            } else {
                vc.devicestate = []
                print("⚠️ No selected device ID found — devicestate cleared for Child Lock")
            }

            navigationController?.pushViewController(vc, animated: true)

        case "Shuffle":
            print("Navigate to Shuffle screen")
            let vc = storyboard?.instantiateViewController(withIdentifier: "ShuffleViewController") as! ShuffleViewController

            vc.selectedDevice = self.selectedDevice
            vc.deviceScene = self.deviceScenes

          
            if let selectedId = self.selectedDevice?.uniqueId {
                let filteredStates = self.receivedDeviceStates.filter { $0.uniqueID == selectedId }
                vc.devicestate = filteredStates
                print("✅ Passing filtered devicestate to ShuffleViewController: \(filteredStates)")
            } else {
                vc.devicestate = []
                print("⚠️ No selected device ID found — devicestate cleared for Shuffle")
            }

            navigationController?.pushViewController(vc, animated: true)


        case "Dimming":
            print("Navigate to Dimming screen")
            
            let vc = storyboard?.instantiateViewController(withIdentifier: "DimmingViewController") as! DimmingViewController
            
            vc.selectedDevice = self.selectedDevice
            vc.filteredButtonDetails = self.filteredButtonDetails
            
            // ✅ Filter only the deviceState matching this selected device
            if let selectedId = self.selectedDevice?.uniqueId {
                let filteredStates = self.receivedDeviceStates.filter { $0.uniqueID == selectedId }
                vc.devicestate = filteredStates
                print("✅ Passing filtered devicestate: \(filteredStates)")
            } else {
                vc.devicestate = []
                print("⚠️ No selected device ID found, devicestate cleared")
            }

            navigationController?.pushViewController(vc, animated: true)


        case "Scenes":
            print("Navigate to Scenes screen")
                    let vc = storyboard?.instantiateViewController(withIdentifier: "SceneViewController")  as! SceneViewController
            
            vc.selectedDevice =  self.selectedDevice
            vc.devicestate =  self.receivedDeviceStates
            vc.deviceScene =  self.deviceScenes
            
                    navigationController?.pushViewController(vc, animated: true)

        case "Schedule & Timers":
            print("Navigate to Schedule & Timers screen")
                    let vc = storyboard?.instantiateViewController(withIdentifier: "ScheduleViewController")  as!
                    ScheduleViewController
            vc.selectedDevice =  self.selectedDevice
           
            vc.deviceScene =  self.deviceScenes
            vc.deviceUid = self.selectedDevice?.deviceUid
            // ✅ Filter only the deviceState matching this selected device
            if let selectedId = self.selectedDevice?.uniqueId {
                let filteredStates = self.receivedDeviceStates.filter { $0.uniqueID == selectedId }
                vc.devicestate = filteredStates
                print("✅ Passing filtered devicestate: \(filteredStates)")
            } else {
                vc.devicestate = []
                print("⚠️ No selected device ID found, devicestate cleared")
            }
            
            
                    navigationController?.pushViewController(vc, animated: true)
        case "Colors & Theams":
            print("Navigate to Colors & Themes screen")
          
                    if isDeviceCatgery == "skroman_new"{
                        let vc = storyboard?.instantiateViewController(withIdentifier: "NewBoardBrightnessViewController")  as!
                        NewBoardBrightnessViewController
            
                        // ✅ Filter only the deviceState matching this selected device
                        if let selectedId = self.selectedDevice?.uniqueId {
                            let filteredStates = self.receivedDeviceStates.filter { $0.uniqueID == selectedId }
                            vc.devicestate = filteredStates
                            print("✅ Passing filtered devicestate: \(filteredStates)")
                        } else {
                            vc.devicestate = []
                            print("⚠️ No selected device ID found, devicestate cleared")
                        }
                        vc.selectedDevice =  self.selectedDevice
                        navigationController?.pushViewController(vc, animated: true)
                    } else {
                        
                        let vc = storyboard?.instantiateViewController(withIdentifier: "OldDevBrightnessViewController")  as!
                        OldDevBrightnessViewController
                        
                        // ✅ Filter only the deviceState matching this selected device
                        if let selectedId = self.selectedDevice?.uniqueId {
                            let filteredStates = self.receivedDeviceStates.filter { $0.uniqueID == selectedId }
                            vc.devicestate = filteredStates
                            print("✅ Passing filtered devicestate: \(filteredStates)")
                        } else {
                            vc.devicestate = []
                            print("⚠️ No selected device ID found, devicestate cleared")
                        }
                        vc.selectedDevice =  self.selectedDevice
                        navigationController?.pushViewController(vc, animated: true)
                    }

        case "Repilca":
            print("Navigate to Replica screen")
                    let vc = storyboard?.instantiateViewController(withIdentifier: "RepilcaViewController")  as! RepilcaViewController
                  
            vc.selectedDevice =  self.selectedDevice
            // ✅ Filter only the deviceState matching this selected device
            if let selectedId = self.selectedDevice?.uniqueId {
                let filteredStates = self.receivedDeviceStates.filter { $0.uniqueID == selectedId }
                vc.devicestate = filteredStates
                print("✅ Passing filtered devicestate: \(filteredStates)")
            } else {
                vc.devicestate = []
                print("⚠️ No selected device ID found, devicestate cleared")
            }
            
                    navigationController?.pushViewController(vc, animated: true)
        
        case "Firmware Update":
       
               let vc = storyboard?.instantiateViewController(withIdentifier: "FirmwareViewController")  as! FirmwareViewController
              
            vc.selectedDevice =  self.selectedDevice
         
       
               navigationController?.pushViewController(vc, animated: true)

        case "Offline BLE":
            print("Navigate to Offline BLE screen")
            // navigateToOfflineBLE()

        case "System   Reset":
            print("Perform system reset confirmation")
                    let vc = storyboard?.instantiateViewController(withIdentifier: "SystemResetViewController")  as! SystemResetViewController
            vc.devicestate =  self.receivedDeviceStates
                   vc.selectedDevice =  self.selectedDevice
            
            
        navigationController?.pushViewController(vc, animated: true)

        default:
            print("Unknown option selected")
        }
    }

    
}



