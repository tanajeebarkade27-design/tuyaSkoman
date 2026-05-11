//
//  BoardBrightnessViewController.swift
//  SkromanIsra
//
//  Created by Admin on 14/02/25.
//


import UIKit
import AWSCore
import AWSIoT
import Alamofire

class BoardBrightnessViewController: UIViewController {
    @IBOutlet weak var closedButton: UIButton!
    @IBOutlet weak var brightnessView: UIView!
    @IBOutlet weak var colorButton: UIButton!
    @IBOutlet weak var modeButton: UIButton!
    @IBOutlet weak var brightnessSlider: UISlider!
    @IBOutlet weak var autoButton: UIButton!
    
    @IBOutlet weak var buttonView: UIView!
    
    @IBOutlet weak var backgroundimage: UIImageView!
    
    
    @IBOutlet weak var autoOffButton: UIButton!
    
    
    @IBOutlet weak var manualButton: UIButton!
    
    @IBOutlet weak var sliderValueLabel: UILabel!
    var selectedDevice: Device?
    
    var devicestate: [DeviceStateArray] = []
    var deviceVc : DeviceViewController?
    var devices: [Device] = []
    var deviceUinqueId: String?
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
        
        // ❌ Close button setup
        closedButton.setTitle("", for: .normal)
        closedButton.setTitleColor(.black, for: .normal)
        if let image = UIImage(named: "close")?.resized(to: CGSize(width: 20, height: 20)) {
            closedButton.setImage(image, for: .normal)
        }

        // 🎨 View styling
        brightnessView.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        brightnessView.layer.cornerRadius = 10
        brightnessView.layer.borderColor = UIColor.gray.cgColor
        brightnessView.layer.borderWidth = 1

        buttonView.backgroundColor = UIColor.white.withAlphaComponent(0.10)
        buttonView.layer.cornerRadius = 10

        
        brightnessSlider.minimumValue = 0
        brightnessSlider.maximumValue = 100
        brightnessSlider.isHidden = true
        sliderValueLabel.isHidden = true
        sliderValueLabel.text = "\(Int(brightnessSlider.value))"
        brightnessSlider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .touchUpInside)
        brightnessSlider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .touchUpOutside)
        brightnessSlider.addTarget(self, action: #selector(sliderValueChanging(_:)), for: .valueChanged)
        
       
        let buttons: [UIButton] = [ modeButton, autoButton,autoOffButton, manualButton]
        for button in buttons {
            button.backgroundColor = .white
            button.setTitleColor(.black, for: .normal)
            button.layer.cornerRadius = 20
            button.layer.masksToBounds = true
        }

        print("deviceUinqueId: \(deviceUinqueId ?? "nil")")
    }

   

    @objc func sliderValueChanging(_ sender: UISlider) {
        let sliderValue = Int(sender.value)
        sliderValueLabel.text = "\(sliderValue)%"
    }

    @objc func sliderValueChanged(_ sender: UISlider) {
        let sliderValue = Int(sender.value)
        sliderValueLabel.text = "\(sliderValue)%"
        print("Slider value released: \(sliderValue)%")
        createCommonJSONForBrightnessControl()
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

   

    @IBAction func colorButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }

    @IBAction func modeButton(_ sender: Any) {
    }

    @IBAction func autoButton(_ sender: Any) {
        sliderValueLabel.isHidden =  true
        brightnessSlider.isHidden = true
        autoButtonTapped()
        
    }

    @IBAction func autoOffButton(_ sender: Any) {
        autoOffButtonTapped()
        brightnessSlider.isHidden = true
        sliderValueLabel.isHidden =  true
    }

    @IBAction func manualButton(_ sender: Any) {
        sliderValueLabel.isHidden =  false
        brightnessSlider.isHidden = false
        manualButtonTapped()
    }
    
   func autoButtonTapped() {
       guard let topic = selectedDevice?.uniqueId else {
           print("Error: PUB_TOPIC_ is nil.")
           return
       }
     
       
  
        let autobordButton : Parameters = [
            "control": "board_brightness_set_mode",
            "mode": 1,
            "from":"A",
            "topic": topic
            
        ]
       print("autobordButton \(autobordButton)")
       
       showPopupAuto()
        if let theJSONData = try? JSONSerialization.data(withJSONObject: autobordButton,options: []) {
            let theJSONText = String(data: theJSONData, encoding: .ascii)
            print("JSON string = \(theJSONText!)")
            let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
            let iot_sample_vc = Iot_sample_ViewController()
            iotDataManager.publishString(theJSONText!, onTopic:  "\(topic)/HA/A/req", qoS:.messageDeliveryAttemptedAtMostOnce)
        }
        print("auto Publishing control JSON: \(autobordButton)")
      
    }
    
    
    
    func autoOffButtonTapped() {
        guard let topic = selectedDevice?.uniqueId  else {
            print("Error: PUB_TOPIC_ is nil.")
            return
        }
      
        
   
         let autobordButton : Parameters = [
             "control": "board_brightness_set_mode",
             "mode": 2,
             "from":"A",
             "topic": topic
             
         ]
        print("autobordButton \(autobordButton)")
        
        showPopupAuto()
         if let theJSONData = try? JSONSerialization.data(withJSONObject: autobordButton,options: []) {
             let theJSONText = String(data: theJSONData, encoding: .ascii)
             print("JSON string = \(theJSONText!)")
             let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
             let iot_sample_vc = Iot_sample_ViewController()
             iotDataManager.publishString(theJSONText!, onTopic:  "\(topic)/HA/A/req", qoS:.messageDeliveryAttemptedAtMostOnce)
         }
         print("auto Publishing control JSON: \(autobordButton)")
       
     }
    
     func manualButtonTapped() {
     
         guard let topic = selectedDevice?.uniqueId  else {
             print("Error: PUB_TOPIC_ is nil.")
             return
         }
        let manualbordButton : Parameters = [
            "control": "board_brightness_set_mode",
            "mode": 3,
            "from":"A",
            "topic": topic
            
        ]
        if let theJSONData = try? JSONSerialization.data(withJSONObject: manualbordButton,options: []) {
            let theJSONText = String(data: theJSONData, encoding: .ascii)
            print("JSON string = \(theJSONText!)")
            showPopupManual()
            let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
            let iot_sample_vc = Iot_sample_ViewController()
            iotDataManager.publishString(theJSONText!, onTopic:  "\(topic)/HA/A/req", qoS:.messageDeliveryAttemptedAtMostOnce)
        }
        print("manual: Publishing control JSON: \(manualbordButton)")
   
     
    }
    
    private func createCommonJSONForBrightnessControl() {
        guard let topic = selectedDevice?.uniqueId  else {
            print("Error: PUB_TOPIC_ is nil.")
            return
        }
        
        let sliderValue = Int(brightnessSlider.value) // Capture slider value
        
        let manualBrightness: Parameters = [
            "control": "board_brightness_ctrl",
            "brightness": sliderValue,
            "from": "A",
            "topic": topic
        ]
        
        print("Payload at slider release: \(manualBrightness)")
        
        if let theJSONData = try? JSONSerialization.data(withJSONObject: manualBrightness, options: []) {
            let theJSONText = String(data: theJSONData, encoding: .ascii)
            print("JSON string = \(theJSONText!)")
            
            let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
            iotDataManager.publishString(theJSONText!, onTopic: "\(topic)/HA/A/req", qoS: .messageDeliveryAttemptedAtMostOnce)
        }
    }

     
    
func showPopupAuto() {
        
        showPopupPresenter.showPopup1(on: self.view,
                                     animationName: "light",
                                     title: "Success!",
                                     subtitle: "Auto Board Brightness Set ")
        
       
    }
    
    
func showPopupAutoOff() {
            showPopupPresenter.showPopup1(on: self.view,
                                         animationName: "light",
                                         title: "Success!",
                                         subtitle: "Auto off Board Brightness Set ")
            
           
        }
    func showPopupManual() {
                showPopupPresenter.showPopup1(on: self.view,
                                             animationName: "light",
                                             title: "Success!",
                                             subtitle: "You can set Brithness Manually")
                
               
            }
    
    
}
