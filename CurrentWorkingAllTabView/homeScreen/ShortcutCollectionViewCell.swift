//
//  ShortcutCollectionViewCell.swift
//  SkromanIsra


import UIKit
import SwiftKeychainWrapper
import AWSCore
import AWSIoT
import Alamofire

class ShortcutCollectionViewCell: UICollectionViewCell {
    
    
    @IBOutlet weak var roomname: UILabel!
    @IBOutlet weak var deviceImageView: UIImageView!
    @IBOutlet weak var imageview: UIView!
    @IBOutlet weak var cellbackgroundview: UIView!
    @IBOutlet weak var buttonNameLabel: UILabel!
    var receivedDeviceStates: [DeviceStateArray] = []
    static var subscribedIds: Set<String> = []
    var globallySubscribedUniqueIds: Set<String> = []
    
    
    let sliderButton = SliderButton()
    /// When disabled, taps pass through so the collection view can select the "Add Shortcut" cell.
    private var cellBackgroundTapGesture: UITapGestureRecognizer?
    private var curtainSlider: CurtainSliderView?
    private var simpleButton: UIButton?
    private var fanSlider: FanSlider?
    
    private var dimSlider: CustomSlider?
    private var isOn = false
    private let powerImageView = UIImageView()
    private var thumbLeadingConstraint: NSLayoutConstraint!
    private var thumbTrailingConstraint: NSLayoutConstraint!
    private var statusLabelCenterXConstraint: NSLayoutConstraint?
    private var statusLabelLeadingConstraint: NSLayoutConstraint?
    private var statusLabelTrailingConstraint: NSLayoutConstraint?
    private var currentButton: ButtonDetails?
    private var currentDeviceCategory: String?
    private var currentDeviceDimmingType: String?
    var currentState: DeviceStateArray?
    
    override func awakeFromNib() {
        print("receivedDeviceStates at cell\(receivedDeviceStates)")
        super.awakeFromNib()
        cellbackgroundview.layer.cornerRadius = 10
        cellbackgroundview.clipsToBounds = true
        imageview.layer.cornerRadius = imageview.frame.height / 2
        imageview.clipsToBounds = true
        imageview.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        cellbackgroundview.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        deviceImageView.tintColor = .white
        
        cellbackgroundview.addSubview(controlsStackView)
        NSLayoutConstraint.activate([
            controlsStackView.topAnchor.constraint(equalTo: buttonNameLabel.bottomAnchor, constant: 10),
            controlsStackView.leadingAnchor.constraint(equalTo: cellbackgroundview.leadingAnchor, constant: 10),
            controlsStackView.trailingAnchor.constraint(equalTo: cellbackgroundview.trailingAnchor, constant: -10),
            controlsStackView.bottomAnchor.constraint(lessThanOrEqualTo: cellbackgroundview.bottomAnchor, constant: -10)
        ])
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cellTapped))
        cellBackgroundTapGesture = tapGesture
        cellbackgroundview.isUserInteractionEnabled = true
        cellbackgroundview.addGestureRecognizer(tapGesture)
    }
   
    @objc private func cellTapped() {

        guard let button = currentButton,
              let state = currentState else {
            print("❌ Missing data")
            return
        }

        let index = button.buttonNo - 1
        let topic = button.uniqueId
        let nameControl = button.buttonControlName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()

        // Match configure(): fan/curtain by button metadata first
        if nameControl == "F" {
            let fanState = state.fanState
            let lightCount = state.lightState.count
            let fanIndex = (button.buttonNo - 1) - lightCount

            guard fanIndex >= 0 && fanIndex < fanState.count else {
                print("❌ Fan index error")
                return
            }

            let fanChar = fanState[fanState.index(fanState.startIndex, offsetBy: fanIndex)]
            let isOn = fanChar == "1"
            let newState = isOn ? 0 : 1

            publish_button_to_topic(
                control: "F",
                no: fanIndex + 1,
                state: newState,
                speed: 1,
                topic: topic
            )
            animateTap()
            return
        }

        if ["O", "Q", "C", "Y"].contains(nameControl) {
            publish_button_to_topic(
                control: "L",
                no: button.buttonNo,
                state: 1,
                speed: 1,
                topic: topic
            )
            animateTap()
            return
        }

        guard index >= 0,
              index < state.cNm.count else {
            print("❌ Index mismatch")
            return
        }

        let controlType = state.cNm[state.cNm.index(state.cNm.startIndex, offsetBy: index)]

        print("👉 Cell tapped → control:", controlType)

        switch controlType {

        // 💡 LIGHT
        case "L":

            let currentChar = state.lightState[state.lightState.index(state.lightState.startIndex, offsetBy: index)]
            let isOn = currentChar == "1"
            let newState = isOn ? 0 : 1

            publish_button_to_topic(
                control: "L",
                no: button.buttonNo,
                state: newState,
                speed: 0,
                topic: topic
            )

        // 🌬 FAN
        case "F":

            let fanState = state.fanState
            let lightCount = state.lightState.count
            let fanIndex = (button.buttonNo - 1) - lightCount

            guard fanIndex >= 0 && fanIndex < fanState.count else {
                print("❌ Fan index error")
                return
            }

            let fanChar = fanState[fanState.index(fanState.startIndex, offsetBy: fanIndex)]
            let isOn = fanChar == "1"
            let newState = isOn ? 0 : 1

            publish_button_to_topic(
                control: "F",
                no: fanIndex + 1,
                state: newState,
                speed: 1,
                topic: topic
            )

        // 🪟 CURTAIN
        case "O", "Q", "C", "Y":

            publish_button_to_topic(
                control: "L",
                no: button.buttonNo,
                state: 1,
                speed: 1,
                topic: topic
            )

        default:
            print("❌ Unsupported control")
        }

        // ✅ Optional UI feedback
        animateTap()
    }
    func animateTap() {
        cellbackgroundview.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)

        UIView.animate(withDuration: 0.2) {
            self.cellbackgroundview.transform = .identity
        }
        highlightCell()
    }
    func highlightCell() {

        cellbackgroundview.layer.borderWidth = 2
        cellbackgroundview.layer.borderColor = UIColor.systemGreen.cgColor

        // smooth animation
        UIView.animate(withDuration: 0.15, animations: {
            self.cellbackgroundview.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
        }) { _ in
            UIView.animate(withDuration: 0.15) {
                self.cellbackgroundview.transform = .identity
            }
        }

        // auto remove after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.cellbackgroundview.layer.borderWidth = 0
        }
    }
    func resetForAddShortcut() {
        cellBackgroundTapGesture?.isEnabled = false
        cellbackgroundview.isUserInteractionEnabled = false
        // Remove all dynamic controls
        sliderButton.removeFromSuperview()
        fanSlider?.removeFromSuperview()
        curtainSlider?.removeFromSuperview()
        dimSlider?.removeFromSuperview()

        // Hide any power buttons if exist
        simpleButton?.removeFromSuperview()

        // Reset UI
        buttonNameLabel.text = ""
    }
    
    @objc private func toggleState() {
        isOn.toggle()

        if let button = simpleButton {
            if isOn {
                button.layer.borderWidth = 2
                button.layer.borderColor = UIColor.systemGreen.cgColor
                button.layer.shadowColor = UIColor.systemGreen.cgColor
                button.layer.shadowRadius = 4
                button.layer.shadowOpacity = 0.8
                button.layer.shadowOffset = .zero
            } else {
                button.layer.borderWidth = 0
                button.layer.shadowOpacity = 0
            }
        }

      
        guard let button = currentButton,
              let category = currentDeviceCategory,
              let dimmingType = currentDeviceDimmingType else {
            print("❌ Missing required data to publish payload")
            return
        }

        let topic = button.uniqueId 

        let index = button.buttonNo
        let control = String(button.buttonControlName.prefix(1)) // E.g., "L", "F"
        let state = isOn ? 1 : 0
        let speed = mapSliderValueToSpeed(value: dimSlider?.currentValue ?? 0, category: category, dimmingType: dimmingType)

        print("📤 Publishing from toggle: control=\(control), no=\(index), state=\(state), speed=\(speed), topic=\(topic)")

        publish_button_to_topic(control: control, no: index, state: state, speed: speed, topic: topic)
    }

    
    func updateDeviceState(_ state: DeviceStateArray) {
        
        print("🔁 Received state for cell: \(state)")
       
    }

    func configure(with device: Device,
                   button: ButtonDetails,
                   state: DeviceStateArray?) {

        cellBackgroundTapGesture?.isEnabled = true
        cellbackgroundview.isUserInteractionEnabled = true
        print("📦 Configure → Device:", device.uniqueId, "Button:", button.buttonName)

        // ✅ Basic UI
        buttonNameLabel.text = button.buttonName
        roomname.text = button.roomName
        updateImageView(for: button)

        // ✅ Store references
        currentButton = button
        currentDeviceCategory = device.deviceCategory
        currentDeviceDimmingType = state?.workingMode
        currentState = state   // 🔥 IMPORTANT
        // Fan/curtain helpers read this; must match this cell’s device (reuse-safe).
        receivedDeviceStates = state.map { [$0] } ?? []

        // ✅ Clean old UI (reuse safe)
        controlsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        cleanupControls()

        // ❌ If no state → show default UI and EXIT
        guard let state = state else {
            print("⚠️ No state → showing default OFF UI")
            setupDefaultUI(for: button)
            return
        }

        let index = button.buttonNo - 1

        let controlNameUpper = button.buttonControlName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()

        print("🔍 buttonControlName:", controlNameUpper, "buttonNo:", button.buttonNo, "cNm.count:", state.cNm.count)

        // Prefer DB button type first. Fans/curtains may be fan-only (short/empty `cNm`) — must not require `index < cNm.count`.
        switch controlNameUpper {
        case "F":
            setupFanControl(with: button)
            return
        case "O", "Q", "C", "Y":
            setupCurtainControl(with: button)
            return
        default:
            break
        }

        guard index >= 0,
              index < state.cNm.count else {
            print("❌ Index out of bounds for:", button.buttonName, "(need cNm slot for lights)")
            setupDefaultUI(for: button)
            return
        }

        let controlType = state.cNm[state.cNm.index(state.cNm.startIndex, offsetBy: index)]

        print("🔍 ControlType (from cNm):", controlType, "Index:", index)

        // ✅ Decide control type (lights + fallback when control name missing)
        switch controlType {

        // 💡 LIGHT
        case "L":

            if index < state.cDim.count,
               state.cDim[state.cDim.index(state.cDim.startIndex, offsetBy: index)] == "1",
               let category = currentDeviceCategory,
               let dimmingType = currentDeviceDimmingType {

                setupDimmableLightControl(
                    with: button,
                    category: category,
                    dimmingType: dimmingType,
                    allDeviceStates: [state]
                )

            } else {

                setupLightControl(
                    with: button,
                    allDeviceStates: [state]
                )
            }

        // 🌬 FAN (fallback if control name was blank but cNm says F)
        case "F":
            setupFanControl(with: button)

        // 🪟 CURTAIN
        case "O", "Q", "C", "Y":
            setupCurtainControl(with: button)

        default:
            print("❌ Unknown control:", controlType)
            setupDefaultUI(for: button)
        }
    }

    func setupDefaultUI(for button: ButtonDetails) {

        sliderButton.setState(false)
        sliderButton.isHidden = false

        contentView.addSubview(sliderButton)

        sliderButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            sliderButton.widthAnchor.constraint(equalToConstant: 60),
            sliderButton.heightAnchor.constraint(equalToConstant: 30),
            sliderButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            sliderButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])
    }
    private let controlsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private func updateImageView(for button: ButtonDetails) {
        
        let iconName = button.buttonIconName.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let controlName = button.buttonControlName.uppercased()

        var image: UIImage?

        // ✅ Use fallback if invalid icon
        if iconName.isEmpty || iconName.lowercased() == "null" || iconName.lowercased() == "unknown" {
            
            switch controlName {
            case "F":
                image = UIImage(named: "Fan1")
            case "L":
                image = UIImage(named: "Group-2")
            case "O", "Q":
                image = UIImage(named: "curtain-filled")
            default:
                image = UIImage(named: "default_device") // 👈 add this asset
            }
            
        } else {
            image = UIImage(named: iconName)
        }

        // ✅ Final fallback safety
        if image == nil {
            print("❌ Image not found: \(iconName)")
            image = UIImage(named: "default_device")
        }

        deviceImageView.image = image
        deviceImageView.contentMode = .scaleAspectFit
    }
    
    private func cleanupControls() {
        sliderButton.removeFromSuperview()
        curtainSlider?.removeFromSuperview()
        simpleButton?.removeFromSuperview()
        fanSlider?.removeFromSuperview()
        dimSlider?.removeFromSuperview()

        sliderButton.isHidden = true
        curtainSlider = nil
        simpleButton = nil
        fanSlider = nil
        dimSlider = nil
    }
   
    private func setupLightControl(with button: ButtonDetails, allDeviceStates: [DeviceStateArray]) {
        contentView.addSubview(sliderButton)
        sliderButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            sliderButton.widthAnchor.constraint(equalToConstant: 60),
            sliderButton.heightAnchor.constraint(equalToConstant: 30),
            sliderButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            sliderButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])

        sliderButton.isHidden = false
        let index = button.buttonNo - 1

        // ✅ Match device state by uniqueId
        guard let matchedState = allDeviceStates.first(where: { $0.uniqueID == button.uniqueId }),
              index >= 0,
              index < matchedState.lightState.count,
              index < matchedState.cNm.count else {
            sliderButton.setState(false)
            print("❌ Incomplete or missing state for button \(button.buttonName)")
            return
        }

        let cNmType = matchedState.cNm[matchedState.cNm.index(matchedState.cNm.startIndex, offsetBy: index)]
        let lState = matchedState.lightState[matchedState.lightState.index(matchedState.lightState.startIndex, offsetBy: index)]

        let isLightOn = cNmType == "L" && lState == "1"
        sliderButton.setState(isLightOn)

        sliderButton.onToggle = { isOn in
            print("💡 Light toggled to \(isOn ? "ON" : "OFF") for \(button.buttonName)")

            let lSpeed = index < matchedState.lightSpeed.count
                ? Int(String(matchedState.lightSpeed[matchedState.lightSpeed.index(matchedState.lightSpeed.startIndex, offsetBy: index)])) ?? 0
                : 0

            self.publish_button_to_topic(
                control: "L",
                no: button.buttonNo,
                state: isOn ? 1 : 0,
                speed: lSpeed,
                topic: matchedState.uniqueID
            )
        }
    }


    private func setupFanControl(with button: ButtonDetails) {
        let powerButton = UIButton(type: .system)
        powerButton.translatesAutoresizingMaskIntoConstraints = false
        powerButton.tintColor = .orange
        powerButton.backgroundColor = .white
        powerButton.layer.cornerRadius = 12.5
        contentView.addSubview(powerButton)
        simpleButton = powerButton

        NSLayoutConstraint.activate([
            powerButton.widthAnchor.constraint(equalToConstant: 25),
            powerButton.heightAnchor.constraint(equalToConstant: 25),
            powerButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            powerButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])

        powerButton.addTarget(self, action: #selector(toggleFanState), for: .touchUpInside)

        let resizedIcon = UIGraphicsImageRenderer(size: CGSize(width: 12, height: 12)).image { _ in
            UIImage(systemName: "power")?.draw(in: CGRect(origin: .zero, size: CGSize(width: 12, height: 12)))
        }
        powerButton.setImage(resizedIcon.withRenderingMode(.alwaysTemplate), for: .normal)

       
        let shouldAddSlider = updateFanUI(for: button, powerButton: powerButton)

        // ➕ Fan slider only if fan is valid
        if shouldAddSlider {
            let slider = FanSlider()
            slider.translatesAutoresizingMaskIntoConstraints = false
            slider.tag = 999
            contentView.addSubview(slider)
            fanSlider = slider

            NSLayoutConstraint.activate([
                slider.widthAnchor.constraint(equalToConstant: 90),
                slider.heightAnchor.constraint(equalToConstant: 30),
                slider.leadingAnchor.constraint(equalTo: powerButton.trailingAnchor, constant: 20),
                slider.centerYAnchor.constraint(equalTo: powerButton.centerYAnchor)
            ])

            slider.onSliderReleased = { [weak self] value in
                guard let self = self else { return }

                // ⚠️ Only publish if fan is ON
                guard self.isOn else {
                    print("⚠️ Fan is OFF, ignoring slider release")
                    return
                }

                let fanSpeed = value // Convert UI value (1-4) to device speed (4-1)
                let topic = button.uniqueId
                let lightCount = self.receivedDeviceStates.first(where: { $0.uniqueID == topic })?.lightState.count ?? 0
                let fanIndex = (button.buttonNo - 1) - lightCount

                print("📤 [Fan Slider Released] control: F\(fanIndex + 1), state: 1, speed: \(fanSpeed), topic: \(topic)")
                self.publish_button_to_topic(
                    control: "F",
                    no: fanIndex + 1,
                    state: 1,
                    speed: fanSpeed,
                    topic: topic
                )
            }

            
            if let state = receivedDeviceStates.first(where: { $0.uniqueID == button.uniqueId }) {
                let speedStr = state.fanSpeed
                let lightCount = state.lightState.count
                let rawFanIndex = (button.buttonNo - 1) - lightCount
                let fanIndex = speedStr.count == 1 ? 0 : rawFanIndex

                if fanIndex >= 0 && fanIndex < speedStr.count {
                    let speedChar = speedStr[speedStr.index(speedStr.startIndex, offsetBy: fanIndex)]
                    if let reportedSpeed = Int(String(speedChar)), (1...4).contains(reportedSpeed) {
                        slider.currentValue = reportedSpeed
                        print("🌬️ Initial fan speed set to \(reportedSpeed) (device reported: \(reportedSpeed))")

                    } else {
                        print("⚠️ Invalid speed char: \(speedChar)")
                    }
                } else {
                    print("⚠️ Fan speed index \(fanIndex) out of bounds for speed string: \(speedStr)")
                }
            }


            contentView.bringSubviewToFront(powerButton)
        } else {
            print("ℹ️ Fan not valid — slider will not be shown for \(button.buttonName)")
        }
    }
    

    private func updateFanUI(for button: ButtonDetails, powerButton: UIButton) -> Bool {
        guard let state = receivedDeviceStates.first(where: { $0.uniqueID == button.uniqueId }) else {
            print("❌ No matching device for UID: \(button.uniqueId)")
            return false
        }

        let fanState = state.fanState
        let lightCount = state.lightState.count
        let rawFanIndex = (button.buttonNo - 1) - lightCount
        
        

        if fanState == "NA" {
            isOn = false
            print("🚫 No fan present for UID: \(button.uniqueId)")
            return false
        }

        if fanState.count == 1 {
            if rawFanIndex != 0 {
                print("⚠️ Only one fan exists but rawFanIndex \(rawFanIndex) ≠ 0. Skipping fan.")
                return false
            }

            let fanChar = fanState.first!
            isOn = fanChar == "1"
            print("✅ Single Fan \(button.buttonName) is \(isOn ? "ON" : "OFF") — fanState: \(fanState)")
        }
        else if rawFanIndex >= 0 && rawFanIndex < fanState.count {
            let fanChar = fanState[fanState.index(fanState.startIndex, offsetBy: rawFanIndex)]
            isOn = fanChar == "1"
            print("✅ Fan \(button.buttonName) is \(isOn ? "ON" : "OFF") — fanState: \(fanState), index: \(rawFanIndex)")
        }
        else {
            isOn = false
            print("⚠️ Fan index \(rawFanIndex) out of bounds for fanState: \(fanState)")
            return false
        }

        // 💡 Style update
        if isOn {
            powerButton.layer.borderWidth = 2
            powerButton.layer.borderColor = UIColor.systemGreen.cgColor
            powerButton.layer.shadowColor = UIColor.systemGreen.cgColor
            powerButton.layer.shadowRadius = 4
            powerButton.layer.shadowOpacity = 0.8
            powerButton.layer.shadowOffset = .zero
        } else {
            powerButton.layer.borderWidth = 0
            powerButton.layer.shadowOpacity = 0
        }

        return true
    }
    
    
    @objc private func toggleFanState() {
        guard let button = currentButton,
              let stateIndex = receivedDeviceStates.firstIndex(where: { $0.uniqueID == button.uniqueId }),
              let slider = fanSlider else {
            print("❌ Missing data in toggleFanState")
            return
        }

        var state = receivedDeviceStates[stateIndex]

        let fanState = state.fanState
        let lightCount = state.lightState.count
        let fanIndex = (button.buttonNo - 1) - lightCount

        guard fanIndex >= 0 && fanIndex < fanState.count else {
            print("⚠️ Fan index out of bounds")
            return
        }

        let fanChar = fanState[fanState.index(fanState.startIndex, offsetBy: fanIndex)]
        let isCurrentlyOn = fanChar == "1"
        let targetState = isCurrentlyOn ? 0 : 1
        isOn = targetState == 1

        // UI Update
        if let buttonView = simpleButton {
            if isOn {
                buttonView.layer.borderWidth = 2
                buttonView.layer.borderColor = UIColor.systemGreen.cgColor
                buttonView.layer.shadowColor = UIColor.systemGreen.cgColor
                buttonView.layer.shadowRadius = 4
                buttonView.layer.shadowOpacity = 0.8
                buttonView.layer.shadowOffset = .zero
            } else {
                buttonView.layer.borderWidth = 0
                buttonView.layer.shadowOpacity = 0
            }
        }

        let uiSpeed = slider.currentValue
        let deviceSpeed = uiSpeed

        print("🚀 [Fan Toggle] control: F\(fanIndex + 1), state: \(targetState), speed: \(deviceSpeed), topic: \(button.uniqueId)")

        // Send actual payload
        publish_button_to_topic(
            control: "F",
            no: fanIndex + 1,
            state: targetState,
            speed: deviceSpeed,
            topic: button.uniqueId
        )

        // ✅ Immediate local fanState update in memory
        var fanStateArray = Array(fanState)
        fanStateArray[fanIndex] = Character("\(targetState)")
        state.fanState = String(fanStateArray)
        receivedDeviceStates[stateIndex] = state
    }

    
    
    
   
    
    private func setupDimmableLightControl(with button: ButtonDetails, category: String, dimmingType: String, allDeviceStates: [DeviceStateArray]) {
        
        print ("dim data ")
        let index = button.buttonNo - 1

        // ✅ Match device state by uniqueId
        guard let matchedState = allDeviceStates.first(where: { $0.uniqueID == button.uniqueId }),
              index >= 0,
              index < matchedState.lightState.count,
              index < matchedState.cDim.count,
              index < matchedState.lightSpeed.count else {
            print("❌ No valid matched state or index out of bounds for dimmable light: \(button.buttonName)")
            return
        }

        currentButton = button

        // MARK: - Power Button Setup
        let powerButton = UIButton(type: .system)
        powerButton.translatesAutoresizingMaskIntoConstraints = false
        powerButton.tintColor = .orange
        powerButton.backgroundColor = .white
        powerButton.layer.cornerRadius = 12.5
        contentView.addSubview(powerButton)
        simpleButton = powerButton

        NSLayoutConstraint.activate([
            powerButton.widthAnchor.constraint(equalToConstant: 25),
            powerButton.heightAnchor.constraint(equalToConstant: 25),
            powerButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            powerButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])

        let resizedIcon = UIGraphicsImageRenderer(size: CGSize(width: 12, height: 12)).image { _ in
            UIImage(systemName: "power")?.draw(in: CGRect(origin: .zero, size: CGSize(width: 12, height: 12)))
        }
        powerButton.setImage(resizedIcon.withRenderingMode(.alwaysTemplate), for: .normal)
        powerButton.addTarget(self, action: #selector(toggleState), for: .touchUpInside)

        // ✅ State values
        let lStateChar = matchedState.lightState[matchedState.lightState.index(matchedState.lightState.startIndex, offsetBy: index)]
        let isOn = lStateChar == "1"

        if isOn {
            powerButton.layer.borderWidth = 2
            powerButton.layer.borderColor = UIColor.systemGreen.cgColor
            powerButton.layer.shadowColor = UIColor.systemGreen
                .cgColor
            powerButton.layer.shadowRadius = 4
            powerButton.layer.shadowOpacity = 0.8
            powerButton.layer.shadowOffset = .zero
        } else {
            powerButton.layer.borderWidth = 0
            powerButton.layer.shadowOpacity = 0
        }

        // MARK: - Slider Setup
        let slider = CustomSlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(slider)
        dimSlider = slider

        NSLayoutConstraint.activate([
            slider.widthAnchor.constraint(equalToConstant: 90),
            slider.heightAnchor.constraint(equalToConstant: 30),
            slider.leadingAnchor.constraint(equalTo: powerButton.trailingAnchor, constant: 20),
            slider.centerYAnchor.constraint(equalTo: powerButton.centerYAnchor)
        ])

        // ✅ Map speed to slider value
        let speedChar = matchedState.lightSpeed[matchedState.lightSpeed.index(matchedState.lightSpeed.startIndex, offsetBy: index)]
        if let speed = Int(String(speedChar)) {
            let sliderValue = mapSpeedToSliderValue(speed: speed, category: category, dimmingType: dimmingType)
            slider.currentValue = min(100, max(0, sliderValue))
            slider.setEnabled(isOn)
            print("🔁 Set slider: speed = \(speed), mapped value = \(sliderValue)")
        } else {
            slider.currentValue = 0
            slider.setEnabled(false)
            print("⚠️ Invalid speed char: \(speedChar)")
        }

        // MARK: - On Value Change
        slider.onValueChangeEnded = { [weak self] sliderValue in
            guard let self = self else { return }

            let lStateChar = matchedState.lightState[matchedState.lightState.index(matchedState.lightState.startIndex, offsetBy: index)]
            let isOn = lStateChar == "1"
            guard isOn else {
                print("⚠️ Light is OFF. Ignoring slider update.")
                return
            }

            let topic = matchedState.uniqueID
             let speed = self.mapSliderValueToSpeed(value: sliderValue, category: category, dimmingType: dimmingType)
            self.publish_button_to_topic(control: "L", no: index + 1, state: 1, speed: speed, topic: topic)
        }
    }


    private func mapSpeedToSliderValue(speed: Int, category: String, dimmingType: String) -> Int {
        if category == "skroman_new" && dimmingType == "zcd" {
            return Int((Double(speed) / 4.0) * 100)
        } else if category == "skroman_new" && dimmingType == "pwm" {
            return Int((Double(speed) / 8.0) * 100)
        } else if category == "skroman_old" && dimmingType == "zcd" {
            return Int((Double(speed) / 7.0) * 100)
        }
        return 0
    }
    
    private func mapSliderValueToSpeed(value: Int, category: String, dimmingType: String) -> Int {
        if category == "skroman_new" && dimmingType == "zcd" {
            return max(1, min(4, Int(ceil(Double(value) / 100 * 4))))
        } else if category == "skroman_new" && dimmingType == "pwm" {
            return max(1, min(8, Int(ceil(Double(value) / 100 * 8))))
        } else if category == "skroman_old" && dimmingType == "zcd" {
            return max(1, min(7, Int(ceil(Double(value) / 100 * 7))))
        }

        return 1
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

                    self.publish_button_to_topic(
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

                    self.publish_button_to_topic(
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
    
}











