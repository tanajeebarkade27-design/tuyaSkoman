//
//  MainTabBarController.swift
//  SkromanIsra
//
//  Created by Admin on 10/04/25.
//

import UIKit
import SwiftKeychainWrapper
import AWSCore
import AWSIoT
import Alamofire
import AppIntents


class MainTabBarController: UITabBarController, UITabBarControllerDelegate {

    private let centerButtonSize: CGFloat = 50
    private let centerButton = UIButton()
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    var deviceList: [String] = []
        var buttonDetails: [ButtonDetails] = []
    var allFetchedDevices: [Device] = []
    var AllreceivedDeviceStates: [DeviceStateArray] = []
    
    weak var latestAllRoomsVC: AllRoomsViewController?
    
    var cachedDevices: [Device] = []
       var cachedReceivedStates: [DeviceStateArray] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cachedDevices.removeAll()
                cachedReceivedStates.removeAll()
        setupTabBarAppearance()
        addCenterButton()
        adjustTabBarItemSpacing()
        addTabBarBackgroundImage()
        
        updateTabBarItems()
        self.delegate = self
        
        print("main tab bar ..")
        if viewControllers?.indices.contains(1) == true,
           let nav = viewControllers?[1] as? UINavigationController,
           let allRoomsVC = nav.viewControllers.first(where: { $0 is AllRoomsViewController }) as? AllRoomsViewController {
            allRoomsVC.delegate = self
        }

       
    }

    private func addBlackBackgroundView() {
        let backgroundView = UIView(frame: tabBar.bounds)
        backgroundView.backgroundColor = UIColor(red: 78/255, green: 92/255, blue: 117/255, alpha: 0.8)
        backgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tabBar.insertSubview(backgroundView, at: 0)
    }

     func updateTabBarItems() {
        guard let viewControllers = self.viewControllers else { return }

        if viewControllers.count >= 5 {
            viewControllers[0].tabBarItem.title = ""
            viewControllers[0].tabBarItem.image = resizedImage(named: "homebtn")
            viewControllers[0].tabBarItem.selectedImage = resizedImage(named: "Hometab")

            viewControllers[1].tabBarItem.title = ""
            viewControllers[1].tabBarItem.image = resizedImage(named: "rooms")
            viewControllers[1].tabBarItem.selectedImage = resizedImage(named: "roomfill")

            viewControllers[2].tabBarItem.isEnabled = false // dummy center

            viewControllers[3].tabBarItem.title = ""
            viewControllers[3].tabBarItem.image = resizedImage(named: "energy")
            viewControllers[3].tabBarItem.selectedImage = resizedImage(named: "enegryfill")

            viewControllers[4].tabBarItem.title = ""
            viewControllers[4].tabBarItem.image = resizedImage(named: "menu")
            viewControllers[4].tabBarItem.selectedImage = resizedImage(named: "menufill")
        }
    }


    private func resizedImage(named name: String, size: CGSize = CGSize(width: 28, height: 28)) -> UIImage? {
        guard let image = UIImage(named: name) else {
            print("❌ Image not found: \(name)")
            return nil
        }

        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: size))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        
        return resized?.withRenderingMode(.alwaysOriginal)
    }



    private func setupTabBarAppearance() {
        tabBar.barTintColor = .gray
        tabBar.tintColor = .white
        tabBar.unselectedItemTintColor = .gray
        tabBar.isTranslucent = false
    }
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
           print("🔄 Tab switched to index: \(selectedIndex) → clearing old button data")

           // ✅ Clear previous data from both VCs
           if let nav0 = viewControllers?[0] as? UINavigationController,
              let homeVC = nav0.viewControllers.first(where: { $0 is MainHomeViewController }) as? MainHomeViewController {
               homeVC.devices.removeAll()
               homeVC.receivedDeviceStates.removeAll()
           }
           
           if let nav1 = viewControllers?[1] as? UINavigationController,
              let allRoomsVC = nav1.viewControllers.first(where: { $0 is AllRoomsViewController }) as? AllRoomsViewController {
               allRoomsVC.allFetchedDevices.removeAll()
               allRoomsVC.receivedDeviceStates.removeAll()
           }
       }

    private func addCenterButton() {
        let tabBarWidth = tabBar.bounds.width

        centerButton.frame = CGRect(
            x: (tabBarWidth / 2) - (centerButtonSize / 2),
            y: -12, // lift it above the tab bar
            width: centerButtonSize,
            height: centerButtonSize
        )

        centerButton.backgroundColor = .clear
        centerButton.layer.cornerRadius = centerButtonSize / 2
        centerButton.layer.masksToBounds = true   // 🔑 Clips image to circle
        centerButton.layer.shadowColor = UIColor.black.cgColor
        centerButton.layer.shadowOpacity = 0.2
        centerButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        centerButton.layer.shadowRadius = 4

        if let customImage = UIImage(named: "masterOff") {
            let circularImage = customImage.circularImage(size: CGSize(width: centerButtonSize, height: centerButtonSize))
            centerButton.setImage(circularImage, for: .normal)
        } else {
            print("Image named 'Group 2-3' not found. Using default.")
            let defaultImage = UIImage(systemName: "arrow.clockwise")
            centerButton.setImage(defaultImage, for: .normal)
        }

        centerButton.tintColor = .white
        centerButton.imageView?.contentMode = .scaleAspectFill  // 🔑 Fill circle properly

        centerButton.addTarget(self, action: #selector(centerButtonTapped), for: .touchUpInside)

        tabBar.addSubview(centerButton)
        tabBar.bringSubviewToFront(centerButton)
    }

    private func updateCenterButtonImage(forMasterState state: Int) {
        let imageName: String
        
        if state == 1 {
          print ("master on room")
            imageName = "masterOn"
        } else {
            print ("master on room")
            imageName = "masterOff"  // 👉 replace with your actual image name
        }
        
        if let customImage = UIImage(named: imageName) {
            let circularImage = customImage.circularImage(size: CGSize(width: centerButtonSize, height: centerButtonSize))
            centerButton.setImage(circularImage, for: .normal)
        } else {
            print("⚠️ Image named '\(imageName)' not found, using default.")
            centerButton.setImage(UIImage(systemName: "arrow.clockwise"), for: .normal)
        }
    }

    
    
    private func addTabBarBackgroundImage() {
        if let bgImage = UIImage(named: "tabBarbackground") {
            let imageView = UIImageView(frame: tabBar.bounds)
            imageView.image = bgImage
            imageView.contentMode = .scaleAspectFill  // adjust to your desired fill mode
            imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

            // Insert below everything in the tab bar
            tabBar.insertSubview(imageView, at: 0)
        } else {
            print("tabBarbackground image not found")
        }
    }

    
    
   
    

    @objc private func centerButtonTapped() {

        let currentTab = selectedIndex

        // ✅ HOME TAB
        if currentTab == 0 {

            if let nav = viewControllers?[0] as? UINavigationController,
               let homeVC = nav.viewControllers.first(where: { $0 is MainHomeViewController }) as? MainHomeViewController {

                let devices = homeVC.devices
                print("📦 Devices from HomeVC: \(devices)")

                homeVC.handleCenterButtonAction(devices: devices)
            }
        }

        // ✅ ROOMS TAB
        else if currentTab == 1 {

            // First prefer latest pushed AllRoomsVC
            if let allRoomsVC = latestAllRoomsVC {

                let devices = allRoomsVC.allFetchedDevices
                print("📦 Devices from latestAllRoomsVC: \(devices)")

                allRoomsVC.handleCenterButtonAction(devices: devices)
                return
            }

            // Otherwise use root Rooms VC
            if let nav = viewControllers?[1] as? UINavigationController,
               let allRoomsVC = nav.viewControllers.last as? AllRoomsViewController {

                let devices = allRoomsVC.allFetchedDevices
                print("📦 Devices from Rooms tab instance: \(devices)")

                allRoomsVC.handleCenterButtonAction(devices: devices)
            }
        }
    }
  

   
    
    func publish_button_to_topic(control: String, no: Int, state: Int, speed: Int, topic: String) {
        let parameters: Parameters = [
            "control": control,
            "no": no,
            "state": state,
            "speed": speed,
            "from": "A",
            "topic": topic
        ]

        print("📤 Publishing to \(topic)/HA/A/req: \(parameters)")

        if let jsonData = try? JSONSerialization.data(withJSONObject: parameters, options: []),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            
            let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
            iotDataManager.publishString(jsonString, onTopic: topic + "/HA/A/req", qoS: .messageDeliveryAttemptedAtMostOnce)
        }
       
    }
    

   
    private func adjustTabBarItemSpacing() {
        let tabBarButtons = tabBar.subviews.filter {
            NSStringFromClass(type(of: $0)).contains("UITabBarButton")
        }.sorted { $0.frame.origin.x < $1.frame.origin.x }

        // Determine the spacing
        let totalWidth = tabBar.bounds.width
        let numberOfItems = CGFloat(tabBarButtons.count + 1)
        let itemWidth = totalWidth / numberOfItems
     // Determine center gap index (where the center button will be)
        let centerGapIndex = Int(tabBarButtons.count / 2)

        for (index, button) in tabBarButtons.enumerated() {
            var frame = button.frame
            var xPosition: CGFloat = 0

            if index < centerGapIndex {
                xPosition = itemWidth * CGFloat(index)
            } else {
                // Skip the center gap
                xPosition = itemWidth * CGFloat(index + 1)
            }

            frame.origin.x = xPosition + 5  // slight offset for padding
            frame.size.width = itemWidth - 10 // add side padding
            button.frame = frame
        }
    }
    
    private func showActivityIndicator() {
        activityIndicator.center = view.center
        activityIndicator.color = .white
        activityIndicator.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        activityIndicator.layer.cornerRadius = 10
        activityIndicator.frame.size = CGSize(width: 80, height: 80)
        activityIndicator.hidesWhenStopped = true
        
        view.addSubview(activityIndicator)
        activityIndicator.startAnimating()
    }

    private func hideActivityIndicator() {
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
            self.activityIndicator.removeFromSuperview()
        }
    }


}


extension MainTabBarController {
    
    


  

    private func reloadCurrentView() {
        // Reload the entire view
        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()
        
        // If you want to reload child view controllers (like the currently selected tab):
        if let selectedVC = self.selectedViewController as? UINavigationController {
            if let visibleVC = selectedVC.visibleViewController {
                visibleVC.viewWillAppear(true)
                visibleVC.viewDidAppear(true)
            }
        } else if let selectedVC = self.selectedViewController {
            selectedVC.viewWillAppear(true)
            selectedVC.viewDidAppear(true)
        }
    }


}



extension Notification.Name {
    static let centerButtonTappedNotification = Notification.Name("centerButtonTappedNotification")
}
extension UIImage {
    func circularImage(size: CGSize) -> UIImage {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        UIBezierPath(ovalIn: rect).addClip()
        self.draw(in: rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image ?? self
    }
}
extension MainTabBarController: AllRoomsDelegate {
    func didChangeMasterState(to state: Int) {
        DispatchQueue.main.async { [weak self] in
            self?.updateCenterButtonImage(forMasterState: state)
        }
    }
}
 
extension MainTabBarController: HomeMasterDelegate {
    func didChangehomeMasterState(to state: Int) {
        DispatchQueue.main.async { [weak self] in
            self?.updateCenterButtonImage(forMasterState: state)
        }
    }
}








