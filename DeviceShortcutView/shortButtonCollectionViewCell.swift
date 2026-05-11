//
//  shortButtonCollectionViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 27/03/25.
//

import UIKit
import SwiftKeychainWrapper
import AWSCore
import AWSIoT
import Alamofire
import Lottie

class shortButtonCollectionViewCell: UICollectionViewCell
{
    @IBOutlet weak var deviceVew: UIView!
    @IBOutlet weak var lockImageView: UIImageView!
    @IBOutlet weak var buttonImageView: UIImageView!
    
    @IBOutlet weak var dimStateImage: UIImageView!
    @IBOutlet weak var buttonName: UILabel!
    
    @IBOutlet weak var FanAndDimmingSlider: UISlider!
    var sliderWorkItem: DispatchWorkItem?
    
    var selectedButtonDetail: ButtonDetails?

    @IBOutlet weak var sliderValueLabel: UILabel!
    var deviceUid: String?
    var deviceUniqueId: String?
    var mappedValues: [[String: String]] = []
    var currentSliderControlType: String?
    var currentButtonNo: Int?
    
    var receivedDeviceStates: [DeviceStateArray] = []
    var buttonDetails: [ButtonDetails] = []
    override func awakeFromNib() {
        super.awakeFromNib()
        
        deviceVew.layer.cornerRadius = 10
        deviceVew.clipsToBounds = true
       
       
        
  
        let thumbSize = CGSize(width: 15, height: 15)
        let thumbImage = createThumbImage(size: thumbSize, color: .white) // Customize color if needed
        FanAndDimmingSlider.setThumbImage(thumbImage, for: .normal)
        FanAndDimmingSlider.setThumbImage(thumbImage, for: .highlighted)
        FanAndDimmingSlider.isHidden = true
           dimStateImage.isHidden       = true
           sliderValueLabel.isHidden    = true
           lockImageView.isHidden       = true

           // reset slider + label
           FanAndDimmingSlider.value = 1
           sliderValueLabel.text     = ""
        FanAndDimmingSlider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
       
    }
    func configure(with item: SwitchItem) {

        // ——— label & icon (unchanged) ———
        buttonName.text = item.buttonDetail?.buttonName ?? item.name
        buttonImageView.image = resolvedIcon(for: item)

        // ——— colours ———
        deviceVew.backgroundColor =
            (item.isOnState == 1) ? UIColor(hex:"#FAEDCB")
                             : UIColor(hex:"#FFFFFF")

     
        if item.isChildLocked == 1 {
            lockImageView.image = UIImage(named: "lockIcon")
            lockImageView.isHidden = false
        } else {
            lockImageView.image = nil  // or "unlocked" if you want to show both
            lockImageView.isHidden = true
        }


        // ——— slider logic (start hidden, then show when needed) ———
        FanAndDimmingSlider.isHidden = true
        dimStateImage.isHidden       = true
        sliderValueLabel.isHidden    = true

        if item.type == .fan, item.isOnState == 1 {
            // Fan speed slider
            FanAndDimmingSlider.isHidden = false
            FanAndDimmingSlider.tintColor = .systemBlue
            FanAndDimmingSlider.minimumValue = 1
            FanAndDimmingSlider.maximumValue = 4

            let speed = Int(item.speed ?? "1") ?? 1
            FanAndDimmingSlider.value  = Float(speed)
            sliderValueLabel.text      = "\(speed)"
            sliderValueLabel.isHidden  = false

            currentSliderControlType = "F"
            currentButtonNo          = item.switchIndex

        } else if item.type == .light, item.configDim == "1", item.isOnState == 1 {
            // Light dimmer slider (only when light is ON and supports dimming)
            dimStateImage.image   = UIImage(named: "brightness-2")
            dimStateImage.isHidden = false

            FanAndDimmingSlider.isHidden = false
            FanAndDimmingSlider.tintColor = .systemOrange
            FanAndDimmingSlider.minimumValue = 1
            FanAndDimmingSlider.maximumValue = 7

            let level = item.buttonDetail?.power ?? 1
            FanAndDimmingSlider.value  = Float(level)
            sliderValueLabel.text      = "\(level)"
            sliderValueLabel.isHidden  = false

            currentSliderControlType = "L"
            currentButtonNo          = item.switchIndex
        }

    }


    private func resolvedIcon(for item: SwitchItem) -> UIImage? {
        let index = item.switchIndex

        // Try custom icon
        if let icon = item.buttonDetail?.buttonIconName,
           !icon.isEmpty, icon != "Unknown",
           let img = UIImage(named: icon) {
            print("Index \(index): Showing custom icon: \(icon)")
            return img
        }

        // Fallback based on buttonControlName or name
        let letter = item.buttonDetail?.buttonControlName.first ?? item.name.first ?? " "
        let fallback: String
        switch letter {
        case "L": fallback = "bulb"
        case "O","Y": fallback = "curtains_Open"
        case "C","Q": fallback = "curtains_close"
        case "F":     fallback = "ceiling-fan"
        case "D":     fallback = "lock-2"
        case "M":     fallback = "AppIcon1"
        default:      fallback = "default_icon"
        }

        print("Index \(index): Showing fallback icon for letter '\(letter)': \(fallback)")
        return UIImage(named: fallback)
    }




    
    // Function to create a circular image for the thumb
    func createThumbImage(size: CGSize, color: UIColor) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            color.setFill()
            UIBezierPath(ovalIn: CGRect(origin: .zero, size: size)).fill()
        }
    }
    
    
    @objc func sliderValueChanged(_ sender: UISlider) {
        let sliderValue = Int(sender.value)
        sliderValueLabel.text = "\(sliderValue)"
        sliderValueLabel.isHidden = false
        sliderWorkItem?.cancel()

        let workItem = DispatchWorkItem {
            guard let buttonNo = self.currentButtonNo else { return }

            if self.currentSliderControlType == "F" {
                self.FanSpeed(speedValue: sliderValue, no: buttonNo)
            } else if self.currentSliderControlType == "L" {
                self.LightSpeed(speedValue: sliderValue, no: buttonNo)
            }
        }

        sliderWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: workItem)
    }


    func LightSpeed(speedValue: Int, no : Int) {
        guard let topic = deviceUniqueId else { return }

        let FanSpeed: Parameters = [
            "control": "L",
            "speed": speedValue,
            "state" : 1,
            "no":no ,
            "from": "A",
            "topic": topic
        ]

        print("Publishing MQTT: \(FanSpeed)")

        if let theJSONData = try? JSONSerialization.data(withJSONObject: FanSpeed, options: []) {
            let theJSONText = String(data: theJSONData, encoding: .utf8)
            print("JSON string = \(theJSONText!)")

            let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
            iotDataManager.publishString(theJSONText!, onTopic: topic + "/HA/A/req", qoS:.messageDeliveryAttemptedAtMostOnce)
        }
    }
    
    
    func FanSpeed(speedValue: Int, no: Int){
        guard let topic = deviceUniqueId else { return }

        let FanSpeed: Parameters = [
            "control": "F",
            "speed": speedValue,
            "state" : no,
            "no": 1,
            "from": "A",
            "topic": topic
        ]

        print("Publishing MQTT: \(FanSpeed)")

        if let theJSONData = try? JSONSerialization.data(withJSONObject: FanSpeed, options: []) {
            let theJSONText = String(data: theJSONData, encoding: .utf8)
            print("JSON string = \(theJSONText!)")

            let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
            iotDataManager.publishString(theJSONText!, onTopic: topic + "/HA/A/req", qoS:.messageDeliveryAttemptedAtMostOnce)
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
          
               return CGSize(width: 60, height: 60)
           }
    
       
}
