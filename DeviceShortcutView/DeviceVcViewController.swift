//
//  DeviceVcViewController.swift
//  SkromanIsra
//
//  Created by Admin on 28/03/25.
//

import UIKit
import MARKRangeSlider
import Lottie
import AWSCore
import AWSIoT
import Alamofire
import HomeKit
import Intents
import AppIntents


class DeviceVcViewController: UIViewController, UITabBarDelegate {
    var rooms: [Room] = []
    var devices: [Device] = []
    var buttonItems: [String] = []
    var roomId: String?
    var iotDataManager: AWSIoTDataManager!
    var iotManager: AWSIoTManager!
    var iot: AWSIoT!
    var selectedDevice: Device?
    var logTextView: UITextView!
    var  SelectedDeviecUid : String?
    var connectButton: UIButton!
    var  deviceUniqueId: String?
    var connected = false
    var receivedDeviceStates: [DeviceStateArray] = []
    var previousDeviceUniqueId: String?
    var mappedValues: [[String: String]] = []
    var fetchDeviceState: [DeviceState] = []
    var isDeviceCatgery: String?
    var buttonDetails: [ButtonDetails] = []
    var selectedDevicePOP: String?
    
    static let devicedataVc  = DeviceVcViewController()
    
  
    @IBOutlet weak var DeviceVCCollcetionView: UICollectionView!
    @IBOutlet weak var deviceView: UIView!
    
   
    @IBOutlet weak var categoryCollectionView: UICollectionView!
    @IBOutlet weak var roomNameLabel: UILabel!
    @IBOutlet weak var fanView: UIView!
    @IBOutlet var mainView: UIView!
    @IBOutlet weak var fanSlider: UISlider!
    @IBOutlet weak var shortCutButtonView: UIView!
    @IBOutlet weak var dimmingView: UIView!
   
    @IBOutlet weak var acView: UIView!
    @IBOutlet weak var dimmingSliderView: UIView!
    @IBOutlet weak var openCurtuions: UIView!
    
    @IBOutlet weak var acImageView: UIView!
    @IBOutlet weak var acValuelabel: UILabel!
    @IBOutlet weak var masterView: UIView!
    
    @IBOutlet weak var closedCurtions: UIView!
    @IBOutlet weak var actemp: UIStepper!
    @IBOutlet weak var acSwingAndSpeedView: UIView!
    
    @IBOutlet weak var fan1View: UIView!
    
    @IBOutlet weak var curtionClosedImage: UIImageView!
    
    @IBOutlet weak var curtionOpenImage: UIImageView!
    
    @IBOutlet weak var mainScrollView: UIScrollView!
    
    @IBOutlet weak var deviceMenuButton: UIButton!
    
    @IBOutlet weak var dimmingImageView: UIImageView!
    
    @IBOutlet weak var roomsCollectionView: UICollectionView!
    
    var fanSliderWorkItem: DispatchWorkItem?
    var fanSliderDebounceTimer: Timer?
    let verticalSlider = UISlider()
    var fanAnimationView: LottieAnimationView?
    var curtianOpenView:LottieAnimationView?
    var curtianClosedView: LottieAnimationView?
    let fanSpeedLabel = UILabel()
    var homeId: String?
    var roomName: String?
    var isTogglingLights = false
    
    let sliderView: UIView = {
           let view = UIView()
           view.translatesAutoresizingMaskIntoConstraints = false
           return view
       }()
       
    
    
    var categorys : [String] = ["All", "Switches", "Curtains", "Camera", "Lock"]
    
  
    
    var buttonImages : [String] =  [""]
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let index = self.tabBarController?.viewControllers?.firstIndex(where: {
              guard let nav = $0 as? UINavigationController else { return false }
              return nav.viewControllers.first === self
          }) {
              print("This view controller is at tab index: \(index)")
          }
        
        print("rooms data \(rooms)")
        print("roomId is \(roomName)")
        print("details is \(buttonDetails)")
        roomNameLabel.text = roomName
      
        applyGradientBackground()
        registerCell()
        setupVerticalSlider()
        setupFanSpeedLabel()
        
       
        setupAcAnimation()
        setupFanSlider()
        applyCornerRadius()
        setupCurtainClosed()
        setupCurtainOpen()
        setupFanAnimation()
        fetchDevicesForSelectedRoom(roomId: roomId ?? "")

        setupTapGestures()
        mainScrollView.isScrollEnabled = false
        roomsCollectionView.isExclusiveTouch = true
            categoryCollectionView.isExclusiveTouch = true
        addSwipeGestures()
        NotificationCenter.default.addObserver(
            forName: .triggerLightMasterToggle,
            object: nil,
            queue: .main
        ) { _ in
            self.samplefunction()
        }

        let longPresslightGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleDimmingImageLongPress(_:)))
        dimmingView.isUserInteractionEnabled = true
        dimmingView.addGestureRecognizer(longPresslightGesture)
        
        
        let longPressfanGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleFanImageLongPress(_:)))
        fan1View.isUserInteractionEnabled = true
        fan1View.addGestureRecognizer(longPressfanGesture)
    }
    

    static func loadButtons(uniqueId: String) -> [ButtonDetails] {
            return SkromanIsraDatabaseHelper.shared.fetchButtonDetails(uniqueId: uniqueId)
        }

    
    
    @objc func closePopup(_ sender: UIButton) {
        sender.superview?.removeFromSuperview()
    }

    
    
    
    func setupTapGestures() {
        addTapGesture(to: fan1View, action: #selector(fan1ViewTapped))
        addTapGesture(to: masterView, action: #selector(masterViewTapped))
        addTapGesture(to: openCurtuions, action: #selector(curtainOpenViewTapped))
        addTapGesture(to: closedCurtions, action: #selector(curtainclosedViewTapped))
        addTapGesture(to: dimmingView, action: #selector(lightOnViewTapped))
    }

    private func addTapGesture(to view: UIView, action: Selector) {
        let tapGesture = UITapGestureRecognizer(target: self, action: action)
        view.addGestureRecognizer(tapGesture)
        view.isUserInteractionEnabled = true
    }

    
    
    func applyCornerRadius() {
        let cornerRadius: CGFloat = 10
        
        let views = [acView, dimmingView, closedCurtions, openCurtuions, masterView,fan1View]
        
        for view in views {
            view?.layer.cornerRadius = cornerRadius
            view?.clipsToBounds = true
        }
    }
    func setupFanSlider() {
            fanSlider.minimumValue = 1
            fanSlider.maximumValue = 4
            fanSlider.value = 1 // Default speed
            fanSlider.addTarget(self, action: #selector(fanSliderChanged(_:)), for: .valueChanged)
        }

        func setupFanSpeedLabel() {
            fanSpeedLabel.text = "1"
            fanSpeedLabel.textColor = .black
            fanSpeedLabel.textAlignment = .center
            fanSpeedLabel.font = UIFont.boldSystemFont(ofSize: 14)
            fanSpeedLabel.backgroundColor = UIColor.clear
            fanSpeedLabel.layer.cornerRadius = 10
            fanSpeedLabel.clipsToBounds = true
            fanSpeedLabel.frame = CGRect(x: 10, y: 0, width: 30, height: 15)
            fanSlider.addSubview(fanSpeedLabel)
            updateFanSpeedLabelPosition()
        }


    

    func updateFanSpeedLabelPosition() {
        let trackRect = fanSlider.trackRect(forBounds: fanSlider.bounds)
        let thumbRect = fanSlider.thumbRect(forBounds: fanSlider.bounds, trackRect: trackRect, value: fanSlider.value)
        
        // Adjust label to be centered over the thumb
        let labelWidth: CGFloat = 30
        let labelHeight: CGFloat = 20
        let labelX = thumbRect.midX - labelWidth / 2
        let labelY = thumbRect.midY - labelHeight / 2

        fanSpeedLabel.frame = CGRect(x: labelX, y: labelY, width: labelWidth, height: labelHeight)
    }



    func setupFanAnimation() {
        fanAnimationView = LottieAnimationView(name: "fan2")
        fanAnimationView?.frame = fanView.bounds
        fanAnimationView?.contentMode = .scaleAspectFit
        fanAnimationView?.loopMode = .loop
        fanAnimationView?.animationSpeed = 1
        fanView.addSubview(fanAnimationView!)
    }

    func setupCurtainClosed() {
        curtianClosedView = LottieAnimationView(name: "curtain-2")
        curtianClosedView?.frame = curtionClosedImage.bounds
        curtianClosedView?.contentMode = .scaleAspectFit
        curtianClosedView?.loopMode = .playOnce

        if let animation = curtianClosedView {
            curtionClosedImage.addSubview(animation)
          
            animation.play(fromProgress: 1.0, toProgress: 0.0) { finished in
                print("Curtain closed animation played in reverse from 100% to 0%")
            }
        }
    }



    
    func setupCurtainOpen() {
        curtianOpenView = LottieAnimationView(name: "curtain-2")
        curtianOpenView?.frame = curtionOpenImage.bounds
        curtianOpenView?.contentMode = .scaleAspectFit
        curtianOpenView?.loopMode = .playOnce

        if let animation = curtianOpenView {
            curtionOpenImage.addSubview(animation)
            
            // Play from beginning to mid-point (like opening halfway)
            animation.play(fromProgress: 0.0, toProgress: 0.5) { finished in
                print("Curtain open animation played from 0% to 50%")
            }
        }
    }

    
    func setupAcAnimation() {
        fanAnimationView = LottieAnimationView(name: "fan")
        guard let fanAnimationView = fanAnimationView else { return }

       
        fanAnimationView.translatesAutoresizingMaskIntoConstraints = false
        fanAnimationView.contentMode = .scaleAspectFit
        fanAnimationView.loopMode = .loop
        fanAnimationView.animationSpeed = 1
        fanAnimationView.play()

        
        acImageView.addSubview(fanAnimationView)

        
        NSLayoutConstraint.activate([
            fanAnimationView.topAnchor.constraint(equalTo: acImageView.topAnchor),
            fanAnimationView.bottomAnchor.constraint(equalTo: acImageView.bottomAnchor),
            fanAnimationView.leadingAnchor.constraint(equalTo: acImageView.leadingAnchor),
            fanAnimationView.trailingAnchor.constraint(equalTo: acImageView.trailingAnchor)
        ])
    }

    
    
    func  registerCell(){
        let catNib = UINib(nibName: "CategoryCollectionViewCell", bundle: nil)
        categoryCollectionView.register(catNib, forCellWithReuseIdentifier: "CategoryCollectionViewCell")
      
        categoryCollectionView.delegate = self
        categoryCollectionView.dataSource =  self
        roomsCollectionView.dataSource =  self
        roomsCollectionView.delegate =  self
        DeviceVCCollcetionView.dataSource = self
        DeviceVCCollcetionView.delegate = self
        let deviceNib = UINib(nibName: "ShortcutDeviceCollectionViewCell", bundle: nil)
        DeviceVCCollcetionView.register(deviceNib, forCellWithReuseIdentifier: "ShortcutDeviceCollectionViewCell")
        let roomNib = UINib(nibName: "ShRoomsCollectionViewCell", bundle: nil)
        roomsCollectionView.register(roomNib, forCellWithReuseIdentifier: "ShRoomsCollectionViewCell")
        
        
        
    }
    func applyGradientBackground() {
        let mainScreen = CAGradientLayer()
        mainScreen.frame = mainView.bounds

        mainScreen.colors = [
            UIColor(red: 163/255, green: 159/255, blue: 98/255, alpha: 1).cgColor,   // Gold
            UIColor(red: 141/255, green: 176/255, blue: 144/255, alpha: 1).cgColor,  // Green
            UIColor(red: 104/255, green: 155/255, blue: 181/255, alpha: 1).cgColor   // Blue
        ]

        mainScreen.locations = [0.0, 0.3, 0.8]  // Expands green & blue areas
        mainScreen.startPoint = CGPoint(x: 0.5, y: 0)   // Top center
        mainScreen.endPoint = CGPoint(x: 0.5, y: 1)     // Bottom center

     
        mainView.layer.sublayers?.removeAll(where: { $0 is CAGradientLayer })
        
        mainView.layer.insertSublayer(mainScreen, at: 0)
    }
    
    func setupVerticalSlider() {
        verticalSlider.translatesAutoresizingMaskIntoConstraints = false
        verticalSlider.minimumValue = 0
        verticalSlider.maximumValue = 100
        verticalSlider.value = 50

        // Rotate slider to make it vertical
        verticalSlider.transform = CGAffineTransform(rotationAngle: -.pi / 2)

      
        if let gradientImage = getGradientSliderTrackImage(size: CGSize(width: 180, height: 50), cornerRadius: 15) {
            verticalSlider.setMinimumTrackImage(gradientImage, for: .normal)
        }

      
        if let maxTrackImage = getSliderTrackImage(color: .lightGray, size: CGSize(width: 180, height: 50), cornerRadius: 15) {
            verticalSlider.setMaximumTrackImage(maxTrackImage, for: .normal)
        }

       
        if let thumbImage = UIImage(named: "brightness-2")?.resized(to: CGSize(width: 30, height: 30)) {
            verticalSlider.setThumbImage(thumbImage, for: .normal)
        }

       
        dimmingSliderView.addSubview(verticalSlider)

        NSLayoutConstraint.activate([
            verticalSlider.centerXAnchor.constraint(equalTo: dimmingSliderView.centerXAnchor),
            verticalSlider.centerYAnchor.constraint(equalTo: dimmingSliderView.centerYAnchor),
            verticalSlider.heightAnchor.constraint(equalTo: dimmingSliderView.heightAnchor, multiplier: 0.8)
        ])

        verticalSlider.addTarget(self, action: #selector(dimmSliderTouchUp(_:)), for: .valueChanged)

    }
    @objc func sliderValueChanged(_ sender: UISlider) {
        let rawValue = sender.value
        for state in receivedDeviceStates {
            guard let matchingDevice = devices.first(where: { $0.uniqueId == state.uniqueID }) else { continue }

            let category = matchingDevice.deviceCategory
            let steps: [Float] = (category == "skroman_old") ? [0, 14, 28, 42, 57, 71, 85, 100] :
                              (category == "skroman_new") ? [0, 33, 66, 100] : []

            guard !steps.isEmpty else { continue }

            let snappedValue = closestStep(to: rawValue, from: steps)
            sender.setValue(snappedValue, animated: true)

            print(" Live Snap (\(category)): \(Int(snappedValue))")
        }
    }

   

    
    func  samplefunction(){
         print("test siri data ")
        
    }

    func getGradientSliderTrackImage(size: CGSize, cornerRadius: CGFloat) -> UIImage? {
        let rect = CGRect(origin: .zero, size: size)

        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        // Create a rounded path
        let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
        path.addClip()

        // Create gradient colors (Yellow → White)
        let colors = [UIColor.white.cgColor, UIColor.yellow.cgColor]
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0.0, 1.0])!

        // Draw gradient within the rounded path
        context.drawLinearGradient(gradient,
                                   start: CGPoint(x: 0, y: size.height / 2),
                                   end: CGPoint(x: size.width, y: size.height / 2),
                                   options: [])

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image
    }
    
    func getSliderTrackImage(color: UIColor, size: CGSize, cornerRadius: CGFloat) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        
        let path = UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: cornerRadius)
        color.setFill()
        path.fill()
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    


   
    func fetchDevicesForSelectedRoom(roomId: String) {
        SkromanIsraDatabaseHelper.shared.fetchDevicesByRoomId(roomId: roomId) { [weak self] roomDevices in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.devices = roomDevices
                print("✅ Devices updated: \(self.devices.count), Devices: \(self.devices)")

                if self.devices.isEmpty {
                    self.showEmptyMessage("No devices found in this room.")
                } else {
                    self.DeviceVCCollcetionView.backgroundView = nil
                    self.fetchDeviceStatesForAllDevices()
                    self.DeviceVCCollcetionView.reloadData()
                    
                }

                self.DeviceVCCollcetionView.reloadData()
            }
        }
    }
    class ButtonManager {
        var buttons: [ButtonDetails] = []

        init(uniqueId: String) {
            self.buttons = SkromanIsraDatabaseHelper.shared.fetchButtonDetails(uniqueId: uniqueId)
            
          
        }
      
    }

    func showEmptyMessage(_ message: String) {
        let messageLabel = UILabel()
        messageLabel.text = message
        messageLabel.textColor = .gray
        messageLabel.textAlignment = .center
        messageLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false

        let backgroundView = UIView()
        backgroundView.addSubview(messageLabel)

        NSLayoutConstraint.activate([
            messageLabel.centerXAnchor.constraint(equalTo: backgroundView.centerXAnchor),
            messageLabel.centerYAnchor.constraint(equalTo: backgroundView.centerYAnchor),
            messageLabel.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor, constant: 20),
            messageLabel.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor, constant: -20)
        ])

        DeviceVCCollcetionView.backgroundView = backgroundView
    }


    
    func fetchDeviceStatesForAllDevices() {
        let dispatchGroup = DispatchGroup()
        var allDeviceStates: [DeviceStateArray] = []

        print("📌 Total fetched devices: \(devices.count)")
       
        for device in devices {
            let fetchDeviceUid = device.deviceUid.trimmingCharacters(in: .whitespacesAndNewlines)
            print("🔍 Fetching state for device UID: [\(fetchDeviceUid)]")
            
            dispatchGroup.enter()
            DispatchQueue.global(qos: .background).async {
                let deviceStates = SkromanIsraDatabaseHelper.shared.fetchDeviceStatesByDeviceUid(deviceUid: fetchDeviceUid)

                DispatchQueue.main.async {
                    if deviceStates.isEmpty {
                        print("⚠️ No states found for device UID: \(fetchDeviceUid)")
                    } else {
                        print("✅ Found \(deviceStates.count) states for device UID: \(fetchDeviceUid)")
                    }

                    let mappedStates = deviceStates.map { deviceState -> DeviceStateArray in
                        let state = DeviceStateArray(
                            uniqueID: deviceState.uniqueId,
                            modelNo: Int(deviceState.master) ?? 0,
                            deviceNumber: deviceState.deviceStateUid,
                            cDim: deviceState.configDim,
                            cNm: deviceState.configButtons,
                            cL: deviceState.childLockL,
                            cF: deviceState.childLockF,
                            cM: deviceState.childLockM,
                            workingMode: deviceState.workingMode,
                            master: Int(deviceState.master) ?? 0,
                            ack: deviceState.connectivity,
                            lightState: deviceState.lState,
                            lightSpeed: deviceState.lSpeed,
                            fanState: deviceState.fState,
                            fanSpeed: deviceState.fSpeed,
                            controlFrom: deviceState.destButton,
                            series: deviceState.series, otaStatus: deviceState.otaStatus, rRegulator: deviceState.fRegulator
                        )

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                          
                        }
                      

                        return state
                    }

                    allDeviceStates.append(contentsOf: mappedStates)
                    dispatchGroup.leave()
                }
            }
        }

        dispatchGroup.notify(queue: .main) { [self] in
            self.receivedDeviceStates = allDeviceStates
            print("devices at fetch\(receivedDeviceStates)")
            print(" Total received device states: \(self.receivedDeviceStates.count)")
            for state in self.receivedDeviceStates {
                print("\(state)")
                
                
            }
        }
       
        
        
       
        
        func fetchDeviceStatesForAllDevicesCurtions() {
            let dispatchGroup = DispatchGroup()
            var allDeviceStates: [DeviceStateArray] = []

            print("📌 Total fetched devices: \(devices.count)")

            for device in devices {
                let fetchDeviceUid = device.deviceUid.trimmingCharacters(in: .whitespacesAndNewlines)
                print("🔍 Fetching state for device UID: [\(fetchDeviceUid)]")

                dispatchGroup.enter()
                DispatchQueue.global(qos: .background).async {
                    let deviceStates = SkromanIsraDatabaseHelper.shared.fetchDeviceStatesByDeviceUid(deviceUid: fetchDeviceUid)

                    DispatchQueue.main.async {
                        if deviceStates.isEmpty {
                            print("⚠️ No states found for device UID: \(fetchDeviceUid)")
                        } else {
                            print("✅ Found \(deviceStates.count) states for device UID: \(fetchDeviceUid)")
                        }

                        let filteredStates = deviceStates.filter { deviceState in
                            let cNm = deviceState.configButtons
                            return cNm.contains("O") || cNm.contains("C") || cNm.contains("Q") || cNm.contains("Y")
                        }

                        let mappedStates = filteredStates.map { deviceState -> DeviceStateArray in
                            return DeviceStateArray(
                                uniqueID: deviceState.uniqueId,
                                modelNo: Int(deviceState.master) ?? 0,
                                deviceNumber: deviceState.deviceStateUid,
                                cDim: deviceState.configDim,
                                cNm: deviceState.configButtons,
                                cL: deviceState.childLockL,
                                cF: deviceState.childLockF,
                                cM: deviceState.childLockM,
                                workingMode: deviceState.workingMode,
                                master: Int(deviceState.master) ?? 0,
                                ack: deviceState.connectivity,
                                lightState: deviceState.lState,
                                lightSpeed: deviceState.lSpeed,
                                fanState: deviceState.fState,
                                fanSpeed: deviceState.fSpeed,
                                controlFrom: deviceState.destButton, series: deviceState.series, otaStatus: deviceState.otaStatus, rRegulator: deviceState.fRegulator
                            )
                        }

                        allDeviceStates.append(contentsOf: mappedStates)
                        dispatchGroup.leave()
                    }
                }
            }

            dispatchGroup.notify(queue: .main) { [self] in
                self.receivedDeviceStates = allDeviceStates
                print("📥 Filtered device states (O/C/Q/Y only): \(self.receivedDeviceStates.count)")
                for state in self.receivedDeviceStates {
                    print("🧾 \(state.uniqueID) → cNm: \(state.cNm)")
                }
            }
        }

    }
    
    @objc func fan1ViewTapped() {
        let allFanStatesOn = receivedDeviceStates.allSatisfy { $0.fanState == "1" }
        let newState = allFanStatesOn ? 0 : 1
        let speed = Int(fanSlider.value)

        print("Fan tap detected. All fans ON: \(allFanStatesOn). Sending state: \(newState), speed: \(speed)")

   
        if newState == 1 {
            
            fanSlider.isHidden = false
            fanAnimationView?.animationSpeed = CGFloat(speed)
                   fanAnimationView?.play()
        } else {
             
            fanSlider.isHidden = true
            fanAnimationView?.animationSpeed = CGFloat(speed)
                   fanAnimationView?.stop()
        }

        
        for state in receivedDeviceStates {
            print("Sending fan operation to \(state.uniqueID)")
            
            fanOpertion(speedValue: speed, state: newState, topic: state.uniqueID)
            
           
             print("allFanStatesOn is \(allFanStatesOn)")
           
        }
    }

    @objc func fanSliderChanged(_ sender: UISlider) {
          let newSpeed = Int(sender.value)
          print("🎚️ Slider changed. New fan speed: \(newSpeed)")

         
          fanSpeedLabel.text = "\(newSpeed)"
          fanAnimationView?.animationSpeed = CGFloat(newSpeed)
        
          updateFanSpeedLabelPosition()

        
          fanSliderWorkItem?.cancel()

        
          let workItem = DispatchWorkItem { [weak self] in
              guard let self = self else { return }
              for state in self.receivedDeviceStates {
                  print("📬 Sending updated speed to \(state.uniqueID)")
                  self.fanOpertion(speedValue: newSpeed, state: 1, topic: state.uniqueID)
              }
          }

          fanSliderWorkItem = workItem
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: workItem)
      }
    
    func fanOpertion(speedValue: Int, state: Int, topic: String) {
        print("fanOpertion START - speed: \(speedValue), state: \(state), topic: \(topic)")

        let allFan: Parameters = [
            "control": "F",
            "speed": speedValue,
            "state": state,
            "no": 1,
            "from": "A",
            "topic": topic
        ]

        print("Publishing MQTT: \(allFan)")

        if let theJSONData = try? JSONSerialization.data(withJSONObject: allFan, options: []) {
            let theJSONText = String(data: theJSONData, encoding: .utf8)
            print("📄 JSON string = \(theJSONText!)")
            fanAnimationView?.play()
            let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
            iotDataManager.publishString(theJSONText!, onTopic: topic + "/HA/A/req", qoS: .messageDeliveryAttemptedAtMostOnce)
        }
    }
    
    @objc func masterViewTapped() {
        guard !receivedDeviceStates.isEmpty else {
            print("❌ No devices found — receivedDeviceStates is empty.")
            return
        }

        // 👉 If ANY device is off (master == 0), turn them ON (newState = 1)
        // 👉 If ALL are ON, turn them OFF (newState = 0)
        let allMastersOn = receivedDeviceStates.allSatisfy { $0.master == 1 }
        let newState = allMastersOn ? 0 : 1

        print("🔘 Master tap detected. All masters ON: \(allMastersOn). Sending new state: \(newState)")
        print("receivedDeviceStates: \(receivedDeviceStates.map { "\($0.uniqueID): \($0.master)" })")

        var alreadySent: Set<String> = []

        for state in receivedDeviceStates {
            guard !alreadySent.contains(state.uniqueID) else { continue }

            // Send ONLY to those that aren't already in desired state
            if state.master != newState {
                print("📤 Sending master control to \(newState) → \(state.uniqueID)")
                masterOperation(state: newState, topic: state.uniqueID)
                alreadySent.insert(state.uniqueID)
            } else {
                print("⚠️ Skipped \(state.uniqueID) — already in desired state (\(newState))")
            }
        }
    }


    
    func masterOperation(state: Int, topic: String) {
        print("masterOperation START - state: \(state), topic: \(topic)")

        let masterPayload: Parameters = [
            "control": "M",
            "state": state,
            "no": 0,
            "from": "A",
            "speed": 0,
            "topic": topic
        ]

        print("Publishing master MQTT: \(masterPayload)")

        if let jsonData = try? JSONSerialization.data(withJSONObject: masterPayload, options: []),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
            iotDataManager.publishString(jsonString, onTopic: topic + "/HA/A/req", qoS: .messageDeliveryAttemptedAtMostOnce)
        }
    }
    
    @objc func curtainOpenViewTapped() {
        for device in receivedDeviceStates {
            let lightStatesArray = Array(device.lightState)
            let cNmArray = Array(device.cNm)

            for (index, char) in cNmArray.enumerated() where char == "O" || char == "Q" {
                guard index < lightStatesArray.count else {
                    print("⚠️ Index \(index) out of bounds for lightState in device \(device.uniqueID)")
                    continue
                }

                let currentLightChar = lightStatesArray[index]
                let currentState = String(currentLightChar)

                // 🔁 Toggle logic
                let toggledState = currentState == "1" ? "0" : "1"
                let noToSend = index + 1

                print("🪟 Curtain toggle at index \(index) (no: \(noToSend)) for \(device.uniqueID): \(currentState) → \(toggledState)")

              
                curtainOperation(state: toggledState, topic: device.uniqueID, no: noToSend)
                setupCurtainOpen()
            }
        }
    }
    func curtainOperation(state: String, topic: String, no: Int) {
        let curtainPayload: Parameters = [
            "control": "L",
            "state": Int(state),
            "no": no,
            "from": "A",
            "speed": 8,
            "topic": topic
        ]

        print("📡 Publishing Curtain MQTT: \(curtainPayload)")

        if let jsonData = try? JSONSerialization.data(withJSONObject: curtainPayload, options: []),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
            iotDataManager.publishString(jsonString, onTopic: topic + "/HA/A/req", qoS: .messageDeliveryAttemptedAtMostOnce)
        }
    }

    @objc func curtainclosedViewTapped() {
        for device in receivedDeviceStates {
            let lightStatesArray = Array(device.lightState)
            let cNmArray = Array(device.cNm)

            for (index, char) in cNmArray.enumerated() where char == "C" || char == "Y" {
                guard index < lightStatesArray.count else {
                    print("⚠️ Index \(index) out of bounds for lightState in device \(device.uniqueID)")
                    continue
                }

                let currentLightChar = lightStatesArray[index]
                let currentState = String(currentLightChar)

                // 🔁 Toggle logic
                let toggledState = currentState == "1" ? "0" : "1"
                let noToSend = index + 1

                print("🪟 Curtain toggle at index \(index) (no: \(noToSend)) for \(device.uniqueID): \(currentState) → \(toggledState)")

             
                curtainClosedOperation(state: toggledState, topic: device.uniqueID, no: noToSend)
            }
        }
    }
    func curtainClosedOperation(state: String, topic: String, no: Int) {
        let curtainPayload: Parameters = [
            "control": "L",
            "state": Int(state),
            "no": no,
            "from": "A",
            "speed": 8,
            "topic": topic
        ]

        print("📡 Publishing Curtain MQTT: \(curtainPayload)")
        setupCurtainClosed()
        if let jsonData = try? JSONSerialization.data(withJSONObject: curtainPayload, options: []),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
            iotDataManager.publishString(jsonString, onTopic: topic + "/HA/A/req", qoS: .messageDeliveryAttemptedAtMostOnce)
        }
    }
    
    
    
    
    @objc func lightOnViewTapped() {
        guard !isTogglingLights else {
            print("⚠️ Light toggle already in progress. Please wait.")
            return
        }
        
        isTogglingLights = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            self.isTogglingLights = false
            print("✅ Ready for next toggle.")
        }
        
        var lightToggleTargets: [(device: DeviceStateArray, index: Int, currentState: String)] = []

        for device in receivedDeviceStates {
            let lightStates = Array(device.lightState)
            let cNmArray = Array(device.cNm)

            let buttonDetails = SkromanIsraDatabaseHelper.shared.fetchButtonDetails(uniqueId: device.uniqueID)
            
            for (index, char) in cNmArray.enumerated() where char == "L" {
                guard index < lightStates.count else { continue }

              
                if let detail = buttonDetails.first(where: { $0.buttonNo == index + 1 && $0.isShortcut == 1 }) {
                    let state = String(lightStates[index])
                    lightToggleTargets.append((device: device, index: index, currentState: state))
                }
            }
        }

        if lightToggleTargets.isEmpty {
            print("⚠️ No shortcut-enabled light buttons found.")
            return
        }

        for target in lightToggleTargets {
            print("🔍 [Shortcut] Device: \(target.device.uniqueID), Light Index: \(target.index), Current State: \(target.currentState)")
        }

        let allLightsOn = lightToggleTargets.allSatisfy { $0.currentState == "1" }
        let newState = allLightsOn ? "0" : "1"
        
        DispatchQueue.main.async {
               self.dimmingView.backgroundColor = (newState == "1")
                   ? .white
                   : .systemGray6
           }

        DispatchQueue.main.async {
            self.dimmingView?.backgroundColor = allLightsOn ? .white : .systemGray6
        }

        print("💡 Toggling lights. All ON: \(allLightsOn). New state: \(newState)")

        for (device, index, currentState) in lightToggleTargets {
            if currentState != newState {
                let noToSend = index + 1
                let lightSpeed = device.lightSpeed
                print("📤 Sending to \(device.uniqueID), Light \(noToSend), New State: \(newState)")
                lightONOperation(state: newState, topic: device.uniqueID, no: noToSend, speed: lightSpeed)
            } else {
                print("⚠️ Light \(index + 1) on \(device.uniqueID) already in desired state.")
            }
        }
    }

    
    
    @objc func handleDimmingImageLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let shortcutVC = storyboard
            .instantiateViewController(withIdentifier: "ShortcutButtonsViewController")
                as? AddShortcutButtonsViewController {
            
            shortcutVC.mode = .dimming
            shortcutVC.devices = self.devices
            shortcutVC.rooms = self.rooms
            shortcutVC.receivedDeviceStates = self.receivedDeviceStates
            
            navigationController?.pushViewController(shortcutVC, animated: true)
        }
    }

    @objc func handleFanImageLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let shortcutVC = storyboard
            .instantiateViewController(withIdentifier: "ShortcutButtonsViewController")
                as? AddShortcutButtonsViewController {
            
            shortcutVC.mode = .fan
            shortcutVC.devices = self.devices
            shortcutVC.rooms = self.rooms
            shortcutVC.receivedDeviceStates = self.receivedDeviceStates
            
            navigationController?.pushViewController(shortcutVC, animated: true)
        }
    }

    
    func updateDimmingViewBackground() {
        let lightStates = receivedDeviceStates.flatMap { device in
            device.cNm.enumerated().compactMap { (index, char) -> String? in
                guard char == "L", index < device.lightState.count else { return nil }
                return String(Array(device.lightState)[index])
                print("💡 lightState = \(device.lightState), cNm = \(device.cNm)")

            }
        }

        let allLightsOn = lightStates.allSatisfy { $0 == "1" }
         print("allLightsOn is \(allLightsOn)")
        self.dimmingView?.backgroundColor = !allLightsOn ? .white : .gray
    }


    func lightONOperation(state: String, topic: String, no: Int, speed: String) {
        guard let stateValue = Int(state) else {
            print("❌ Invalid state value: \(state)")
            return
        }

        let lightSpeed = Int(speed) ?? 0

        let curtainPayload: [String: Any] = [
            "control": "L",
            "state": stateValue,
            "no": no,
            "from": "A",
            "speed": 0,
            "topic": topic
        ]

        print(" Publishing Light at MQTT: \(curtainPayload)")
        setupCurtainClosed()

        if let jsonData = try? JSONSerialization.data(withJSONObject: curtainPayload, options: []),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
            iotDataManager.publishString(jsonString, onTopic: topic + "/HA/A/req", qoS: .messageDeliveryAttemptedAtMostOnce)
        }
    }

    
    @objc func dimmSliderTouchUp(_ sender: UISlider) {
        let rawValue = sender.value

        for state in receivedDeviceStates {
            guard let matchingDevice = devices.first(where: { $0.uniqueId == state.uniqueID }) else { continue }

            let category = matchingDevice.deviceCategory
            let steps: [Float] = (category == "skroman_old") ? [0, 14, 28, 42, 57, 71, 85, 100] :
                              (category == "skroman_new") ? [0, 33, 66, 100] : []

            guard let snappedValue = steps.min(by: { abs($0 - rawValue) < abs($1 - rawValue) }),
                  let stepIndex = steps.firstIndex(of: snappedValue),
                  stepIndex > 0 else {
                print("Invalid snap or step index.")
                continue
            }

            let speed = String(stepIndex)

            let dimArray = Array(state.cDim)
            for (index, char) in dimArray.enumerated() {
                if char == "1" {
                    let no = index + 1
                    print("📨 On release: Topic: \(state.uniqueID), No: \(no), Speed: \(speed)")
                    lightBrightOperation(topic: state.uniqueID, no: no, speed: speed)
                }
            }
        }
    }

    
    

    func closestStep(to value: Float, from steps: [Float]) -> Float {
        return steps.min(by: { abs($0 - value) < abs($1 - value) }) ?? value
    }

    func lightBrightOperation( topic: String, no: Int, speed: String) {
        let lightSpeed = Int(speed) ?? 0
        let lightPayload: Parameters = [
            "control": "L",
            "state": 1,
            "no": no,
            "from": "A",
            "speed": lightSpeed,
            "topic": topic
        ]

        print(" Publishing Light brightness MQTT: \(lightPayload)")
        setupCurtainClosed()

        if let jsonData = try? JSONSerialization.data(withJSONObject: lightPayload, options: []),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
            iotDataManager.publishString(jsonString, onTopic: topic + "/HA/A/req", qoS: .messageDeliveryAttemptedAtMostOnce)
        }
    }
    func addSwipeGestures() {
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeLeft.direction = .left
        self.view.addGestureRecognizer(swipeLeft)

        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeRight.direction = .right
        self.view.addGestureRecognizer(swipeRight)
    }

    @objc func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        guard let currentRoomId = roomId,
              let currentIndex = rooms.firstIndex(where: { $0.roomId == currentRoomId }) else {
            return
        }

        if gesture.direction == .left {
            let nextIndex = currentIndex + 1
            guard nextIndex < rooms.count else { return }

            let nextRoom = rooms[nextIndex]
            roomId = nextRoom.roomId
            roomNameLabel.text = nextRoom.name
            let indexPath = IndexPath(item: nextIndex, section: 0)
            roomsCollectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
            
            fetchDevicesForSelectedRoom(roomId: nextRoom.roomId)
            
           

        } else if gesture.direction == .right {
            let previousIndex = currentIndex - 1
            guard previousIndex >= 0 else { return }

            let previousRoom = rooms[previousIndex]
            roomId = previousRoom.roomId
            roomNameLabel.text = previousRoom.name
            let indexPath = IndexPath(item: previousIndex, section: 0)
            roomsCollectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
            fetchDevicesForSelectedRoom(roomId: previousRoom.roomId)
            self.roomsCollectionView.reloadData()

        }
    }


    }


extension DeviceVcViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == categoryCollectionView {
            return categorys.count
        } else if collectionView == DeviceVCCollcetionView {
            print("🔄 Reloading DeviceVCCollcetionView. devices.count: \(devices.count)")
            return devices.count
        }
        else if collectionView == roomsCollectionView{
             return rooms.count
            
        }
        
        return 0
    }


    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        print("✅ cellForItemAt called for index: \(indexPath.item)") // Check if this prints
        if collectionView == categoryCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CategoryCollectionViewCell", for: indexPath) as! CategoryCollectionViewCell
            let list = categorys[indexPath.row]
            cell.categoryLabel.text = list
            return cell
        } else if collectionView == DeviceVCCollcetionView {
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ShortcutDeviceCollectionViewCell", for: indexPath) as! ShortcutDeviceCollectionViewCell
            
            let device = devices[indexPath.item]
            
            
            cell.deviceUid = device.deviceUid
            cell.deviceUniqueId = device.uniqueId
            cell.deviecNameLabel.text = "\(device.uniqueId)"
            cell.delegate = self
            cell.requestLatestDeviceState(topic: device.deviceUid)
            cell.subscribe_topic_function()
            cell.sHSceneCollectionView.reloadData()
            cell.devices = devices
           
            
     
            return cell
        }else if collectionView == roomsCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ShRoomsCollectionViewCell", for: indexPath) as! ShRoomsCollectionViewCell
            let room =  rooms[indexPath.item]
        
            cell.roomNameLabel.text =  room.name
            
            if room.roomId == roomId {
                        cell.underlineView.isHidden = false
                    } else {
                        cell.underlineView.isHidden = true
                    }
            return cell
        }
        
        return UICollectionViewCell()
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == categoryCollectionView {
            
            let selectedCategory = categorys[indexPath.row]
            print("Selected category: \(selectedCategory)")
            print("🟦 Room tapped at index \(indexPath.item)")
            if selectedCategory == "All"{
                shortCutButtonView.isHidden = false
                mainScrollView.isScrollEnabled = false
                deviceView.isHidden = true
                
               
                if let validRoomId = roomId {
                    fetchDevicesForSelectedRoom(roomId: validRoomId)
                    
                }
                DispatchQueue.main.async {
                    self.DeviceVCCollcetionView.reloadData()
                    
                }
                
            }
            else  if  selectedCategory == "Switches" {
                shortCutButtonView.isHidden = true
//                mainScrollView.isScrollEnabled = false
            
                if let validRoomId = roomId {
                    fetchDevicesForSelectedRoom(roomId: validRoomId)
                    
                    
                    DeviceVCCollcetionView.isHidden = false
                    deviceView.isHidden = false
                }
                DispatchQueue.main.async {
                    self.DeviceVCCollcetionView.reloadData()
                    self.deviceView.layoutIfNeeded()
                }
            } else if selectedCategory == "Curtains" {
                shortCutButtonView.isHidden = true
                mainScrollView.isScrollEnabled = false
                
                if let validRoomId = roomId {
                    fetchDevicesForSelectedRoom(roomId: validRoomId)
                    fetchDeviceStatesForAllDevices()
                    DeviceVCCollcetionView.isHidden = false
                    deviceView.isHidden = false
                  
                    DispatchQueue.main.async {
                        self.DeviceVCCollcetionView.reloadData()
                        self.deviceView.layoutIfNeeded()
                    }
                    
                }
                
                DispatchQueue.main.async {
                    self.DeviceVCCollcetionView.reloadData()
                    self.deviceView.layoutIfNeeded()
                    
                }
            }
            
            
            else {
                shortCutButtonView.isHidden = false
                DeviceVCCollcetionView.isHidden = true
                deviceView.isHidden = true
                mainScrollView.isScrollEnabled = true
               
            }
        } else if  collectionView == roomsCollectionView {
          
            let roomData =  rooms[indexPath.item]
            let selectedRoom = rooms[indexPath.item]
            roomNameLabel.text = selectedRoom.name
            fetchDevicesForSelectedRoom(roomId: roomData.roomId)
           
           
            print("room id at  select \(roomData.roomId)")
           
            
        }
    }

   
        func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            if collectionView == DeviceVCCollcetionView {
                return CGSize(width: 375, height: 400)
            } else {
                return CGSize(width: 70, height: 35)
            }
        }
    
}


extension DeviceVcViewController: ShortcutDeviceCellDelegate {
    func didTapShortcutButton(control: String, no: Int, state: Int, speed: Int, deviceUniqueId: String) {
           let payload: [String: Any] = [
               "control": control,
               "no": no,
               "state": state,
               "speed": speed,
               "from": "A",
               "topic": deviceUniqueId
           ]

           if let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []),
              let jsonString = String(data: jsonData, encoding: .ascii) {
               
               let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
               iotDataManager.publishString(jsonString, onTopic: "\(deviceUniqueId)/HA/A/req", qoS: .messageDeliveryAttemptedAtMostOnce)
               
               print("📡 MQTT Sent: \(jsonString)")
           }
       }

    
    func didUpdateDeviceState(_ state: DeviceStateArray) {
        if let index = self.receivedDeviceStates.firstIndex(where: { $0.uniqueID == state.uniqueID }) {
            self.receivedDeviceStates[index] = state
        } else {
            self.receivedDeviceStates.append(state)
        }
        
        print("Updated device state for: \(state.lightState)")
        
        
        let allFansOn = receivedDeviceStates.allSatisfy { $0.fanState == "1" }
        var curtainOpenStates: [(deviceID: String, index: Int, state: String)] = []

        for device in receivedDeviceStates {
            for (index, char) in device.cNm.enumerated() where char == "O" || char == "Q" {
                let lightChar = Array(device.lightState)[index]
                curtainOpenStates.append((deviceID: device.uniqueID, index: index, state: String(lightChar)))
            }
        }
        var curtainStates: [(deviceID: String, index: Int, state: String)] = []
        for device in receivedDeviceStates {
            for (index, char) in device.cNm.enumerated() where char == "C" || char == "Y" {
                let lightChar = Array(device.lightState)[index]
                curtainStates.append((deviceID: device.uniqueID, index: index, state: String(lightChar)))
            }
        }
        var lightStates: [(deviceID: String, index: Int, state: String)] = []
        for device in receivedDeviceStates {
            for (index, char) in device.cNm.enumerated() where char == "L" {
                let lightChar = Array(device.lightState)[index]
                lightStates.append((deviceID: device.uniqueID, index: index, state: String(lightChar)))
            }
        }
        // --- Begin: only shortcut-enabled “L” buttons ---
        var shortcutLightStates: [(device: DeviceStateArray, index: Int, state: String)] = []

        for device in receivedDeviceStates {
            // fetch your ButtonDetails once per device
            let details = SkromanIsraDatabaseHelper.shared.fetchButtonDetails(uniqueId: device.uniqueID)
            let lightChars = Array(device.lightState)
            let cNmArray   = Array(device.cNm)

            for (idx, char) in cNmArray.enumerated() where char == "L" {
                guard idx < lightChars.count else { continue }
                // only include if this button was marked shortcut=1
                if let bd = details.first(where: { $0.buttonNo == idx + 1 && $0.isShortcut == 1 }) {
                    shortcutLightStates.append((device: device,
                                                index: idx,
                                                state: String(lightChars[idx])))
                }
            }
        }

        let allShortcutOn = shortcutLightStates.allSatisfy { $0.state == "1" }
        DispatchQueue.main.async {
            self.dimmingView.backgroundColor = allShortcutOn ? .white : .gray
        }
        // --- End: only shortcut-enabled “L” buttons ---

        
        let allCurtainsOpen = curtainStates.allSatisfy { $0.state == "1" }
        DispatchQueue.main.async{
            self.openCurtuions?.backgroundColor = allCurtainsOpen ? .white : .gray
        }
        
        DispatchQueue.main.async {
            
            self.fanSlider.isHidden = !allFansOn
            
            if let first = self.receivedDeviceStates.first {
                let speed = Int(first.fanSpeed) ?? 0
                self.fanSlider.value = Float(speed)
                self.fanSpeedLabel.text = "\(speed)"
                self.updateFanSpeedLabelPosition()
                
                
                let anyFanOn = self.receivedDeviceStates.contains { $0.fanState == "1" }

                if anyFanOn {
                    self.fan1View.backgroundColor = .white
                    self.fanSlider.isHidden = false
                    self.fanAnimationView?.animationSpeed = CGFloat(speed)
                    self.fanAnimationView?.play()
                } else {
                    self.fan1View.backgroundColor = .gray
                    self.fanSlider.isHidden = true
                    self.fanAnimationView?.stop()
                }

            }
            
            self.openCurtuions?.backgroundColor = allCurtainsOpen ? .white : .gray

        }
        
        print("Current fan states:")
        for device in self.receivedDeviceStates {
            print("• \(device.uniqueID) - Fan: \(device.fanState), Speed: \(device.fanSpeed) cnm:\(device.cNm) lstate\(device.lightState) master\(device.master)")
            let allMastersOn = self.receivedDeviceStates.allSatisfy { $0.master == 1 }
            self.masterView?.backgroundColor = allMastersOn ? .white : .darkGray
        }
        
        print("Current curtain states:")
        for state in curtainStates {
            print("• \(state.deviceID) - Curtain Index: \(state.index), State: \(state.state)")
        }
    }
    
    func didUpdateDeviceScenes(_ scenes: [DeviceScene], for deviceUid: String) {
        print(" Received updated scenes for \(deviceUid)")
        for scene in scenes {
            print("• Scene: \(scene.sceneNo) - \(scene.sceneName)")
        }
      
    }
    
    func navigateToDeviceMenu(device: Device, states: [DeviceStateArray], buttons: [String], devices: [Device],  deviceScene: [DeviceScene], isDeviceCatgery: String?,selectedUniqueId : String?) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let menuPOPUp = storyboard.instantiateViewController(withIdentifier: "DeviceMenuViewController") as! DeviceMenuViewController
        
        menuPOPUp.devicestate = states
        menuPOPUp.buttonItems = buttons
        menuPOPUp.devices = devices
        menuPOPUp.deviceScene = deviceScene
        menuPOPUp.isDeviceCatgery = device.deviceCategory
        menuPOPUp.selectedUniqueId =  device.uniqueId
        menuPOPUp.selecetdDevicePOP = device.POP
        
        self.navigationController?.pushViewController(menuPOPUp, animated: true)
    }
    
}






extension Notification.Name {
    static let triggerLightMasterToggle = Notification.Name("triggerLightMasterToggle")
    
}
