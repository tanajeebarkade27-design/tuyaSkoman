//
//  EditDeviceButtonViewController.swift
//  SkromanIsra
//
//  Created by Admin on 19/07/25.
//

import UIKit
import Alamofire
import AWSCore
import AWSIoT


protocol EditDeviceButtonDelegate: AnyObject {
    func didUpdateDeviceButtons()
}

class EditDeviceButtonViewController: UIViewController {
    
    
    @IBOutlet weak var selectedBackView: UIView!
    @IBOutlet weak var selectedImageBackview: UIView!
    @IBOutlet weak var selecedImageView: UIImageView!
    @IBOutlet weak var selectedButtonNameLabel: UILabel!
    @IBOutlet weak var brightnessView: UIView!
    @IBOutlet weak var colorView: UIView!
    @IBOutlet weak var favouriteView: UIView!
    @IBOutlet weak var buttonNameText: UITextField!
    @IBOutlet weak var buttonWattageText: UITextField!
    @IBOutlet weak var buttonImageCollectionView: UICollectionView!
    
    @IBOutlet weak var buttonSchdeulerView: UIView!
    
    @IBOutlet weak var cancelButton: UIButton!
    
    @IBOutlet weak var submitbutton: UIButton!
    
    
    var selectedIconName: String?

    var filteredButtonDetails: [ButtonDetails] = []
    var isFromLongPress: Bool = false
    var receivedDeviceStates: [DeviceStateArray] = []
    var lightArray: [String] = []
    var lightNames: [String: String] = [:]
    var selectedButtonDetail: ButtonDetails?
    var isBrightnessHigh = false
    weak var delegate: EditDeviceButtonDelegate?
    var batteryMonitorTimer: Timer?
    var isAutoSocketEnabled = false
    var batteryTimer: Timer?
    @IBOutlet weak var backgroundcollectionView: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUIvalues()
        
        
        
        cancelButton.backgroundColor = .white
        cancelButton.setTitleColor(.black, for: .normal) // text color
        cancelButton.layer.cornerRadius = 10
        cancelButton.layer.masksToBounds = true
        submitbutton.backgroundColor = .white
        submitbutton.setTitleColor(.black, for: .normal) // text color
        submitbutton.layer.cornerRadius = 10
        submitbutton.layer.masksToBounds = true

        // Selected button title should not overflow the UI.
        selectedButtonNameLabel.numberOfLines = 1
        selectedButtonNameLabel.lineBreakMode = .byTruncatingTail
        selectedButtonNameLabel.adjustsFontSizeToFitWidth = false
        selectedButtonNameLabel.minimumScaleFactor = 0.85
        
        
        print ("buttonstate long press \(selectedButtonDetail)")
        if let deviceState = getDeviceStateForSelectedButton() {
               // ✅ Use matched device state here
               print("🎯 Matched device state: \(deviceState)")
               // For example:
            print("💡 Dim State:", deviceState.cDim)
               
           } else {
               print("❌ No matching device found for selected button")
           }
        
        buttonNameText.addTarget(self, action: #selector(buttonNameTextChanged(_:)), for: .editingChanged)
        let favouriteTapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleFavourite))
        favouriteView.addGestureRecognizer(favouriteTapGesture)
        favouriteView.isUserInteractionEnabled = true
        
        let brightnessTapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleBrightnessAlpha))
        brightnessView.addGestureRecognizer(brightnessTapGesture)
        brightnessView.isUserInteractionEnabled = true

        let colorTap = UITapGestureRecognizer(target: self, action: #selector(openColorPickerWithSetButton))
        colorView.addGestureRecognizer(colorTap)
        colorView.isUserInteractionEnabled = true
        
        let schedulerTap = UITapGestureRecognizer(target: self, action: #selector(showSetTimerPopup))
        buttonSchdeulerView.addGestureRecognizer(schedulerTap)
        buttonSchdeulerView.isUserInteractionEnabled = true

       


        guard let selectedUniqueId = selectedButtonDetail?.uniqueId else {
            print("❌ No selectedButtonDetail or uniqueID found")
            return
        }

        guard let matchedDeviceState = receivedDeviceStates.first(where: { $0.uniqueID == selectedUniqueId }) else {
            print("❌ No matching device state found for uniqueID: \(selectedUniqueId)")
            return
        }

        if matchedDeviceState.series == "AVR_V9_NORMAL" {
            buttonSchdeulerView.isHidden = false
        } else {
            buttonSchdeulerView.isHidden = true
        }



        imagsetUp()
        registerXIB()
        UIDevice.current.isBatteryMonitoringEnabled = true
        let batteryLevel = UIDevice.current.batteryLevel
            if batteryLevel < 0 {
                print("Battery level is unavailable")
            } else {
                let batteryPercent = Int(batteryLevel * 100)
                print("Battery Level: \(batteryPercent)%")
            }
        
        
        
    }
    
    
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        guard let deviceState = getDeviceStateForSelectedButton(),
              let button = selectedButtonDetail else {
            brightnessView.alpha = 0.0
            brightnessView.isUserInteractionEnabled = false
            brightnessView.isHidden = false
            return
        }

        if button.buttonControlName == "F" {
            brightnessView.alpha = 0.0
            brightnessView.isUserInteractionEnabled = false
            brightnessView.isHidden = true
            return
        }

        guard let buttonNo = selectedButtonDetail?.buttonNo,
              !deviceState.cNm.isEmpty,
              !deviceState.cDim.isEmpty else {
            brightnessView.alpha = 0.0
            brightnessView.isUserInteractionEnabled = false
            brightnessView.isHidden = false
            return
        }

        let index = buttonNo - 1

        guard index >= 0,
              index < deviceState.cNm.count,
              index < deviceState.cDim.count else {
            brightnessView.alpha = 0.0
            brightnessView.isUserInteractionEnabled = false
            brightnessView.isHidden = false
            return
        }

        brightnessView.isHidden = false

        let cNmChar = deviceState.cNm[deviceState.cNm.index(deviceState.cNm.startIndex, offsetBy: index)]
        let cDimChar = deviceState.cDim[deviceState.cDim.index(deviceState.cDim.startIndex, offsetBy: index)]

        if cNmChar == "L" {
            brightnessView.alpha = (cDimChar == "1") ? 1.0 : 0.3
            brightnessView.isUserInteractionEnabled = true
            print("🔁 brightnessView shown with alpha \(brightnessView.alpha)")
        } else {
            brightnessView.alpha = 0.0
            brightnessView.isUserInteractionEnabled = false
        }
    }

    
    @objc func socketViewTapped() {
        let alert = UIAlertController(
            title: "Enable Auto Socket?",
            message: "The socket will automatically turn off when battery reaches 100%.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        alert.addAction(UIAlertAction(title: "Proceed", style: .default, handler: { _ in
            UIDevice.current.isBatteryMonitoringEnabled = true
            let batteryLevel = UIDevice.current.batteryLevel
            
            if batteryLevel < 0 {
                print("⚠️ Battery level is unavailable")
                return
            }
            
            if batteryLevel >= 1.0 {
                print("🔋 Battery already full! Auto socket not needed.")
            } else {
                let percent = Int(batteryLevel * 100)
                print("✅ Auto Socket monitoring started at \(percent)% battery.")
                self.isAutoSocketEnabled = true
                self.startBatteryMonitoring()
            }
        }))

        self.present(alert, animated: true, completion: nil)
    }

    
    
    
    func stopBatteryMonitoring() {
           batteryTimer?.invalidate()
           batteryTimer = nil
       }
    
    

    func startBatteryMonitoring() {
        // Invalidate old timer if any
        batteryMonitorTimer?.invalidate()
        
        // Start checking every 10 seconds
        batteryMonitorTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            UIDevice.current.isBatteryMonitoringEnabled = true
            let batteryLevel = UIDevice.current.batteryLevel
            
            if batteryLevel < 0 {
                print("⚠️ Battery level unavailable")
                return
            }
            
            let percent = Int(batteryLevel * 100)
            print("🔋 Current battery: \(percent)%")
            
            if batteryLevel >= 1.0 {
                print("🚀 Battery 100%! Sending payload...")
                self.batteryMonitorTimer?.invalidate()
                self.isAutoSocketEnabled = false
                self.sendAutoSocketPayload()
            }
        }
    }

    
    func sendAutoSocketPayload() {
        guard let uniqueId = selectedButtonDetail?.uniqueId,
              let buttonNo = selectedButtonDetail?.buttonNo else {
            print("❌ Missing uniqueId or buttonNo")
            return
        }

        // Build payload as per your example
        let payload: [String: Any] = [
            "control": "L",
            "no": buttonNo,
            "state": "0",
            "from": "A",
            "speed": "1",
            "topic": uniqueId
        ]
        
        // Convert to JSON string
        if let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print("Publishing Auto Socket Payload: \(jsonString)")
            
            let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
            iotDataManager.publishString(jsonString, onTopic: uniqueId + "/HA/A/req", qoS: .messageDeliveryAttemptedAtMostOnce)
        }
    }


    func setupUIvalues(){
        let viewsToStyle = [
            selectedImageBackview,
            colorView,
            favouriteView,
            brightnessView
            ]
        for view in viewsToStyle {
            view?.layer.cornerRadius = view!.frame.height / 2
            view?.clipsToBounds = true
            view?.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        }
        let viewsToStyle1 = [
            backgroundcollectionView,
            buttonWattageText,
            buttonNameText,
            selectedBackView
        
        ]
        
        for view in viewsToStyle1 {
            view?.layer.cornerRadius = 10
            view?.clipsToBounds = true
            view?.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        }
        buttonNameText.text =  selectedButtonDetail?.buttonName
        selectedButtonNameLabel.text =  selectedButtonDetail?.buttonName
        if let powerValue = selectedButtonDetail?.power {
            buttonWattageText.text = "\(powerValue) Watt"
        } else {
            buttonWattageText.text =  "Please enter Button Wttage"
        }
        if selectedButtonDetail?.isFavourite == 0 {
            favouriteView.alpha = 0.3
        } else {
            favouriteView.alpha = 1.0
        }

        if let iconName = selectedButtonDetail?.buttonIconName {
            if iconName == "Unknown" {
                // Use type-based fallback image
                if let type = selectedButtonDetail?.buttonControlName,
                   let fallbackImage = getImageForType(type) {
                    selecedImageView.image = fallbackImage
                } else {
                    selecedImageView.image = UIImage(named: "defaultIcon") // Optional: safe default
                }
            } else {
                // Use the provided icon
                selecedImageView.image = UIImage(named: iconName)
            }
        }
        
    }
    
    @IBAction func backButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
        
    }
  
    @IBAction func cancelButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func submitButton(_ sender: Any) {

        guard let buttonDetails = selectedButtonDetail else { return }

        // ✅ Wattage is mandatory
        let wattageRaw = (buttonWattageText.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard let updatedPower = Int(wattageRaw), updatedPower > 0 else {
            let alert = UIAlertController(
                title: "Wattage required",
                message: "Please add wattage (e.g. 5, 10).",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        let updatedName = buttonNameText.text ?? buttonDetails.buttonName
        let updatedIcon = selectedIconName ?? buttonDetails.buttonIconName
        let updatedFav = buttonDetails.isFavourite ?? 0

        // ✅ 1. UPDATE LOCAL DATABASE IMMEDIATELY
        SkromanIsraDatabaseHelper.shared.updateButtonDetails(
            buttonId: buttonDetails.buttonId ?? "",
            buttonName: updatedName,
            power: updatedPower,
            buttonIconName: updatedIcon ?? "",
            isFavourite: updatedFav
        )

        // ✅ 2. UPDATE LOCAL OBJECT
        selectedButtonDetail?.buttonName = updatedName
        selectedButtonDetail?.power = updatedPower
        selectedButtonDetail?.buttonIconName = updatedIcon

        // ✅ 3. REFRESH UI VIA DELEGATE
        delegate?.didUpdateDeviceButtons()

        // ✅ 4. CALL API
        sendFavouriteUpdateToServer()

        dismiss(animated: true)
    }
    func  registerXIB(){
         let uiNib =  UINib(nibName: "EditDeviceButtonCollectionViewCell", bundle: nil)
        buttonImageCollectionView.register(uiNib, forCellWithReuseIdentifier: "EditDeviceButtonCollectionViewCell")
        buttonImageCollectionView.dataSource  = self
        buttonImageCollectionView.delegate =  self
    
    }
    
    func  imagsetUp(){
        guard let controlName = selectedButtonDetail?.buttonControlName else {
                print("❌ No selectedButtonDetail or control name.")
                return
            }

            print("📦 Control name: \(controlName)")

            // Set icon arrays based on control name
            switch controlName {
            case "L":
                // For lights, also allow icons used in other categories (curtain/lock/fan),
                // so user can pick any of them while editing a light button.
                let lArray = ["ic_light_n","light_bulb_fill0","light_bulb_fill1","light_default","light_emoji_fill0","light_emoji_fill1","light_round_fill0","light_round_fill1", "chandelier_1","chandelier_1","air_purifier","blender","door", "door_open","doorbell1","microwave","oven","roller_shades_closed","roller_shades","sink","speaker","temple","terrace","thermostat_1","universal_plug","washing_machine","water_heater"]
                var lNames: [String: String] = [
                    "ic_light_n":"light" ,"light_bulb_fill0":"light","light_bulb_fill1":"light","light_default":"light","light_emoji_fill0":"light","light_emoji_fill1":"light","light_round_fill0":"light","light_round_fill1":"light", "chandelier_1":"chandelier","chandelier_5":"chandelier","air_purifier":"air purifier","blender":"blender","door":"door","door_open":"door_open","doorbell1":"doorbell1","microwave":"microwave","oven":"oven","roller_shades_closed":"shades closed","roller_shades":"roller shades","sink":"sink","speaker":"speaker","temple":"temple","terrace":"terrace","washing_machine":"washing machi","thermostat_1":"thermostat","universal_plug":"plug","water_heater":"water heater"
                ]

                let oArray = [ "curtains_Open"]
                let oNames = [ "curtains_Open": "Curtain Open"]

                let cArray = ["curtains_close2", "curtains_close"]
                let cNames = ["curtainClosed": "Curtain Close", "curtains_close": "Curtain Close"]

              
                let dArray = ["lock-2", "Lock-100"]
                let dNames = [ "lock-2": "Lock", "Lock-100": "Lock"]

                let fArray = ["fan_mode_fill0", "fan_mode_fill1","fan_table_round2","ic_fan_n"]
                let fNames = ["fan_mode_fill0":"fan", "fan_mode_fill1":"fan","fan_table_round2":"fan","ic_fan_n":"fan"]

                // Merge without duplicates (keep first occurrence order)
                var seen = Set<String>()
                let merged = (lArray + oArray + cArray + dArray + fArray).filter { seen.insert($0).inserted }
                lightArray = merged

                // Merge names (keep existing if duplicated)
                for (k, v) in oNames { if lNames[k] == nil { lNames[k] = v } }
                for (k, v) in cNames { if lNames[k] == nil { lNames[k] = v } }
                for (k, v) in dNames { if lNames[k] == nil { lNames[k] = v } }
                for (k, v) in fNames { if lNames[k] == nil { lNames[k] = v } }
                lightNames = lNames
            
            case "D":
                lightArray = ["lockIcon", "lock-2", "Lock-100"]
                lightNames = ["lockIcon": "Lock", "lock-2": "Lock", "Lock-100": "Lock"]
                
            case "C":
                lightArray = ["curtains_close"]
                lightNames = [ "curtains_close": "Curtain Close"]
                
            case "O":
                lightArray = ["curtains-2", "curtains_Open"]
                lightNames = ["curtains-2": "Curtain Open", "curtains_Open": "Curtain Open"]
                
            case "F":
                lightArray = ["fan_mode_fill0", "fan_mode_fill1","fan_table_round2","ic_fan_n"]
                lightNames = ["fan_mode_fill0":"fan", "fan_mode_fill1":"fan","fan_table_round2":"fan","ic_fan_n":"fan"]

            default:
                lightArray = []
                lightNames = [:]
            }
      
    }
    
    
     func getImageForType(_ type: String) -> UIImage? {
         switch type {
         case "L":
             return UIImage(named: "LightBulb")
         case "O":
             return UIImage(named: "curtainOpen")
         case "C":
             return UIImage(named: "curtains_close")
         case "Q":
             return UIImage(named: "curtainOpen")
         case "Y":
             return UIImage(named: "curtains_close")
         case "F":
             return UIImage(named: "Fan1")
         case "M":
             return UIImage(named: "AppIcon")
         default:
             return nil
         }
     }
    
    @objc func buttonNameTextChanged(_ textField: UITextField) {
        selectedButtonNameLabel.text = textField.text
    }
    
    func updateFavourite() {
        let targetAlpha: CGFloat = (selectedButtonDetail?.isFavourite == 0) ? 0.3 : 1.0
        UIView.animate(withDuration: 0.25) {
            self.favouriteView.alpha = targetAlpha
        }
    }
    @objc func toggleFavourite() {

        guard let button = selectedButtonDetail else {
            print("❌ selectedButtonDetail is nil")
            return
        }

        print("Before toggle:", button.isFavourite)

        // Toggle safely
        selectedButtonDetail?.isFavourite =
            (button.isFavourite == 1) ? 0 : 1

        // Animate UI
        UIView.animate(withDuration: 0.3) {
            self.favouriteView.alpha =
                (self.selectedButtonDetail?.isFavourite == 1) ? 1.0 : 0.3
        }

        // 🔥 Make sure buttonId is valid
        guard !button.buttonId.isEmpty else {
            print("❌ buttonId is empty")
            return
        }

        SkromanIsraDatabaseHelper.shared.updateIsFavourite(
            buttonId: button.buttonId,
            isFavourite: selectedButtonDetail?.isFavourite ?? 0
        )

        print("After toggle:", selectedButtonDetail?.isFavourite ?? -1)

        delegate?.didUpdateDeviceButtons()
    }
    func getDeviceStateForSelectedButton() -> DeviceStateArray? {
        guard let selectedBtnUniqueId  = selectedButtonDetail?.uniqueId else { return nil }
        return receivedDeviceStates.first(where: { $0.uniqueID == selectedBtnUniqueId })
        
    }
    

    func isSelectedButtonDimmable() -> Bool {
        guard let deviceState = getDeviceStateForSelectedButton(),
              let buttonNo = selectedButtonDetail?.buttonNo,
              !deviceState.cDim.isEmpty,
              !deviceState.cNm.isEmpty else {
            return false
        }

        let index = buttonNo - 1

        guard index < deviceState.cDim.count,
              index < deviceState.cNm.count else {
            print("⚠️ Index \(index) is out of bounds. cDim: \(deviceState.cDim), cNm: \(deviceState.cNm)")
            return false
        }

        let cDimChar = deviceState.cDim[deviceState.cDim.index(deviceState.cDim.startIndex, offsetBy: index)]
        let cNmChar  = deviceState.cNm[deviceState.cNm.index(deviceState.cNm.startIndex, offsetBy: index)]

        print("🧪 buttonNo: \(buttonNo), checking index: \(index)")
        print("🔎 cDimChar: \(cDimChar), cNmChar: \(cNmChar)")

        return cDimChar == "1" && cNmChar == "L"
    }
    @objc func toggleBrightnessAlpha() {
        guard let buttonNo = selectedButtonDetail?.buttonNo,
              let deviceState = getDeviceStateForSelectedButton(),
              !deviceState.cNm.isEmpty,
              !deviceState.cDim.isEmpty else {
            return
        }

        let index = buttonNo - 1

        guard index >= 0 && index < deviceState.cNm.count,
              index < deviceState.cDim.count else { return }

        let cNmChar = deviceState.cNm[deviceState.cNm.index(deviceState.cNm.startIndex, offsetBy: index)]
        let cDimChar = deviceState.cDim[deviceState.cDim.index(deviceState.cDim.startIndex, offsetBy: index)]

        guard cNmChar == "L" else { return }

        // Show alert based on original cDimChar value (BEFORE toggling)
        let isDimmable = (cDimChar == "1")
        showDimmingAlert(isDimmable: isDimmable)

        // Then toggle alpha
        isBrightnessHigh.toggle()
        UIView.animate(withDuration: 0.3) {
            self.brightnessView.alpha = self.isBrightnessHigh ? 1.0 : 0.3
        }
        print("🔁 BrightnessView toggled to alpha \(brightnessView.alpha)")
    }


    @objc func showSetTimerPopup() {
        guard let button = selectedButtonDetail else { return }

        let popup = SetTimerPopupView()
        popup.buttonDetail = button
        popup.isSwitchOn = true

        popup.onSubmit = { [weak self] selectedTime, isSwitchOn in
            guard let self = self else { return }

            // Display time for alert
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "hh:mm a"
            let displayTime = displayFormatter.string(from: selectedTime)

            // Force seconds = 00
            var components = Calendar.current.dateComponents([.hour, .minute], from: selectedTime)
            components.second = 0

            guard let finalDate = Calendar.current.date(from: components) else { return }

            // Backend format HH:mm:ss
            let backendFormatter = DateFormatter()
            backendFormatter.dateFormat = "HH:mm:ss"
            let postTime = backendFormatter.string(from: finalDate)

            let topic = button.uniqueId ?? ""

            // Build payload
            let payload: [String: Any] = [
                "control": "timer_config",
                "type": "L",
                "no": button.buttonNo,
                "state": isSwitchOn ? 1 : 0,
                "speed": 1,
                "post_time": postTime,
                "from": "A",
                "topic": topic
            ]

            // Convert payload to JSON
            if let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []),
               let jsonString = String(data: jsonData, encoding: .utf8) {

                print("📡 Publishing Timer Payload: \(jsonString)")

                // ✅ Publish to MQTT
                let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
                iotDataManager.publishString(
                    jsonString,
                    onTopic: "\(topic)/HA/A/req",
                    qoS: .messageDeliveryAttemptedAtMostOnce
                )

                // ✅ Show success alert
                let stateText = isSwitchOn ? "turn ON" : "turn OFF"
                let message = "\(button.buttonName) will \(stateText) at \(displayTime)"

                let alert = UIAlertController(
                    title: "Timer Scheduled",
                    message: message,
                    preferredStyle: .alert
                )

                alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                    self.navigationController?.popViewController(animated: true)
                })

                self.present(alert, animated: true)
            } else {
                print("❌ Failed to serialize timer payload JSON.")
            }
        }

        popup.show(on: self.view)
    }

    
    func showDimmingAlert(isDimmable: Bool) {
        let title = isDimmable ? "Turn Off Dimming" : "Turn On Dimming"
        let subTitle = isDimmable
            ? "Converts light to regular on/off mode"
            : "Add brightness control for this light"

        let alert = UIAlertController(title: title, message: subTitle, preferredStyle: .alert)

        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            guard let buttonNo = self.selectedButtonDetail?.buttonNo,
                  let deviceState = self.getDeviceStateForSelectedButton(),
                  var cDim = deviceState.cDim as String?,
                  buttonNo - 1 >= 0,
                  buttonNo - 1 < cDim.count else {
                print("❌ Error: invalid buttonNo or cDim")
                return
            }

            let index = buttonNo - 1
            let cDimIndex = cDim.index(cDim.startIndex, offsetBy: index)
            let currentChar = cDim[cDimIndex]
            let newChar: Character = (currentChar == "1") ? "0" : "1"

            // Toggle the character at index
            cDim.replaceSubrange(cDimIndex...cDimIndex, with: String(newChar))

            // 🔁 Send the updated cDim as val
            let topic = deviceState.uniqueID
            self.publish_button(val: cDim, topic: topic)

            // Also animate the alpha change
            UIView.animate(withDuration: 0.3) {
                self.brightnessView.alpha = (newChar == "1") ? 1.0 : 0.3
            }

            print("📡 Toggled dimming. New cDim: \(cDim)")
        }

        alert.addAction(okAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }


    func publish_button(val: String, topic: String) {
        let fetch_all_params: [String: Any] = [
            "control": "config_dim",
            "val": val,
            "from": "A",
            "topic": topic
        ]
        print("FETCH ALL PARAMS : >>> ", fetch_all_params)

        if let theJSONData = try? JSONSerialization.data(withJSONObject: fetch_all_params, options: []),
           let theJSONText = String(data: theJSONData, encoding: .ascii) {
            print("JSON dimm string = \(theJSONText)")
            let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
            iotDataManager.publishString(theJSONText, onTopic: topic + "/HA/A/req", qoS: .messageDeliveryAttemptedAtMostOnce)
        }
    }
    @objc func showPopupdimming() {
        showPopupPresenter.showPopup1(on: self.view,
                                       animationName: "light",
                                       title: "Success!",
                                       subtitle: "Dimming Changes Done.")

        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func sendFavouriteUpdateToServer() {
        guard let buttonDetails = selectedButtonDetail else {
            print("❌ No button detail")
            return
        }

        let isFavouriteSet = buttonDetails.isFavourite == 1

        let edit_params: Parameters = [
            "deviceServerId": buttonDetails.deviceServerId,
            "buttonName": buttonNameText.text ?? buttonDetails.buttonName,
            "power": Int(buttonWattageText.text ?? "") ?? 0,
            "buttonIconId": 1,
            "buttonControlName": buttonDetails.buttonControlName,
            "buttonIconName": selectedIconName ?? buttonDetails.buttonIconName,
            "isFavourite": isFavouriteSet,
            "ishomefav": false
        ]

        print("button details API: \(edit_params)")

        AF.request("http://3.7.18.55:3000/skroman/buttondetails/buttonupdate",
                   method: .put,
                   parameters: edit_params,
                   encoding: JSONEncoding.default,
                   headers: nil)
            .response { response in
                debugPrint(response)

                switch response.result {
                case .success(let data):
                    do {
                        let jsonOne = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary
                        if let msg = jsonOne?["msg"] as? String, msg == "Success update button details" {

                            // ✅ Update in local SQLite DB
                            SkromanIsraDatabaseHelper.shared.updateIsFavourite(
                                buttonId: buttonDetails.buttonId ?? "",
                                isFavourite: isFavouriteSet ? 1 : 0
                            )

                            // ✅ Show animation if now favourite
                            if isFavouriteSet {
                                self.showHeartAnimation {
                                    self.dismiss(animated: true, completion: nil)
                                    self.delegate?.didUpdateDeviceButtons()
                                }
                            } else {
                                
                                self.dismiss(animated: true, completion: nil)
                            }
                        }
                    } catch {
                        print("Error parsing response: \(error.localizedDescription)")
                    }

                case .failure(let err):
                    print("Request failed: \(err.localizedDescription)")
                }
            }
    }



    func showHeartAnimation(completion: @escaping () -> Void) {
        let heartImageView = UIImageView(image: UIImage(named: "heart-2"))
        heartImageView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        heartImageView.center = view.center
        heartImageView.alpha = 0.0
        heartImageView.contentMode = .scaleAspectFit
        view.addSubview(heartImageView)

        UIView.animate(withDuration: 0.3, animations: {
            heartImageView.alpha = 1.0
            heartImageView.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        }) { _ in
            UIView.animate(withDuration: 0.3, delay: 0.5, options: [], animations: {
                heartImageView.alpha = 0.0
                heartImageView.transform = CGAffineTransform.identity
            }, completion: { _ in
                heartImageView.removeFromSuperview()
                completion()
            })
        }
    }

    
    @objc func openColorPickerWithSetButton() {
        let parentVC = UIViewController()
        parentVC.view.backgroundColor = UIColor.black.withAlphaComponent(0.65)

        // Color Picker
        let colorPicker = UIColorPickerViewController()
        colorPicker.supportsAlpha = false
        colorPicker.selectedColor = .white
        colorPicker.modalPresentationStyle = .overFullScreen

        parentVC.addChild(colorPicker)
        parentVC.view.addSubview(colorPicker.view)
        colorPicker.view.translatesAutoresizingMaskIntoConstraints = false
        colorPicker.didMove(toParent: parentVC)
        colorPicker.view.layer.cornerRadius = 16
        colorPicker.view.clipsToBounds = true
        colorPicker.view.backgroundColor = UIColor.black.withAlphaComponent(0.35)

        // Set Color Button
        let setColorButton = UIButton(type: .system)
        setColorButton.setTitle("Set Color", for: .normal)
        setColorButton.backgroundColor = .white
        setColorButton.setTitleColor(.black, for: .normal)
        setColorButton.layer.cornerRadius = 22 // capsule (height 44)
        setColorButton.translatesAutoresizingMaskIntoConstraints = false
        setColorButton.addTarget(nil, action: #selector(handleColorSetButtonTapped(_:)), for: .touchUpInside)

        parentVC.view.addSubview(setColorButton)

        // Close Button
        let closeButton = UIButton(type: .system)
        closeButton.setTitle("✕", for: .normal)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.titleLabel?.font = .systemFont(ofSize: 24, weight: .bold)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(nil, action: #selector(handleCloseButtonTapped(_:)), for: .touchUpInside)

        parentVC.view.addSubview(closeButton)

        // Title label (white)
        let title = UILabel()
        title.text = "Select color"
        title.textColor = .white
        title.font = .systemFont(ofSize: 18, weight: .semibold)
        title.translatesAutoresizingMaskIntoConstraints = false
        parentVC.view.addSubview(title)

        // Constraints
        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: parentVC.view.safeAreaLayoutGuide.topAnchor, constant: 14),
            title.centerXAnchor.constraint(equalTo: parentVC.view.centerXAnchor),

            colorPicker.view.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 12),
            colorPicker.view.leadingAnchor.constraint(equalTo: parentVC.view.leadingAnchor, constant: 12),
            colorPicker.view.trailingAnchor.constraint(equalTo: parentVC.view.trailingAnchor, constant: -12),
            colorPicker.view.bottomAnchor.constraint(equalTo: setColorButton.topAnchor, constant: -12),

            setColorButton.bottomAnchor.constraint(equalTo: parentVC.view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            setColorButton.centerXAnchor.constraint(equalTo: parentVC.view.centerXAnchor),
            setColorButton.widthAnchor.constraint(equalToConstant: 160),
            setColorButton.heightAnchor.constraint(equalToConstant: 44),

            closeButton.centerYAnchor.constraint(equalTo: title.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: parentVC.view.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30)
        ])

        // Store for later
        objc_setAssociatedObject(setColorButton, &AssociatedKeys.colorPicker, colorPicker, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(setColorButton, &AssociatedKeys.parentVC, parentVC, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(closeButton, &AssociatedKeys.parentVC, parentVC, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        present(parentVC, animated: true)
    }
    @objc func handleCloseButtonTapped(_ sender: UIButton) {
        if let parentVC = objc_getAssociatedObject(sender, &AssociatedKeys.parentVC) as? UIViewController {
            parentVC.dismiss(animated: true)
        }
    }

    @objc func handleColorSetButtonTapped(_ sender: UIButton) {
        guard
            let colorPicker = objc_getAssociatedObject(sender, &AssociatedKeys.colorPicker) as? UIColorPickerViewController,
            let parentVC = objc_getAssociatedObject(sender, &AssociatedKeys.parentVC) as? UIViewController
        else { return }

        let selectedColor = colorPicker.selectedColor
        print("Selected color: \(selectedColor)")

      
        triggerColorUpdate(with: selectedColor)

        // Close the popup
        parentVC.dismiss(animated: true)
    }


    private struct AssociatedKeys {
        static var colorPicker = "AssociatedColorPicker"
        static var parentVC = "AssociatedParentVC"
    }
    
    
    func triggerColorUpdate(with color: UIColor) {
        
           
            let topic  = selectedButtonDetail?.uniqueId                 // ‹topic›
            let specialTypes   = selectedButtonDetail?.buttonControlName        // ‹T›
            let selectedNumber = selectedButtonDetail?.buttonNo
        let controlName    = selectedButtonDetail?.buttonControlName
     


        let lightTypes: Set<String> = ["L","O","C","D","Q","Y"]
        

        let colorComponents = color.cgColor.components ?? [1, 1, 1]
        let red = colorComponents.count > 0 ? colorComponents[0] : 1.0
        let green = colorComponents.count > 1 ? colorComponents[1] : 1.0
        let blue = colorComponents.count > 2 ? colorComponents[2] : 1.0

        let all_params: Parameters = [
            "control": "ctrl_board_button_rgb_color",
            "T": controlName,
            "N": selectedNumber,
            "R": red * 100,
            "G": green * 100,
            "B": blue * 100,
            "H": "255",
            "from": "A",
            "topic": topic
        ]

        print("MQTT Params: \(all_params)")

        if let jsonData = try? JSONSerialization.data(withJSONObject: all_params, options: []),
           let jsonText = String(data: jsonData, encoding: .utf8) {

            print("📦 JSON String = \(jsonText)")

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
                iotDataManager.publishString(jsonText, onTopic: "\(topic)/HA/A/req", qoS: .messageDeliveryAttemptedAtMostOnce)
            }

        } else {
            print("❌ Error: Failed to serialize JSON or encode string")
        }
    }


    
}

extension EditDeviceButtonViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return lightArray.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "EditDeviceButtonCollectionViewCell",
            for: indexPath
        ) as! EditDeviceButtonCollectionViewCell

        let iconName = lightArray[indexPath.item]
        let labelName = lightNames[iconName]

        cell.buttonImage.image = UIImage(named: iconName)
        cell.buttonNameLabel.text = labelName

        // ✅ Highlight selected icon (reuse-safe)
        let isSelected = (iconName == selectedIconName)
        cell.isSelected = isSelected
        cell.applySelectedStyle(isSelected)

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let leftInset: CGFloat = 8
        let rightInset: CGFloat = 8
        let spacing: CGFloat = 8
        let columns: CGFloat = 4

        let totalSpacing = leftInset + rightInset + spacing * (columns - 1)
        let availableWidth = collectionView.bounds.width - totalSpacing
        let baseCellWidth = availableWidth / columns

        return CGSize(width: baseCellWidth, height: 80)
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let iconName = lightArray[indexPath.item]
        let labelName = lightNames[iconName] ?? "Unknown"
        
        // Store selected icon name
        selectedIconName = iconName
        
        // Update preview and labels
        selecedImageView.image = UIImage(named: iconName)
        buttonNameText.text = labelName
        selectedButtonNameLabel.text = labelName
        
        collectionView.reloadData()

    }



   
}

