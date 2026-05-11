//
//  DeviceListCollectionViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 25/06/25.
//

import UIKit
import SwiftKeychainWrapper
import AWSCore
import AWSIoT
import Alamofire

class DeviceListCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var cellBackgroundView: UIView!
    
    @IBOutlet weak var imageView: UIView!
    
    @IBOutlet weak var deviceImageView: UIImageView!
    
    @IBOutlet weak var deviceNameLabel: UILabel!
    
    @IBOutlet weak var faviourteButtons: UIImageView!
    
    @IBOutlet weak var childLockButton: UIImageView!
    
    @IBOutlet weak var brightnessButton: UIImageView!
    
    let sliderButton = SliderButton()
    private var curtainSlider: CurtainSliderView?
    private var simpleButton: UIButton?
    private var fanSlider: FanSlider?
    var receivedDeviceStates: [DeviceStateArray] = []
    private var dimSlider: CustomSlider?
//    private var isOn = false
    private let powerImageView = UIImageView()
    private var thumbLeadingConstraint: NSLayoutConstraint!
    private var thumbTrailingConstraint: NSLayoutConstraint!
    private var statusLabelCenterXConstraint: NSLayoutConstraint?
    private var statusLabelLeadingConstraint: NSLayoutConstraint?
    private var statusLabelTrailingConstraint: NSLayoutConstraint?
    private var currentButton: ButtonDetails?
    private var currentDeviceCategory: String?
    private var currentDeviceDimmingType: String?
    private var isSelectedState: Bool = false
    var device: Device?
    private var persistedNextState: Int?
    private var switchItem: SwitchItem?
    var onToggle: ((Bool) -> Void)?
    /// Notifies parent datasource to keep `switchList` in sync (reuse-safe).
    var onSwitchItemUpdated: ((SwitchItem) -> Void)?
    private var currentLightState: Bool?

    /// Horizontal row for favourite / child lock / brightness; hidden icons collapse so visible ones stay left-aligned in order.
    private var statusIconsStackView: UIStackView?

    private let thumbView = UIView()
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        cellBackgroundView.layer.cornerRadius = 10
        cellBackgroundView.clipsToBounds = true
        imageView.layer.cornerRadius = imageView.frame.height / 2
        imageView.clipsToBounds = true
        imageView.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        cellBackgroundView.backgroundColor = UIColor.white.withAlphaComponent(0.15)

        embedStatusIconsInStackView()

        cellBackgroundView.addSubview(controlsStackView)
        NSLayoutConstraint.activate([
            controlsStackView.topAnchor.constraint(equalTo: deviceNameLabel.bottomAnchor, constant: 10),
            controlsStackView.leadingAnchor.constraint(equalTo: cellBackgroundView.leadingAnchor, constant: 10),
            controlsStackView.trailingAnchor.constraint(equalTo: cellBackgroundView.trailingAnchor, constant: -10),
            controlsStackView.bottomAnchor.constraint(lessThanOrEqualTo: cellBackgroundView.bottomAnchor, constant: -10)
        ])
        
        let slider = CustomSlider()
        slider.translatesAutoresizingMaskIntoConstraints = false

//        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cellTapped))
//           cellBackgroundView.isUserInteractionEnabled = true
//           cellBackgroundView.addGestureRecognizer(tapGesture)
        print("receivedDeviceStates at switch \(switchItem)")
        
        
    }

    private func embedStatusIconsInStackView() {
        guard statusIconsStackView == nil,
              let fav = faviourteButtons,
              let lock = childLockButton,
              let bright = brightnessButton else { return }

        [fav, lock, bright].forEach { $0.removeFromSuperview() }

        let stack = UIStackView(arrangedSubviews: [fav, lock, bright])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .fill
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        cellBackgroundView.addSubview(stack)
        statusIconsStackView = stack

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 8),
            stack.topAnchor.constraint(equalTo: deviceNameLabel.bottomAnchor, constant: 4)
        ])
    }

//    @objc private func cellTapped() {
//
//        let generator = UIImpactFeedbackGenerator(style: .medium)
//        generator.prepare()
//        generator.impactOccurred()
//
//        print("🟢 Cell tapped for \(currentButton?.buttonName ?? "unknown")")
//
//        // Scale down animation
//        UIView.animate(withDuration: 0.15, animations: {
//            self.cellBackgroundView.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
//            self.cellBackgroundView.layer.borderWidth = 2
//            self.cellBackgroundView.layer.borderColor = UIColor.green.cgColor
//        })
//
//        // Scale back + remove border
//        UIView.animate(withDuration: 0.15, delay: 0.15, options: [.curveEaseOut], animations: {
//            self.cellBackgroundView.transform = .identity
//        }) { _ in
//            UIView.animate(withDuration: 0.2) {
//                self.cellBackgroundView.layer.borderWidth = 0
//            }
//        }
//
//       
//
//        toggleState()
//        
//    }

    func flashTapAnimation() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        // flash ON
        UIView.animate(withDuration: 0.1) {
            self.cellBackgroundView.layer.borderWidth = 2
            self.cellBackgroundView.layer.borderColor = UIColor.green.cgColor
            self.cellBackgroundView.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
        }

        // flash OFF
        UIView.animate(withDuration: 0.2, delay: 0.15, options: [.curveEaseOut]) {
            self.cellBackgroundView.layer.borderWidth = 0
            self.cellBackgroundView.transform = .identity
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()

        // Reset image
        deviceImageView.image = nil

        // Reset model refs
        switchItem = nil
        device = nil
        currentButton = nil
        persistedNextState = nil
        currentDeviceCategory = nil
        currentDeviceDimmingType = nil
        currentLightState = nil
        onSwitchItemUpdated = nil

        // Reset callbacks/state (important for reuse)
        sliderButton.onToggle = nil
        sliderButton.setState(false)

        // Remove dynamically added views
        sliderButton.removeFromSuperview()
        simpleButton?.removeFromSuperview()
        dimSlider?.removeFromSuperview()
        fanSlider?.removeFromSuperview()
        curtainSlider?.removeFromSuperview()

        simpleButton = nil
        dimSlider = nil
        fanSlider = nil
        curtainSlider = nil
        
        cellBackgroundView.layer.borderWidth = 0
            cellBackgroundView.layer.borderColor = UIColor.clear.cgColor
            cellBackgroundView.transform = .identity
    }

    private let controlsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
   
    
    private var isProcessingTap = false
        @objc private func toggleState() {
            guard var item = switchItem else { return }
            guard !isProcessingTap else { return }
               isProcessingTap = true

               DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                   self.isProcessingTap = false
               }
            let newState = item.isOnState == 1 ? 0 : 1
            item.isOnState = newState
            self.switchItem = item
            // Keep parent list in sync so reuse/reload cannot leak state.
            onSwitchItemUpdated?(item)
            let isOn = (item.isOnState == 1)
            if let button = simpleButton {
                if isOn {
                    button.layer.borderWidth = 2
                    button.layer.borderColor = UIColor.green.cgColor
                    button.layer.shadowColor = UIColor.green.cgColor
                    button.layer.shadowRadius = 4
                    button.layer.shadowOpacity = 0.8
                    button.layer.shadowOffset = .zero
                } else {
                    button.layer.borderWidth = 0
                    button.layer.shadowOpacity = 0
                }
            }
            
            if let button = simpleButton {
                updatePowerButtonUI(button: button, isOn: isOn)
            }
            sliderButton.setState(isOn)
            updateSliderState(isEnabled: isOn)
            
            guard let switchItem = switchItem,
                  let buttonDetail = switchItem.buttonDetail else { return }

            switch buttonDetail.buttonControlName {
            case "L":
                if switchItem.configDim == "1" {
                  
                    setupDimLightToggle()
                } else {
                    
                    var updatedItem = switchItem
                    updatedItem.isOnState = isOn ? 1 : 0
                    self.onSwitchItemUpdated?(updatedItem)

                    publish_button_to_topic(
                        control: "L",
                        no: updatedItem.switchIndex,
                        state: updatedItem.isOnState,
                        speed: 0,
                        topic: updatedItem.uniqueID
                    )

                    self.switchItem = updatedItem
                }
            case "A":
                presentACPopup()
                
            case "F":
              
                var updatedItem = switchItem
                updatedItem.isOnState = isOn ? 1 : 0
                self.onSwitchItemUpdated?(updatedItem)

                let currentSpeed = Int(updatedItem.speed ?? "0") ?? 0
                publish_button_to_topic(
                    control: "F",
                    no: updatedItem.fanDest ?? updatedItem.switchIndex,
                    state: updatedItem.isOnState,
                    speed: currentSpeed,
                    topic: updatedItem.uniqueID
                )

                self.switchItem = updatedItem

            case "O", "Q", "C", "Y":
                setupCurtainSlider()
                
            default:
                break
            }
        }
    private func parentViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while responder != nil {
            responder = responder?.next
            if let vc = responder as? UIViewController {
                return vc
            }
        }
        return nil
    }

    private func presentACPopup() {
        guard let vc = parentViewController(),
              let switchItem = switchItem,
              let device = device else { return }

        let acVC = ACPopupViewController()
        acVC.modalPresentationStyle = .overCurrentContext
        acVC.modalTransitionStyle = .crossDissolve

        acVC.onACValueChanged = { [weak self] temp, fan, swing, which, state in
            guard let self = self else { return }

            print("📥 AC → Temp:", temp, "Fan:", fan, "Swing:", swing, "Which:", which, "State:", state)

            self.publish_ac_to_topic_temp(
                no: switchItem.buttonDetail?.buttonNo ?? switchItem.switchIndex,
                state: state,
                topic: device.uniqueId,
                tempr: temp,
                fan: fan,
                which: which,
                swing: swing
            )
        }


        

        vc.present(acVC, animated: true)
    }



    private func updatePowerButtonUI(button: UIButton, isOn: Bool) {
        if isOn {
            button.layer.borderWidth = 2
            button.layer.borderColor = UIColor.green.cgColor
            button.layer.shadowColor = UIColor.green.cgColor
            button.layer.shadowRadius = 4
            button.layer.shadowOpacity = 0.8
            button.layer.shadowOffset = .zero
        } else {
            button.layer.borderWidth = 0
            button.layer.shadowOpacity = 0
        }
    }

    func performToggle() {
        toggleState()
    }
    
    func toggleSelection() {
            isSelectedState.toggle()
            
        }

        func resetSelection() {
            isSelectedState = false
             
        }
    
    
    private func cleanupControls() {

        // remove dynamic controls
        sliderButton.removeFromSuperview()
        sliderButton.onToggle = nil
        curtainSlider?.removeFromSuperview()
        simpleButton?.removeFromSuperview()
        fanSlider?.removeFromSuperview()
        dimSlider?.removeFromSuperview()

        // reset refs
        curtainSlider = nil
        simpleButton = nil
        fanSlider = nil
        dimSlider = nil

        // 🔥 EXTRA SAFETY: remove any unknown leftover views
        for view in contentView.subviews {
            if view is CurtainSliderView ||
               view is FanSlider ||
               view is CustomSlider ||
               view is UIButton {
                view.removeFromSuperview()
            }
        }
    }
    func configure(with switchItem: SwitchItem, device: Device, nextState: Int?) {
        cleanupControls()
        self.switchItem = switchItem
        self.device = device
        self.persistedNextState = nextState
        
        deviceNameLabel.text = switchItem.buttonDetail?.buttonName ?? switchItem.name
        self.currentButton = switchItem.buttonDetail
         
        updateUI()
    }
    
    
    private func setupLightPowerWithDimmer() {

        guard let switchItem = switchItem else { return }
        let isOn = (switchItem.isOnState == 1)   // ✅ derive here

        if simpleButton == nil {
            createPowerButton()
        }

        if dimSlider == nil {
            createDimSlider()
        }

        // ✅ use local derived state
        updatePowerButtonUI(button: simpleButton!, isOn: isOn)

        if let device = device,
           let speedChar = switchItem.speed?.first,
           let speed = Int(String(speedChar)) {

            let sliderValue = mapSpeedToSliderValue(
                speed: speed,
                category: device.deviceCategory,
                dimmingType: device.deviceDimmingType
            )

            dimSlider?.currentValue = sliderValue
        }

        updateSliderState(isEnabled: isOn)
    }
    
    
    private func createDimSlider() {
        let slider = CustomSlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(slider)
        dimSlider = slider

        NSLayoutConstraint.activate([
            slider.widthAnchor.constraint(equalToConstant: 90),
            slider.heightAnchor.constraint(equalToConstant: 30),
            slider.leadingAnchor.constraint(equalTo: simpleButton!.trailingAnchor, constant: 20),
            slider.centerYAnchor.constraint(equalTo: simpleButton!.centerYAnchor)
        ])

        slider.onValueChangeEnded = { [weak self] newValue in
            guard let self = self,
                  let switchItem = self.switchItem,
                  let device = self.device,
                  switchItem.isOnState == 1 else { return }

            let mappedSpeed = self.mapSliderValueToSpeed(
                value: newValue,
                category: device.deviceCategory,
                dimmingType: device.deviceDimmingType
            )

            self.publish_button_to_topic(
                control: "",
                no: switchItem.switchIndex,
                state: 1,
                speed: mappedSpeed,
                topic: device.uniqueId
            )
        }
    }

    private func createPowerButton() {
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
    }
    
    
    private func setupFanControls() {
        guard let switchItem = switchItem else { return }

      
        if simpleButton == nil {
            createFanPowerButton()
        }

        if fanSlider == nil {
            createFanSlider()
        }


        updateFanUI(for: switchItem, powerButton: simpleButton!, slider: fanSlider)
    }
    
    private func createFanPowerButton() {
        let powerButton = UIButton(type: .system)
        powerButton.translatesAutoresizingMaskIntoConstraints = false
        powerButton.tintColor = .green
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
    }
    
    private func createFanSlider() {
        let slider = FanSlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(slider)
        fanSlider = slider

        NSLayoutConstraint.activate([
            slider.widthAnchor.constraint(equalToConstant: 90),
            slider.heightAnchor.constraint(equalToConstant: 30),
            slider.leadingAnchor.constraint(equalTo: simpleButton!.trailingAnchor, constant: 20),
            slider.centerYAnchor.constraint(equalTo: simpleButton!.centerYAnchor)
        ])

        slider.onSliderReleased = { [weak self] value in
            guard let self = self,
                  let btnNumber = self.switchItem?.switchIndex,
                  let topic = self.switchItem?.uniqueID,
                  self.switchItem?.isOnState == 1 else { return }

            self.publish_button_to_topic(
                control: "F",
                no: btnNumber,
                state: self.switchItem!.isOnState,
                speed: value,
                topic: topic
            )
        }
    }
    private func updateUI() {
        guard let switchItem = switchItem else { return }

        let isCurtain = (switchItem.name == "Curtain")

       
        faviourteButtons.isHidden = true
        brightnessButton.isHidden = true
        childLockButton.isHidden = true

        // ✅ Update image first
        updateDeviceImage()

        // ===============================
        // ✅ CURTAIN (Handled separately)
        // ===============================
        if isCurtain {
            setupCurtainSlider()
            return
        }

        // ===============================
        // ✅ NORMAL ICON VISIBILITY
        // ===============================
        if switchItem.buttonDetail?.isFavourite == 1 {
            faviourteButtons.isHidden = false
            faviourteButtons.image = UIImage(named: "isFaviourte")
        }

        if switchItem.configDim == "1" {
            brightnessButton.isHidden = false
            brightnessButton.image = UIImage(named: "brightness-2")
        }

        if switchItem.isChildLocked == 1 {
            childLockButton.isHidden = false
            childLockButton.image = UIImage(named: "childLock")
        }

        // ===============================
        // ✅ CONTROL TYPE DETECTION
        // ===============================
        let controlName: String = {
            if let name = switchItem.buttonDetail?.buttonControlName {
                return name
            }
            switch switchItem.type {
            case .fan: return "F"
            case .ac: return "A"
            default: return "L"
            }
        }()

        // ===============================
        // ✅ UI SETUP BASED ON TYPE
        // ===============================
        switch controlName {

        case "L", "A":
            if switchItem.configDim == "1" {
                setupLightPowerWithDimmer()
            } else {
                setupLightSlider()
                setupLightToggle()
            }

        case "F":
            setupFanControls()

        case "R":
            setupFanRegulatorToggle()
            setupLightSlider()

        default:
            break
        }
    }

    // MARK: - Individual UI setups

    private func updateDeviceImage() {

        guard let switchItem = switchItem else { return }

        let controlName = switchItem.buttonDetail?.buttonControlName ?? {
            switch switchItem.type {
            case .fan: return "F"
            case .ac: return "A"
            default: return "L"
            }
        }()

        let iconName = switchItem.buttonDetail?.buttonIconName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

      
        if let iconName = iconName,
           !iconName.isEmpty,
           iconName != "null",
           iconName != "unknown",
           let customImage = UIImage(named: iconName) {

            deviceImageView.image = customImage
            return
        }

        // 🔥 CASE 2: Fallback defaults
        switch controlName {

        case "F":
            deviceImageView.image = UIImage(named: "Fan1")

        case "L":
            deviceImageView.image = UIImage(named: "bulb")

        case "A":
            deviceImageView.image = UIImage(named: "ac_2")

        case "O", "Q", "C", "Y":
            deviceImageView.image = UIImage(named: "curtains_Open")

        case "R":
            deviceImageView.image = UIImage(named: "Fan1")

        default:
            deviceImageView.image = UIImage(named: "Group-2")
        }
    }


    private func setupLightSlider() {
        guard let switchItem = switchItem else { return }

        let isOn = (switchItem.isOnState == 1)   // ✅ derive state

        contentView.addSubview(sliderButton)
        sliderButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            sliderButton.widthAnchor.constraint(equalToConstant: 60),
            sliderButton.heightAnchor.constraint(equalToConstant: 30),
            sliderButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            sliderButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])

        sliderButton.setState(isOn)   // ✅ correct
    }

    private func updateSliderState(isEnabled: Bool) {
        dimSlider?.isUserInteractionEnabled = isEnabled
        dimSlider?.alpha = isEnabled ? 1.0 : 0.4
        dimSlider?.setEnabled(isEnabled)
    }


    private func setupCurtainSlider() {
        guard let switchItem = switchItem,
              let device = device else { return }
        if curtainSlider != nil { return }
        curtainSlider = CurtainSliderView()
        curtainSlider!.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(curtainSlider!)

        NSLayoutConstraint.activate([
            curtainSlider!.widthAnchor.constraint(equalToConstant: 120),
            curtainSlider!.heightAnchor.constraint(equalToConstant: 34),
            curtainSlider!.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            curtainSlider!.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])

        let openButtonNo = switchItem.switchIndex
        let closeButtonNo = switchItem.switchIndex + 1

        curtainSlider?.updateThumbState(
            for: "Curtain",
            isOn: switchItem.isOnState == 1,
            nextValueIsOn: switchItem.nextState == 1
        )

        // 🟢 LEFT TAP → OPEN
        curtainSlider?.onLeftTap = { [weak self] in
            guard let self = self else { return }

            print("📤 Curtain OPEN → button:", openButtonNo)

            self.publish_button_to_topic(
                control: "L",
                no: openButtonNo,
                state: 1,
                speed: 0,
                topic: device.uniqueId
            )
        }

        // 🔴 RIGHT TAP → CLOSE
        curtainSlider?.onRightTap = { [weak self] in
            guard let self = self else { return }

            print("📤 Curtain CLOSE → button:", closeButtonNo)

            self.publish_button_to_topic(
                control: "L",
                no: closeButtonNo,
                state: 1,
                speed: 0,
                topic: device.uniqueId
            )
        }
    }



   
    private func updateFanUI(for switchItem: SwitchItem, powerButton: UIButton, slider: FanSlider?) {
        guard let button = switchItem.buttonDetail else {
            print("❌ No button detail for \(switchItem.name)")
            slider?.setEnabled(false)
            return
        }

      
        let isOn = (switchItem.isOnState == 1)

        // 🔹 Update power button UI
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

        
        if let slider = slider {
            slider.setEnabled(isOn)
            if let speedStr = switchItem.speed, let speed = Int(speedStr) {
                slider.currentValue = speed
            } else {
                slider.currentValue = 0
            }
        }
       
        
    }
   

    func setupLightToggle() {

        // 🔥 Clear old callback (cell reuse safety)
        sliderButton.onToggle = nil

        guard let item = switchItem,
              let device = device,
              let detail = item.buttonDetail,
              ["L", "A"].contains(detail.buttonControlName),
              item.configDim == "0" else { return }

        let control = detail.buttonControlName
        let buttonNo = detail.buttonNo        // ✅ real hardware button
        let isOn = item.isOnState == 1

        // Set initial UI state
        sliderButton.setState(isOn)

        // Toggle callback
        sliderButton.onToggle = { [weak self] newState in
            guard let self = self else { return }

            print("💡 \(control) toggled to:", newState, "button:", buttonNo)

            self.switchItem?.isOnState = newState ? 1 : 0
            if let updated = self.switchItem {
                self.onSwitchItemUpdated?(updated)
            }

            if control == "A" {
                _ = self.publish_ac_to_topic(
                        no: buttonNo,
                     state: newState ? 1 : 0,
                    topic: device.uniqueId
                )

            } else {
                self.publish_button_to_topic(
                    control: "L",
                    no: buttonNo,
                    state: newState ? 1 : 0,
                    speed: 0,
                    topic: device.uniqueId
                )
            }
        }
    }

    
    func setupFanRegulatorToggle() {
        guard let switchItem = switchItem,
              let device = device,
              let buttonDetail = switchItem.buttonDetail else { return }

        guard buttonDetail.buttonControlName == "R",
              switchItem.configDim == "0" else { return }

        let regulator = switchItem.rRegulator ?? ""
        print("manual switch \(regulator)")

        let onState = switchItem.isOnState == 1
        sliderButton.setState(onState)

        sliderButton.onToggle = { [weak self] newState in
            guard let self = self else { return }
            
            let buttonNumber = switchItem.switchIndex
            let index = buttonNumber - 1

            print("manual switch at \(switchItem)")

            // ensure regulator index exists
            if regulator.count > index {
                let char = regulator[regulator.index(regulator.startIndex, offsetBy: index)]

                print("Regulator bit =", char)

                // ❗ Your condition:
                
                if char == "1" {
                    print("operate manually. please do not publish payload")

                    self.showAlert(
                        title: "warning",
                        message: "Please turn on fan using regulator manually."
                    )

                    // revert the UI toggle
                    self.sliderButton.setState(!newState)
                    return
                }

            }

            
            print("publish payload...")

            self.switchItem?.isOnState = newState ? 1 : 0
            if let updated = self.switchItem {
                self.onSwitchItemUpdated?(updated)
            }

            self.publish_button_to_topic(
                control: "L",
                no: buttonNumber,
                state: newState ? 1 : 0,
                speed: 0,
                topic: device.uniqueId
            )
        }
    }
    
    
    func publishACPayload(
        no: Int,
        speed: Int,
        temperature: Int,
        swing: Int,
        state: Int,
        which: Int,
        topic: String
    ) {

        let parameters: [String: Any] = [
            "control": "A",
            "no": no,
            "speed": speed,
            "swing": swing,
            "tempr": temperature,
            "state": state,
            "which": which,
            "from": "A",
            "topic": topic
        ]

        print("📤 AC Payload:", parameters)

        if let jsonData = try? JSONSerialization.data(withJSONObject: parameters),
           let jsonString = String(data: jsonData, encoding: .utf8) {

            let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)

            iotDataManager.publishString(
                jsonString,
                onTopic: topic + "/HA/A/req",
                qoS: .messageDeliveryAttemptedAtMostOnce
            )
        }
    }
    
    func showAlert(title: String, message: String) {
        guard let vc = self.parentViewController else {
            print("❗ No parent view controller found to present alert")
            return
        }
        
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        vc.present(alert, animated: true)
    }


    func setupDimLightToggle() {
        guard let switchItem = switchItem,
              let device = device,
              let buttonDetail = switchItem.buttonDetail,
              buttonDetail.buttonControlName == "L",
              switchItem.configDim == "1" else { return }

        // ✅ derive state from model
        let isOn = (switchItem.isOnState == 1)

        sliderButton.setState(isOn)

        print("💡 Light toggled to:", isOn)

        let dimSpeed: Int = Int(switchItem.speed ?? "0") ?? 0
        let buttonNumber = switchItem.switchIndex ?? 0

        publish_button_to_topic(
            control: buttonDetail.buttonControlName,
            no: buttonNumber,
            state: isOn ? 1 : 0,
            speed: dimSpeed,
            topic: device.uniqueId ?? ""
        )

        // 🔥 VERY IMPORTANT: avoid reuse bug
        sliderButton.onToggle = nil

        sliderButton.onToggle = { [weak self] newState in
            guard let self = self else { return }

            print("💡 Light toggled via slider:", newState)

            // ✅ update model
            self.switchItem?.isOnState = newState ? 1 : 0
            if let updated = self.switchItem {
                self.onSwitchItemUpdated?(updated)
            }

            let dimSpeed: Int = Int(self.switchItem?.speed ?? "0") ?? 0
            let buttonNumber = self.switchItem?.switchIndex ?? 0

            self.publish_button_to_topic(
                control: buttonDetail.buttonControlName,
                no: buttonNumber,
                state: newState ? 1 : 0,
                speed: dimSpeed,
                topic: device.uniqueId ?? ""
            )
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

    
    
    func publish_ac_to_topic(no: Int, state: Int, topic: String, ) {
        
        let parameters: [String: Any] = [
            "control": "A",
            "no": no,
            "speed": 1,
            "swing": 1,
            "tempr": 24,
            "state": state,
            "which": 1,
            "from": "A",
            "topic": topic
        ]
        
        print("📤 Publishing to \(topic)/HA/A/req: \(parameters)")
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: parameters),
              let jsonString = String(data: jsonData, encoding: .utf8)  {
                  
                  let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
                  iotDataManager.publishString(jsonString,onTopic: topic + "/HA/A/req",qoS: .messageDeliveryAttemptedAtMostOnce)
              }
    }
  
    func publish_ac_to_topic_temp(no: Int, state: Int, topic: String, tempr: Int, fan : Int, which: Int, swing :Int) {
        
        let parameters: [String: Any] = [
            "control": "A",
            "no": no,
            "speed": fan,
            "swing": swing,
            "tempr": tempr,
            "state": state,
            "which": which,
            "from": "A",
            "topic": topic
        ]
        
        print("📤 Publishing to \(topic)/HA/A/req: \(parameters)")
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: parameters),
              let jsonString = String(data: jsonData, encoding: .utf8)  {
                  
                  let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
                  iotDataManager.publishString(jsonString,onTopic: topic + "/HA/A/req",qoS: .messageDeliveryAttemptedAtMostOnce)
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
   
    
}
   

extension UIView {
    var parentViewController: UIViewController? {
        var responder: UIResponder? = self
        while responder != nil {
            if let vc = responder as? UIViewController {
                return vc
            }
            responder = responder?.next
        }
        return nil
    }
}
