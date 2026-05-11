//
//  FavouriteButtonCollectionViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 04/06/25.
//

import UIKit

class FavouriteButtonCollectionViewCell: UICollectionViewCell {
    weak var delegate: FavouriteButtonCellDelegate?

    @IBOutlet weak var roomname: UILabel!
    @IBOutlet weak var deviceImageView: UIImageView!
    @IBOutlet weak var imageview: UIView!
    @IBOutlet weak var cellbackgroundview: UIView!
    @IBOutlet weak var buttonName: UILabel!
    var isSelectedFlag: Int = 1
    @IBOutlet weak var isShortcutSelect: UIView!
    
    @IBOutlet weak var isshortcutImage: UIImageView!
    
    @IBOutlet weak var isSelectdButton: UIButton!
    let sliderButton = SliderButton()
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
    private var isMarkedOk = false
    var isShortcutSelected: Bool = false

    override func awakeFromNib() {
        super.awakeFromNib()
        isShortcutSelect.isHidden =  true
        cellbackgroundview.layer.cornerRadius = 10
        cellbackgroundview.clipsToBounds = true
        imageview.layer.cornerRadius = imageview.frame.height / 2
        imageview.clipsToBounds = true
        imageview.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        cellbackgroundview.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        deviceImageView.tintColor =  .white
        imageview.layer.cornerRadius = imageview.frame.height / 2
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDeviceImageTap))
        cellbackgroundview.isUserInteractionEnabled = true
        cellbackgroundview.addGestureRecognizer(tapGesture)
        isShortcutSelect.layer.cornerRadius = isShortcutSelect.frame.height / 2
    }
    
 
    @objc private func handleDeviceImageTap() {
        delegate?.didToggleShortcutSelection(cell: self)
    }

    

    @objc private func toggleState() {
        isOn.toggle()
        
        if let button = simpleButton {
            if isOn {
                button.layer.borderWidth = 2
                button.layer.borderColor = UIColor.systemBlue.cgColor
                button.layer.shadowColor = UIColor.systemBlue.cgColor
                button.layer.shadowRadius = 4
                button.layer.shadowOpacity = 0.8
                button.layer.shadowOffset = .zero
            } else {
                button.layer.borderWidth = 0
                button.layer.shadowOpacity = 0
            }
        }
    }
    private func setDeviceImage(for button: ButtonDetails) {
        
        let rawName = button.buttonIconName ?? ""
        
        // ✅ Clean string from DB
        let iconName = rawName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        
        let control = button.buttonControlName.uppercased()
        
        var image: UIImage?

        // ✅ Handle invalid DB values
        if iconName.isEmpty || iconName == "null" || iconName == "unknown" {
            
            switch control {
            case "F":
                image = UIImage(named: "Fan1")
            case "L":
                image = UIImage(named: "Group-2")
            case "O", "Q":
                image = UIImage(named: "curtain-filled")
            default:
                image = UIImage(named: "Group-2") // make sure exists
            }
            
        } else {
            image = UIImage(named: rawName.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        // ✅ Final fallback
        if image == nil {
            print("❌ Image NOT found for:", rawName)
            image = UIImage(named: "default_icon")
        }

        deviceImageView.image = image
        deviceImageView.contentMode = .scaleAspectFit
    }
    
    func configure(with button: ButtonDetails, device: Device? = nil, deviceState: DeviceState?) {
        buttonName.text = button.buttonName
        roomname.text = button.roomName
       
        setDeviceImage(for: button)
        print("📟 Device UniqueId: \(button.uniqueId)")
        print("🔢 Button No: \(button.buttonNo)")

        var buttonState: Character?

        if let state = deviceState {
            print("✅ Got DeviceState for \(button.buttonName):")
            print("🔹 UniqueId: \(state.uniqueId)")
            print("🔹 configButtons: \(state.configButtons)")
            print("🔹 lState: \(state.lState)")
            print("🔹 fState: \(state.fState)")

            let controlChar = Character(button.buttonControlName)
            let usesLState = ["O", "L", "C", "Q", "Y"]

            // 🔍 Find the Nth occurrence of the control type in configButtons
            var matchCount = 0
            var matchedIndex: Int?

            for (i, char) in state.configButtons.enumerated() {
                if char == controlChar {
                    matchCount += 1
                    if matchCount == button.buttonNo {
                        matchedIndex = i
                        break
                    }
                }
            }

            if let offset = matchedIndex {
                if usesLState.contains(button.buttonControlName) {
                    if offset < state.lState.count {
                        buttonState = state.lState[state.lState.index(state.lState.startIndex, offsetBy: offset)]
                        print("💡 lState[\(offset)] (Button No: \(button.buttonNo)) = \(buttonState!) → \(buttonState == "1" ? "ON" : "OFF") dimm  state \(state.configDim)")
                    } else {
                        print("❌ Offset \(offset) out of bounds in lState \(state.lState)")
                    }
                } else if controlChar == "F" {
                    if offset < state.fState.count {
                        buttonState = state.fState[state.fState.index(state.fState.startIndex, offsetBy: offset)]
                        print("🌪️ fState[\(offset)] (Button No: \(button.buttonNo)) = \(buttonState!) → \(buttonState == "1" ? "ON" : "OFF") ")
                    } else {
                        print("❌ Offset \(offset) out of bounds in fState \(state.fState)")
                    }
                }
            } else {
                print("❌ Could not find \(controlChar) for Button No \(button.buttonNo) in configButtons: \(state.configButtons) d ")
            }

        } else {
            print("⚠️ No device state found for this button.")
        }

        // 🔄 Reset UI
        sliderButton.removeFromSuperview()
        fanSlider?.removeFromSuperview()
        curtainSlider?.removeFromSuperview()

        // 🎛️ Setup controls
        let controlType = button.buttonControlName
        switch controlType {
        case "L":
            if let state = deviceState {
                let controlChar = Character(button.buttonControlName)
                var matchCount = 0
                var matchedIndex: Int?

                for (i, char) in state.configButtons.enumerated() {
                    if char == controlChar {
                        matchCount += 1
                        if matchCount == button.buttonNo {
                            matchedIndex = i
                            break
                        }
                    }
                }

                if let offset = matchedIndex {
                    if offset < state.configDim.count {
                        let cDimChar = state.configDim[state.configDim.index(state.configDim.startIndex, offsetBy: offset)]
                        if cDimChar == "1" {
                            print("💡 Dimmable light detected at config index \(offset)")
                            setupDimmableLightControl(
                                with: button,
                                category: button.buttonControlName,
                                dimmingType: device?.deviceDimmingType ?? ""
                            )
                        } else {
                            setupLightControl(with: button, deviceState: state)
                        }
                    } else {
                        print("⚠️ configDim index \(offset) out of bounds: \(state.configDim)")
                        setupLightControl(with: button, deviceState: state)
                    }
                } else {
                    print("❌ Could not find \(controlChar) for Button No \(button.buttonNo) in configButtons")
                    setupLightControl(with: button, deviceState: state)
                }
            } else {
                setupLightControl(with: button, deviceState: nil)
            }



            case "F":
                setupFanControl(with: button)

            case "O", "Q":
                setupCurtainControl(with: button)
                print("🪟 Curtain/Other skipped for now")
            

            case "C", "Y":
                print("⏭ Skipping curtain slave: \(button.buttonName)")
                //filterCurtainButtons(filterCurtainButtons(button, from: deviceState))

            default:
                print("ℹ️ Unknown control type: \(controlType)")
        }

        // ✅ Optionally update UI based on `buttonState`
        if let s = buttonState {
            if s == "1" {
                print("✅ \(button.buttonName) (Button No: \(button.buttonNo)) is ON")
            } else {
                print("❎ \(button.buttonName) (Button No: \(button.buttonNo)) is OFF")
            }
        }
    }



    
    private func setupLightControl(with button: ButtonDetails, deviceState: DeviceState?) {
        contentView.addSubview(sliderButton)
        sliderButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            sliderButton.widthAnchor.constraint(equalToConstant: 60),
            sliderButton.heightAnchor.constraint(equalToConstant: 30),
            sliderButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            sliderButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])

        guard let matchedState = deviceState else {
            sliderButton.setState(false)
            return
        }

        let usesLState: Set<Character> = ["O", "L", "C", "Q", "Y"]
        let buttonIndex = button.buttonNo - 1

        guard buttonIndex >= 0, buttonIndex < matchedState.configButtons.count else {
            sliderButton.setState(false)
            return
        }

        // Step 1: Count matching control types before this button
        let prefix = matchedState.configButtons.prefix(button.buttonNo)
        let lStateIndex = prefix.filter { usesLState.contains($0) }.count - 1

        guard lStateIndex >= 0, lStateIndex < matchedState.lState.count else {
            sliderButton.setState(false)
            return
        }

        let lStateChar = matchedState.lState[matchedState.lState.index(matchedState.lState.startIndex, offsetBy: lStateIndex)]
        let isLightOn = lStateChar == "1"

        sliderButton.setState(isLightOn)
        sliderButton.isHidden = false

        sliderButton.onToggle = { isOn in
            print("💡 Light toggled to \(isOn ? "ON" : "OFF") for \(button.buttonName)")

            // 🔄 Handle your publish logic here, e.g.:
            // let speed = matchedState.lSpeed[...] if needed
            // publish_button_to_topic(control: "L", no: button.buttonNo, state: isOn ? 1 : 0, speed: speed, topic: matchedState.uniqueId)
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

        powerButton.addTarget(self, action: #selector(toggleState), for: .touchUpInside)

        let resizedIcon = UIGraphicsImageRenderer(size: CGSize(width: 12, height: 12)).image { _ in
            UIImage(systemName: "power")?.draw(in: CGRect(origin: .zero, size: CGSize(width: 12, height: 12)))
        }
        powerButton.setImage(resizedIcon.withRenderingMode(.alwaysTemplate), for: .normal)

        // ⚠️ Fan is assumed to be valid. Add slider directly (you can still use a flag if needed)
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

            guard self.isOn else {
                print("Fan is OFF, ignoring slider release")
                return
            }

            let fanSpeed = value
            let fanIndex = button.buttonNo

            print("📤 [Fan Slider Released] control: F\(fanIndex), state: 1, speed: \(fanSpeed), topic: \(button.uniqueId)")
           
        }

        // Optionally: set default value
        slider.currentValue = 2  // Default speed
        print("🌬️ Default fan speed set to 2")

        contentView.bringSubviewToFront(powerButton)
    }

    private func setupDimmableLightControl(with button: ButtonDetails, category: String, dimmingType: String) {
     
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
    
    func filterCurtainButtons(_ buttons: [ButtonDetails], from deviceState: DeviceState) -> [ButtonDetails] {
        let configButtons = deviceState.configButtons
        var filteredButtons: [ButtonDetails] = []

        for button in buttons {
            let index = button.buttonNo - 1
            guard index >= 0, index < configButtons.count else { continue }

            let type = configButtons[configButtons.index(configButtons.startIndex, offsetBy: index)]

            if isCurtainSlave(String(type)) {
                print("⏭ Hiding curtain slave: \(button.buttonName) — type: \(type)")
                continue // ✅ Always skip slaves
            }

            filteredButtons.append(button) // ✅ Keep master and non-curtain
        }

        return filteredButtons
    }


    func isCurtainMaster(_ type: String) -> Bool {
        return ["O", "Q"].contains(type.uppercased())
    }

    func isCurtainSlave(_ type: String) -> Bool {
        return ["C", "Y"].contains(type.uppercased())
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

    }

    
}
