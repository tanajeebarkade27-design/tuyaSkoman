//
//  FirmWareViewController.swift
//  SkromanIsra
//
//  Created by Admin on 14/02/25.
//


import UIKit
import AWSCore
import AWSIoT
import Alamofire


class SystemResetViewController: UIViewController {

    @IBOutlet weak var firmwareview: UIView!
    
    @IBOutlet weak var closedButton: UIButton!
    
    @IBOutlet weak var restartButton: UIButton!
    
    @IBOutlet weak var resetButton: UIButton!
    
    @IBOutlet var backgroundView: UIView!
    
    
    
    @IBOutlet weak var backgroundimage: UIImageView!
    var devicestate: [DeviceStateArray] = []
    var deviceVc : DeviceViewController?
    var devices: [Device] = []
  var selectedDevice: Device?
    var deviceUinqueId : String?
    
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
        
        if let image = UIImage(named: "close")?.resized(to: CGSize(width: 20, height: 20)) {
            closedButton.setImage(image, for: .normal)
        }
        // Set button images and titles
        configureButton(restartButton, title: "Restart", imageName: "restart")
        configureButton(resetButton, title: "Reset", imageName: "reset")
      
        firmwareview.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        firmwareview.cornerRadius = 10
       
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }

    func configureButton(_ button: UIButton, title: String, imageName: String) {
        if let image = UIImage(named: imageName)?.resized(to: CGSize(width: 30, height: 30)) {
            button.setImage(image.withRenderingMode(.alwaysOriginal), for: .normal)
        }
        
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal) // sets the text color
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)

        button.backgroundColor = .clear
        button.layer.cornerRadius = 10
        button.clipsToBounds = true
        button.layer.borderColor = UIColor.gray.cgColor
        button.layer.borderWidth = 1

        
        // Adjust spacing and alignmentba
        button.semanticContentAttribute = .forceLeftToRight
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -5, bottom: 0, right: 5)
    }

    func configureCloseButton() {
        if let closeImage = UIImage(named: "close")?.resized(to: CGSize(width: 20, height: 20)) {
            closedButton.setImage(closeImage.withRenderingMode(.alwaysOriginal), for: .normal)
        }
        closedButton.tintColor = .systemRed
        closedButton.setTitle("", for: .normal) // No title
    }


   
    
    func avrReset() {
        guard let topic = selectedDevice?.uniqueId else {
            print("Error: PUB_TOPIC_ is nil. Cannot subscribe to MQTT topic.")
            return
        }
        
        let alert = UIAlertController(
            title: "⚠️ Device Reset",
            message: "Are you sure you want to reset the device? This action cannot be undone.",
            preferredStyle: .alert
        )
        
        let confirmAction = UIAlertAction(title: "✅ Yes, Reset", style: .destructive) { _ in
            self.performDeviceReset(topic: topic)
        }
        
        let cancelAction = UIAlertAction(title: "❌ Cancel", style: .cancel)
        
        alert.addAction(confirmAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }

    private func performDeviceReset(topic: String) {
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            let fetch_all_params: Parameters = [
                "control": "set_device_to_default_settings",
                "from": "A",
                "type": topic
            ]
            
            if let jsonData = try? JSONSerialization.data(withJSONObject: fetch_all_params, options: []),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                
                print("JSON string = \(jsonString)")
                let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
                iotDataManager.publishString(jsonString, onTopic: topic + "/HA/A/req", qoS: .messageDeliveryAttemptedAtMostOnce)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
               self.showPopupreset()
           }
    }
    
    
  

    func avrRestart() {
        guard let topic = selectedDevice?.uniqueId else {
            print("Error: PUB_TOPIC_ is nil. Cannot subscribe to MQTT topic.")
            return
        }
        
        let alert = UIAlertController(
            title: "🔄 Restart Device",
            message: "Are you sure you want to restart the device?",
            preferredStyle: .alert
        )
        
        let confirmAction = UIAlertAction(title: "✅ Yes, Restart", style: .destructive) { _ in
            self.performDeviceRestart(topic: topic)
        }
        
        let cancelAction = UIAlertAction(title: "❌ Cancel", style: .cancel)
        
        alert.addAction(confirmAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }

    private func performDeviceRestart(topic: String) {
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            let fetch_all_params: Parameters = [
                "control": "avr_restart",
                "from": "A",
                "type": topic
            ]
            
            if let jsonData = try? JSONSerialization.data(withJSONObject: fetch_all_params, options: []),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                self.showPopupRestart()
                print("JSON string = \(jsonString)")
                let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
                iotDataManager.publishString(jsonString, onTopic: topic + "/HA/A/req", qoS: .messageDeliveryAttemptedAtMostOnce)
            }
            
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
               self.showPopupRestart()
           }
    }

    @objc func showPopupreset() {
        showPopupPresenter.showPopup1(on: self.view,
                                     animationName: "reset",
                                     title: "Reset!",
                                     subtitle: "Please wait while your system resets")
        
        // Automatically dismiss SystemResetViewController after popup finishes
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.navigationController?.popViewController(animated: true)
        }
    }

    @objc func showPopupRestart() {
        showPopupPresenter.showPopup1(on: self.view,
                                     animationName: "restart",
                                     title: "Restart!",
                                     subtitle: "Please wait while your system restarts")
        
        // Automatically dismiss SystemResetViewController after popup finishes
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.navigationController?.popViewController(animated: true)
        }
    }


    
   
    
    @IBAction func closedButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func restartButton(_ sender: Any) {
        
        
        avrRestart()
    }
    
    
    
    @IBAction func resetButton(_ sender: Any) {
        avrReset()
    }
    
}
