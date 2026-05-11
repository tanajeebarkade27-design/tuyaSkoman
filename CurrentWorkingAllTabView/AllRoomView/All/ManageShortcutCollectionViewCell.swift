//
//  ManageShortcutCollectionViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 06/08/25.
//

import UIKit

class ManageShortcutCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var cellbackgroundView: UIView!
    
    @IBOutlet weak var imageBackgroundView: UIView!
    
    @IBOutlet weak var deviceImageView: UIImageView!
    
    @IBOutlet weak var buttonNamelabel: UILabel!
    
    @IBOutlet weak var isSelectedImage: UIImageView!
    private(set) var selectedServerIds: [String] = []

    
    var receivedDeviceStates: [DeviceStateArray] = []
    let sliderButton = SliderButton()
    private var curtainSlider: CurtainSliderView?
    private var simpleButton: UIButton?
    private var fanSlider: FanSlider?
    var onSelectionChanged: ((Set<String>) -> Void)?
    var selectedIndexbutton: Int?
    private var buttonId: String = "" 
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
    private var isSelectedState: Bool = false
    private var deviceServerId: String = ""
    var selectedCell:Int?
    var onToggle: ((String, String, Bool) -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        cellbackgroundView.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        cellbackgroundView.clipsToBounds =  true
        print("selectedCell\(selectedIndexbutton)")
        cellbackgroundView.cornerRadius =  15
        imageBackgroundView.backgroundColor = UIColor.white.withAlphaComponent(0.10)
        imageBackgroundView.clipsToBounds =  true
        
        imageBackgroundView.layer.cornerRadius = imageBackgroundView.frame.height / 2
        cellbackgroundView.addSubview(controlsStackView)

        NSLayoutConstraint.activate([
            controlsStackView.topAnchor.constraint(equalTo: buttonNamelabel.bottomAnchor, constant: 10),
            controlsStackView.leadingAnchor.constraint(equalTo: cellbackgroundView.leadingAnchor, constant: 10),
            controlsStackView.trailingAnchor.constraint(equalTo: cellbackgroundView.trailingAnchor, constant: -10),
            controlsStackView.bottomAnchor.constraint(lessThanOrEqualTo: cellbackgroundView.bottomAnchor, constant: -10)
        ])
        isSelectedImage.isHidden = !isSelected
        
        isSelectedImage.isHidden = true
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleCellTap))
                contentView.addGestureRecognizer(tap)
        
    }
    @objc private func handleCellTap() {
        // Toggle selection state
        let newSelected = isSelectedImage.isHidden
        isSelectedImage.isHidden = !newSelected
        isSelectedState = newSelected // Keep track internally

        if newSelected {
            // Add deviceServerId if not already in array
            if !selectedServerIds.contains(deviceServerId) {
                selectedServerIds.append(deviceServerId)
            }
        } else {
            // Remove deviceServerId if it exists
            if let index = selectedServerIds.firstIndex(of: deviceServerId) {
                selectedServerIds.remove(at: index)
            }
        }

      
        onToggle?(buttonId, deviceServerId, newSelected)

        print("✅ Selected server IDs after tap: \(selectedServerIds)")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        
        // reset selection visuals
        isSelectedState = false
        isSelectedImage.isHidden = true
        selectedServerIds.removeAll()

        // clean dynamic subviews if needed
        simpleButton?.removeFromSuperview()
        simpleButton = nil
        dimSlider?.removeFromSuperview()
        dimSlider = nil
        fanSlider?.removeFromSuperview()
        fanSlider = nil
        curtainSlider?.removeFromSuperview()
        curtainSlider = nil
    }

    func configure(with switchItem: SwitchItem, device: Device) {
        buttonId = switchItem.buttonDetail?.buttonId ?? ""
        deviceServerId = switchItem.buttonDetail?.deviceServerId ?? ""

        buttonNamelabel.text = switchItem.buttonDetail?.buttonName
        if let iconName = switchItem.buttonDetail?.buttonIconName,
           iconName != "Unknown",
           let image = UIImage(named: iconName) {

            deviceImageView.image = image

        } else {
            // Fallback based on control type
            switch switchItem.buttonDetail?.buttonControlName {
            case "L":
                deviceImageView.image = UIImage(named: "bulb")
            case "F":
                deviceImageView.image = UIImage(named: "Fan1")
            case "O", "C", "Q", "Y":
                deviceImageView.image = UIImage(named: "curtains_Open")
            default:
                deviceImageView.image = UIImage(named: "bulb")
            }
        }

        isSelectedImage.isHidden = (switchItem.buttonDetail?.isShortcut != 1)

        let isPreselected = (switchItem.buttonDetail?.isShortcut == 1)
        
        guard let controlName = switchItem.buttonDetail?.buttonControlName else { return }

        switch (controlName, switchItem.configDim) {

      
        case ("L", "0"):
            contentView.addSubview(sliderButton)
            sliderButton.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                sliderButton.widthAnchor.constraint(equalToConstant: 60),
                sliderButton.heightAnchor.constraint(equalToConstant: 30),
                sliderButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
                sliderButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
            ])
            let isLightOn = switchItem.isOnState == 1
            sliderButton.setState(isLightOn)

        // MARK: - Dimmable Light
        case ("L", "1"):
            // 👉 Power button
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

            // ✅ Initial power state from model
            isOn = (switchItem.isOnState == 1)
            updatePowerButtonUI(button: powerButton, isOn: isOn)

            // 👉 Slider
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

            if let speedChar = switchItem.speed?.first,
               let speed = Int(String(speedChar)) {
                let sliderValue = mapSpeedToSliderValue(
                    speed: speed,
                    category: device.deviceCategory,
                    dimmingType: device.deviceDimmingType
                )
                slider.currentValue = min(100, max(0, sliderValue))
                slider.setEnabled(isOn)
            } else {
                slider.currentValue = 0
                slider.setEnabled(false)
            }
        case ("O", "0"), ("C", "0"), ("Q", "0"), ("Y", "0"):
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

            // 👉 State tracking
            var isOpen = false
            var isClosed = false
            
            

            switch controlName {
            case "C", "Y":
                isClosed = switchItem.isOnState == 1
            case "O", "Q":
                isOpen = switchItem.isOnState == 1
                
                
                
            default:
                break
            }



            print("🌐 Curtain update — UID: \(device.uniqueId), isOpen: \(isOpen), isClosed: \(isClosed)")
            curtainSlider?.updateThumbState(
                for: "Curtain",
                isOn: isOpen,
                nextValueIsOn: isClosed
            )

        case ("F", _):
            // Power button
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

            // Fan slider
            let slider = FanSlider()
            slider.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(slider)
            fanSlider = slider

            NSLayoutConstraint.activate([
                slider.widthAnchor.constraint(equalToConstant: 90),
                slider.heightAnchor.constraint(equalToConstant: 30),
                slider.leadingAnchor.constraint(equalTo: powerButton.trailingAnchor, constant: 20),
                slider.centerYAnchor.constraint(equalTo: powerButton.centerYAnchor)
            ])

            // Update both power button and slider state
            updateFanUI(for: switchItem, powerButton: powerButton, slider: slider)
        case ("A", "0"):
            contentView.addSubview(sliderButton)
            sliderButton.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                sliderButton.widthAnchor.constraint(equalToConstant: 60),
                sliderButton.heightAnchor.constraint(equalToConstant: 30),
                sliderButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
                sliderButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
            ])

            let isACOn = switchItem.isOnState == 1
            sliderButton.setState(isACOn)

        default:
            break
        }
    }

    private func updateFanUI(for switchItem: SwitchItem, powerButton: UIButton, slider: FanSlider?) {
        guard let button = switchItem.buttonDetail else {
            print("❌ No button detail for \(switchItem.name)")
            slider?.setEnabled(false)
            return
        }

        // 🔹 Power state from switchItem
        let isOn = (switchItem.isOnState == 1)

        // 🔹 Update power button UI
        if isOn {
            powerButton.layer.borderWidth = 2
            powerButton.layer.borderColor = UIColor.systemBlue.cgColor
            powerButton.layer.shadowColor = UIColor.systemBlue.cgColor
            powerButton.layer.shadowRadius = 4
            powerButton.layer.shadowOpacity = 0.8
            powerButton.layer.shadowOffset = .zero
        } else {
            powerButton.layer.borderWidth = 0
            powerButton.layer.shadowOpacity = 0
        }

        // 🔹 Update slider with speed
        if let slider = slider {
            slider.setEnabled(isOn)
            if let speedStr = switchItem.speed, let speed = Int(speedStr) {
                slider.currentValue = speed
            } else {
                slider.currentValue = 0
            }
        }
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

    func toggleSelection() {
            isSelectedState.toggle()
            isSelectedImage.isHidden = !isSelectedState
        }

        func resetSelection() {
            isSelectedState = false
            isSelectedImage.isHidden = true
        }
    @objc private func toggleState() {
        isOn.toggle()
        
        // Update button UI
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
    }
    
    private let controlsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

   
   

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
    
   
       
    

}


