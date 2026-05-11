//
//  OldDevBrightnessViewController.swift
//  SkromanIsra
//
//  Created by Admin on 08/03/25.
//

import UIKit
import AWSCore
import AWSIoT
import Alamofire

class OldDevBrightnessViewController: UIViewController {

    @IBOutlet weak var themNumberCollectionView: UICollectionView!
    @IBOutlet weak var closedButton: UIButton!
    @IBOutlet var colorPicker: SwiftHSVColorPicker!
    
    @IBOutlet weak var offButton: UIButton!
    @IBOutlet weak var onButton: UIButton!
    @IBOutlet weak var bulbImage: UIImageView!
    @IBOutlet weak var themeView: UIView!
    @IBOutlet weak var themesButton: UIButton!
    @IBOutlet weak var themViewHeight: NSLayoutConstraint!
    let numbers = Array(1...10)
    @IBOutlet var boardView: UIView!
   
    @IBOutlet weak var backgroundimage: UIImageView!
    var selectedDevice: Device?
    
    var devicestate: [DeviceStateArray] = []
    var deviceVc: DeviceViewController?
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
        
        let buttons: [UIButton] = [ offButton, onButton]
        for button in buttons {
            button.backgroundColor = .white
            button.setTitleColor(.black, for: .normal)
            button.layer.cornerRadius = 20
            button.layer.masksToBounds = true
        }

        
        let imageSize = CGSize(width: 30, height: 30)
        themesButton.setImage(resizeImage(named: "chromatic", size: imageSize), for: .normal)
        closedButton.setTitle("", for: .normal)
        closedButton.setTitleColor(.black, for: .normal) // Set text color
        
        if let image = UIImage(named: "close")?.resized(to: CGSize(width: 20, height: 20)) {
            closedButton.setImage(image, for: .normal)
        }
        colorPicker.setViewColor(.white)
        
        themNumberCollectionView.isHidden = true
        themViewHeight.constant = 0
        view.layoutIfNeeded()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(colorPickerTouchEnded))
        colorPicker.addGestureRecognizer(tapGesture)
        
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            let selectedColor = self.colorPicker.color
            self.updateBulbColor(selectedColor ?? .white)
        }
       // chromatic
      
        if let firstScene = devices.first {
            deviceUinqueId = firstScene.uniqueId
        } else {
            deviceUinqueId = nil
        }
        
       
        themNumberCollectionView.delegate = self
        themNumberCollectionView.dataSource = self
        registerXib()
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
    
    // MARK: - Close Button Action
    @IBAction func closedButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
   
    @IBAction func themesButton(_ sender: Any) {
        themNumberCollectionView.isHidden = false
        themViewHeight.constant = 44
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()  // Animate the height change
        }
    }
    
    func registerXib(){
        let uinib =  UINib(nibName: "NumberCollectionViewCell", bundle: nil)
        themNumberCollectionView.register(uinib, forCellWithReuseIdentifier: "NumberCollectionViewCell")
    }
    
   
 
    @objc func colorPickerTouchEnded() {
        let selectedColor = colorPicker.color // Get the last selected color
        bulbImage.tintColor = selectedColor  // Apply color to the bulb image
        print("Final Selected Color: \(selectedColor)")
    }
    
    
    func updateBulbColor(_ color: UIColor) {
        bulbImage.image = (bulbImage.image ?? UIImage(named: "bulb"))?.withRenderingMode(.alwaysTemplate)
        bulbImage.tintColor = color
    }
    
    // MARK: - Other Actions
    @IBAction func onColorButton(_ sender: Any) {
        setOnAndOff(ButtonState: true)
        onButton.tintColor = .blue
        offButton.tintColor = .gray
        
        
       
    }
    
    
    @IBAction func offColorButton(_ sender: Any) {
        setOnAndOff(ButtonState: false)
        onButton.tintColor = .gray
        offButton.tintColor = .blue
    }
    
    @IBAction func oldStateSwitch(_ sender: UISwitch) {
        let buttonState = sender.isOn ? "NEW" : "OLD"
        switchButton(buttonState: buttonState)
    }

    
    
    func switchButton(buttonState:String ) {
        guard let topic = selectedDevice?.uniqueId  else {
            print("Error: PUB_TOPIC_ is nil.")
            return
        }
         let autobordButton : Parameters = [
             "control": "DEVICE_MEMORY_STATE",
             "theme_no": buttonState,
             "from":"A",
             "topic": topic
             
         ]
        print("autobordButton \(autobordButton)")
        
    
         if let theJSONData = try? JSONSerialization.data(withJSONObject: autobordButton,options: []) {
             let theJSONText = String(data: theJSONData, encoding: .ascii)
             print("JSON string = \(theJSONText!)")
             let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
             let iot_sample_vc = Iot_sample_ViewController()
             iotDataManager.publishString(theJSONText!, onTopic:  "\(topic)/HA/A/req", qoS:.messageDeliveryAttemptedAtMostOnce)
         }
         print("auto Publishing control JSON: \(autobordButton)")
       
     }
    
    
    
    
    @objc func showPopupScene(themeNumber: Int) {
        showPopupPresenter.showPopup1(on: self.view,
                                      animationName: "color",
                                      title: "Success!",
                                      subtitle: "Board Theme has been changed to \(themeNumber)")
    }

    
    func setTheam(themeNo:Int) {
        guard let topic = selectedDevice?.uniqueId  else {
            print("Error: PUB_TOPIC_ is nil.")
            return
        }
         let autobordButton : Parameters = [
             "control": "REALTIME_LED_STRIP_THEME",
             "theme_no": themeNo,
             "from":"A",
             "topic": topic
             
         ]
        print("autobordButton \(autobordButton)")
        
    
         if let theJSONData = try? JSONSerialization.data(withJSONObject: autobordButton,options: []) {
             let theJSONText = String(data: theJSONData, encoding: .ascii)
             print("JSON string = \(theJSONText!)")
             let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
             let iot_sample_vc = Iot_sample_ViewController()
             iotDataManager.publishString(theJSONText!, onTopic:  "\(topic)/HA/A/req", qoS:.messageDeliveryAttemptedAtMostOnce)
         }
         print("auto Publishing control JSON: \(autobordButton)")
       
     }
    
    
    func setOnAndOff(ButtonState: Bool) {
        guard let topic = selectedDevice?.uniqueId else {
            print("Error: PUB_TOPIC_ is nil.")
            return
        }

        let stateValue = ButtonState ? 1 : 0  // 1 for On, 0 for Off
        let color = bulbImage.tintColor ?? UIColor.white  // Get the current color of the bulb
        
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)  // Extract RGB values
        
        let autobordButton: Parameters = [
            "control": "REALTIME_LED_STRIP_THEME",
            "LS_BT_TYPE": "ALL",
            "LS_BT_STATE": stateValue,
            "LS_BT_R": Int(red * 255),   // Convert to 0-255 integer range
            "LS_BT_G": Int(green * 255),
            "LS_BT_B": Int(blue * 255),
            "from": "A",
            "topic": topic
        ]
        
        print("autobordButton \(autobordButton)")

        if let theJSONData = try? JSONSerialization.data(withJSONObject: autobordButton, options: []) {
            let theJSONText = String(data: theJSONData, encoding: .ascii)
            print("JSON string = \(theJSONText!)")
            
            let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
            iotDataManager.publishString(theJSONText!, onTopic: "\(topic)/HA/A/req", qoS: .messageDeliveryAttemptedAtMostOnce)
        }
        
        print("Auto Publishing control JSON: \(autobordButton)")
    }

    
    
}
extension OldDevBrightnessViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
   
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return numbers.count
    }
    
   
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NumberCollectionViewCell", for: indexPath) as! NumberCollectionViewCell
        cell.numberLabel.text = "\(numbers[indexPath.item])"
        return cell
    }
 
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedNumber = numbers[indexPath.item]
        setTheam(themeNo: selectedNumber)
        showPopupScene(themeNumber: selectedNumber)
        print("Selected Theme Number: \(selectedNumber)")
    }



}
