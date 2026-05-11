
import UIKit
import SwiftKeychainWrapper
import AWSCore
import AWSIoT
import Alamofire

class CurtaimCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var cellbackgroundView: UIView!
    
    @IBOutlet weak var imageBackgroundView: UIView!
    
    @IBOutlet weak var deviceImageView: UIImageView!
    
    
    @IBOutlet weak var deviceNameLabel: UILabel!
    private var curtainSlider: CurtainSliderView?
    var receivedDeviceStates: [DeviceStateArray] = []
    private var currentButton: ButtonDetails?
    override func awakeFromNib() {
        super.awakeFromNib()
        
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        cellbackgroundView.layer.cornerRadius = 10
        cellbackgroundView.clipsToBounds = true
        imageBackgroundView.layer.cornerRadius = imageBackgroundView.frame.height / 2
        imageBackgroundView.clipsToBounds = true
        imageBackgroundView.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        cellbackgroundView.backgroundColor = UIColor.white.withAlphaComponent(0.15)
      
    }
    
    func configure(with button: ButtonDetails, device: Device? = nil, deviceStates: [DeviceStateArray] = []) {
        print("🛠 configure(button:device:) called for at curtain\(button) ")
        
         
        receivedDeviceStates = deviceStates
        deviceNameLabel.text = button.buttonName
       
        self.currentButton = button

        configureButtonUI(for: button, with: device)
        
    }
    
    
    func configureButtonUI(for button: ButtonDetails, with device: Device?) {
        guard let state = receivedDeviceStates.first(where: { $0.uniqueID == button.uniqueId }) else {
            return
        }

     
        let controlType = button.buttonControlName.uppercased()
        let index = button.buttonNo - 1

        var resolvedType: Character? = nil

        if index >= 0 && index < state.cNm.count {
            resolvedType = state.cNm[state.cNm.index(state.cNm.startIndex, offsetBy: index)]
        } else {
            print("⚠️ Invalid index \(index) for cNm in \(state.uniqueID)")
        }

        // ✅ Use resolvedType instead of liveType
        if let type = resolvedType {
            switch type {
               

                case "O", "Q":
                    setupCurtainControl(with: button)
                print("setupCurtainControl")
                    return

                case "C", "Y":
                    print("⏭ Skipping curtain slave: \(button.buttonName)")
                    return

                default:
                    break
            }
        }

       
        switch controlType {
           

            case "O", "Q":
                setupCurtainControl(with: button)

            case "C", "Y":
                print("⏭ Skipping curtain slave: \(button.buttonName)")

            default:
                break
        }
    }

    private func setupCurtainControl(with button: ButtonDetails) {
        curtainSlider = CurtainSliderView()
        curtainSlider!.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(curtainSlider!)

        NSLayoutConstraint.activate([
            curtainSlider!.widthAnchor.constraint(equalToConstant: 120),
            curtainSlider!.heightAnchor.constraint(equalToConstant: 30),
            curtainSlider!.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            curtainSlider!.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])

        curtainSlider?.isHidden = false

        if let thisDevice = receivedDeviceStates.first(where: { $0.uniqueID == button.uniqueId }) {
            let cNm = thisDevice.cNm
            let lightState = thisDevice.lightState

            var isClosed = false
            var isOpen = false

            for (i, char) in cNm.enumerated() {
                guard i < lightState.count else { continue }
                let stateChar = lightState[lightState.index(lightState.startIndex, offsetBy: i)]

                if stateChar == "1" {
                    switch char {
                    case "C", "Y":
                        isClosed = true
                    case "O", "Q":
                        isOpen = true
                    default:
                        continue
                    }
                }
            }

            print("🌐 Curtain update — UID: \(thisDevice.uniqueID), isOpen: \(isOpen), isClosed: \(isClosed)")
            curtainSlider?.updateThumbState(for: "Curtain", isOn: isOpen, nextValueIsOn: isClosed)
        }

        // Right tap: handle "O" or "Q"
        curtainSlider?.onRightTap = { [weak self] in
            guard let self = self else { return }

            guard let device = self.receivedDeviceStates.first(where: { $0.uniqueID == button.uniqueId }) else {
                print("❌ No matching device for UID: \(button.uniqueId)")
                return
            }

            let cNm = device.cNm
            let lightState = device.lightState
            let topic = button.uniqueId

            for (i, char) in cNm.enumerated() {
                guard i < lightState.count else { continue }

                if char == "O" || char == "Q" {
                    let currentChar = lightState[lightState.index(lightState.startIndex, offsetBy: i)]
                    let isOn = currentChar == "1"
                    let newState = isOn ? 0 : 1

                    print("📤 [RIGHT TAP] control: L, no: \(i+1), state: \(newState), speed: 1, topic: \(topic)")

                    self.publish_button_to_topic1(
                        control: "L",
                        no: i + 1,
                        state: newState,
                        speed: 1,
                        topic: topic
                    )
                    break
                }
            }
        }

        // Left tap: handle "C" or "Y"
        curtainSlider?.onLeftTap = { [weak self] in
            guard let self = self else { return }

            guard let device = self.receivedDeviceStates.first(where: { $0.uniqueID == button.uniqueId }) else {
                print("❌ No matching device for UID: \(button.uniqueId)")
                return
            }

            let cNm = device.cNm
            let lightState = device.lightState
            let topic = button.uniqueId

            for (i, char) in cNm.enumerated() {
                guard i < lightState.count else { continue }

                if char == "C" || char == "Y" {
                    let currentChar = lightState[lightState.index(lightState.startIndex, offsetBy: i)]
                    let isOn = currentChar == "1"
                    let newState = isOn ? 0 : 1

                    print("📤 [LEFT TAP] control: L, no: \(i+1), state: \(newState), speed: 1, topic: \(topic)")

                    self.publish_button_to_topic1(
                        control: "L",
                        no: i + 1,
                        state: newState,
                        speed: 1,
                        topic: topic
                    )
                    break
                }
            }
        }
    }
    func publish_button_to_topic1(control: String, no: Int, state: Int, speed: Int, topic: String) {
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
    
}
