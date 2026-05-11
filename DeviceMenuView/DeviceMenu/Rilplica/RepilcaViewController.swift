//
//  RepilcaViewController.swift
//  SkromanIsra
//
//  Created by Admin on 14/02/25.
//

import UIKit
import AWSCore
import AWSIoT
import Alamofire

class RepilcaViewController: UIViewController {
    @IBOutlet weak var replicaButton: UIButton!
    
    @IBOutlet weak var nonReplicaButton: UIButton!
    
    @IBOutlet weak var replicaView: UIView!
    @IBOutlet weak var configureButton: UIButton!
    @IBOutlet weak var closedButton: UIButton!
    
    
    @IBOutlet weak var backgroundimage: UIImageView!
    
    
    var selectedDevice: Device?
    
    var devicestate: [DeviceStateArray] = []
    var deviceVc : DeviceViewController?
    var devices: [Device] = []
 
    var buttonItems: [String] = []
    var deviceScene: [DeviceScene] = []
    var selectedWorkingMode: String?
    var deviceUinqueId  : String?
    override func viewDidLoad() {
        super.viewDidLoad()
        nonReplicaButton.setTitle("", for: .normal)
        replicaButton.setTitle("", for: .normal)
        closedButton.setTitle("", for: .normal)
        closedButton.setTitleColor(.black, for: .normal) // Set text color
        replicaView.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        replicaView.cornerRadius = 10
        if let image = UIImage(named: "close")?.resized(to: CGSize(width: 30, height: 30)) {
            closedButton.setImage(image, for: .normal)
            
            let buttons: [UIButton] = [ configureButton]
            for button in buttons {
                button.backgroundColor = .white
                button.setTitleColor(.black, for: .normal)
                button.layer.cornerRadius = 20
                button.layer.masksToBounds = true
            }
        }
        backgroundimage.contentMode = .scaleAspectFill
        backgroundimage.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            backgroundimage.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundimage.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundimage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundimage.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        
//        replicaView.layer.cornerRadius = 8
//        replicaView.borderColor = .gray
//        replicaView.borderWidth = 1
     
        
        print("devicestate at rep\(devicestate)")
        print("devices at rep\(devices)")
        
      
        if let device = devicestate.first {
               let imageSize = CGSize(width: 30, height: 30)
               if device.workingMode == "non_replica" {
                   nonReplicaButton.setImage(resizeImage(named: "check", size: imageSize), for: .normal)
                   replicaButton.setImage(nil, for: .normal)
               } else if device.workingMode == "replica" {
                   replicaButton.setImage(resizeImage(named: "check", size: imageSize), for: .normal)
                   nonReplicaButton.setImage(nil, for: .normal)
               }
           }
        
        
        
        if let firstScene = devices.first {
            deviceUinqueId = firstScene.uniqueId
        } else {
            deviceUinqueId = nil // Fallback if no scenes exist
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
    func resizeImage(named imageName: String, size: CGSize) -> UIImage? {
        guard let image = UIImage(named: imageName) else { return nil }
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage
    }
    
   
    
    func updateButtonImages() {
        let imageSize = CGSize(width: 24, height: 24)
        let checkImage = UIImage(named: "check")?.resized(to: imageSize) // Selected state
        let unselectImage = UIImage(named: "uncheck")?.resized(to: imageSize) // Deselected state

        if selectedWorkingMode == "non_replica" {
            nonReplicaButton.setImage(checkImage, for: .normal)
            replicaButton.setImage(unselectImage, for: .normal)
        } else if selectedWorkingMode == "replica" {
            replicaButton.setImage(checkImage, for: .normal)
            nonReplicaButton.setImage(unselectImage, for: .normal)
        } else {
          
            nonReplicaButton.setImage(unselectImage, for: .normal)
            replicaButton.setImage(unselectImage, for: .normal)
        }
    }



    @IBAction func closedButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
        
    }
    
    
    @IBAction func nonRplicaButton(_ sender: Any) {
        if selectedWorkingMode == "non_replica" {
               selectedWorkingMode = nil // Deselect if already selected
           } else {
               selectedWorkingMode = "non_replica"
           }
           updateButtonImages()
        
    }
    
    @IBAction func replicaButton(_ sender: Any) {
        if selectedWorkingMode == "replica" {
               selectedWorkingMode = nil // Deselect if already selected
           } else {
               selectedWorkingMode = "replica"
           }
           updateButtonImages()
    }
    
    
    @IBAction func configureButton(_ sender: Any) {
        if selectedWorkingMode == "replica" {
            replica_config(mode: "replica")
        } else if selectedWorkingMode == "non_replica" {
            replica_config(mode: "non_replica")
        } else {
            print("No working mode selected!")
        }
    }

    
    @objc func showPopupScene() {
        
        showPopupPresenter.showPopup1(on: self.view,
                                     animationName: "replica",
                                     title: "Success!",
                                     subtitle: "Replica Selection Sucessfully Done!")
        
       
    }
    
    
    
    func replica_config(mode: String) {
        guard let topic = selectedDevice?.uniqueId  else {
            print("Error: PUB_TOPIC_ is nil. Cannot subscribe to MQTT topic.")
            return
        }
        
        let replica_params : Parameters = [
            
            
            "control":"work_mode",
            "mode": mode,
            "from": "A",
            "topic": topic
            
        ]
        
        
        if let theJSONData = try? JSONSerialization.data(withJSONObject: replica_params,options: []) {
            
            let theJSONText = String(data: theJSONData,
                                     encoding: .ascii)
            print("JSON string = \(theJSONText!)")
            showPopupScene()
            
            let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
            
            let iot_sample_vc = Iot_sample_ViewController()
            
            iotDataManager.publishString(theJSONText!, onTopic: topic + "/HA/A/req", qoS:.messageDeliveryAttemptedAtMostOnce)
            
            
        }
        
        
    }
    
    
    
}
extension UIImage {
    func resized(to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        draw(in: CGRect(origin: .zero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage
    }
}
