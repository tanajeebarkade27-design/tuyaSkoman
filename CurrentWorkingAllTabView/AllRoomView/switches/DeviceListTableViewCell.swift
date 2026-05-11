//
//  DeviceListTableViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 24/06/25.
//

import UIKit
import SwiftKeychainWrapper
import AWSCore
import AWSIoT
import Alamofire
import AppIntents
import AppIntents


class DeviceListTableViewCell: UITableViewCell {
    protocol DeviceListTableViewCellDelegate: AnyObject {
        func didLongPressButton(_ buttonDetail: ButtonDetails)
        func didTapDeviceSettings(
            for device: Device,
            buttonDetails: [ButtonDetails],
            deviceStates: [DeviceStateArray],
            deviceScenes: [DeviceScene],
            deviceSchedules: [Schedule]
        )
    }
    
    
    @IBOutlet weak var cellbackgroundView: UIView!
    @IBOutlet weak var WIFIAndDevicelabel: UILabel!
    @IBOutlet weak var deviceListCollectionView: UICollectionView!
    
    @IBOutlet weak var collectionViewHeight: NSLayoutConstraint!
    
    
    @IBOutlet weak var isonlineImage: UIImageView!
    var deviceslist = ["curtains", "light", "fan"]
    weak var delegate: DeviceListTableViewCellDelegate?
    private var lastSwitchCount: Int = 0
    var cachedHeights: [String: CGFloat] = [:]
    let sliderButton = masterSlideDevicerButton()
    var buttonDetails: [ButtonDetails] = []
    var filteredButtonDetails: [ButtonDetails] = []
    var deviceUniqueid: String?
    var currentDevice: Device?
    var receivedDeviceStates: [DeviceStateArray] = []
    private var customSlider :  CustomSlider?
    var deviceScene: [DeviceScene] = []
    var deviceSchdeule:[Schedule] =  []
    var switchList: [SwitchItem] = []
    private var fetchedUniqueIds: Set<String> = []
    var visibleButtonDetails: [ButtonDetails] {
        return filteredButtonDetails.filter { btn in
            let controlName = btn.buttonControlName.uppercased()
            return controlName != "C" && controlName != "Y"
        }
        
    }
    var currentState: DeviceStateArray?
    var allSwitchList: [SwitchItem] = []
    var isHumanDetectionDevice: Bool = false
    
    var humanDetectionView: UIView!
    var humanLabel: UILabel!
    var humanToggle: UISwitch!
    var humanStatusLabel: UILabel!
    var selectedSwitchID: String?
    override func awakeFromNib() {
        super.awakeFromNib()

        contentView.addSubview(sliderButton)
        deviceListCollectionView.delegate = self
        deviceListCollectionView.dataSource = self
        NSLayoutConstraint.activate([
            sliderButton.widthAnchor.constraint(equalToConstant: 60),
            sliderButton.heightAnchor.constraint(equalToConstant: 35),
            sliderButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 7),
            sliderButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -60)
        ])

        sliderButton.onToggle = { [weak self] isOn in
            guard let self = self else { return }

           
            self.showMasterPopup()

            // ✅ your existing logic
            if let state = self.currentState {
                self.currentState = state.updatingMaster(isOn ? 1 : 0)
            }

            self.publishSliderState(isOn: isOn)
        }
        registerxib()

        // ✅ Human Detection Container
        humanDetectionView = UIView()
        humanDetectionView.translatesAutoresizingMaskIntoConstraints = false
        humanDetectionView.backgroundColor = .clear
        humanDetectionView.layer.cornerRadius = 8
        humanDetectionView.isHidden = true
        contentView.addSubview(humanDetectionView)

        NSLayoutConstraint.activate([
            humanDetectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            humanDetectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            humanDetectionView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 50),
            humanDetectionView.heightAnchor.constraint(equalToConstant: 50)
        ])

        // ✅ Label
        humanLabel = UILabel()
        humanLabel.text = "Human Detection"
        humanLabel.textColor = .white

        // ✅ SINGLE Toggle
        humanToggle = UISwitch()
        humanToggle.translatesAutoresizingMaskIntoConstraints = false
        humanToggle.onTintColor = .systemGreen

        // ✅ Stack (ONLY place where switch exists)
        let stack = UIStackView(arrangedSubviews: [humanLabel, humanToggle])
        stack.axis = .horizontal
        stack.distribution = .equalSpacing
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false

        humanDetectionView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: humanDetectionView.leadingAnchor, constant: 10),
            stack.trailingAnchor.constraint(equalTo: humanDetectionView.trailingAnchor, constant: -10),
            stack.topAnchor.constraint(equalTo: humanDetectionView.topAnchor),
            stack.bottomAnchor.constraint(equalTo: humanDetectionView.bottomAnchor)
        ])

        // ✅ Status Label (below)
        humanStatusLabel = UILabel()
        humanStatusLabel.text = ""
        humanStatusLabel.textColor = .lightGray
        humanStatusLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        humanStatusLabel.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(humanStatusLabel)

        NSLayoutConstraint.activate([
            humanStatusLabel.topAnchor.constraint(equalTo: humanDetectionView.bottomAnchor, constant: 8),
            humanStatusLabel.leadingAnchor.constraint(equalTo: humanDetectionView.leadingAnchor)
        ])

        // ✅ Toggle action
       humanToggle.addTarget(self, action: #selector(humanToggleChanged(_:)), for: .valueChanged)
    }
    override func prepareForReuse() {
        super.prepareForReuse()

        WIFIAndDevicelabel.text = nil
        isonlineImage.tintColor = .gray
        currentDevice = nil
        deviceUniqueid = nil
        receivedDeviceStates = []
        buttonDetails = []
        filteredButtonDetails = []
        deviceScene = []
        deviceSchdeule = []
        switchList = []

        collectionViewHeight.constant = 0
        lastSwitchCount = 0
        isHumanDetectionDevice = false
        humanDetectionView.isHidden = true
        deviceListCollectionView.isHidden = false
        humanStatusLabel.isHidden = false
        sliderButton.isHidden = false
        
        
        
        
    }
    
    @objc func humanToggleChanged(_ sender: UISwitch) {

        // Step 1: Revert immediately (wait for confirmation)
        sender.setOn(!sender.isOn, animated: true)

        let isTurningOn = !sender.isOn

        guard let uniqueID = deviceUniqueid else {
            print("❌ deviceUniqueid is nil")
            return
        }

        guard let viewController = self.parentViewController else {
            print("❌ parentViewController is nil")
            return
        }

        let title = "Human Detection"
        let message = isTurningOn
            ? "Do you want to turn ON human detection? You will receive notification when this feature is enabled."
            : "Do you want to turn OFF human detection?"

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        // ❌ Cancel → keep previous state
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            // nothing → already reverted
        }

        // ✅ Proceed → apply change
        let proceed = UIAlertAction(title: "Proceed", style: .default) { [weak self] _ in
            guard let self = self else { return }

            // update UI
            sender.setOn(isTurningOn, animated: true)

            // publish MQTT
            self.publishHumanDetectionState(isOn: isTurningOn, uniqueID: uniqueID)
        }

        alert.addAction(cancel)
        alert.addAction(proceed)

        viewController.present(alert, animated: true)
    }
    func publishHumanDetectionState(isOn: Bool, uniqueID: String) {

        let payload: [String: Any] = [
            "control": "H",
            "active_status": isOn ? 1 : 0,
            "from": "A",
            "topic": uniqueID
        ]

        print("📤 Human detection toggle:", payload)

        if let jsonData = try? JSONSerialization.data(withJSONObject: payload),
           let jsonString = String(data: jsonData, encoding: .utf8) {

            let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
            iotDataManager.publishString(jsonString,
                                         onTopic: "\(uniqueID)/HA/A/req",
                                         qoS: .messageDeliveryAttemptedAtMostOnce)
        }
    }
    func configure(with device: Device,
                   deviceStates: [DeviceStateArray],
                   series: String?) {

        let previousUniqueId = self.deviceUniqueid
        self.currentDevice = device
        self.deviceUniqueid = device.uniqueId
        self.WIFIAndDevicelabel.text = device.uniqueId
        self.receivedDeviceStates = deviceStates

        // ✅ Reset UI
        humanDetectionView.isHidden = true
        deviceListCollectionView.isHidden = false
        isHumanDetectionDevice = false

        // When user changes room, table cells are reused with a new device before async `switchList` is ready.
        // Stale `switchList` + new `currentDevice` made collection `configure` skip or mismatch → taps showed "unknown".
        if previousUniqueId != device.uniqueId {
            selectedSwitchID = nil
            switchList.removeAll()
            deviceListCollectionView.reloadData()
            updateCollectionHeightIfNeeded()
        }

       
        let isRadarDevice =
            (series == "human_detection_v1") ||
            device.uniqueId.uppercased().contains("RADAR")

        // MARK: - 🚨 HUMAN DETECTION DEVICE
        if isRadarDevice {

            isHumanDetectionDevice = true

            sliderButton.isHidden = true
            deviceListCollectionView.isHidden = true
            switchList.removeAll()

            humanDetectionView.isHidden = false
            collectionViewHeight.constant = 100

            humanStatusLabel.text = ""
            humanStatusLabel.textColor = .lightGray
            humanToggle.setOn(false, animated: false)

            if let tableView = self.superview(of: UITableView.self),
               let vc = tableView.dataSource as? AllRoomsViewController,
               let radar = vc.radarStates[device.uniqueId] {

                updateWiFiStatus(isOnline: true)

                let isPresent = radar.humanStatus == 1
                humanStatusLabel.text = isPresent ? "🟢 Human Present" : "⚪ No Human"
                humanStatusLabel.textColor = isPresent ? .systemGreen : .lightGray

                humanToggle.setOn(radar.activeStatus == 1, animated: false)

            } else {
                updateWiFiStatus(isOnline: false)
            }

            return
        }

        // MARK: - NORMAL DEVICE

        let state: DeviceStateArray

        if let liveState = deviceStates.first(where: { $0.uniqueID == device.uniqueId }) {

            // 🟢 ONLINE
            state = liveState
            updateWiFiStatus(isOnline: true)

        } else {

            // 🔴 OFFLINE → fallback DB
            if let dbState = SkromanIsraDatabaseHelper.shared
                .fetchDeviceStateByUniqueId(uniqueId: device.uniqueId) {

                state = mapDBStateToDeviceStateArray(dbState)

            } else {

                state = DeviceStateArray(
                    uniqueID: device.uniqueId,
                    modelNo: nil,
                    deviceNumber: "",
                    cDim: "0000",
                    cNm: "LLLL",
                    cL: "0000",
                    cF: "",
                    cM: "",
                    workingMode: nil,
                    master: 0,
                    ack: "",
                    lightState: "0000",
                    lightSpeed: "0000",
                    fanState: "0",
                    fanSpeed: "0",
                    controlFrom: "DB",
                    series: nil,
                    otaStatus: nil,
                    rRegulator: nil
                )
            }

            updateWiFiStatus(isOnline: false)
        }

        self.currentState = state
        sliderButton.setState(state.master == 1, sendCallback: false)

        // MARK: - 🚀 BACKGROUND PROCESSING (NO LAG)

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            // ✅ DB fetch (background)
            let buttonDetails = SkromanIsraDatabaseHelper.shared
                .fetchButtonDetails(uniqueId: device.uniqueId)

            let scenes = SkromanIsraDatabaseHelper.shared
                .fetchScenesByUniqueId(uniqueId: device.uniqueId)

            let schedules = SkromanIsraDatabaseHelper.shared
                .fetchSchedulesByDeviceUid(deviceUid: device.deviceUid)

            // ✅ Sort (background)
            let sortedButtons = buttonDetails.sorted { $0.buttonNo < $1.buttonNo }
            let sortedScenes = scenes.sorted { (Int($0.sceneNo) ?? 0) < (Int($1.sceneNo) ?? 0) }
            let sortedSchedules = schedules.sorted { $0.scheduleNumber < $1.scheduleNumber }

            // ✅ Heavy switch creation (background)
            let switches = self.createSwitches(
                from: device,
                deviceState: state,
                buttonDetails: sortedButtons
            )

            // MARK: - 🎯 UPDATE UI (MAIN THREAD ONLY ONCE)

            DispatchQueue.main.async {
                
                self.filteredButtonDetails = sortedButtons
                self.deviceScene = sortedScenes
                self.deviceSchdeule = sortedSchedules
                self.switchList = switches
                
                self.deviceListCollectionView.reloadData()
                self.updateCollectionHeightIfNeeded()
                
                // ✅ Restore selection
                if let selectedID = self.selectedSwitchID,
                   let index = self.switchList.firstIndex(where: {
                       $0.uniqueID + "_\($0.switchIndex)" == selectedID
                   }) {
                    
                    let indexPath = IndexPath(item: index, section: 0)
                    
                    DispatchQueue.main.async {
                        self.deviceListCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
                    }
                }
            }
        }
    }
    
    func reloadCollectionData() {
        deviceListCollectionView.reloadData()
        updateCollectionHeightIfNeeded()
    }
    
    
    func showMasterPopup() {
        guard let parentVC = self.parentViewController else { return }

        let popup = SyncProcessingPopup(frame: parentVC.view.bounds)
        popup.configure(title: "Master", message: "Please wait...")

        parentVC.view.addSubview(popup)

        // Auto remove after 1 sec
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            popup.stop()
            popup.removeFromSuperview()
        }
    }
    
    @IBAction func deviceSettingButton(_ sender: Any) {
        guard let device = currentDevice else { return }
        print ("setting btn")
        let fetchedScenes = SkromanIsraDatabaseHelper.shared.fetchScenesByUniqueId(uniqueId: device.uniqueId)
        let sortedScenes = fetchedScenes.sorted { (Int($0.sceneNo) ?? 0) < (Int($1.sceneNo) ?? 0) }
        deviceScene = sortedScenes
        
        let schedule = SkromanIsraDatabaseHelper.shared.fetchSchedulesByDeviceUid(deviceUid: device.deviceUid)
        
        let sortedSchedule = schedule.sorted { $0.scheduleNumber < $1.scheduleNumber }
        
        
        deviceSchdeule = sortedSchedule
        
        
        print("📦 Device Scenes Fetched: \(deviceScene.map { "\($0.sceneNo): \($0.sceneName)" })")
        print("📦 Device schedule Fetched: \(sortedSchedule)")
        
        delegate?.didTapDeviceSettings(
            for: device,
            buttonDetails: filteredButtonDetails,
            deviceStates: receivedDeviceStates,
            deviceScenes: deviceScene,
            deviceSchedules: deviceSchdeule
        )
    }
    
    
    func fetchDeviceScenes(selectdeviceUniqueid: String) {
        DispatchQueue.main.async {
            self.deviceScene.removeAll()
            
        }
        
        let fetchedScenes = SkromanIsraDatabaseHelper.shared.fetchScenesByUniqueId(uniqueId: selectdeviceUniqueid)
        
        let sortedScenes = fetchedScenes.sorted {
            (Int($0.sceneNo) ?? 0) < (Int($1.sceneNo) ?? 0)
        }
        
        DispatchQueue.main.async {
            self.deviceScene.append(contentsOf: sortedScenes)
            print("🔄 Appended Scenes: \(sortedScenes.map { "\($0.sceneNo): \($0.sceneName)" })")
            
        }
    }
    
    func fetchSchedule( deviceUid: String) {
        deviceSchdeule.removeAll()
        deviceSchdeule = []
        let schedule = SkromanIsraDatabaseHelper.shared.fetchSchedulesByDeviceUid(deviceUid: deviceUid)
        
        let sortedSchedule = schedule.sorted { $0.scheduleNumber < $1.scheduleNumber } // Sorting in Swift
        
        
        deviceSchdeule = sortedSchedule
        
        
        print("Sorted Schedule: \(deviceSchdeule)")
    }
    
    
    func configure(isOn: Bool) {
        sliderButton.setState(isOn)
    }
    
    
    override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    func registerxib(){
        let uiNib = UINib(nibName: "DeviceListCollectionViewCell", bundle:nil)
        deviceListCollectionView.register(uiNib, forCellWithReuseIdentifier: "DeviceListCollectionViewCell")
    }
    
    func fetchButtonsDetails(SelectedUniqueUid: String) {

        buttonDetails.removeAll()
        filteredButtonDetails.removeAll()
     
        buttonDetails = SkromanIsraDatabaseHelper.shared
            .fetchButtonDetails(uniqueId: SelectedUniqueUid)

        buttonDetails.sort { $0.buttonNo < $1.buttonNo }

        let invalidFirstChars: Set<Character> = ["S","W","X","G","H","I","J"]

        filteredButtonDetails = buttonDetails.filter {
            guard let firstChar = $0.buttonControlName.uppercased().first else { return false }
            return !invalidFirstChars.contains(firstChar)
        }

     
              guard let device = currentDevice,
                    let state = currentState else {
                  print("❌ No state available")
                  return
              }

        print("🔄 Rebuilding switches from MQTT for \(device.uniqueId)")

        let oldSwitchList = self.switchList

        let newSwitchList = createSwitches(
            from: device,
            deviceState: state,
            buttonDetails: filteredButtonDetails
        )

        var indexPathsToReload: [IndexPath] = []

        for (index, newItem) in newSwitchList.enumerated() {

            if index < oldSwitchList.count {

                let oldItem = oldSwitchList[index]

                if oldItem.isOnState != newItem.isOnState ||
                   oldItem.speed != newItem.speed ||
                   oldItem.isChildLocked != newItem.isChildLocked {

                    indexPathsToReload.append(IndexPath(item: index, section: 0))
                }

            } else {
                indexPathsToReload.append(IndexPath(item: index, section: 0))
            }
        }

        DispatchQueue.global(qos: .userInitiated).async {

            let newSwitchList = self.createSwitches(
                from: device,
                deviceState: state,
                buttonDetails: self.filteredButtonDetails
            )

            var indexPathsToReload: [IndexPath] = []

            for (index, newItem) in newSwitchList.enumerated() {

                if index < self.switchList.count {
                    let oldItem = self.switchList[index]

                    if oldItem.isOnState != newItem.isOnState ||
                       oldItem.speed != newItem.speed ||
                       oldItem.isChildLocked != newItem.isChildLocked {

                        indexPathsToReload.append(IndexPath(item: index, section: 0))
                    }
                } else {
                    indexPathsToReload.append(IndexPath(item: index, section: 0))
                }
            }

            DispatchQueue.main.async {

                let oldCount = self.switchList.count
                self.switchList = newSwitchList

                if oldCount == newSwitchList.count && !indexPathsToReload.isEmpty {
                    self.deviceListCollectionView.performBatchUpdates {
                        self.deviceListCollectionView.reloadItems(at: indexPathsToReload)
                    }
                } else {
                    self.deviceListCollectionView.reloadData()
                }

                self.updateCollectionHeightIfNeeded()
            }
        }
    }
    func updateCollectionHeightIfNeeded() {

        deviceListCollectionView.layoutIfNeeded()
        let height = deviceListCollectionView.collectionViewLayout.collectionViewContentSize.height

        if collectionViewHeight.constant != height {
            collectionViewHeight.constant = height

            if let tableView = self.superview(of: UITableView.self) {
                tableView.beginUpdates()
                tableView.endUpdates()
            }
        }
    }
    
    func reloadCollectionViewAndResize() {

        deviceListCollectionView.reloadData()
        deviceListCollectionView.layoutIfNeeded()

        let height = deviceListCollectionView.collectionViewLayout.collectionViewContentSize.height

        if collectionViewHeight.constant != height {

            collectionViewHeight.constant = height

            DispatchQueue.main.async {
                if let tableView = self.superview(of: UITableView.self) {
                    tableView.beginUpdates()
                    tableView.endUpdates()
                }
            }
        }
    }
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }

        let point = gesture.location(in: deviceListCollectionView)
        guard let indexPath = deviceListCollectionView.indexPathForItem(at: point) else { return }
        guard indexPath.item < switchList.count else { return }

        let switchItem = switchList[indexPath.item]
        if let buttonDetail = switchItem.buttonDetail {
            delegate?.didLongPressButton(buttonDetail)
            return
        }
        // Fallback: match by device + button index when detail was not attached to the switch model
        if let uid = currentDevice?.uniqueId,
           let bd = buttonDetails.first(where: {
               $0.uniqueId == uid && $0.buttonNo == switchItem.switchIndex
           }) {
            delegate?.didLongPressButton(bd)
        }
    }
    
    
    func publishSliderState(isOn: Bool) {
        guard let uniqueID = self.deviceUniqueid else {
            print("❌ deviceUniqueid not available")
            return
        }
        
        let payload: Parameters = [
            "control": "M",
            "no": 1,
            "state": isOn ? 0 : 1,
            "speed": 0,
            "from": "A",
            "topic": uniqueID
        ]
        
        print("📤 Sending slider payload: \(payload)")
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            
            let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
            iotDataManager.publishString(jsonString, onTopic: "\(uniqueID)/HA/A/req", qoS: .messageDeliveryAttemptedAtMostOnce)
        }
    }
    
    func createSwitches(
        from device: Device,
        deviceState: DeviceStateArray,
        buttonDetails: [ButtonDetails]
    ) -> [SwitchItem] {
        var switches: [SwitchItem] = []
        let lightRelevantChars: Set<Character> = ["L", "O", "D", "Q", "R", "A"]
        let hasOpen = deviceState.cNm.contains("O")
        let hasClose = deviceState.cNm.contains("C")
        let hasCurtain = hasOpen && hasClose

        for (index, char) in deviceState.cNm.enumerated() {

            // ===============================
            // ✅ CURTAIN LOGIC (ADDED BLOCK)
            // ===============================
            if hasCurtain {

                // Create curtain ONLY at "O" position
                if char == "O",
                   index < deviceState.lightState.count {

                    let buttonDetail = buttonDetails.first(where: { $0.buttonNo == index + 1 })

                    switches.append(SwitchItem(
                        name: "Curtain",
                        type: .light,
                        switchIndex: index + 1,
                        isOnState: 0,
                        isChildLocked: 0,
                        speed: nil,
                        uniqueID: deviceState.uniqueID,
                        buttonDetail: buttonDetail,
                        configDim: nil,
                        destButton: index + 1,
                        fanDest: nil,
                        isShortcut: buttonDetail?.isShortcut,
                        nextState: nil,
                        rRegulator: deviceState.rRegulator
                    ))

                    continue
                }

                // Ignore "C" completely
                if char == "C" {
                    continue
                }
            }
            // ===============================
            // 🔚 END CURTAIN LOGIC
            // ===============================


           
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

            // ✅ Match by buttonNo instead of index
            let buttonDetail = buttonDetails.first(where: { $0.buttonNo == index + 1 })

            // ✅ Handle nextState for C/Y
            var nextState: Int? = nil
            if let cIndex = deviceState.cNm.firstIndex(of: "C") {
                let intIndex = deviceState.cNm.distance(from: deviceState.cNm.startIndex, to: cIndex)
                if intIndex < deviceState.lightState.count {
                    let cState = deviceState.lightState[deviceState.lightState.index(deviceState.lightState.startIndex, offsetBy: intIndex)]
                    nextState = (cState == "1" ? 1 : 0)
                }
            }
            if let yIndex = deviceState.cNm.firstIndex(of: "Y") {
                let intIndex = deviceState.cNm.distance(from: deviceState.cNm.startIndex, to: yIndex)
                if intIndex < deviceState.lightState.count {
                    let yState = deviceState.lightState[deviceState.lightState.index(deviceState.lightState.startIndex, offsetBy: intIndex)]
                    nextState = (yState == "1" ? 1 : 0)
                }
            }

            let switchType: SwitchType
            let switchName: String

            if char == "A" {
                switchType = .ac
                switchName = "AC\(index + 1)"
            } else {
                switchType = .light
                switchName = "L\(index + 1)"
            }

            
            
            switches.append(SwitchItem(
                name: switchName,
                type: switchType,
                switchIndex: index + 1,
                isOnState: isOn,
                isChildLocked: isChildLocked,
                speed: speedChar,
                uniqueID: deviceState.uniqueID,
                buttonDetail: buttonDetail,
                configDim: configDimChar,
                destButton: index + 1,
                fanDest: nil,
                isShortcut: buttonDetail?.isShortcut,
                nextState: nextState,
                rRegulator: deviceState.rRegulator
            ))

        }

      

    


        if deviceState.fanState != "NA" && !deviceState.fanState.isEmpty {
            let fanButtons = buttonDetails
                .filter { $0.buttonControlName == "F" }
                .sorted { $0.buttonNo < $1.buttonNo }

            for (index, fanChar) in deviceState.fanState.enumerated() {
                let isOn = fanChar == "1" ? 1 : 0
                let speedChar = index < deviceState.fanSpeed.count
                    ? String(deviceState.fanSpeed[deviceState.fanSpeed.index(deviceState.fanSpeed.startIndex, offsetBy: index)])
                    : nil

                // ✅ Decode 3-bit child lock segments
                var isChildLocked = 0
                if deviceState.cF.count >= 6 {
                    // Each fan has 3 bits in cF
                    let start = index * 3
                    let end = start + 3
                    let startIndex = deviceState.cF.index(deviceState.cF.startIndex, offsetBy: start)
                    let endIndex = deviceState.cF.index(deviceState.cF.startIndex, offsetBy: min(end, deviceState.cF.count))
                    let segment = String(deviceState.cF[startIndex..<endIndex])

                    // If any of those 3 bits = 1 → fan locked
                    if segment.contains("1") {
                        isChildLocked = 1
                    }
                } else if index < deviceState.cF.count {
                    // Fallback for simple case (1-bit per fan)
                    isChildLocked = (deviceState.cF[deviceState.cF.index(deviceState.cF.startIndex, offsetBy: index)] == "1" ? 1 : 0)
                }

                let buttonDetail = index < fanButtons.count ? fanButtons[index] : nil

                print("➡️ Creating Fan\(index+1): isOn=\(isOn), speed=\(speedChar ?? "nil"), lock=\(isChildLocked), cF=\(deviceState.cF), btn=\(buttonDetail?.buttonNo ?? -1)")

                
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
                    isShortcut: buttonDetail?.isShortcut,
                    rRegulator: deviceState.rRegulator
                ))

            }
        } else {
            print("⚠️ Skipping fan switches — fanState is \(deviceState.fanState)")
        }


        debugLog("✅ All switches created: \(switches)")
        return switches
    }
    
    
    
    



}


extension DeviceListTableViewCell : UICollectionViewDataSource, UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return switchList.count
    }

    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        guard indexPath.item < switchList.count else {
            return collectionView.dequeueReusableCell(
                withReuseIdentifier: "DeviceListCollectionViewCell",
                for: indexPath
            )
        }

        let switchItem = switchList[indexPath.item]

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "DeviceListCollectionViewCell",
            for: indexPath
        ) as! DeviceListCollectionViewCell

        guard let device = currentDevice, switchItem.uniqueID == device.uniqueId else {
            cell.prepareForReuse()
            return cell
        }

        cell.configure(with: switchItem, device: device, nextState: switchItem.nextState)

        // ✅ Keep datasource in sync with cell-level toggles (prevents reuse bleed).
        let cellID = switchItem.uniqueID + "_\(switchItem.switchIndex)"
        cell.onSwitchItemUpdated = { [weak self] updated in
            guard let self = self else { return }
            let updatedID = updated.uniqueID + "_\(updated.switchIndex)"
            guard updatedID == cellID else { return }
            if let idx = self.switchList.firstIndex(where: { $0.uniqueID + "_\($0.switchIndex)" == updatedID }) {
                self.switchList[idx] = updated
            }
        }

        
        if cell.gestureRecognizers?.isEmpty ?? true {
            let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
            cell.addGestureRecognizer(longPress)
        }
        
        let item = switchList[indexPath.item]
        let currentID = item.uniqueID + "_\(item.switchIndex)"

        let isSelected = currentID == selectedSwitchID

//        cell.cellBackgroundView.layer.borderWidth = isSelected ? 2 : 0
//        cell.cellBackgroundView.layer.borderColor = isSelected ? UIColor.green.cgColor : UIColor.clear.cgColor

        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let leftInset: CGFloat = 8
        let rightInset: CGFloat = 8
        let spacing: CGFloat = 8
        let columns: CGFloat = 2

        let totalSpacing = leftInset + rightInset + spacing * (columns - 1)
        let availableWidth = collectionView.bounds.width - totalSpacing
        let baseCellWidth = availableWidth / columns

        return CGSize(width: baseCellWidth, height: 100)
    }
    
   
    
    func mapDBStateToDeviceStateArray(_ dbState: DeviceState) -> DeviceStateArray {

        return DeviceStateArray(
            uniqueID: dbState.uniqueId,

            modelNo: nil, // DB doesn’t have Int modelNo → keep nil
            deviceNumber: "",

            cDim: dbState.configDim,
            cNm: dbState.configButtons,
            cL: dbState.childLockL,
            cF: dbState.childLockF,
            cM: dbState.destButton,

            workingMode: dbState.workingMode,
            master: Int(dbState.master) ?? 0,
            ack: "",

            lightState: dbState.lState,
            lightSpeed: dbState.lSpeed,

            fanState: dbState.fState,
            fanSpeed: dbState.fSpeed,

            controlFrom: "DB",   // important
            series: dbState.series,
            otaStatus: dbState.otaStatus,

            rRegulator: dbState.fRegulator
        )
    }
    
    func updateWiFiStatus(isOnline: Bool) {

        let imageName = isOnline ? "wifi" : "wifi.slash"

        isonlineImage.image = UIImage(systemName: imageName)
        isonlineImage.tintColor = isOnline ? .systemGreen : .systemRed
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

       
        guard indexPath.item < switchList.count else { return }

        let item = switchList[indexPath.item]

       
        guard let cell = collectionView.cellForItem(at: indexPath) as? DeviceListCollectionViewCell else { return }

      
        guard cell.device?.uniqueId == item.uniqueID else { return }

        
        cell.flashTapAnimation()

      
        cell.performToggle()

        // ❗ Optional: if you really need reload
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            collectionView.reloadItems(at: [indexPath])
        }
    }
}

extension UIView {
    func superview<T: UIView>(of type: T.Type) -> T? {
        if let view = self.superview as? T {
            return view
        }
        return self.superview?.superview(of: type)
    }
}

extension DeviceStateArray {
    func updatingMaster(_ newValue: Int) -> DeviceStateArray {
        return DeviceStateArray(
            uniqueID: self.uniqueID,
            modelNo: self.modelNo,
            deviceNumber: self.deviceNumber,
            cDim: self.cDim,
            cNm: self.cNm,
            cL: self.cL,
            cF: self.cF,
            cM: self.cM,
            workingMode: self.workingMode,
            master: newValue,   // ✅ updated
            ack: self.ack,
            lightState: self.lightState,
            lightSpeed: self.lightSpeed,
            fanState: self.fanState,
            fanSpeed: self.fanSpeed,
            controlFrom: self.controlFrom,
            series: self.series,
            otaStatus: self.otaStatus,
            rRegulator: self.rRegulator
        )
    }
}
