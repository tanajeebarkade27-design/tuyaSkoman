//
//  AllShortcutDeviceCollectionViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 19/06/25.
//

import UIKit
import SwiftKeychainWrapper
import AWSCore
import AWSIoT
import Alamofire

class AllShortcutDeviceCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var roomname: UILabel!
    @IBOutlet weak var deviceImageView: UIImageView!
    @IBOutlet weak var imageview: UIView!
    @IBOutlet weak var cellbackgroundview: UIView!
    @IBOutlet weak var buttonName: UILabel!
    var isSelectedFlag: Int = 1
    var onLongPressNavigate: ((_ index: Int, _ buttonDetails: [ButtonDetails], _ deviceStates: [DeviceStateArray], _ filteredDevices: [Device]) -> Void)?



   
    @IBOutlet weak var isSelectdButton: UIButton!
    
    var deviceStateArray: [DeviceStateArray] = []
    var filteredButtonDetails: [ButtonDetails] = []
    var  deviceButtonDetails :[ButtonDetails] = []
    var filteredDevices: [Device] = []
    var receivedDeviceStates: DeviceStateArray?
    private var curtainSlider: CurtainSliderView?
    private var customSlider :  CustomSlider?
    private var fanSlider : FanSlider?
    private var statusLabelLeadingConstraint: NSLayoutConstraint?
    private var statusLabelTrailingConstraint: NSLayoutConstraint?
    private var statusLabelCenterXConstraint: NSLayoutConstraint?
    private var thumbTrailingConstraint: NSLayoutConstraint!
    var selectedRoomId: String?
    var deviceType:String?
    var deviceCategory : String?
    var onDimmingSpeedChanged: ((Int) -> Void)?
    var switchList: [SwitchItem] = []
    var filteredDeviceStatesForCell: [DeviceStateArray] = []
    let sliderButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .black
        button.layer.cornerRadius = 15
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private var simpleButton: UIButton?
    private var horizontalSlider: UISlider?
    private var isOn = false
    private let thumbView = UIView()
    private let arrowImageView = UIImageView()
    private let powerImageView = UIImageView()
    private var thumbLeadingConstraint: NSLayoutConstraint!
    var onSliderToggle: (() -> Void)?
    var cellIndex: Int?
    // Add to your cell properties:
    var fanSwitches: [SwitchItem] = []
    private var fanShortcutSwitches: [SwitchItem] = []
    var deviceUniqueId: String = ""
    var onPublishPayload: (() -> Void)?

    /// Card category label from last `configure` — used with `buttonName` so long-press matches what the user sees (avoids stale `cellIndex` after reuse).
    private var shortcutCardTitle: String?

    override func prepareForReuse() {
        super.prepareForReuse()
        cellIndex = nil
        shortcutCardTitle = nil
    }

    /// Maps the All-tab shortcut card title to `deviceList` / `navigateToManageShortcut` index (0 Lights … 3 Fans).
    private func resolvedShortcutCategoryIndex() -> Int {
        let raw = (buttonName.text ?? shortcutCardTitle ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        if raw.contains("dimm") { return 2 }
        if raw.contains("curtain") { return 1 }
        if raw.contains("fan") { return 3 }
        if raw.contains("light") { return 0 }
        return cellIndex ?? 0
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        self.addGestureRecognizer(longPressGesture)

        contentView.addSubview(sliderButton)
        NSLayoutConstraint.activate([
            sliderButton.widthAnchor.constraint(equalToConstant: 60),
            sliderButton.heightAnchor.constraint(equalToConstant: 30),
            sliderButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            sliderButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])
        
        setupSliderButtonUI()
        
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        cellbackgroundview.layer.cornerRadius = 10
        cellbackgroundview.clipsToBounds = true
        imageview.layer.cornerRadius = imageview.frame.height / 2
        imageview.clipsToBounds = true
        imageview.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        cellbackgroundview.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        print("selectedRoomId at cell \(filteredButtonDetails)")
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cellTapped))
        cellbackgroundview.isUserInteractionEnabled = true
        cellbackgroundview.addGestureRecognizer(tapGesture)
    }

   
   

    
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            isSelectedFlag = isSelectedFlag == 1 ? 0 : 1

            let index = resolvedShortcutCategoryIndex()
            print("🔁 isSelectedFlag toggled to: \(isSelectedFlag) for cell: \(buttonName.text ?? "")")
            print("📦 Passing to navigation — resolved index: \(index) (cellIndex was \(cellIndex.map { String($0) } ?? "nil"), title: \(buttonName.text ?? shortcutCardTitle ?? ""))")
            print("🔹 buttonDetails count: \(filteredButtonDetails.count)")
            print(" 🔸 deviceStates count: \(deviceStateArray.count)")
            print(" 🧩 filteredDevices count: \(filteredDevices.count)")

//            cellbackgroundview.backgroundColor = isSelectedFlag == 1
//                ? UIColor.gray.withAlphaComponent(0.3)
//                : UIColor.white.withAlphaComponent(0.50)

            onLongPressNavigate?(index, filteredButtonDetails, deviceStateArray, filteredDevices)
        }
    }


    
    
    

    @objc private func selectButtonTapped() {
        isSelectedFlag = isSelectedFlag == 1 ? 0 : 1
        print("🔁 isSelectedFlag toggled to: \(isSelectedFlag) for cell: \(buttonName.text ?? "")")
    }

    

    
    
    @objc private func cellTapped() {
        
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.prepare()
            generator.impactOccurred()
      //  print("🟢 Cell tapped for \(currentButton?.buttonName ?? "unknown")")
        
        // Highlight briefly
        cellbackgroundview.layer.borderWidth = 2
        cellbackgroundview.layer.borderColor = UIColor.systemGreen.cgColor
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.cellbackgroundview.layer.borderWidth = 0
        }
        
        // Trigger the same action as the simple power button
        toggleState()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Force layout to ensure width is resolved
        sliderButton.layoutIfNeeded()
        print("sliderButton width in layoutSubviews: \(sliderButton.bounds.width)")
        
        updateButtonStyle(animated: false)
    }

    private func setupSliderButtonUI() {
          let thumbSize: CGFloat = 20
          let thumbPadding: CGFloat = 4

          thumbView.backgroundColor = .white
          thumbView.layer.cornerRadius = thumbSize / 2
          thumbView.translatesAutoresizingMaskIntoConstraints = false
          sliderButton.addSubview(thumbView)

          NSLayoutConstraint.activate([
              thumbView.centerYAnchor.constraint(equalTo: sliderButton.centerYAnchor),
              thumbView.widthAnchor.constraint(equalToConstant: thumbSize),
              thumbView.heightAnchor.constraint(equalToConstant: thumbSize)
          ])

          thumbLeadingConstraint = thumbView.leadingAnchor.constraint(equalTo: sliderButton.leadingAnchor, constant: thumbPadding)
          thumbTrailingConstraint = thumbView.trailingAnchor.constraint(equalTo: sliderButton.trailingAnchor, constant: -thumbPadding)
          thumbLeadingConstraint.isActive = true
          
          powerImageView.image = UIImage(systemName: "power")
          powerImageView.tintColor = .orange
          powerImageView.contentMode = .scaleAspectFit
          powerImageView.translatesAutoresizingMaskIntoConstraints = false
          thumbView.addSubview(powerImageView)
          
          NSLayoutConstraint.activate([
              powerImageView.centerXAnchor.constraint(equalTo: thumbView.centerXAnchor),
              powerImageView.centerYAnchor.constraint(equalTo: thumbView.centerYAnchor),
              powerImageView.widthAnchor.constraint(equalToConstant: 12),
              powerImageView.heightAnchor.constraint(equalToConstant: 12)
          ])
          
          let thumbTapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleState))
          thumbView.addGestureRecognizer(thumbTapGesture)
          thumbView.isUserInteractionEnabled = true
          
          statusLabel.translatesAutoresizingMaskIntoConstraints = false
          statusLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
          statusLabel.textAlignment = .center
          statusLabel.textColor = .white
          statusLabel.text = "OFF"
          sliderButton.addSubview(statusLabel)
          
          statusLabelLeadingConstraint = statusLabel.leadingAnchor.constraint(equalTo: sliderButton.leadingAnchor, constant: 8)
          statusLabelTrailingConstraint = statusLabel.trailingAnchor.constraint(equalTo: sliderButton.trailingAnchor, constant: -8)
          statusLabelCenterXConstraint = statusLabel.centerXAnchor.constraint(equalTo: sliderButton.centerXAnchor)
          
          NSLayoutConstraint.activate([
              statusLabel.centerYAnchor.constraint(equalTo: sliderButton.centerYAnchor),
              statusLabelCenterXConstraint!
          ])
          
          sliderButton.addTarget(self, action: #selector(toggleState), for: .touchUpInside)
          updateButtonStyle(animated: false)
      }
    private func setupSimpleButtonAndSlider() {
        sliderButton.isHidden = true

        if simpleButton == nil {
            let button = UIButton(type: .system)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.setImage(UIImage(systemName: "power"), for: .normal)
            button.imageView?.contentMode = .scaleAspectFit
            button.tintColor = .orange
            button.backgroundColor = .white
            button.layer.cornerRadius = 12.5
            contentView.addSubview(button)

            NSLayoutConstraint.activate([
                button.widthAnchor.constraint(equalToConstant: 25),
                button.heightAnchor.constraint(equalToConstant: 25),
                button.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
                button.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
            ])

            button.addTarget(self, action: #selector(toggleState), for: .touchUpInside)
            simpleButton = button
        }

        
        removeCustomSliderIfAny()

        // Add new custom slider
        let newSlider = CustomSlider()
        newSlider.translatesAutoresizingMaskIntoConstraints = false
        newSlider.tag = 999
        contentView.addSubview(newSlider)

        NSLayoutConstraint.activate([
            newSlider.widthAnchor.constraint(equalToConstant: 90),
            newSlider.heightAnchor.constraint(equalToConstant: 25),
            newSlider.leadingAnchor.constraint(equalTo: simpleButton!.trailingAnchor, constant: 20),
            newSlider.centerYAnchor.constraint(equalTo: simpleButton!.centerYAnchor)
        ])

        newSlider.onValueChanged = { value in
            print("Slider changed to \(value)")
        }

      
        simpleButton?.isHidden = false
        simpleButton?.tintColor = .orange
        simpleButton?.backgroundColor = isOn ? .systemGreen : .white
        simpleButton?.imageEdgeInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        simpleButton?.contentHorizontalAlignment = .center
        simpleButton?.contentVerticalAlignment = .center

        if isOn {
            simpleButton?.layer.borderWidth = 2
            simpleButton?.layer.borderColor = UIColor.systemGreen.cgColor
            simpleButton?.layer.shadowColor = UIColor.systemGreen.cgColor
            simpleButton?.layer.shadowRadius = 4
            simpleButton?.layer.shadowOpacity = 0.8
            simpleButton?.layer.shadowOffset = .zero
        } else {
            simpleButton?.layer.borderWidth = 0
            simpleButton?.layer.shadowOpacity = 0
        }
    }

 
    private func removeCustomSliderIfAny() {
        if let oldSlider = contentView.viewWithTag(999) {
            oldSlider.removeFromSuperview()
        }
    }

   
    private func adjustSliderWidth(to width: CGFloat) {
        if let widthConstraint = sliderButton.constraints.first(where: { $0.firstAttribute == .width }) {
            widthConstraint.constant = width
        }
    }



    func updateStateBasedOnLState(lState: String, at index: Int) {
        let charIndex = index
        if charIndex < lState.count {
            let valueIndex = lState.index(lState.startIndex, offsetBy: charIndex)
            let value = lState[valueIndex]
            isOn = (value == "1")
        } else {
            isOn = false
        }
        //updateButtonStyle(animated: false)
    }


    @objc private func toggleState() {
        isOn.toggle()
        print("Toggle called - new isOn: \(isOn)")
        statusLabel.text = isOn ? "ON" : "OFF"

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

        updateButtonStyle(animated: true)

        // Use robust matching (label text sometimes differs: "Light"/"Lights", casing, whitespace)
        let key = (buttonName.text ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        if key.contains("dimmable") {
            publishDimmableToggleBasedOnState(deviceStates: deviceStateArray, switchesList: switchList)
        } else if key.contains("light") {
            publishLightsToggleBasedOnState(
                deviceStates: deviceStateArray,
                isCurrentlyOn: !isOn,
                buttonDetails: deviceButtonDetails
            )
        } else if key.contains("fan") {
            let sliderValue = fanSlider?.currentValue ?? 1
            publishFanToggleFromSwitches(fanShortcutSwitches, isCurrentlyOn: !isOn, sliderValue: sliderValue)
        } else if key.contains("curtain") {
//           publishCurtainToggleLeftBasedOnState(deviceStates: deviceStateArray, isCurrentlyOn: !isOn)
        }

    }
    func createSwitches(from deviceState: DeviceStateArray, buttonDetails: [ButtonDetails]) -> [SwitchItem] {
        var switches: [SwitchItem] = []
        let lightRelevantChars: [Character] = ["L", "O", "C", "D", "Q", "Y" ,"R"]

        // ------------------------
        // 1️⃣ Create LIGHT switches
        // ------------------------
        for (index, char) in deviceState.cNm.enumerated() {
            guard lightRelevantChars.contains(char),
                  index < deviceState.lightState.count,
                  index < deviceState.cL.count else { continue }

            let isOn = deviceState.lightState[deviceState.lightState.index(deviceState.lightState.startIndex, offsetBy: index)] == "1" ? 1 : 0
            let isChildLocked = deviceState.cL[deviceState.cL.index(deviceState.cL.startIndex, offsetBy: index)] == "1" ? 1 : 0

            let configDimChar = index < deviceState.cDim.count
                ? String(deviceState.cDim[deviceState.cDim.index(deviceState.cDim.startIndex, offsetBy: index)])
                : nil

            let speedChar = index < deviceState.lightSpeed.count
                ? String(deviceState.lightSpeed[deviceState.lightSpeed.index(deviceState.lightSpeed.startIndex, offsetBy: index)])
                : nil
            
            // IMPORTANT:
            // ButtonDetails ordering is not guaranteed (DB often returns L1, L3, L2...).
            // Always match by hardware button number (1-based) to avoid swapping
            // shortcut flags and dimming config between buttons.
            let expectedNo = index + 1
            let expectedControl = String(char).uppercased()
            let buttonDetail =
                buttonDetails.first(where: { $0.buttonNo == expectedNo && ($0.buttonControlName ?? "").uppercased() == expectedControl })
                ?? buttonDetails.first(where: { $0.buttonNo == expectedNo })

            switches.append(SwitchItem(
                name: "L\(index + 1)",
                type: .light,
                switchIndex: index + 1,
                isOnState: isOn,
                isChildLocked: isChildLocked,
                speed: speedChar,
                uniqueID: deviceState.uniqueID,
                buttonDetail: buttonDetail,
                configDim: configDimChar,
                destButton: index + 1,
                fanDest: nil,
                isShortcut: buttonDetail?.isShortcut, rRegulator: deviceState.rRegulator
            ))
        }

        // ---------------------
        // 2️⃣ Create FAN switches (match buttonControlName == "F")
        // ---------------------
        let fanButtons = buttonDetails
            .filter { $0.buttonControlName == "F" }
            .sorted { $0.buttonNo < $1.buttonNo }

        for (index, fanChar) in deviceState.fanState.enumerated() {
            let isOn = fanChar == "1" ? 1 : 0

            let speedChar = index < deviceState.fanSpeed.count
                ? String(deviceState.fanSpeed[deviceState.fanSpeed.index(deviceState.fanSpeed.startIndex, offsetBy: index)])
                : nil

            let isChildLocked = index < deviceState.cF.count
                ? (deviceState.cF[deviceState.cF.index(deviceState.cF.startIndex, offsetBy: index)] == "1" ? 1 : 0)
                : 0

            let buttonDetail = fanButtons.count > index ? fanButtons[index] : nil

            switches.append(SwitchItem(
                name: "F\(index + 1)",
                type: .fan,
                switchIndex: index + 1,
                isOnState: isOn,
                isChildLocked: isChildLocked,
                speed: speedChar,
                uniqueID: deviceState.uniqueID,
                buttonDetail: buttonDetail,
                configDim: nil,
                destButton: nil,
                fanDest: index + 1,
                isShortcut: buttonDetail?.isShortcut, rRegulator: deviceState.rRegulator
            ))
        }

        // -------------------------
        // 3️⃣ Create MASTER switch
        // -------------------------
        if let masterChar = deviceState.cM.first {
            let isOn = (deviceState.master == 1) ? 1 : 0
            let isChildLocked = (masterChar == "1") ? 1 : 0
            let masterButton = buttonDetails.first { $0.buttonControlName == "M" }

            switches.append(SwitchItem(
                name: "Master",
                type: .master,
                switchIndex: 1,
                isOnState: isOn,
                isChildLocked: isChildLocked,
                speed: nil,
                uniqueID: deviceState.uniqueID,
                buttonDetail: masterButton,
                configDim: nil,
                destButton: nil,
                fanDest: nil,
                isShortcut: masterButton?.isShortcut, rRegulator: deviceState.rRegulator
            ))
        }

       
        debugLog("✅ All switches created: \(switches)")
        return switches
    }



    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 10, weight: .bold)
        label.textColor = .black
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private func resetCellUI() {
        // Hide known reusable components
        sliderButton.isHidden = true
        simpleButton?.isHidden = true
        curtainSlider?.isHidden = true
        fanSlider?.isHidden = true

      
        contentView.subviews.forEach { subview in
            if subview.tag == 999 {
                subview.removeFromSuperview()
            }
        }
    }

    
    func filterLightShortcutWithDimZero(from switches: [SwitchItem]) -> [SwitchItem] {
        return switches.filter { switchItem in
            // Ensure it's a light
            guard switchItem.type == .light else { return false }
            
            // Ensure buttonDetail exists
            guard let buttonDetail = switchItem.buttonDetail else { return false }
            
          
            let isShortcutMatch = (buttonDetail.isShortcut == 1)
            let controlNameMatch = (buttonDetail.buttonControlName == "L")
            let configDimMatch = (switchItem.configDim == "0")
            
            let isMatch = isShortcutMatch && controlNameMatch && configDimMatch
            
            if isMatch {
                print("✅ Filter matched button:\(buttonDetail.uniqueId) \(buttonDetail.buttonName) | ControlName: \(buttonDetail.buttonControlName) | ConfigDim: \(switchItem.configDim ?? "nil") isshortcut:\(isShortcutMatch) isonstate \(switchItem.isOnState) ")
            }
            
            
            return isMatch
        }
    }
    
   

    func filterLightShortcutWithDimOne(from switches: [SwitchItem]) -> [SwitchItem] {
        print("🔍 Starting filterLightShortcutWithDimOne on \(switches.count) switches")
        
        let filtered = switches.filter { switchItem in
            // Ensure it's a light
            guard switchItem.type == .light else {
                print("❌ Skipped switch \(switchItem.name) because type is not light")
                return false
            }
            
    
            guard let buttonDetail = switchItem.buttonDetail else {
                print("❌ Skipped switch \(switchItem.name) because buttonDetail is nil")
                return false
            }
            
            let isShortcutMatch = (buttonDetail.isShortcut == 1)
            let controlNameMatch = (buttonDetail.buttonControlName == "L")
            let configDimMatch = (switchItem.configDim == "1")
            
            let isMatch = isShortcutMatch && controlNameMatch && configDimMatch
            
            if isMatch {
                print("💡 Dimmable light matched: \(buttonDetail.buttonName) | ControlName: \(buttonDetail.buttonControlName) | ConfigDim: \(switchItem.configDim ?? "nil") | isShortcut: \(isShortcutMatch) | isOnState: \(switchItem.isOnState)")
            } else {
                print("❌ Filter skipped button: \(buttonDetail.buttonName) - isShortcut: \(isShortcutMatch), ControlNameMatch: \(controlNameMatch), ConfigDimMatch: \(configDimMatch)")
            }
            
            return isMatch
        }
        
        print("✅ filterLightShortcutWithDimOne returning \(filtered.count) matched switches")
        return filtered
    }


    func configure(
        
        
        roomName: String,
        cellName: String? = nil,
        imageName: String? = nil,
        isInitiallyOn: Bool = false,
        index: Int = 0,
        deviceStates: [DeviceStateArray],
        deviceData: [Device],
        filteredButtonDetails: [ButtonDetails]
    ) {
        
        
        
        self.roomname.text = roomName
        self.buttonName.text = cellName ?? roomName
        self.shortcutCardTitle = cellName ?? roomName
        self.filteredButtonDetails = filteredButtonDetails
        self.deviceStateArray = deviceStates
        self.filteredDeviceStatesForCell = deviceStates

        resetCellUI()
        deviceImageView.contentMode = .scaleAspectFit
        deviceImageView.tintColor = .white

        if let imageName = imageName {
            if let assetImage = UIImage(named: imageName) {
                deviceImageView.image = assetImage
            } else {
                deviceImageView.image = UIImage(systemName: imageName)
            }
        } else {
            deviceImageView.image = UIImage(systemName: "lightbulb.fill")
        }

        print("filteredButtonDetails att \(deviceStates)")
        isOn = isInitiallyOn
        statusLabel.text = isOn ? "ON" : "OFF"
        updateButtonStyle(animated: false)

        var matching: DeviceStateArray?
        var matchingFanState: DeviceStateArray?


        if cellName == "Lights" || cellName == "Dimmable" {
            matching = deviceStates.first(where: { $0.cNm.contains("L") })
        } else if cellName == "Curtains" {
            print("🔍 Curtain matching for cellName = \(cellName ?? "nil")")

            // Find first curtain device that has at least one OCQY shortcut button
            matching = deviceStates.first(where: { state in
                let details = SkromanIsraDatabaseHelper.shared.fetchButtonDetails(uniqueId: state.uniqueID)

                for btn in details where btn.isShortcut == 1 {
                    if "OCQY".contains(btn.buttonControlName) {
                        print("✅ Curtain shortcut match found: \(btn.buttonControlName) for button \(btn.buttonName)")
                        
                         
                        let shortcutButtons = details.filter {
                            $0.isShortcut == 1 && "OCQY".contains($0.buttonControlName)
                        }

                       
                        
                        return true
                    }
                }
                return false
            })
        }
       
        else if cellName == "Fans" {
            print("🔍 Fan matching for cellName = \(cellName ?? "nil")")

            let fanShortcutStates = deviceStates.filter { state in
                let details = SkromanIsraDatabaseHelper.shared.fetchButtonDetails(uniqueId: state.uniqueID)
                let fanShortcuts = details.filter {
                    $0.isShortcut == 1 && $0.buttonControlName.uppercased() == "F"
                }
                print("✅ Filtered fan shortcut details for \(state.uniqueID): \(fanShortcuts)")
                return !fanShortcuts.isEmpty
            }

            matchingFanState = fanShortcutStates.first
            self.filteredDeviceStatesForCell = fanShortcutStates

            // 🆕 Create switches for fan
            if let matchedFanState = matchingFanState {
                self.deviceUniqueId = matchedFanState.uniqueID
                self.deviceButtonDetails = SkromanIsraDatabaseHelper.shared.fetchButtonDetails(uniqueId: matchedFanState.uniqueID)

                let fanSwitches = createSwitches(from: matchedFanState, buttonDetails: self.deviceButtonDetails)
                    .filter { $0.type == .fan }

                self.switchList = fanSwitches

                print("🌀 Fan switches for UID \(matchedFanState.uniqueID):")
                for sw in fanSwitches {
                    print("at fanswitch List  \(sw.name) isOn: \(sw.isOnState), speed: \(sw.speed ?? "nil"), isShortcut: \(sw.isShortcut ?? -1)\(sw.buttonDetail), switchIndex\(sw.switchIndex)")
                }
            }
        }

        // Clear old data
        self.deviceButtonDetails.removeAll()
        self.switchList.removeAll()

        for state in deviceStates {

            self.deviceUniqueId = state.uniqueID

            // Fetch button details for this device
            let buttonDetails = SkromanIsraDatabaseHelper.shared.fetchButtonDetails(uniqueId: state.uniqueID)
            
            print("📦 ButtonDetails for UID: \(state.uniqueID)")
            for btn in buttonDetails {
                print("- ID: \(btn.uniqueId), Name: \(btn.buttonName), Control: \(btn.buttonControlName), isShortcut: \(btn.isShortcut)")
            }

            // Store button details for all devices
            self.deviceButtonDetails.append(contentsOf: buttonDetails)

            // Create switches for this device
            let switches = createSwitches(from: state, buttonDetails: buttonDetails)

            // Store all switches
            self.switchList.append(contentsOf: switches)

            // Curtain state update
            if cellName == "Curtains" {
                updateCurtainState(deviceStates: [state])
            }

            // Find device metadata
            let matchedDevice = deviceData.first(where: {
                $0.uniqueId == state.uniqueID || $0.deviceUid == state.uniqueID
            })

            let category = matchedDevice?.deviceCategory ?? "skroman_new"
            let dimmingType = matchedDevice?.deviceDimmingType ?? "zcd"

            print("🔍 Matched device category: \(category), dimmingType: \(dimmingType)")
        }

        // Debug print final switches
        print("✅ Final switchList after updates:")
        for sw in switchList {
            print(" - sw\(sw.name) isOn: \(sw.isOnState), isShortcut: \(sw.isShortcut ?? -1), configDim: \(sw.configDim ?? "nil") \(sw.speed ?? "nil")")
        }

   
        switch cellName {
        case "Curtains":
            sliderButton.isHidden = true
            simpleButton?.isHidden = true
            removeCustomSliderIfAny()

            if curtainSlider == nil {
                curtainSlider = CurtainSliderView()
                curtainSlider!.translatesAutoresizingMaskIntoConstraints = false
                contentView.addSubview(curtainSlider!)

                NSLayoutConstraint.activate([
                    curtainSlider!.widthAnchor.constraint(equalToConstant: 120),
                    curtainSlider!.heightAnchor.constraint(equalToConstant: 30),
                    curtainSlider!.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
                    curtainSlider!.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
                ])
            }

            curtainSlider!.isHidden = false

            // ✅ Use the matched curtain from `configure`
            if let matchedCurtain = matching {
              
                let curtainShortcutButtons = SkromanIsraDatabaseHelper.shared
                    .fetchButtonDetails(uniqueId: matchedCurtain.uniqueID)
                    .filter { $0.isShortcut == 1 && "OCQY".contains($0.buttonControlName ?? "") }

                if curtainShortcutButtons.isEmpty {
                    print("❌ No OC/QY curtain shortcut buttons found for \(cellName ?? "")")
                } else {
                    // Update curtain state using just this matched curtain
                    updateCurtainState(deviceStates: [matchedCurtain])
                }

                curtainSlider!.onLeftTap = { [weak self] in
                    guard let self = self else { return }
                    let isCurrentlyClosed = self.isCurtainClosed(deviceStates: [matchedCurtain])
                    self.publishCurtainToggleLeftBasedOnState(deviceStates: [matchedCurtain], isCurrentlyOn: isCurrentlyClosed, buttonDetails: curtainShortcutButtons)
                    self.statusLabel.text = "Closed"
                    self.updateCurtainState(deviceStates: [matchedCurtain])
                }

                curtainSlider!.onRightTap = { [weak self] in
                    guard let self = self else { return }
                    let isCurrentlyOpen = self.isCurtainOpen(deviceStates: [matchedCurtain])
                    self.publishCurtainToggleRightBasedOnState(
                        deviceStates: [matchedCurtain],
                        isCurrentlyOn: isCurrentlyOpen,
                        buttonDetails: curtainShortcutButtons
                    )
                    self.statusLabel.text = "Open"
                    self.updateCurtainState(deviceStates: [matchedCurtain])
                }
            } else {
                print("❌ No matching curtain device found in configure for \(cellName ?? "")")
            }

        case "Lights":
            // Hide other controls
            fanSlider?.isHidden = true
            sliderButton.isHidden = false
            simpleButton?.isHidden = true
            curtainSlider?.isHidden = true

            print("att light case")
          
            // Filter only matching lights
            let matchedLights = filterLightShortcutWithDimZero(from: switchList)
            print("matchedLights\(matchedLights)")
            if !matchedLights.isEmpty {
                // If ANY of them is on, we treat the cell as ON
                let anyLightOn = matchedLights.contains { $0.isOnState == 1 }
                isOn = anyLightOn
                statusLabel.text = isOn ? "ON" : "OFF"
                updateButtonStyle(animated: false)
                print("💡 Lights toggle updated: \(isOn ? "ON" : "OFF") from matchedLights")
            } else {
                print("⚠️ No matching light shortcuts with dim=0 found")
            }
        case "Dimmable":
            // Hide other controls
            fanSlider?.isHidden = true
            sliderButton.isHidden = true
            curtainSlider?.isHidden = true
            simpleButton?.isHidden = false

            print("✅ Entered Dimmable cell block")

            // Filter only matching dimmable lights from the switchList passed in
            let dimmableLights = filterLightShortcutWithDimOne(from: switchList)
            print("dimmableLights\(dimmableLights)")

            if !dimmableLights.isEmpty {
                // If ANY dimmable light is ON, mark the cell ON
                let anyLightOn = dimmableLights.contains { $0.isOnState == 1 }
                isOn = anyLightOn
            } else {
                isOn = false
            }

            statusLabel.text = isOn ? "ON" : "OFF"

            if simpleButton == nil {
                let button = UIButton(type: .system)
                button.translatesAutoresizingMaskIntoConstraints = false
                button.backgroundColor = .white
                button.layer.cornerRadius = 12.5
                button.tintColor = .orange

                if let powerImage = UIImage(systemName: "power") {
                    let resized = UIGraphicsImageRenderer(size: CGSize(width: 12, height: 12)).image { _ in
                        powerImage.draw(in: CGRect(origin: .zero, size: CGSize(width: 12, height: 12)))
                    }
                    button.setImage(resized.withRenderingMode(.alwaysTemplate), for: .normal)
                }

                button.addTarget(self, action: #selector(toggleState), for: .touchUpInside)
                contentView.addSubview(button)

                NSLayoutConstraint.activate([
                    button.widthAnchor.constraint(equalToConstant: 25),
                    button.heightAnchor.constraint(equalToConstant: 25),
                    button.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
                    button.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
                ])

                simpleButton = button
            }

            simpleButton?.isHidden = false

            DispatchQueue.main.async {
                if self.isOn {
                    self.simpleButton?.layer.borderWidth = 2
                    self.simpleButton?.layer.borderColor = UIColor.green.cgColor
                    self.simpleButton?.layer.shadowColor = UIColor.green.cgColor
                    self.simpleButton?.layer.shadowRadius = 4
                    self.simpleButton?.layer.shadowOpacity = 0.8
                    self.simpleButton?.layer.shadowOffset = .zero
                } else {
                    self.simpleButton?.layer.borderWidth = 0
                    self.simpleButton?.layer.borderColor = UIColor.clear.cgColor
                    self.simpleButton?.layer.shadowOpacity = 0
                    self.simpleButton?.layer.shadowRadius = 0
                }
            }

            // Remove old slider if any
            contentView.viewWithTag(999)?.removeFromSuperview()

            // Create new slider and add it
            let newSlider = CustomSlider()
            newSlider.translatesAutoresizingMaskIntoConstraints = false
            newSlider.tag = 999
            contentView.addSubview(newSlider)

            NSLayoutConstraint.activate([
                newSlider.widthAnchor.constraint(equalToConstant: 90),
                newSlider.heightAnchor.constraint(equalToConstant: 30),
                newSlider.leadingAnchor.constraint(equalTo: simpleButton!.trailingAnchor, constant: 20),
                newSlider.centerYAnchor.constraint(equalTo: simpleButton!.centerYAnchor)
            ])

            print("Debug switchList contents:")
            for sw in switchList {
                print("- name at dim: \(sw.name), isOnState: \(sw.isOnState), speed: \(String(describing: sw.speed))")
            }
            if let matchingSwitch = switchList.first(where: { $0.isOnState == 1 && $0.speed != nil }),
               let speedStr = matchingSwitch.speed,
               let speed = Int(speedStr) {

                print("Current speed from switchList: \(speed)")

                let matchedDevice = deviceData.first(where: {
                    $0.uniqueId == self.deviceUniqueId || $0.deviceUid == self.deviceUniqueId
                })

                let category = matchedDevice?.deviceCategory ?? "skroman_new"
                let dimmingType = matchedDevice?.deviceDimmingType ?? "zcd"

                let sliderValue = mapSpeedToSliderValue(speed: speed, category: category, dimmingType: dimmingType)
                print("🎚️ Mapped slider value = \(sliderValue) for speed = \(speed)")

                
                
                newSlider.currentValue = sliderValue
            } else {
                newSlider.currentValue = 0
            }
           


            newSlider.onValueChangeEnded = { [weak self] value in
                guard let self = self else { return }
                self.publishDimmingSpeedFromSlider(value: value, deviceStates: deviceStates)
            }

        case "Fans":
            print("🔍 Filtering shortcut fans for cellName = Fans")

            // 1️⃣ Get all fan shortcut switches
            let fanSwitches = deviceStates.compactMap { state -> SwitchItem? in
                let details = SkromanIsraDatabaseHelper.shared.fetchButtonDetails(uniqueId: state.uniqueID)
                let fanShortcuts = details.filter {
                    $0.isShortcut == 1 && $0.buttonControlName.uppercased() == "F"
                }
                guard !fanShortcuts.isEmpty else { return nil }
                
                // Convert matching state into SwitchItem
                return createSwitches(from: state, buttonDetails: fanShortcuts)
                    .first(where: { $0.type == .fan })
            }

            print("fanSwitches count: \(fanSwitches)")

            // Store fanSwitches for toggleState() later
            self.fanShortcutSwitches = fanSwitches

            sliderButton.isHidden = true

            // 2️⃣ Setup power button if not already created
            if simpleButton == nil {
                let button = UIButton(type: .system)
                button.translatesAutoresizingMaskIntoConstraints = false
                button.setImage(UIImage(systemName: "power"), for: .normal)
                button.imageView?.contentMode = .scaleAspectFit
                button.tintColor = .orange
                button.backgroundColor = .white
                button.layer.cornerRadius = 12.5
                contentView.addSubview(button)

                NSLayoutConstraint.activate([
                    button.widthAnchor.constraint(equalToConstant: 25),
                    button.heightAnchor.constraint(equalToConstant: 25),
                    button.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
                    button.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
                ])

                button.addTarget(self, action: #selector(toggleState), for: .touchUpInside)
                simpleButton = button
            }

            // 3️⃣ Remove old slider if exists
            if let oldSlider = contentView.viewWithTag(999) {
                oldSlider.removeFromSuperview()
            }

            // 4️⃣ Create new slider
            let newSlider = FanSlider()
            newSlider.translatesAutoresizingMaskIntoConstraints = false
            newSlider.tag = 999
            contentView.addSubview(newSlider)

            NSLayoutConstraint.activate([
                newSlider.widthAnchor.constraint(equalToConstant: 90),
                newSlider.heightAnchor.constraint(equalToConstant: 30),
                newSlider.leadingAnchor.constraint(equalTo: simpleButton!.trailingAnchor, constant: 20),
                newSlider.centerYAnchor.constraint(equalTo: simpleButton!.centerYAnchor)
            ])

            // Store slider for toggleState()
            self.fanSlider = newSlider

            // ✅ Publish fan speed only after user releases the slider (avoids publish loops on reload/configure)
            newSlider.onSliderReleased = { [weak self] value in
                guard let self = self else { return }
                self.publishFanSpeedForShortcutSwitches(value: value)
            }

           
            if let firstFanSwitch = fanSwitches.first {
                let isOnState = firstFanSwitch.isOnState
                isOn = (isOnState == 1)
                print("is on state fan \(isOnState)")

                // Set slider based on speed
                if let speedStr = firstFanSwitch.speed, let speed = Int(speedStr), isOn {
                    newSlider.currentValue = max(1, min(4, speed))
                    newSlider.isUserInteractionEnabled = true
                    newSlider.alpha = 1.0
                } else {
                    newSlider.currentValue = 1
                    newSlider.isUserInteractionEnabled = false
                    newSlider.alpha = 0.5
                }

                
                
            } else {
                print("⚠️ No matching fan shortcut found")
                newSlider.currentValue = 1
                newSlider.isUserInteractionEnabled = false
                newSlider.alpha = 0.5
                isOn = false
            }

            // 6️⃣ Power button icon resize
            if let powerImage = UIImage(systemName: "power") {
                let resized = UIGraphicsImageRenderer(size: CGSize(width: 12, height: 12)).image { _ in
                    powerImage.draw(in: CGRect(origin: .zero, size: CGSize(width: 12, height: 12)))
                }
                simpleButton?.setImage(resized.withRenderingMode(.alwaysTemplate), for: .normal)
            }

            // 7️⃣ Update button style
            if isOn {
                simpleButton?.layer.borderWidth = 2
                simpleButton?.layer.borderColor = UIColor.systemGreen.cgColor
                simpleButton?.layer.shadowColor = UIColor.systemGreen.cgColor
                simpleButton?.layer.shadowRadius = 4
                simpleButton?.layer.shadowOpacity = 0.8
                simpleButton?.layer.shadowOffset = .zero
            } else {
                simpleButton?.layer.borderWidth = 0
                simpleButton?.layer.shadowOpacity = 0
            }

            simpleButton?.isHidden = false


        case "AC" :
                sliderButton.isHidden = true

                if simpleButton == nil {
                    let button = UIButton(type: .system)
                    button.translatesAutoresizingMaskIntoConstraints = false
                    button.setImage(UIImage(systemName: "power"), for: .normal)
                    button.imageView?.contentMode = .scaleAspectFit
                    button.tintColor = .orange
                    button.backgroundColor = .white
                    button.layer.cornerRadius = 12.5
                    contentView.addSubview(button)

                    NSLayoutConstraint.activate([
                        button.widthAnchor.constraint(equalToConstant: 25),
                        button.heightAnchor.constraint(equalToConstant: 25),
                        button.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
                        button.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
                    ])

                    button.addTarget(self, action: #selector(toggleState), for: .touchUpInside)
                    simpleButton = button
                }

                if let oldSlider = contentView.viewWithTag(999) {
                    oldSlider.removeFromSuperview()
                }

                // Minus button
                let minusButton = UIButton(type: .system)
                minusButton.translatesAutoresizingMaskIntoConstraints = false
                minusButton.setImage(UIImage(systemName: "minus"), for: .normal)
                minusButton.tintColor = .white
                contentView.addSubview(minusButton)

                // Plus button
                let plusButton = UIButton(type: .system)
                plusButton.translatesAutoresizingMaskIntoConstraints = false
                plusButton.setImage(UIImage(systemName: "plus"), for: .normal)
                plusButton.tintColor = .white
                contentView.addSubview(plusButton)

                // Temp label
                let tempLabel = UILabel()
                tempLabel.translatesAutoresizingMaskIntoConstraints = false
                tempLabel.text = "21°C"
                tempLabel.textColor = .white
                tempLabel.backgroundColor =  .systemGreen
                tempLabel.cornerRadius = 10
                tempLabel.clipsToBounds =  true
                
               
                tempLabel.font = .systemFont(ofSize: 18, weight: .bold)
                contentView.addSubview(tempLabel)

                var temperature = 21
                func updateTempLabel() {
                    tempLabel.text = "\(temperature)°C"
                }

                minusButton.addAction(UIAction { _ in
                    if temperature > 16 {
                        temperature -= 1
                        updateTempLabel()
                    }
                }, for: .touchUpInside)

                plusButton.addAction(UIAction { _ in
                    if temperature < 30 {
                        temperature += 1
                        updateTempLabel()
                    }
                }, for: .touchUpInside)
                
                


                // Fan speed slider
                let acSlider = FanSlider()
                acSlider.translatesAutoresizingMaskIntoConstraints = false
                acSlider.tag = 999
                contentView.addSubview(acSlider)
                // 1. Swing Horizontal Button
                let swingHorizontalButton = UIButton(type: .system)
                swingHorizontalButton.translatesAutoresizingMaskIntoConstraints = false
                swingHorizontalButton.setImage(UIImage(systemName: "arrow.left.and.right.circle"), for: .normal)
                swingHorizontalButton.tintColor = .white
                swingHorizontalButton.addAction(UIAction { _ in
                    print("Swing Left-Right tapped")
                }, for: .touchUpInside)
                contentView.addSubview(swingHorizontalButton)

                // 2. Swing Vertical Button
                let swingVerticalButton = UIButton(type: .system)
                swingVerticalButton.translatesAutoresizingMaskIntoConstraints = false
                swingVerticalButton.setImage(UIImage(systemName: "arrow.up.and.down.circle"), for: .normal)
                swingVerticalButton.tintColor = .white
                swingVerticalButton.addAction(UIAction { _ in
                    print("Swing Up-Down tapped")
                }, for: .touchUpInside)
                contentView.addSubview(swingVerticalButton)


                NSLayoutConstraint.activate([
                    minusButton.leadingAnchor.constraint(equalTo: simpleButton!.trailingAnchor, constant: 8),
                    minusButton.centerYAnchor.constraint(equalTo: simpleButton!.centerYAnchor),

                    acSlider.leadingAnchor.constraint(equalTo: minusButton.trailingAnchor, constant: 8),
                    acSlider.centerYAnchor.constraint(equalTo: simpleButton!.centerYAnchor),
                    acSlider.widthAnchor.constraint(equalToConstant: 200),
                    acSlider.heightAnchor.constraint(equalToConstant: 30),

                    plusButton.leadingAnchor.constraint(equalTo: acSlider.trailingAnchor, constant: 8),
                    plusButton.centerYAnchor.constraint(equalTo: acSlider.centerYAnchor),

                    tempLabel.centerXAnchor.constraint(equalTo: acSlider.centerXAnchor),
                    tempLabel.bottomAnchor.constraint(equalTo: acSlider.topAnchor, constant: -4),

                    swingHorizontalButton.bottomAnchor.constraint(equalTo: tempLabel.topAnchor, constant: -4),
                    swingHorizontalButton.trailingAnchor.constraint(equalTo: tempLabel.centerXAnchor, constant: -8),

                    swingVerticalButton.bottomAnchor.constraint(equalTo: tempLabel.topAnchor, constant: -4),
                    swingVerticalButton.leadingAnchor.constraint(equalTo: tempLabel.centerXAnchor, constant: 8),
                ])

           

                acSlider.onValueChanged = { value in
                    print("🌬️ AC Fan Speed changed to \(value)")
                }
                

                if let powerImage = UIImage(systemName: "power") {
                    let resized = UIGraphicsImageRenderer(size: CGSize(width: 12, height: 12)).image { _ in
                        powerImage.draw(in: CGRect(origin: .zero, size: CGSize(width: 12, height: 12)))
                    }
                    simpleButton?.setImage(resized.withRenderingMode(.alwaysTemplate), for: .normal)
                }

                simpleButton?.isHidden = false
                if isOn {
                    simpleButton?.layer.borderWidth = 2
                    simpleButton?.layer.borderColor = UIColor.systemGreen.cgColor
                    simpleButton?.layer.shadowColor = UIColor.systemGreen.cgColor
                    simpleButton?.layer.shadowRadius = 4
                    simpleButton?.layer.shadowOpacity = 0.8
                    simpleButton?.layer.shadowOffset = .zero
                } else {
                    simpleButton?.layer.borderWidth = 0
                    simpleButton?.layer.shadowOpacity = 0
                }
            


        default:
            
            break
        }
        
    }
 

    func publishLightsToggleBasedOnState(deviceStates: [DeviceStateArray], isCurrentlyOn: Bool, buttonDetails: [ButtonDetails]) {
      
        let buttonsByUniqueId = Dictionary(grouping: buttonDetails, by: { $0.uniqueId })
        
        let targetState = isCurrentlyOn ? 0 : 1

        for device in deviceStates {
            let uniqueId = device.uniqueID
            let cNm = device.cNm
            let cDim = device.cDim
            let lSpeed = device.lightSpeed
            
            // Buttons for this device
            guard let buttonsForDevice = buttonsByUniqueId[uniqueId] else { continue }

            for (i, char) in cNm.enumerated() {
                guard char == "L" else { continue }

                // Find matching button by buttonNo (1-based)
                guard let button = buttonsForDevice.first(where: { $0.buttonNo == i + 1 }) else { continue }

                // Only proceed if button is shortcut
                guard button.isShortcut == 1 else { continue }
                
                let speed = i < lSpeed.count ? Int(String(lSpeed[lSpeed.index(lSpeed.startIndex, offsetBy: i)])) ?? 0 : 0
                let isDimmable = i < cDim.count && cDim[cDim.index(cDim.startIndex, offsetBy: i)] == "1"

                // Publish payload only for this button/light
                print("📤 Toggle Light \(i + 1) to \(targetState) — UID: \(uniqueId), speed: \(speed), dimmable: \(isDimmable), button: \(button.buttonName)")

                publish_button_to_topic(control: "L", no: i + 1, state: targetState, speed: speed, topic: uniqueId)
            }
        }
    }




    func publish_button_to_topic(control: String, no: Int, state: Int, speed: Int, topic: String, allowRetry: Bool = true) {
        onPublishPayload?()

        // If MQTT isn't connected yet, request connection and retry once shortly.
        if !IoTConnectionState.shared.isConnected {
            print("⚠️ MQTT not connected yet — requesting connect, will retry publish once")
            NotificationCenter.default.post(name: .iotConnectionRequested, object: nil)
            if allowRetry {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                    self?.publish_button_to_topic(
                        control: control,
                        no: no,
                        state: state,
                        speed: speed,
                        topic: topic,
                        allowRetry: false
                    )
                }
            }
            return
        }

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

    

  
    func publishDimmableToggleBasedOnState(deviceStates: [DeviceStateArray], switchesList: [SwitchItem]) {
        for device in deviceStates {
            let cNm = device.cNm
            let cDim = device.cDim
            let lightState = device.lightState
            let topic = device.uniqueID
            
            for (i, char) in cNm.enumerated() {
                guard char == "L" else { continue }
                
                // ✅ Only dimmable lights
                let isDimmable = i < cDim.count && cDim[cDim.index(cDim.startIndex, offsetBy: i)] == "1"
                guard isDimmable else { continue }
                
                // ✅ Find matching SwitchItem for speed & shortcut check
                guard let matchingSwitch = switchesList.first(where: {
                    $0.uniqueID == device.uniqueID &&
                    $0.switchIndex == i + 1 && // assuming index matches button number
                    $0.isShortcut == 1
                }) else {
                    continue
                }
                
                // 🔄 Determine target ON/OFF state
                let currentState = i < lightState.count &&
                    lightState[lightState.index(lightState.startIndex, offsetBy: i)] == "1"
                let targetState = currentState ? 0 : 1
                
                // 📊 Get speed from SwitchItem
                let speed = Int(matchingSwitch.speed ?? "0") ?? 0
                
                print("💡 [Dimmable Toggle] L\(i + 1) — current: \(currentState), sending: \(targetState), speed: \(speed), topic: \(topic)")
                publish_button_to_topic(control: "L", no: i + 1, state: targetState, speed: speed, topic: topic)
            }
        }
    }


    
    func publishDimmingSpeedFromSlider(value: Int, deviceStates: [DeviceStateArray]) {
        guard isOn else {
            print("⚠️ Dimming ignored because isOn == false")
            return
        }

        for device in deviceStates {
            guard let matchingDevice = filteredDevices.first(where: { $0.uniqueId == device.uniqueID }) else {
                print("❌ No matching metadata found for device \(device.uniqueID)")
                continue
            }

            let category = matchingDevice.deviceCategory ?? ""
            let dimmingType = matchingDevice.deviceDimmingType ?? ""

            let speed = mapSliderValueToSpeed(value: value, category: category, dimmingType: dimmingType)
            let topic = device.uniqueID
            let cNm = device.cNm
            let cDim = device.cDim

            for (i, char) in cNm.enumerated() {
                guard char == "L" else { continue }

                let isDimmable = i < cDim.count && cDim[cDim.index(cDim.startIndex, offsetBy: i)] == "1"
                guard isDimmable else { continue }

                let state = speed > 0 ? 1 : 0

                print("🚀 Publish Dimming from slider — L\(i + 1), speed: \(speed), state: \(state), topic: \(topic)")
                publish_button_to_topic(control: "L", no: i + 1, state: state, speed: speed, topic: topic)
            }
        }
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
  
    
   
    /// Publish fan ON/OFF for the provided SwitchItems (only those marked as shortcuts).
    func publishFanToggleFromSwitches(_ switches: [SwitchItem], isCurrentlyOn: Bool, sliderValue: Int) {
        let newState = isCurrentlyOn ? 0 : 1
        let effectiveSpeed = (newState == 1) ? max(1, sliderValue) : 1
 
        for (index, sw) in switches.enumerated() {
            print("🔍 Fan switch index in array: \(index)")

            guard sw.type == .fan else { continue }
          
            let isShortcut = (sw.isShortcut == 1) || (sw.buttonDetail?.isShortcut == 1)
            guard isShortcut else { continue }

            let no =  sw.switchIndex 
            let topic = sw.uniqueID

            print("📤 Toggle Fan (no:\(no)) -> state:\(newState), speed:\(effectiveSpeed), topic:\(topic), name:\(sw.name)")
            publish_button_to_topic(control: "F", no: no, state: newState, speed: effectiveSpeed, topic: topic)
        }
    }

    
    

    
    func publishFanSpeedFromSlider(value: Int, deviceStates: [DeviceStateArray]) {
        guard isOn else {
            print("⚠️ Fan speed ignored because isOn == false")
            return
        }

        for device in deviceStates {
            let topic = device.uniqueID
            let fanState = device.fanState
            let fanSpeed = device.fanSpeed

            guard fanState != "NA" else {
                print("🚫 Skipping fan speed publish — UID: \(topic), fanState: NA")
                continue
            }

            for (i, stateChar) in fanState.enumerated() {
                guard stateChar == "1" else { continue } // Only send if current fan is ON

                let fanIndex = i + 1
                let speed = max(1, min(4, value)) // Limit fan speed to 1–4

                print("🚀 Publish Fan from slider — F\(fanIndex), speed: \(speed), state: 1, topic: \(topic)")
                publish_button_to_topic(control: "F", no: fanIndex, state: 1, speed: speed, topic: topic)
            }
        }
    }

    private func publishFanSpeedForShortcutSwitches(value: Int) {
        guard isOn else {
            print("⚠️ Fan speed ignored because isOn == false")
            return
        }

        let speed = max(1, min(4, value))
        guard !fanShortcutSwitches.isEmpty else {
            print("⚠️ No shortcut fan switches available for speed publish")
            return
        }

        for sw in fanShortcutSwitches {
            let isShortcut = (sw.isShortcut == 1) || (sw.buttonDetail?.isShortcut == 1)
            guard isShortcut else { continue }

            let no = sw.switchIndex
            let topic = sw.uniqueID
            print("🚀 Publish Fan speed from shortcut slider — F\(no), speed: \(speed), state: 1, topic: \(topic)")
            publish_button_to_topic(control: "F", no: no, state: 1, speed: speed, topic: topic)
        }
    }

    
    func updateCurtainState(deviceStates: [DeviceStateArray]) {
        
        guard let thisDevice = deviceStates.first(where: { $0.uniqueID == self.deviceUniqueId }) else {
            print("❌ No matching curtain device")
            return
        }

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

        print("Curtain state — UID: \(thisDevice.uniqueID), isOpen: \(isOpen), isClosed: \(isClosed)")

        curtainSlider?.updateThumbState(for: "Curtain", isOn: isOpen, nextValueIsOn: isClosed)
        statusLabel.text = isOpen ? "Open" : isClosed ? "Closed" : "Idle"
    }

    
    func publishCurtainToggleLeftBasedOnState(
        deviceStates: [DeviceStateArray],
        isCurrentlyOn: Bool,
        buttonDetails: [ButtonDetails]
    ) {
        let buttonsByUniqueId = Dictionary(grouping: buttonDetails, by: { $0.uniqueId })
        let targetState = isCurrentlyOn ? 0 : 1

        for device in deviceStates {
            let uniqueId = device.uniqueID
            let cNm = device.cNm
            let lightState = device.lightState

            // Filter only shortcut buttons for this device
            guard let shortcutButtons = buttonsByUniqueId[uniqueId]?.filter({ $0.isShortcut == 1 }) else { continue }

            for (i, char) in cNm.enumerated() {
                guard char == "C" || char == "Y" else { continue }
                guard i < lightState.count else { continue }

                // Find matching shortcut button
                guard let button = shortcutButtons.first(where: { $0.buttonNo == i + 1 }) else { continue }

                let current = lightState[lightState.index(lightState.startIndex, offsetBy: i)]
                if (targetState == 1 && current == "1") || (targetState == 0 && current == "0") {
                    continue
                }

                print("📤 Toggle Curtain Left \(i + 1) to \(targetState) — UID: \(uniqueId), button: \(button.buttonName)")
                publish_button_to_topic(
                    control: "L",
                    no: i + 1,
                    state: targetState,
                    speed: 0,
                    topic: uniqueId
                )
            }
        }
    }


    
    func publishCurtainToggleRightBasedOnState(
        deviceStates: [DeviceStateArray],
        isCurrentlyOn: Bool,
        buttonDetails: [ButtonDetails]
    ) {
        let buttonsByUniqueId = Dictionary(grouping: buttonDetails, by: { $0.uniqueId })
        let targetState = isCurrentlyOn ? 0 : 1

        for device in deviceStates {
            let uniqueId = device.uniqueID
            let cNm = device.cNm
            let lightState = device.lightState

            // Filter only shortcut buttons for this device
            guard let shortcutButtons = buttonsByUniqueId[uniqueId]?.filter({ $0.isShortcut == 1 }) else { continue }

            for (i, char) in cNm.enumerated() {
                guard char == "O" || char == "Q" else { continue }
                guard i < lightState.count else { continue }

                // Find matching shortcut button
                guard let button = shortcutButtons.first(where: { $0.buttonNo == i + 1 }) else { continue }

                let current = lightState[lightState.index(lightState.startIndex, offsetBy: i)]
                if (targetState == 1 && current == "1") || (targetState == 0 && current == "0") {
                    continue
                }

                print("📤 Toggle Curtain Right \(i + 1) to \(targetState) — UID: \(uniqueId), button: \(button.buttonName)")
                publish_button_to_topic(
                    control: "L",
                    no: i + 1,
                    state: targetState,
                    speed: 0,
                    topic: uniqueId
                )
            }
        }
    }



    private func isCurtainOpen(deviceStates: [DeviceStateArray]) -> Bool {
        guard let thisDevice = deviceStates.first(where: { $0.uniqueID == self.deviceUniqueId }) else { return false }

        for (i, char) in thisDevice.cNm.enumerated() {
            guard i < thisDevice.lightState.count else { continue }
            let stateChar = thisDevice.lightState[thisDevice.lightState.index(thisDevice.lightState.startIndex, offsetBy: i)]
            if stateChar == "1" && (char == "O" || char == "Q") {
                return true
            }
        }
        return false
    }

    private func isCurtainClosed(deviceStates: [DeviceStateArray]) -> Bool {
        guard let thisDevice = deviceStates.first(where: { $0.uniqueID == self.deviceUniqueId }) else { return false }

        for (i, char) in thisDevice.cNm.enumerated() {
            guard i < thisDevice.lightState.count else { continue }
            let stateChar = thisDevice.lightState[thisDevice.lightState.index(thisDevice.lightState.startIndex, offsetBy: i)]
            if stateChar == "1" && (char == "C" || char == "Y") {
                return true
            }
        }
        return false
    }

    
    
    private func updateButtonStyle(animated: Bool) {
        let thumbWidth: CGFloat = 20
        let thumbY: CGFloat = 5
        let padding: CGFloat = 5

        let maxThumbX = sliderButton.bounds.width - thumbWidth - padding
        let minThumbX = padding

        let thumbX = isOn ? maxThumbX : minThumbX

        let updates = {
            // Update thumb appearance
            if self.isOn {
                self.thumbView.layer.borderWidth = 2
                self.thumbView.layer.borderColor = UIColor.systemGreen.cgColor
                self.thumbView.layer.shadowColor = UIColor.systemGreen.cgColor
                self.thumbView.layer.shadowRadius = 4
                self.thumbView.layer.shadowOpacity = 0.8
                self.thumbView.layer.shadowOffset = .zero
                
               
                self.thumbLeadingConstraint.isActive = false
                self.thumbTrailingConstraint.isActive = true
                
                // Status label on left
                self.statusLabelCenterXConstraint?.isActive = false
                self.statusLabelLeadingConstraint?.isActive = true
                self.statusLabelTrailingConstraint?.isActive = false
            } else {
                self.thumbView.layer.borderWidth = 0
                self.thumbView.layer.shadowOpacity = 0
                
                // Thumb left
                self.thumbTrailingConstraint.isActive = false
                self.thumbLeadingConstraint.isActive = true
                
                // Status label on right
                self.statusLabelCenterXConstraint?.isActive = false
                self.statusLabelLeadingConstraint?.isActive = false
                self.statusLabelTrailingConstraint?.isActive = true
            }
            
            self.sliderButton.layoutIfNeeded()
        }

        if animated {
            UIView.animate(withDuration: 0.3, animations: updates)
        } else {
            updates()
        }
    



        let updateThumbFrame = {
            self.thumbView.frame = CGRect(x: thumbX, y: thumbY, width: thumbWidth, height: thumbWidth)
            self.powerImageView.frame = CGRect(x: 2, y: 2, width: 16, height: 16)
        }

        if animated {
            UIView.animate(withDuration: 0.3) {
                updateThumbFrame()
            }
        } else {
            updateThumbFrame()
        }
    }



    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true  
        }


}


extension AllShortcutDeviceCollectionViewCell: DeviceStateConfigurable {
    func configure(with buttonDetails: [ButtonDetails], deviceStates: [DeviceStateArray], filteredDevices: [Device]) {
        self.filteredButtonDetails = buttonDetails
        self.deviceStateArray = deviceStates
        self.filteredDevices = filteredDevices

        print("🧩 Cell configure called —")
        print("   → ButtonDetails count: \(buttonDetails.count)")
        for (i, btn) in buttonDetails.enumerated() {
            print("  rr   🔹 [\(i)] Name: \(btn.buttonName), UID: \(btn.uniqueId), switchName: \(btn.switchName)")
        }

        print("   → Filtered Devices count: \(filteredDevices.count)")
        for (i, dev) in filteredDevices.enumerated() {
            print("     🔸 [\(i)] DeviceName: \(dev.deviceName), UID: \(dev.uniqueId), Category: \(dev.deviceCategory) dimmingType : \(dev.deviceDimmingType)")
        }
    }

}
