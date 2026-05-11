//
//  AllRoomsViewController.swift
//  SkromanIsra
//
//  Created by Admin on 09/06/25.
//

import UIKit
import SwiftKeychainWrapper
import AWSCore
import AWSIoT
import Alamofire
import ThingSmartLockKit


protocol DeviceStateConfigurable: AnyObject {
    func configure(with buttonDetails: [ButtonDetails],deviceStates: [DeviceStateArray] , filteredDevices: [Device] )
}
 
protocol AllRoomsDelegate: AnyObject {
    func didChangeMasterState(to state: Int)
}


class AllRoomsViewController: UIViewController, DeviceListTableViewCell.DeviceListTableViewCellDelegate {

    @IBOutlet weak var roomView: UIView!
    @IBOutlet var backgroundView: UIView!
    
    @IBOutlet weak var HomeNameLabel: UILabel!
    
    @IBOutlet weak var selectedRoomNameLabel: UILabel!
    
    @IBOutlet weak var roomsCollectionView: UICollectionView!
    
    @IBOutlet weak var CategoryScrollView: UIView!
    
    @IBOutlet weak var categoryStackView: UIStackView!
    
    @IBOutlet weak var buttonView: UIView!
    
    @IBOutlet weak var AcView: UIView!
    
    @IBOutlet weak var leftswingButton: UIButton!
    
    @IBOutlet weak var acOnOffButton: UIButton!
    
    @IBOutlet weak var rightSwiftButton: UIButton!
    
    @IBOutlet weak var acTempLabel: UILabel!
    
    @IBOutlet weak var shortcutView: UIView!
    
    @IBOutlet weak var catagaryCollectionView: UICollectionView!
    
    @IBOutlet weak var buttonsCollectionView: UICollectionView!
    
    @IBOutlet weak var lockCollectionView: UICollectionView!
    
    @IBOutlet weak var stackScrollView: UIScrollView!
    
    @IBOutlet weak var AcCircularView: UIView!
    
    @IBOutlet weak var switchView: UIView!
    var selectedRoomId: String?
    
    @IBOutlet weak var curtainView: UIView!
    
    @IBOutlet weak var backgroundimage: UIImageView!
    
    @IBOutlet weak var masterButton: UIButton!
    @IBOutlet weak var deviceListTableView: UITableView!
    
    @IBOutlet weak var CamereView: UIView!
    
    @IBOutlet weak var LockView: UIView!
    
    @IBOutlet weak var roomscnelabel: UILabel!
    
    @IBOutlet weak var lockVIewLabel: UILabel!
    
    @IBOutlet weak var cameralabel: UILabel!
    
    var homeNameshow : String?
    private var simpleButton: UIButton?
    
    @IBOutlet weak var roomSceneView: UIView!
    
    @IBOutlet weak var roomlistView: UIView!
    
    @IBOutlet weak var curtaintableView: UITableView!
    
    @IBOutlet weak var acCommingSoonlabel: UILabel!
    private var isOn = false
    var HomeId : String?
    var rooms: [Room] = []
    var devices: [Device] = []
    var cartagarys = ["All", "Switches","AC","Curtains", "Lock", "Camera"]
    var deviceList =  ["Lights","Curtains","Dimmable","Fans"]
    var deviceImages  = ["LightBulb","curtain-filled","LightBulb" ,"Fan1"]
    // Fallback (static) arrays
    let defaultRoomScenes = ["Scene 1","Scene 2","Scene 3","Scene 4","Scene 5","Scene 6","Scene 7","Scene 8"]
    let defaultRoomSceneIcons = ["scene1","Scene","scene3","scene4","scene1","Scene","scene3","scene4"]
    var lastSelectedRoomIndex: IndexPath?
  
    private var acCircularHeightConstraint: NSLayoutConstraint?
    var selectedRoomName:String?
    // Fetched scenes from DB (empty if none)
    var fetchedRoomScenes: [(sceneNo: String, sceneName: String, sceneIcon: String, roomId: String)] = []
    var mergedScenes: [(sceneNo: String, sceneName: String, sceneIcon: String)] = []
    var currentMasterState: Int = 0
    var currentACSpeed = 1
    var selectedCategoryIndex: IndexPath?
    var filteredDevices: [Device] = []
    let acSlider = FanSlider()
    var deviceUniqueid: String?
    var buttonDetails: [ButtonDetails] = []
    var allFetchedDevices: [Device] = []
    var iotDataManager: AWSIoTDataManager!
    var iotManager: AWSIoTManager!
    var iot: AWSIoT!
    var connectIoTDataWebSocket: UIButton!
    var connected = false
    private let circularSlider = CircularSliderView()
    var connectButton: UIButton!
    var currentDeviceState: DeviceStateArray?
    
    var receivedDeviceStates: [DeviceStateArray] = []
    var receivedDeviceStatesDict: [String: DeviceStateArray] = [:]

    /// MQTT states for devices in the **selected room** only. `receivedDeviceStates` keeps every subscribed device; All-tab shortcuts must not read/control another room.
    private var deviceStatesForCurrentRoom: [DeviceStateArray] {
        guard !devices.isEmpty else { return [] }
        let allowed = Set(devices.map { $0.uniqueId })
        return receivedDeviceStates.filter { allowed.contains($0.uniqueID) }
    }
    var switchItems: [SwitchItem] = []
    var radarStates: [String: TheftDetectorState] = [:]
    var filteredButtonDetails: [ButtonDetails] = []
    var subscribedTopics: Set<String> = []
    var logTextView: UITextView!
    var subscribedDeviceIds: Set<String> = []
    var masterSliderView: MasterButtonSliderView?
     
    var selectedDevice: Device?
    private var noRoomsView: UIView?
    private var isCircularSliderAdded = false
    var cachedButtonDetails = [String: [ButtonDetails]]()
    var mappedValues: [[String: String]] = []
    weak var delegate: AllRoomsDelegate?
    var isInitialStateLoaded = false
    @IBOutlet weak var roomSceneCollectionView: UICollectionView!
    private var noDevicesView: UIView?

    @IBOutlet weak var btnScrollView: UIScrollView!
    
    var syncPopup: SyncProcessingPopup?
    
    var deviceSeries: [String: String] = [:]

    // MARK: - MQTT feedback-driven sync
    private var isDeviceStateSyncInProgress = false
    private var syncExpectedDeviceIds: Set<String> = []
    private var syncReceivedDeviceIds: Set<String> = []
    private var syncRetryCounts: [String: Int] = [:]
    private var syncTimeoutWorkItem: DispatchWorkItem?
    private var syncRefreshControls: [UIRefreshControl] = []
    
    var tuyaHomeId: Int64?
    var tuyaRoomId: Int64?
    var tuyaLockDevices: [TuyaDeviceModel] = []
    private let refreshControl = UIRefreshControl()
    
    var buttonItems: [String] = [] {
        didSet {
            DispatchQueue.main.async {
//                self.ShButtonCollectionView.reloadData()
//                self.sHSceneCollectionView.reloadData()
            }
        }
    }
    
    override func viewDidLoad() {
    
       
        super.viewDidLoad()
        
        backgroundimage.contentMode = .scaleAspectFill
        backgroundimage.translatesAutoresizingMaskIntoConstraints = false
        deviceListTableView.alwaysBounceVertical = true
           curtaintableView.alwaysBounceVertical = true
        NSLayoutConstraint.activate([
            backgroundimage.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundimage.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundimage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundimage.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        print("HomeId at all room\(HomeId)")
        fetchRoomsForSelectedHome()
        registerXIb()
        roomsCollectionView.reloadData()
        roomSceneCollectionView.reloadData()
       print("selectedRoomId is \(selectedRoomId)")
        roomsCollectionView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 15)
        catagaryCollectionView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 15)
       
        roomView.layer.cornerRadius = 25
           roomView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
           roomView.clipsToBounds = true
     
        roomView.backgroundColor = UIColor(hex: "#FFFFFF"/*, alpha: 0.9*/)

        roomsCollectionView.indicatorStyle = .white
        catagaryCollectionView.indicatorStyle =  .white
        customizeScrollIndicator(for: roomsCollectionView)
        customizeScrollIndicator(for: catagaryCollectionView)
       // fetchDeviceByRoomId()
//        deviceListTableView.rowHeight = UITableView.automaticDimension
//            deviceListTableView.estimatedRowHeight = 430
        
        deviceListTableView.rowHeight = UITableView.automaticDimension
        deviceListTableView.estimatedRowHeight = 200
        curtaintableView.rowHeight = UITableView.automaticDimension
        curtaintableView.estimatedRowHeight = 200

     
        setupACSliderUI()
        mergedScenes = defaultScenes
        if let powerImage = UIImage(systemName: "power") {
            let resized = UIGraphicsImageRenderer(size: CGSize(width: 12, height: 12)).image { _ in
                powerImage.draw(in: CGRect(origin: .zero, size: CGSize(width: 12, height: 12)))
            }
            acOnOffButton?.setImage(resized.withRenderingMode(.alwaysTemplate), for: .normal)
        }
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleSceneLongPress(_:)))
           roomSceneCollectionView.addGestureRecognizer(longPressGesture)
        acOnOffButton.addTarget(self, action: #selector(toggleACPower), for: .touchUpInside)
       

        let longPresac = UILongPressGestureRecognizer(target: self, action: #selector(acSliderLongPressed(_:)))
        longPresac.minimumPressDuration = 0.6
        AcView.addGestureRecognizer(longPresac)

        NotificationCenter.default.addObserver(self,
         selector: #selector(loadTuyaDevices),
         name: NSNotification.Name("TuyaSyncDone"),
         object: nil)

      

        NotificationCenter.default.addObserver(self, selector: #selector(handleMasterSliderNotification(_:)), name: .masterSliderSwiped, object: nil)

      
        deviceListTableView.isScrollEnabled = true
            deviceListTableView.alwaysBounceVertical = true
            curtaintableView.isScrollEnabled = true
            curtaintableView.alwaysBounceVertical = true

            let firstCategoryIndexPath = IndexPath(item: 0, section: 0)
            selectedCategoryIndex = firstCategoryIndexPath
            catagaryCollectionView.selectItem(at: firstCategoryIndexPath, animated: false, scrollPosition: [])
            collectionView(catagaryCollectionView, didSelectItemAt: firstCategoryIndexPath)
        connetion_aws_function()
        
//        let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleRoomSwipe(_:)))
//        leftSwipe.direction = .left
//        shortcutView.addGestureRecognizer(leftSwipe)

//        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleRoomSwipe(_:)))
//        rightSwipe.direction = .right
//        shortcutView.addGestureRecognizer(rightSwipe)
       
        
        NotificationCenter.default.addObserver(
               self,
               selector: #selector(handleCenterButtonNotification(_:)),
               name: .centerButtonTappedNotification,
               object: nil
           )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAllTabShortcutsDidChange),
            name: .allTabShortcutsDidChange,
            object: nil
        )
        roomSceneView.backgroundColor =  UIColor.white.withAlphaComponent(0.05)
        roomSceneView.cornerRadius =  20
        roomSceneView.clipsToBounds = true
        
        
        //startBlinking(label: lockVIewLabel)
        startBlinking(label: cameralabel)
        //startBlinking(label: acCommingSoonlabel)
        
    setupCircularSlider()
        refreshControl.addTarget(self, action: #selector(refreshSwitchesData), for: .valueChanged)
           deviceListTableView.refreshControl = refreshControl
         

    }
    @objc func refreshSwitchesData() {

        print("🔄 Pull to refresh triggered")

        startDeviceStateSync(triggeringRefreshControl: refreshControl)
        fetchDeviceByRoomId()
    }


    @objc private func handleCenterButtonNotification(_ notification: Notification) {
        if let userInfo = notification.userInfo {
            if let devices = userInfo["deviceList"] as? [String],
               let buttons = userInfo["buttonDetails"] as? [ButtonDetails],
            let receivedState = userInfo["receivedDeviceStates"] as? [DeviceStateArray] {
                print("Received from tab bar button: \(devices), \(buttons)")
                 
            }
        }
        setupRefreshControl()
    }
    
    @objc func loadTuyaDevices() {
        fetchDeviceByRoomId()
        fetchWithRetry()
    }
    
    func fetchWithRetry() {
        fetchDeviceByRoomId()

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if self.devices.isEmpty {
                print("🔁 Retry fetching devices...")
                self.fetchDeviceByRoomId()
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        fetchRoomsForSelectedHome()
        
        HomeNameLabel.text =  homeNameshow
        if let previousIndex = selectedCategoryIndex {
            catagaryCollectionView.deselectItem(at: previousIndex, animated: false)
        }
        let firstCategoryIndexPath = IndexPath(item: 0, section: 0)
        selectedCategoryIndex = firstCategoryIndexPath
        catagaryCollectionView.selectItem(at: firstCategoryIndexPath, animated: false, scrollPosition: [])
        collectionView(catagaryCollectionView, didSelectItemAt: firstCategoryIndexPath)

        if let selectedIndexPaths = roomsCollectionView.indexPathsForSelectedItems {
            for indexPath in selectedIndexPaths {
                roomsCollectionView.deselectItem(at: indexPath, animated: false)
            }
            
        }
        
        if let lastIndex = lastSelectedRoomIndex {
               roomsCollectionView.selectItem(at: lastIndex, animated: false, scrollPosition: [])
               collectionView(roomsCollectionView, didSelectItemAt: lastIndex)
           }
        
        if let previous = selectedCategoryIndex,
               let cell = catagaryCollectionView.cellForItem(at: previous) as? CatgegoryCollectionViewCell {
                cell.isSelected = false
            }

            catagaryCollectionView.reloadData()

            DispatchQueue.main.async {
                self.catagaryCollectionView.selectItem(at: firstCategoryIndexPath, animated: false, scrollPosition: [])
                self.collectionView(self.catagaryCollectionView, didSelectItemAt: firstCategoryIndexPath)
            }
       
        if !rooms.isEmpty {
            if let lastIndex = lastSelectedRoomIndex,
               lastIndex.row < rooms.count {

                roomsCollectionView.selectItem(at: lastIndex, animated: false, scrollPosition: [])
                collectionView(roomsCollectionView, didSelectItemAt: lastIndex)

            } else {
                let firstRoomIndexPath = IndexPath(item: 0, section: 0)
                lastSelectedRoomIndex = firstRoomIndexPath
                roomsCollectionView.selectItem(at: firstRoomIndexPath, animated: false, scrollPosition: [])
                collectionView(roomsCollectionView, didSelectItemAt: firstRoomIndexPath)
            }
        }
        
        connetion_aws_function()
       // fetchDeviceByRoomId()
        
        //startBlinking(label: lockVIewLabel)
        startBlinking(label: cameralabel)
       // startBlinking(label: acCommingSoonlabel)
        setupCircularSlider()
        
        
    }
    
    @objc func handleMasterSliderNotification(_ notification: Notification) {
        if let direction = notification.userInfo?["direction"] as? String {
            handleMasterSliderSlide(direction: direction)
        }
    }

    private func setupCircularSlider() {

        if circularSlider.superview != nil { return }

        print("✅ ac slider for test")

//        AcCircularView.backgroundColor = .red
//        circularSlider.backgroundColor = .green

        circularSlider.translatesAutoresizingMaskIntoConstraints = false
        AcCircularView.addSubview(circularSlider)

        NSLayoutConstraint.activate([
            circularSlider.centerXAnchor.constraint(equalTo: AcCircularView.centerXAnchor),
            circularSlider.topAnchor.constraint(equalTo: AcCircularView.topAnchor, constant: 16),
            circularSlider.widthAnchor.constraint(equalTo: AcCircularView.widthAnchor, multiplier: 0.85),
            circularSlider.heightAnchor.constraint(equalTo: circularSlider.widthAnchor)
        ])

        AcCircularView.layoutIfNeeded()

        //circularSlider.layer.cornerRadius = circularSlider.bounds.width / 2
        circularSlider.clipsToBounds = true
        
        circularSlider.onACValueChanged = { [weak self] temp, fan, swing, which, state in
            
            guard let self = self else { return }

            // ✅ Only AC category active
            guard self.selectedCategoryIndex?.item == 2 else {
                print("⛔ Not AC category → ignore")
                return
            }

            // ✅ Only buttonControlName = A
            guard let acButton = self.filteredButtonDetails.first(where: {
                $0.buttonControlName == "A"
            }) else {
                print("❌ No AC button found")
                showNoACPopup()
                return
            }

            print("📤 AC Payload from Circular")

            self.publishACPayload(
                no: acButton.buttonNo,
                speed: fan,
                temperature: temp,
                state: state,
                which: which,
                topic: acButton.uniqueId
            )
        }
    }
    
    
    

    @IBAction func lockButton(_ sender: Any) {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        let lockVC = storyboard.instantiateViewController(withIdentifier: "LockViewController") as! LockViewController
        
        self.navigationController?.pushViewController(lockVC, animated: true)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self.view)

      
        let buttonFrameInView = buttonView.convert(buttonView.bounds, to: self.view)

     
        if buttonFrameInView.contains(location) {
            stackScrollView.isScrollEnabled = true
        } else {
            stackScrollView.isScrollEnabled = false
        }
    }

    private func startBlinking(label: UILabel) {
   
        label.layer.removeAllAnimations()
        
        label.alpha = 1
        UIView.animate(withDuration: 0.8,
                       delay: 0,
                       options: [.autoreverse, .repeat, .allowUserInteraction],
                       animations: {
                           label.alpha = 0.2
                       },
                       completion: nil)
    }


    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkIfHomeExists()
        if !CamereView.isHidden {
                startBlinking(label: cameralabel)
            }
            if !LockView.isHidden {
                
//                startBlinking(label: lockVIewLabel)
            }
        if !AcCircularView.isHidden{
            startBlinking(label: acTempLabel)
            setupCircularSlider()
        }
        
           
        if !connected {
            connetion_aws_function()
        }
    }
    
    
    
    
    @objc func handleRoomSwipe(_ gesture: UISwipeGestureRecognizer) {
        guard !rooms.isEmpty,
              let currentIndex = roomsCollectionView.indexPathsForSelectedItems?.first?.row else {
            print("❌ No room is currently selected.")
            return
        }

        print("📍 Current selected room index: \(currentIndex)")

        var newIndex: Int?

        if gesture.direction == .left {
            newIndex = currentIndex + 1 < rooms.count ? currentIndex + 1 : nil
            print("👈 Left swipe detected. Trying to move to next room at index: \(String(describing: newIndex))")
        } else if gesture.direction == .right {
            newIndex = currentIndex - 1 >= 0 ? currentIndex - 1 : nil
            print("👉 Right swipe detected. Trying to move to previous room at index: \(String(describing: newIndex))")
        }

        if let index = newIndex {
            let indexPath = IndexPath(item: index, section: 0)
            print("✅ Navigating to room at index: \(indexPath.row), Room name: \(rooms[indexPath.row].name)")
            roomsCollectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
            collectionView(roomsCollectionView, didSelectItemAt: indexPath)
        } else {
            print(" Swipe ignored. Already at the first or last room.")
        }
    }
    
    

    func printDeviceList() {
            print("📦 Device List in AllRoomsViewController:", allFetchedDevices)
        }
    
    @IBAction func masterButton(_ sender: Any) {
        
        
    }
    
    func handleCenterButtonAction(devices: [Device]) {

        guard !deviceStatesForCurrentRoom.isEmpty else { return }

        // Toggle locally
        currentMasterState = currentMasterState == 1 ? 0 : 1
        let toggleState = currentMasterState

        for state in deviceStatesForCurrentRoom {
            publish_button_to_topic(
                control: "M",
                no: 1,
                state: toggleState,
                speed: 1,
                topic: state.uniqueID
            )
        }

        showPopupScene(state: toggleState)

        // update center button image
        delegate?.didChangeMasterState(to: toggleState)
    }


    @objc func showPopupScene(state: Int) {
        let title = "Success!"
        let subtitle: String

        if state == 0 {
            subtitle = "Master Off"
        } else {
            subtitle = "Master On"
        }

        showPopupPresenter.showPopup1(
            on: self.view,
            animationName: "success",
            title: title,
            subtitle: subtitle
        )
    }
    
    
    @objc private func toggleACPower() {

        guard let acButton = buttonDetails.first(where: {
            $0.buttonControlName == "A" && $0.isShortcut == 1
        }) else {
            print("❌ No AC shortcut configured")
            return
        }

        let topic = acButton.uniqueId
        let buttonNo = acButton.buttonNo

        let deviceState = receivedDeviceStates.first { $0.uniqueID == topic }

        let currentState = deviceState?.fanState ?? "0"
        let newState = currentState == "1" ? 0 : 1

        print("⚡ AC Toggle")
        print("Device:", topic)
        print("Button:", buttonNo)
        print("State:", newState)

        publish_ac_to_topic(
            no: buttonNo,
            state: newState,
            topic: topic
        )

        isOn.toggle()
        acOnOffButton.backgroundColor = isOn ? .systemGreen : .white
    }

    
    func publish_ac_to_topic(no: Int, state: Int, topic: String) {

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

        print("📤 Publishing AC payload:", parameters)

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
    private func setupACSliderUI() {
        AcView.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        AcView.cornerRadius = 10
        AcView.clipsToBounds = true
        acTempLabel.cornerRadius = 12
        acTempLabel.clipsToBounds =  true
        shortcutView.backgroundColor = UIColor(white: 1.0, alpha: 0.01)
        applyRoomViewGradient()
        let leftImage = UIImage(named: "leftswing")
        let rightImage = UIImage(named: "rightSwing")

        let resizedLeft = leftImage?.resize(to: CGSize(width: 20, height: 20))
       
        let resizedRight = rightImage?.resize(to: CGSize(width: 20, height: 20))
        

        leftswingButton.setImage(resizedLeft, for: .normal)
        rightSwiftButton.setImage(resizedRight, for: .normal)
        leftswingButton.layer.cornerRadius = 17.5
        leftswingButton.layer.masksToBounds = true
        leftswingButton.backgroundColor = .gray
        acOnOffButton.backgroundColor =  .white
        acOnOffButton.cornerRadius = 15
        acOnOffButton.clipsToBounds = true
        rightSwiftButton.layer.cornerRadius = 17.5
        
        rightSwiftButton.layer.masksToBounds = true
        rightSwiftButton.backgroundColor = .gray
       stackScrollView.isScrollEnabled = false
       
       
        let minusButton = UIButton(type: .system)
        minusButton.translatesAutoresizingMaskIntoConstraints = false
        
        minusButton.tintColor = .white
        AcView.addSubview(minusButton)

       
        let plusButton = UIButton(type: .system)
        plusButton.translatesAutoresizingMaskIntoConstraints = false
       
        plusButton.tintColor = .white
        
        plusButton.layer.zPosition = 999
        AcView.addSubview(plusButton)

        
        
        
        let plusImg = UIImage(systemName: "plus")?.withRenderingMode(.alwaysTemplate)
        let minusImg = UIImage(systemName: "minus")?.withRenderingMode(.alwaysTemplate)

        plusButton.setImage(plusImg, for: .normal)
        minusButton.setImage(minusImg, for: .normal)

        plusButton.tintColor = .white
        minusButton.tintColor = .white

        
        let acSlider = FanSlider()
        acSlider.translatesAutoresizingMaskIntoConstraints = false
        AcView.addSubview(acSlider)

        acSlider.onValueChanged = { [weak self] value in

            guard let self = self else { return }

            let speed = Int(value)
            self.currentACSpeed = speed   // ✅ store latest speed

            let tempText = self.acTempLabel.text ?? "18°C"
            let tempValue = tempText.replacingOccurrences(of: "°C", with: "")
            let temperature = Int(tempValue) ?? 18

            guard let acButton = self.buttonDetails.first(where: {
                $0.buttonControlName == "A" && $0.isShortcut == 1
            }) else { return }

            self.publishACPayload(
                no: acButton.buttonNo,
                speed: speed,
                temperature: temperature,
                state: 1,
                which: 3,
                topic: acButton.uniqueId
            )
        }

        var temperature = 24
        acTempLabel.text = "\(temperature)°C"

        func updateTempLabel() {
            acTempLabel.text = "\(temperature)°C"
        }

        minusButton.addAction(UIAction { [weak self] _ in
            guard let self = self else { return }

            if temperature > 18 {
                temperature -= 1
                updateTempLabel()

                self.sendACTempUpdate(temp: temperature)
            }
        }, for: .touchUpInside)
        plusButton.addAction(UIAction { [weak self] _ in
            guard let self = self else { return }

            if temperature < 32 {
                temperature += 1
                updateTempLabel()

                self.sendACTempUpdate(temp: temperature)
            }
        }, for: .touchUpInside)
        
        acTempLabel.translatesAutoresizingMaskIntoConstraints = false
        acTempLabel.trailingAnchor.constraint(equalTo: AcView.trailingAnchor, constant: -28).isActive = true

        
        NSLayoutConstraint.activate([

            // minus
            minusButton.trailingAnchor.constraint(equalTo: acTempLabel.leadingAnchor, constant: -6),
            minusButton.centerYAnchor.constraint(equalTo: acTempLabel.centerYAnchor),
            minusButton.widthAnchor.constraint(equalToConstant: 18),
            minusButton.heightAnchor.constraint(equalToConstant: 18),

            // plus
            plusButton.leadingAnchor.constraint(equalTo: acTempLabel.trailingAnchor, constant: 6),
            plusButton.centerYAnchor.constraint(equalTo: acTempLabel.centerYAnchor),
            plusButton.widthAnchor.constraint(equalToConstant: 18),
            plusButton.heightAnchor.constraint(equalToConstant: 18),

            // slider
            acSlider.topAnchor.constraint(equalTo: acTempLabel.bottomAnchor, constant: 20),
            acSlider.centerXAnchor.constraint(equalTo: AcView.centerXAnchor),
            acSlider.widthAnchor.constraint(equalToConstant: 200),
            acSlider.heightAnchor.constraint(equalToConstant: 30),
        ])

    }
    func showSyncPopup(message: String = "Processing...") {

        // Avoid stacking multiple popups
        hideSyncPopup()

        let popup = SyncProcessingPopup(frame: view.bounds)

        popup.configure(
            title: "Please Wait",
            message: message
        )

        view.addSubview(popup)

        syncPopup = popup
    }

    func hideSyncPopup() {
        syncPopup?.stop()
        syncPopup?.removeFromSuperview()
        syncPopup = nil
    }

    private func startDeviceStateSync(triggeringRefreshControl: UIRefreshControl?) {
        syncTimeoutWorkItem?.cancel()

        isDeviceStateSyncInProgress = true
        syncExpectedDeviceIds = Set(devices.map { $0.uniqueId })
        syncReceivedDeviceIds.removeAll()
        syncRetryCounts.removeAll()

        syncRefreshControls.removeAll()
        if let rc = triggeringRefreshControl { syncRefreshControls.append(rc) }
        if let rc = deviceListTableView.refreshControl { syncRefreshControls.append(rc) }
        if let rc = curtaintableView.refreshControl { syncRefreshControls.append(rc) }

        showSyncPopup(message: "Syncing 0/\(max(syncExpectedDeviceIds.count, 1)) devices...")

        // Kick off state requests (if we are already subscribed, we’ll get acks quickly.
        // If subscription is being refreshed, fetchDeviceByRoomId will also request state after subscribe.)
        for id in syncExpectedDeviceIds {
            requestLatestDeviceState(topic: id)
        }

        scheduleDeviceStateSyncTimeout()
    }

    private func scheduleDeviceStateSyncTimeout() {
        syncTimeoutWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.handleDeviceStateSyncTimeout()
        }
        syncTimeoutWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 8.0, execute: work)
    }

    private func handleDeviceStateSyncTimeout() {
        guard isDeviceStateSyncInProgress else { return }

        let missing = syncExpectedDeviceIds.subtracting(syncReceivedDeviceIds)
        guard !missing.isEmpty else {
            finishDeviceStateSync(success: true)
            return
        }

        // One retry per missing device (keeps UI responsive; avoids infinite loops)
        var retriedAny = false
        for id in missing {
            let count = (syncRetryCounts[id] ?? 0)
            if count < 1 {
                syncRetryCounts[id] = count + 1
                requestLatestDeviceState(topic: id)
                retriedAny = true
            }
        }

        if retriedAny {
            syncPopup?.configure(
                title: "Please Wait",
                message: "Still waiting… \(syncReceivedDeviceIds.count)/\(max(syncExpectedDeviceIds.count, 1))"
            )
            scheduleDeviceStateSyncTimeout()
        } else {
            finishDeviceStateSync(success: false)
        }
    }

    private func finishDeviceStateSync(success: Bool) {
        isDeviceStateSyncInProgress = false
        syncTimeoutWorkItem?.cancel()
        syncTimeoutWorkItem = nil

        hideSyncPopup()

        // End any active refresh UI
        for rc in syncRefreshControls {
            rc.endRefreshing()
        }
        syncRefreshControls.removeAll()

        // Ensure latest UI render from received MQTT state
        deviceListTableView.reloadData()
        curtaintableView.reloadData()

        if !success, !syncExpectedDeviceIds.isEmpty {
            let missing = syncExpectedDeviceIds.subtracting(syncReceivedDeviceIds)
            let alert = UIAlertController(
                title: "Sync incomplete",
                message: "Some devices didn’t respond. Please check device power/Wi‑Fi and try again.\n\nMissing: \(missing.joined(separator: ", "))",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }

    func sendACTempUpdate(temp: Int) {

        guard let acButton = buttonDetails.first(where: {
            $0.buttonControlName == "A" && $0.isShortcut == 1
        }) else { return }

        publishACPayload(
            no: acButton.buttonNo,
            speed: currentACSpeed,   // ✅ correct fan speed
            temperature: temp,
            state: 1,
            which: 2,
            topic: acButton.uniqueId
        )
    }
    
    func publishACPayload(
        no: Int,
        speed: Int,
        temperature: Int,
        state: Int,
        which: Int,
        topic: String
    ) {

        let parameters: [String: Any] = [
            "control": "A",
            "no": no,
            "speed": speed,
            "swing": 1,
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
    
    func publishShrortcutPayload(
        no: Int,
        speed: Int,
        temperature: Int,
        state: Int,
        which: Int,
        topic: String,
        swing : Int
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
    func fetchRoomsForSelectedHome() {
        guard let homeId = HomeId else {
            print("HomeId is nil. Cannot fetch rooms.")
            return
        }
       
        SkromanIsraDatabaseHelper.shared.fetchRoomsByHomeId(homeServerId: homeId) { fetchedRooms in
            let mappedRooms = fetchedRooms.map { roomTuple in
                let matchingIcon = self.roomsIconType
                    .first { $0.name == roomTuple.roomIconType }?
                    .image ?? "default_image"

                return Room(
                    name: roomTuple.roomName,
                    imageName: matchingIcon,
                    roomId: roomTuple.roomId,
                    homeId: homeId
                )
            }

            DispatchQueue.main.async {
                self.rooms = mappedRooms
                self.roomsCollectionView.reloadData()

                if self.rooms.isEmpty {
                       
                        self.showNoRoomsPlaceholder()

                       
                        self.hideNoDevicesPlaceholder()
                        self.shortcutView.isHidden = true
                        self.deviceListTableView.isHidden = true
                        self.curtaintableView.isHidden = true
                        self.buttonsCollectionView.isHidden = true

                    } else {
                        self.hideNoRoomsPlaceholder()

                        self.shortcutView.isHidden = false
                        self.deviceListTableView.isHidden = false
                        self.buttonsCollectionView.isHidden = false
                       
                    
                    if let selectedId = self.selectedRoomId,
                       let index = self.rooms.firstIndex(where: { $0.roomId == selectedId }) {
                        let indexPath = IndexPath(item: index, section: 0)
                        self.roomsCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
                        self.collectionView(self.roomsCollectionView, didSelectItemAt: indexPath)
                    } else {
                        if let selectedId = self.selectedRoomId,
                           let index = self.rooms.firstIndex(where: { $0.roomId == selectedId }) {

                            let indexPath = IndexPath(item: index, section: 0)
                            self.lastSelectedRoomIndex = indexPath
                            self.roomsCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
                            self.collectionView(self.roomsCollectionView, didSelectItemAt: indexPath)

                        } else {
                            let firstIndexPath = IndexPath(item: 0, section: 0)
                            self.lastSelectedRoomIndex = firstIndexPath
                            self.roomsCollectionView.selectItem(at: firstIndexPath, animated: false, scrollPosition: [])
                            self.collectionView(self.roomsCollectionView, didSelectItemAt: firstIndexPath)
                        }
                    }
                        
                        self.checkTuyaDevicesInRoom { [weak self] hasTuyaDevices in
                            guard let self = self else { return }
                            
                            DispatchQueue.main.async {
                                
                                print("👉 Tuya Present:", hasTuyaDevices)
                                
                                if hasTuyaDevices {
                                   
                                    self.hideNoDevicesPlaceholder()
                                }
                                // ❗ DO NOT show placeholder here
                                // fetchDeviceByRoomId() will handle that
                            }
                        }
                }
            }

        }
    }
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    func showNoACPopup() {

        let alert = UIAlertController(
            title: "No AC Found",
            message: "No AC present in your room.",
            preferredStyle: .alert
        )

        let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(ok)

        present(alert, animated: true)
    }
    
    
    func showNoRoomsPlaceholder() {
        // Prevent duplicate view
        guard noRoomsView == nil else { return }

        let placeholder = UIView(frame: view.bounds)
        placeholder.backgroundColor = UIColor.clear
        
        // --- Image view above label ---
        let imageView = UIImageView()
        imageView.image = UIImage(named: "livingRoom") ?? UIImage(systemName: "livingRoom")
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit

        // --- Message label ---
        let messageLabel = UILabel()
        messageLabel.text = "Add Room in Home."
        messageLabel.textColor = .white
        messageLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0

        // --- Stack everything ---
        let stackView = UIStackView(arrangedSubviews: [imageView, messageLabel])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 16

        placeholder.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: placeholder.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: placeholder.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 80),
            imageView.heightAnchor.constraint(equalToConstant: 80)
        ])

        // --- Add tap gesture to entire placeholder ---
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleNoRoomsPlaceholderTap))
        placeholder.isUserInteractionEnabled = true
        placeholder.addGestureRecognizer(tapGesture)

        // --- Add to main view ---
        view.addSubview(placeholder)
        noRoomsView = placeholder
    }
    @objc func handleNoRoomsPlaceholderTap() {
        guard let homeId = HomeId else {
            print("⚠️ HomeId is nil, cannot navigate to AddNewRoomViewController.")
            return
        }

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let addRoomVC = storyboard.instantiateViewController(withIdentifier: "AddNewRoomViewController") as? AddNewRoomViewController {
            addRoomVC.HomeId = homeId
            addRoomVC.homeName = homeNameshow // optional if you have it
            navigationController?.pushViewController(addRoomVC, animated: true)
        }
    }


    func hideNoRoomsPlaceholder() {
        noRoomsView?.removeFromSuperview()
        noRoomsView = nil
    }

    
    func fetchDeviceByRoomId() {

        guard let roomId = selectedRoomId else {
            print("❌ selectedRoomId is nil")
            return
        }

        // Do not unsubscribe globally; subscriptions are shared app-wide.
        isInitialStateLoaded = false

      
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

          
            let roomDevices = SkromanIsraDatabaseHelper.shared.fetchDevicesByRoomIdSync(roomId: roomId)

           
            var tempButtonDetails: [ButtonDetails] = []

            for device in roomDevices {

               
                if let cached = self.cachedButtonDetails[device.uniqueId] {
                    tempButtonDetails.append(contentsOf: cached)
                } else {
                    let details = SkromanIsraDatabaseHelper.shared.fetchButtonDetails(uniqueId: device.uniqueId)
                    self.cachedButtonDetails[device.uniqueId] = details
                    tempButtonDetails.append(contentsOf: details)
                }
            }

          
            DispatchQueue.main.async {

                self.devices = roomDevices
                self.buttonDetails = tempButtonDetails
                self.allFetchedDevices = roomDevices
                self.filteredButtonDetails = tempButtonDetails

                self.removeDuplicateDevices()
                self.devices.sort { $0.uniqueId < $1.uniqueId }

                self.deviceListTableView.reloadSections(IndexSet(integer: 0), with: .none)
                self.buttonsCollectionView.reloadData()

               
                self.checkTuyaDevicesInRoom { [weak self] hasTuyaDevices in
                    guard let self = self else { return }

                    DispatchQueue.main.async {

                        let hasLocalDevices = !self.devices.isEmpty

                        if !hasLocalDevices && !hasTuyaDevices {
                           
                            self.showNoDevicesPlaceholder()

                            self.deviceListTableView.isHidden = true
                            self.curtaintableView.isHidden = true
                            self.buttonsCollectionView.isHidden = true
                            self.AcView.isHidden = true
                            self.roomSceneView.isHidden = true
                            self.catagaryCollectionView.isHidden = true

                            self.roomscnelabel?.text = ""

                        } else {
                            // ✅ At least one device exists (Local OR Tuya)
                            self.hideNoDevicesPlaceholder()

                            self.deviceListTableView.isHidden = false
                            self.buttonsCollectionView.isHidden = false
                            self.roomSceneView.isHidden = false
                            self.catagaryCollectionView.isHidden = false

                            self.roomscnelabel?.text = "Room Scene"
                        }

                        // ✅ Subscribe only local devices (Tuya handled separately)
                        self.subscribeToDevices(roomDevices)
                    }
                }

                // If a pull-to-sync is active, realign expected IDs
                if self.isDeviceStateSyncInProgress {
                    self.syncExpectedDeviceIds = Set(roomDevices.map { $0.uniqueId })
                    self.syncReceivedDeviceIds.removeAll()
                    self.syncRetryCounts.removeAll()
                    self.syncPopup?.configure(
                        title: "Please Wait",
                        message: "Syncing 0/\(max(self.syncExpectedDeviceIds.count, 1)) devices..."
                    )
                    for id in self.syncExpectedDeviceIds {
                        self.requestLatestDeviceState(topic: id)
                    }
                    self.scheduleDeviceStateSyncTimeout()
                }
            }
        }
    }
    
    func subscribeToDevices(_ devices: [Device]) {
        DispatchQueue.global(qos: .background).async {
            for device in devices {
                self.subscribeToTopic(for: device.uniqueId)
            }
        }
    }
    func reloadVisibleDeviceCells() {
         print ("data reload ")
        for cell in deviceListTableView.visibleCells {
            if let deviceCell = cell as? DeviceListTableViewCell {
                //deviceCell.deviceListCollectionView.reloadData()
            }
        }
    }
    
    func checkIfHomeExists() {
        
        let homes = SkromanIsraDatabaseHelper.shared.fetchAllHomesData()
        
        if homes.isEmpty {
            showNoHomeAlert()
        }
    }
    func showNoHomeAlert() {
        
        let alert = UIAlertController(
            title: "No Home Available",
            message: "Please add a home first.",
            preferredStyle: .alert
        )
        
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            
            // Navigate to MainHomeViewController
            if let tabBar = self.tabBarController {
                tabBar.selectedIndex = 0   // assuming Home tab = 0
            } else {
                self.navigationController?.popToRootViewController(animated: true)
            }
        }
        
        alert.addAction(okAction)
        present(alert, animated: true)
    }
    
    let defaultScenes: [(sceneNo: String, sceneName: String, sceneIcon: String)] = [
        ("1", "Scene 1", "scene1"),
        ("2", "Scene 2", "scene2"),
        ("3", "Scene 3", "scene3"),
        ("4", "Scene 4", "scene4"),
        ("5", "Scene 5", "scene1"),
        ("6", "Scene 6", "scene2"),
        ("7", "Scene 7", "scene3"),
        ("8", "Scene 8", "scene4")
    ]


    func prepareScenes() {
        // Start with defaults
        mergedScenes = defaultScenes
        
        
        for fetched in fetchedRoomScenes {
            if let index = mergedScenes.firstIndex(where: { $0.sceneNo == fetched.sceneNo }) {
                mergedScenes[index] = (fetched.sceneNo, fetched.sceneName, fetched.sceneIcon)
            }
        }
    }
    func subscribeToTopic(for uniqueId: String) {
        let fullTopic = uniqueId + "/HA/E/ack"
        print("📡 Ensuring global subscription to topic: \(fullTopic)")

        MQTTSubscriptionManager.shared.subscribeIfNeeded(topic: fullTopic) { [weak self] data in
            guard let self = self else { return }

            guard let stringValue = String(data: data, encoding: .utf8) else {
                print("⚠️ Unable to decode payload for topic: \(fullTopic)")
                return
            }

            debugLog("📥 Topic: \(fullTopic): \(stringValue)")
            guard let jsonData = stringValue.data(using: .utf8) else {
                print("⚠️ Invalid JSON string for topic: \(fullTopic)")
                return
            }

            do {
                // ✅ Step 1: Parse general fields
                if let dict = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
                   let series = dict["series"] as? String,
                   let uniqueId = dict["unique_id"] as? String
                  {

                    self.deviceSeries[uniqueId] = series
                    switch series {
                    case "AVR_V9_NORMAL":
                        print("💾 Storing \(uniqueId) as V9 series device")
                        var storedV9Devices = UserDefaults.standard.array(forKey: "V9SeriesDevices") as? [String] ?? []
                        if !storedV9Devices.contains(uniqueId) {
                            storedV9Devices.append(uniqueId)
                            UserDefaults.standard.set(storedV9Devices, forKey: "V9SeriesDevices")
                        }

                    case "AVR_V11_NORMAL":
                        print("💾 Storing \(uniqueId) as V11 series device")
                        var storedV11Devices = UserDefaults.standard.array(forKey: "V11SeriesDevices") as? [String] ?? []
                        if !storedV11Devices.contains(uniqueId) {
                            storedV11Devices.append(uniqueId)
                            UserDefaults.standard.set(storedV11Devices, forKey: "V11SeriesDevices")
                        }
                  
                    case "human_detection_v1":

                        let theftState = try JSONDecoder().decode(TheftDetectorState.self, from: jsonData)

                        print("🚨 Human Detection Update:", theftState)
                        self.radarStates[theftState.uniqueId] = theftState
                        DispatchQueue.main.async {

                            NotificationCenter.default.post(
                                name: NSNotification.Name("TheftDetectorDetected"),
                                object: nil,
                                userInfo: [
                                    "uniqueId": theftState.uniqueId,
                                    "humanStatus": theftState.humanStatus ?? 0,
                                    "activeStatus": theftState.activeStatus ?? 0
                                ]
                            )

                            // ✅ UPDATE ONLINE STATUS IN TABLE CELL
                            DispatchQueue.main.async { [weak self] in
                                guard let self = self else { return }

                                if let row = self.devices.firstIndex(where: { $0.uniqueId == theftState.uniqueId }) {

                                    let indexPath = IndexPath(row: row, section: 0)

                                    if let cell = self.deviceListTableView.cellForRow(at: indexPath) as? DeviceListTableViewCell {

                                        if cell.isHumanDetectionDevice {

                                            let isPresent = (theftState.humanStatus ?? 0) == 1
                                            cell.humanStatusLabel?.text = isPresent ? "🟢 Human Present" : "⚪ No Human"
                                            cell.humanStatusLabel?.textColor = isPresent ? .systemGreen : .lightGray

                                            cell.humanToggle?.setOn((theftState.activeStatus ?? 0) == 1, animated: true)
                                        }
                                    }
                                }
                            }
                        }

                        return


                    default:

                        if series == "human_detection_v1" {

                            let theftState = try JSONDecoder().decode(TheftDetectorState.self, from: jsonData)

                            print("🚨 Human Detection Update:", theftState)

                            DispatchQueue.main.async {
                                NotificationCenter.default.post(
                                    name: NSNotification.Name("TheftDetectorDetected"),
                                    object: nil,
                                    userInfo: [
                                        "uniqueId": theftState.uniqueId,
                                        "humanStatus": theftState.humanStatus ?? 0,
                                        "activeStatus": theftState.activeStatus ?? 0
                                    ]
                                )
                            }

                            return
                        }

                        print("ℹ️ Unknown series: \(series)")
                    }

                    if let otaStatus = dict["ota_status"] as? Int {
                        print("🧩 OTA status for \(uniqueId): \(otaStatus)")
                        NotificationCenter.default.post(
                            name: NSNotification.Name("DeviceStateUpdated"),
                            object: nil,
                            userInfo: [
                                "uniqueId": uniqueId,
                                "ota_status": otaStatus
                            ]
                        )
                    }


                }

              
                guard let dict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
                    print("⚠️ Not valid JSON dictionary")
                    return
                }

                // 🔥 Only decode full state if unique_id exists
                guard dict["unique_id"] != nil else {
                    print("⚠️ Skipping MQTT message — no unique_id (not full state payload)")
                    return
                }

             
                guard let dict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
                    print("⚠️ Not valid JSON dictionary")
                    return
                }

                // 🔥 Only decode full state if unique_id exists
                guard dict["unique_id"] != nil else {
                    print("⚠️ Skipping MQTT message — no unique_id (not full state payload)")
                    return
                }

                
                guard let dict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
                    print("⚠️ Not a valid JSON dictionary")
                    return
                }

                // STEP 2: Check if this is a FULL device state payload
                guard dict["unique_id"] != nil else {
                    print("⚠️ MQTT message skipped (no unique_id)")
                    return
                }

                // STEP 3: Now decode safely
                let deviceState = try JSONDecoder().decode(DeviceStateArray.self, from: jsonData)

                // ✅ Find the correct device using uniqueID
                if let device = self.devices.first(where: { $0.uniqueId == deviceState.uniqueID }) {

                    print("📡 API calling for device:", device.uniqueId)

                    self.add_device_state_api_func(
                        selectedDevice: device,
                        state: deviceState
                    )
                }

                // ✅ Step 5: Update UI and local states
                DispatchQueue.main.async {
                    self.handleMQTTUpdate(deviceState: deviceState)
                }


            } catch {
                print("❌ JSON decode error for topic \(fullTopic): \(error)")
            }
        }

        // Request current state shortly after subscription
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.requestLatestDeviceState(topic: uniqueId)
        }
    }

   

    func handleMQTTUpdate(deviceState: DeviceStateArray) {

        DispatchQueue.main.async {
            self.receivedDeviceStatesDict[deviceState.uniqueID] = deviceState

           
            if let index = self.receivedDeviceStates.firstIndex(where: {
                $0.uniqueID == deviceState.uniqueID
            }) {
                self.receivedDeviceStates[index] = deviceState
            } else {
                self.receivedDeviceStates.append(deviceState)
            }

            
            guard let row = self.devices.firstIndex(where: {
                $0.uniqueId == deviceState.uniqueID
            }) else { return }

            let indexPath = IndexPath(row: row, section: 0)

            if let cell = self.deviceListTableView.cellForRow(at: indexPath) as? DeviceListTableViewCell {
                cell.configure(
                    with: self.devices[row],
                    deviceStates: [deviceState],
                    series: self.deviceSeries[deviceState.uniqueID]
                )
            }

            // Keep shortcut cells in sync as ACKs arrive
            self.buttonsCollectionView.reloadData()

            if self.isDeviceStateSyncInProgress, self.syncExpectedDeviceIds.contains(deviceState.uniqueID) {
                self.syncReceivedDeviceIds.insert(deviceState.uniqueID)

                let total = max(self.syncExpectedDeviceIds.count, 1)
                let done = self.syncReceivedDeviceIds.count
                self.syncPopup?.configure(title: "Please Wait", message: "Syncing \(done)/\(total) devices...")

                if done >= self.syncExpectedDeviceIds.count {
                    self.finishDeviceStateSync(success: true)
                }
            }
        }
    }
    
    func unsubscribeFromAllTopics() {
        let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
        for topic in subscribedTopics {
            iotDataManager.unsubscribeTopic(topic)
            print("🔌 Unsubscribed from topic: \(topic)")
        }
        subscribedTopics.removeAll()
            
           //receivedDeviceStates.removeAll()
           buttonsCollectionView.reloadData()
    }


    func handleMasterSliderSlide(direction: String) {
        guard !deviceStatesForCurrentRoom.isEmpty else {
            print("⚠️ No device states available.")
            return
        }

       
        let state = (direction == "left") ? 1 : 0
        print("⬅️➡️ Master slide state: \(state)")

        // ✅ Skip if already ON and trying to turn ON again
        if direction == "left", deviceStatesForCurrentRoom.contains(where: { $0.master == 1 }) {
            print("⛔️ Master already ON — skipping left-slide publish")
            return
        }

        for device in deviceStatesForCurrentRoom {
            let topic = device.uniqueID
            let no = 1
            let speed = 0

            print("📤 Publishing Master Slide (\(direction.uppercased())) to topic: \(topic)")
            publish_button_to_topic(control: "M", no: no, state: state, speed: speed, topic: topic)
        }
    }
   
    private func showNoDevicesPlaceholder() {
        // Remove if already exists
        noDevicesView?.removeFromSuperview()

        let placeholder = UIView(frame: shortcutView.frame) // 👈 same size/position as shortcutView
        placeholder.backgroundColor = .clear

        // Image
        let imageView = UIImageView(image: UIImage(named: "device")) // put your asset name here
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        placeholder.addSubview(imageView)

        // Label
        let label = UILabel()
        label.text = "Add Device in Room"
        label.textColor = .darkGray
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        placeholder.addSubview(label)

        NSLayoutConstraint.activate([
            // Image constraints
            imageView.centerXAnchor.constraint(equalTo: placeholder.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: placeholder.centerYAnchor, constant: -20),
            imageView.widthAnchor.constraint(equalToConstant: 90),
            imageView.heightAnchor.constraint(equalToConstant: 90),

            // Label constraints (below image)
            label.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 12),
            label.centerXAnchor.constraint(equalTo: placeholder.centerXAnchor)
        ])

        // Tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(noDevicesImageTapped))
        placeholder.addGestureRecognizer(tapGesture)
        placeholder.isUserInteractionEnabled = true

        self.view.addSubview(placeholder)
        self.noDevicesView = placeholder
    }


    private func hideNoDevicesPlaceholder() {
        noDevicesView?.removeFromSuperview()
        noDevicesView = nil
    }

    @objc private func noDevicesImageTapped() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let addDeviceVC = storyboard.instantiateViewController(withIdentifier: "DeviceSelectViewController") as? DeviceSelectViewController {
            //addDeviceVC.tuyaHomeid =
            addDeviceVC.selectedRoomId = selectedRoomId
            addDeviceVC.selectedHomeId = HomeId
            addDeviceVC.tuyaHomeid =  tuyaHomeId
            addDeviceVC.selectedRoomName = selectedRoomName
            self.navigationController?.pushViewController(addDeviceVC, animated: true)
        }

    }
   



    func applyRoomViewGradient() {
       
        roomView.layer.sublayers?.removeAll(where: { $0.name == "roomGradientLayer" })

       
        roomView.backgroundColor = UIColor(hex: "#11171C")

        // Gradient layer
        let gradientLayer = CAGradientLayer()
        gradientLayer.name = "roomGradientLayer"
        gradientLayer.frame = roomView.bounds

     
        let startColor = UIColor(hex: "#477CF7", alpha: 0.1).cgColor  // 10% opacity
        let endColor = UIColor.clear.cgColor                           // Fade to transparent

        gradientLayer.colors = [startColor, endColor]

        // Gradient starts from top-left and fades to bottom-right
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)

        roomView.layer.insertSublayer(gradientLayer, at: 0)
    }

    
    
    

    func registerXIb(){
        let uiNib =  UINib(nibName: "AllRoomsCollectionViewCell", bundle: nil)
        roomsCollectionView.register(uiNib, forCellWithReuseIdentifier: "AllRoomsCollectionViewCell")
        let uiNib1 =  UINib(nibName: "CatgegoryCollectionViewCell", bundle: nil)
        catagaryCollectionView.register(uiNib1, forCellWithReuseIdentifier: "CatgegoryCollectionViewCell")
        let uiNib2 =  UINib(nibName: "AllShortcutDeviceCollectionViewCell", bundle: nil)
        buttonsCollectionView.register(uiNib2, forCellWithReuseIdentifier: "AllShortcutDeviceCollectionViewCell")
        let uiNib3  =  UINib(nibName: "DeviceListTableViewCell", bundle: nil)
        deviceListTableView.register(uiNib3, forCellReuseIdentifier: "DeviceListTableViewCell")
        
        let Uinib4 = UINib(nibName: "CurtainTableViewCell", bundle: nil)
        curtaintableView.register(Uinib4, forCellReuseIdentifier: "CurtainTableViewCell")
        let uiNib5 =  UINib(nibName: "RoomsSceneCollectionViewCell", bundle: nil)
        roomSceneCollectionView.register(uiNib5, forCellWithReuseIdentifier: "RoomsSceneCollectionViewCell")
        let uiNib6 =  UINib(nibName: "LockCollectionViewCell", bundle: nil)
        lockCollectionView.register(uiNib6, forCellWithReuseIdentifier: "LockCollectionViewCell")
        
        deviceListTableView.dataSource = self
        deviceListTableView.delegate =  self
        buttonsCollectionView.dataSource = self
        buttonsCollectionView.delegate =  self
        catagaryCollectionView.dataSource = self
        catagaryCollectionView.delegate =  self
        roomsCollectionView.dataSource =  self
        roomsCollectionView.delegate =  self
        curtaintableView.dataSource =  self
        curtaintableView.delegate =  self
        roomSceneCollectionView.dataSource =  self
        roomSceneCollectionView.delegate =  self
        lockCollectionView.dataSource =  self
        lockCollectionView.delegate =  self
        
    }
    
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
      
        setupCircularSlider()
     
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.customizeScrollIndicator(for: self.roomsCollectionView)
            self.customizeScrollIndicator(for: self.catagaryCollectionView)
            self.customizeScrollIndicator(for: self.roomSceneCollectionView)
           
           
            
        }
        let bottomInset = view.safeAreaInsets.bottom + 120
           deviceListTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: bottomInset, right: 0)
    }

    


    private func customizeScrollIndicator(for collectionView: UICollectionView) {
        for subview in collectionView.subviews {
            if let indicator = subview as? UIImageView, indicator.frame.width < 10 {
                indicator.backgroundColor = UIColor.white
                indicator.layer.cornerRadius = 3
                indicator.clipsToBounds = true

                var frame = indicator.frame
                frame.size.width = 4
                indicator.frame = frame
            }
        }
    }


    let roomsIconType: [RoomIconType] = [
     
        RoomIconType(name: "Living Room", image: "Living Room"),
        RoomIconType(name: "Living Room 1", image: "Living Room 1"),
        RoomIconType(name: "Living Room 2", image: "Living Room 2"),
      
       
        RoomIconType(name: "Bed Room", image: "Bed"),
        RoomIconType(name: "Bed Room 1", image: "Bed Room 1"),
        RoomIconType(name: "Bed Room 2", image: "Bed Room 2"),
        
        RoomIconType(name: "Study Room", image: "study"),
        RoomIconType(name: "Kitchen", image: "Kitchen"),
        RoomIconType(name: "DiningHall", image: "Dining"),
       
        RoomIconType(name: "Wash Room", image: "Wash Room"),
        RoomIconType(name: "Wash Room 1", image: "Wash Room 1"),
        RoomIconType(name: "Wash Room 2", image: "Wash Room 2"),
        
        RoomIconType(name: "Toilet", image: "Wash Room"),
        RoomIconType(name: "Patio", image: "Patio"),
        RoomIconType(name: "Lobby", image: "lobby"),
        
        RoomIconType(name: "Balcony", image: "Balcony"),
        RoomIconType(name: "Garden", image: "garden"),
        RoomIconType(name: "Varanda", image: "Varanda"),
        
      
        RoomIconType(name: "Theater", image: "theater"),
        RoomIconType(name: "Lift", image: "lift"),
        RoomIconType(name: "Staircase", image: "Staircase"),
        
        RoomIconType(name: "Gate", image: "gate"),

        RoomIconType(name: "Other Room", image: "other")
        
        
        
        
    ]
    
    func updateStackViewForCategory(_ category: String) {
        // Only hide these views — NOT catagaryCollectionVie
        buttonView.isHidden = true
        //AcView.isHidden = true
        ///shortcutView.isHidden = true

        switch category {
        case "All":
            buttonView.isHidden = false
            AcView.isHidden = false
            switchView.isHidden =  true
            AcCircularView.isHidden =  true
            CamereView.isHidden =  true
            curtainView.isHidden =  true
            LockView.isHidden =  true
            buttonsCollectionView.reloadData()
            fetchDeviceByRoomId()

            
        case "Switches" :
            buttonView.isHidden = true
            AcView.isHidden = true
            switchView.isHidden =  false
            AcCircularView.isHidden =  true
            CamereView.isHidden =  true
            curtainView.isHidden =  true
            LockView.isHidden =  true
            deviceListTableView.reloadData()
            fetchDeviceByRoomId()

            
        case "AC":

            buttonView.isHidden = true
            AcView.isHidden = true
            switchView.isHidden = true
            AcCircularView.isHidden = false
            CamereView.isHidden = true
            curtainView.isHidden = true
            LockView.isHidden = true

            // ✅ Step 1: find AC states in the selected room only
            let roomIds = Set(devices.map { $0.uniqueId })
            let acStates = receivedDeviceStates.filter {
                roomIds.contains($0.uniqueID) && $0.cNm.contains("A")
            }

            print("❄️ AC States:", acStates.count)

            guard let acState = acStates.first else {
                print("❌ No AC found in config_buttons")
                return
            }

            // ✅ Step 2: match device
            guard let acDevice = devices.first(where: {
                $0.uniqueId == acState.uniqueID
            }) else {
                print("❌ AC device not found")
                return
            }

            selectedDevice = acDevice
            deviceUniqueid = acDevice.uniqueId

            // ✅ Step 3: filter buttonDetails
            filteredButtonDetails = buttonDetails.filter {
                $0.uniqueId == acDevice.uniqueId &&
                $0.buttonControlName == "A"
            }

            print("✅ AC ButtonDetails:", filteredButtonDetails)
        case "Curtains":
            buttonView.isHidden = true
            AcView.isHidden = true
            switchView.isHidden =  true
            AcCircularView.isHidden =  true
            CamereView.isHidden =  true
            curtainView.isHidden =  false
            LockView.isHidden =  true
            curtaintableView.reloadData()
            print("curtain att")
           

               
        case "Lock":
            
            buttonView.isHidden = true
            AcView.isHidden = true
            switchView.isHidden = true
            AcCircularView.isHidden = true
            CamereView.isHidden = true
            curtainView.isHidden = true
            LockView.isHidden = false

            guard let homeId = self.HomeId,
                  let roomId = self.selectedRoomId else {
                print("❌ Missing homeId or roomId")
                return
            }

            guard let home = SkromanIsraDatabaseHelper.shared.fetchHomeById(homeServerId: homeId),
                  let tuyaHomeId = home.tuyaHomeId else {
                print("❌ Not Tuya Home")
                return
            }

           

                SkromanIsraDatabaseHelper.shared.fetchRoomByRoomId(roomId: roomId) { room in

                    guard let room = room,
                          let tuyaRoomId = room.tuyaRoomId else {
                        print("❌ Not Tuya Room")
                        return
                    }

                    SkromanIsraDatabaseHelper.shared.fetchTuyaDevices(
                        tuyaHomeId: tuyaHomeId ?? 0,
                        tuyaRoomId: tuyaRoomId
                    ) { devices in

                        let locks = devices.filter {
                            let category = $0.deviceCategory.lowercased()
                            return category == "jtmspro" || category == "videolock"
                        }

                        print("🔐 Filtered Locks:", locks)

                        self.tuyaLockDevices = locks
                        self.lockCollectionView.reloadData()
                    }
                
            }
        case "Camera":
            buttonView.isHidden = true
            AcView.isHidden = true
            switchView.isHidden = true
            AcCircularView.isHidden = true
            CamereView.isHidden = false
            curtainView.isHidden = true
            LockView.isHidden = true
 
            

            
            
        default:
            break
        }
    }
    
    
    func checkTuyaDevicesInRoom(completion: @escaping (Bool) -> Void) {

        guard let homeId = self.HomeId,
              let roomId = self.selectedRoomId else {
            completion(false)
            return
        }

        guard let home = SkromanIsraDatabaseHelper.shared.fetchHomeById(homeServerId: homeId),
              let tuyaHomeId = home.tuyaHomeId else {
            completion(false)
            return
        }

        SkromanIsraDatabaseHelper.shared.fetchRoomByRoomId(roomId: roomId) { room in

            guard let room = room,
                  let tuyaRoomId = room.tuyaRoomId,
                  tuyaRoomId > 0 else {
                completion(false)
                return
            }

            SkromanIsraDatabaseHelper.shared.fetchTuyaDevices(
                tuyaHomeId: tuyaHomeId ?? 0,
                tuyaRoomId: tuyaRoomId
            ) { devices in

                let locks = devices.filter {
                    let category = $0.deviceCategory.lowercased()
                    return category == "jtmspro" || category == "videolock"
                }

                print("🔐 Filtered Locks:", locks)
                DispatchQueue.main.async {
                    self.tuyaLockDevices = locks
                    self.lockCollectionView.reloadData()
                    completion(!locks.isEmpty)
                }
            }
        }
    }
   
    private let comingSoonLabel: UILabel = {
        let label = UILabel()
        //label.text = "Coming Soon"
        label.textColor = .white
        label.font = UIFont.boldSystemFont(ofSize: 22)
        label.textAlignment = .center
        label.alpha = 0 // start hidden
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

   

    
    
    func publish_button_to_topic(control: String, no: Int, state: Int, speed: Int, topic: String) {
        let parameters: Parameters = [
            "control": control,
            "no": no,
            "state": state,
            "speed": speed,
            "from": "A",
            "topic": topic
        ]

        print("📤 Publishing to all room \(topic)/HA/A/req: \(parameters)")

        if let jsonData = try? JSONSerialization.data(withJSONObject: parameters, options: []),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            
            let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
            iotDataManager.publishString(jsonString, onTopic: topic + "/HA/A/req", qoS: .messageDeliveryAttemptedAtMostOnce)
        }
    }

    
    func requestLatestDeviceState(topic: String) {
        let fetch_all_params: Parameters = [
            "control": "fetch_all",
            "no": 0,
            "state": 0,
            "speed": 0,
            "from": "A",
            "topic": topic
        ]

        if let jsonData = try? JSONSerialization.data(withJSONObject: fetch_all_params, options: []) {
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("📤 Requesting latest state: \(jsonString)")

                let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
                iotDataManager.publishString(jsonString, onTopic: topic + "/HA/A/req", qoS: .messageDeliveryAttemptedAtMostOnce)
            }
        }
    }

    
  
    func add_device_state_api_func(selectedDevice: Device, state: DeviceStateArray) {
        let add_device_state_params: Parameters = [
            "deviceUid": selectedDevice.deviceUid,
            "unique_id": selectedDevice.uniqueId,
            "POP": selectedDevice.POP,
            "modelNo": selectedDevice.deviceModelNo,
            "deviceType": selectedDevice.deviceType,
            "ack": state.ack,
            "dest_button": state.deviceNumber ?? "",
            "fan_dest": "",
            "config_dim": state.cDim,
            "config_buttons": state.cNm,
            "working_mode": state.workingMode,
            "child_lock_l": state.cL,
            "child_lock_f": state.cF,
            "master": state.master,
            "L_state": state.lightState,
            "L_speed": state.lightSpeed,
            "F_state": state.fanState,
            "F_speed": state.fanSpeed,
            "connectivity": "",
            "control_from": state.controlFrom
        ]
        
        print("📤 Sending device state params:", add_device_state_params)

        AF.request(
            "http://3.7.18.55:3000/skroman/devicestate",
            method: .post,
            parameters: add_device_state_params,
            encoding: JSONEncoding.default
        )
        .validate(statusCode: 200..<300) // ✅ Ensure only success codes pass
        .responseJSON { response in
            switch response.result {
            case .success(let value):
               
                debugLog("✅ Device state added successfully \(value)")
            case .failure(let error):
                if let data = response.data,
                   let serverMessage = String(data: data, encoding: .utf8) {
                    print("❌ API Error:", serverMessage)
                } else {
                    print("❌ Request failed:", error.localizedDescription)
                }
            }
        }
    }

   
    func setupRefreshControl() {
        print("🔄 Pull-to- triggered!")
        let refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        deviceListTableView.refreshControl = refreshControl

        // Optional: if you want same for curtain table
        let curtainRefresh = UIRefreshControl()
        curtainRefresh.attributedTitle = NSAttributedString(string: "Pull to refresh")
        curtainRefresh.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        curtaintableView.refreshControl = curtainRefresh
    }

    @objc func refreshData(_ sender: UIRefreshControl) {
        print("🔄 Pull-to-refresh triggered!")

        startDeviceStateSync(triggeringRefreshControl: sender)
        fetchDeviceByRoomId()
    }

    @objc private func handleAllTabShortcutsDidChange() {
        cachedButtonDetails.removeAll()
        fetchDeviceByRoomId()
    }



    
    func didLongPressButton(_ buttonDetail: ButtonDetails) {
          

           let storyboard = UIStoryboard(name: "Main", bundle: nil)
           guard let editVC = storyboard.instantiateViewController(withIdentifier: "EditDeviceButtonViewController") as? EditDeviceButtonViewController else { return }


         editVC.receivedDeviceStates = receivedDeviceStates
        editVC.selectedButtonDetail = buttonDetail
//           editVC.isFromLongPress = true
           editVC.modalPresentationStyle = .overFullScreen
           editVC.modalTransitionStyle = .crossDissolve
        editVC.delegate = self
           present(editVC, animated: true, completion: nil)
       }

    func didTapDeviceSettings(
        for device: Device,
        buttonDetails: [ButtonDetails],
        deviceStates: [DeviceStateArray],
        deviceScenes: [DeviceScene],
        deviceSchedules: [Schedule]
    ) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let menuVC = storyboard.instantiateViewController(withIdentifier: "NewDeviceMenuViewController") as? NewDeviceMenuViewController {
           // print("✅ Navigating to NewDeviceMenuViewController")
            menuVC.title = "Device Menu"
            menuVC.selectedDevice = device
            menuVC.filteredButtonDetails = buttonDetails
            menuVC.receivedDeviceStates = deviceStates
            menuVC.deviceScenes = deviceScenes
            
            
          
            menuVC.hidesBottomBarWhenPushed = true

            self.navigationController?.pushViewController(menuVC, animated: true)
        } else {
            print("❌ Failed to instantiate NewDeviceMenuViewController")
        }
    }



    func removeDuplicateDevices() {
        devices = Array(Dictionary(grouping: devices, by: { $0.uniqueId }).compactMap { $0.value.first })
    }
    
    
    @objc private func acSliderLongPressed(_ gesture: UILongPressGestureRecognizer) {

        if gesture.state == .began {

            guard !deviceStatesForCurrentRoom.isEmpty else {
                print("⏳ Waiting for device states")
                return
            }

            let storyboard = UIStoryboard(name: "Main", bundle: nil)

            if let manageVC = storyboard.instantiateViewController(
                withIdentifier: "ManageShortcutViewController"
            ) as? ManageShortcutViewController {

                manageVC.filteredDevices = self.devices
                manageVC.deviceStates = self.deviceStatesForCurrentRoom

                let allButtonDetails = self.devices.flatMap {
                    SkromanIsraDatabaseHelper.shared.fetchButtonDetails(uniqueId: $0.uniqueId)
                }

                manageVC.buttonDetails = allButtonDetails
                manageVC.selectedIndexbutton =  4
               
                manageVC.selectedSwitchType = .ac

                navigationController?.pushViewController(manageVC, animated: true)
            }
        }
    }

    func sendACPowerPayload(state: Int) {

        guard let acButton = filteredButtonDetails.first else {
            print("❌ No AC button found")
            return
        }

        let topic = acButton.uniqueId
        let buttonNo = acButton.buttonNo

        print("⚡ Sending AC Power Payload")
        print("topic:", topic)
        print("buttonNo:", buttonNo)
        print("state:", state)

        publishACPayload(
            no: buttonNo,
            speed: currentACSpeed,
            temperature: circularSlider.currentValue,
            state: state,
            which: 1,
            topic: topic
        )
    }
    
}
extension AllRoomsViewController:UITableViewDataSource, UITableViewDelegate{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == deviceListTableView{
            
            return devices.count
        } else if tableView == curtaintableView {
            return devices.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == deviceListTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "DeviceListTableViewCell", for: indexPath) as! DeviceListTableViewCell

            let device = devices[indexPath.row]
            
            print("➡️ For device: \(device.uniqueId), received states: ")
            cell.delegate = self
           // cell.receivedDeviceStates = receivedDeviceStates
            let state = receivedDeviceStates.first(where: { $0.uniqueID == device.uniqueId })

            let series = deviceSeries[device.uniqueId]

            cell.configure(
                with: device,
                deviceStates: state != nil ? [state!] : [],
                series: series
            )
    
            cell.delegate = self
            cell.selectionStyle = .none
            return cell
        }
        else if  tableView == curtaintableView  {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CurtainTableViewCell", for: indexPath) as! CurtainTableViewCell
            let device = devices[indexPath.row]
           // print("➡️ For device curtain: \(device.uniqueId), received states: \(receivedDeviceStates)")
                           cell.receivedDeviceStates = deviceStatesForCurrentRoom
                           cell.configure(with: device, deviceStates: deviceStatesForCurrentRoom)
                 
                  return cell
            
        }
        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView == deviceListTableView {
            return UITableView.automaticDimension
        } else if tableView == curtaintableView {
            return UITableView.automaticDimension
           
        }
        
       
        return UITableView.automaticDimension
    }

    

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Do your navigation or action
        tableView.deselectRow(at: indexPath, animated: false) // so it doesn’t flash
    }

    
    
}



extension AllRoomsViewController:UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch collectionView {
        case roomsCollectionView: return rooms.count
        case catagaryCollectionView: return cartagarys.count
        case buttonsCollectionView: return deviceList.count
        case roomSceneCollectionView:
                print("mergedScenes.count = \(mergedScenes.count)")
                return mergedScenes.count
        case lockCollectionView:
            print("🔢 Lock count:", tuyaLockDevices.count)
            return tuyaLockDevices.count

        default: return 0
        }
    }


       
     
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch collectionView {
            case roomsCollectionView:
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: "AllRoomsCollectionViewCell",
                    for: indexPath
                ) as! AllRoomsCollectionViewCell
                let room = rooms[indexPath.row]
                cell.configure(with: room)
                return cell

            case catagaryCollectionView:
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: "CatgegoryCollectionViewCell",
                    for: indexPath
                ) as! CatgegoryCollectionViewCell
                let categoryName = cartagarys[indexPath.row]
                let isSelected = indexPath == selectedCategoryIndex
                cell.configure(with: categoryName, isSelected: isSelected)
                return cell

        case roomSceneCollectionView:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "RoomsSceneCollectionViewCell",
                for: indexPath
            ) as! RoomsSceneCollectionViewCell

            let scene = mergedScenes[indexPath.row]
            cell.sceneNameLabel.text = scene.sceneName
            cell.sceneImage.image = UIImage(named: scene.sceneIcon)
            return cell

        case   lockCollectionView:

                
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "LockCollectionViewCell",
                for: indexPath
            ) as! LockCollectionViewCell

            let lock = tuyaLockDevices[indexPath.row]

            let name = lock.deviceName.trimmingCharacters(in: .whitespacesAndNewlines)
            cell.lockname.text = name.isEmpty ? lock.deviceId : name
            return cell
            
            
            case buttonsCollectionView:
            guard indexPath.row < deviceList.count else {
                print("❗ Index out of bounds for deviceList at \(indexPath.row)")
                return UICollectionViewCell()
            }

            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "AllShortcutDeviceCollectionViewCell",
                for: indexPath
            ) as! AllShortcutDeviceCollectionViewCell

            let devicedata = deviceList[indexPath.row]
            let deviceImage = deviceImages[indexPath.row]
           
            
            // For shortcut cards we need all buttonDetails + current states.
            // `filteredButtonDetails` can be empty depending on category filters, so use `buttonDetails`.
            cell.configure(with: buttonDetails, deviceStates: deviceStatesForCurrentRoom, filteredDevices: allFetchedDevices)

            cell.configure(
                roomName: devicedata,
                cellName: devicedata,
                imageName: deviceImage,
                isInitiallyOn: false,
                index: indexPath.row,
                deviceStates: deviceStatesForCurrentRoom,
                deviceData: allFetchedDevices,
                filteredButtonDetails: buttonDetails
            )
            cell.cellIndex = indexPath.row // Set index
            cell.onLongPressNavigate = { [weak self] index, _, _, _ in
                guard let self = self else { return }

                if self.deviceStatesForCurrentRoom.isEmpty {

                    print("⚠️ Device states not received yet → requesting state")

                    for device in self.devices {
                        self.requestLatestDeviceState(topic: device.uniqueId)
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                        guard let self = self else { return }

                        if self.deviceStatesForCurrentRoom.isEmpty {
                            print("❌ Still no state received. Navigation cancelled.")
                            return
                        }

                        self.navigateToManageShortcut(index: index)
                    }

                    return
                }

                self.navigateToManageShortcut(index: index)
            }

            cell.isHighlighted = false
            cell.contentView.backgroundColor = .clear
            cell.onPublishPayload = { [weak self] in
                guard let self = self else { return }

                DispatchQueue.main.async {

                    let popup = AutoClosePopup(frame: self.view.bounds)

                    popup.configure(
                        icon: "AppIcon1",     // your image asset
                        title: "Please wait",
                        message: "Processing"
                    )

                    self.view.addSubview(popup)
                }
            }

            return cell
        default:
             break
        }

        return UICollectionViewCell()
    }

    func navigateToManageShortcut(index: Int) {

        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        guard let manageVC = storyboard.instantiateViewController(
            withIdentifier: "ManageShortcutViewController"
        ) as? ManageShortcutViewController else { return }

        manageVC.filteredDevices = self.devices
        manageVC.deviceStates = self.deviceStatesForCurrentRoom

        let allButtonDetails = self.devices.flatMap {
            SkromanIsraDatabaseHelper.shared.fetchButtonDetails(uniqueId: $0.uniqueId)
        }

        manageVC.buttonDetails = allButtonDetails
        manageVC.selectedIndexbutton = index

        switch index {
        case 0:
            manageVC.selectedSwitchType = .light
        case 3:
            manageVC.selectedSwitchType = .fan
        default:
            manageVC.selectedSwitchType = .light
        }

        print("🚀 Passing switchType:", manageVC.selectedSwitchType!)

        self.navigationController?.pushViewController(manageVC, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        switch collectionView {
            
        case roomsCollectionView:
            return CGSize(width: 100, height: 35)
            
        case catagaryCollectionView:
            let category = cartagarys[indexPath.row]
            let font = UIFont.systemFont(ofSize: 14, weight: .medium)
            let padding: CGFloat = 11
            let textWidth = (category as NSString).size(withAttributes: [.font: font]).width
            let totalWidth = textWidth + padding
            return CGSize(width: totalWidth, height: 35)
            
        case roomSceneCollectionView:
               let totalSpacing: CGFloat = 8 * 3
               let leftRightInset: CGFloat = 8 + 8
               let availableWidth = collectionView.bounds.width - totalSpacing - leftRightInset
               let cellWidth = availableWidth / 4
               return CGSize(width: cellWidth, height: 70)
            
        case buttonsCollectionView:
            let leftInset: CGFloat = 8
            let rightInset: CGFloat = 8
            let spacing: CGFloat = 8
            let columns: CGFloat = 2

            let totalSpacing = leftInset + rightInset + spacing * (columns - 1)
            let availableWidth = collectionView.bounds.width - totalSpacing
            let baseCellWidth = availableWidth / columns

            let deviceName = deviceList[indexPath.row]

            if deviceName == "AC" {
                // Return double-width cell
                return CGSize(width: baseCellWidth * 2 + spacing + 10, height: 100)
            } else {
                // Normal cell size
                return CGSize(width: baseCellWidth, height: 100)
            }
            
        case lockCollectionView :
            let leftInset: CGFloat = 8
            let rightInset: CGFloat = 8
            let spacing: CGFloat = 8
            let columns: CGFloat = 2

            let totalSpacing = leftInset + rightInset + spacing * (columns - 1)
            let availableWidth = collectionView.bounds.width - totalSpacing
            let baseCellWidth = availableWidth / columns
            return CGSize(width: baseCellWidth, height: 100)
                   
            
        default:
            return CGSize(width: 20, height: 20)
        }
    }

    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch collectionView {
            
        case roomsCollectionView:
            lastSelectedRoomIndex = indexPath
            for visibleCell in collectionView.visibleCells {
                if let cell = visibleCell as? AllRoomsCollectionViewCell {
                    cell.isSelected = false
                }
            }
            if let selectedCell = collectionView.cellForItem(at: indexPath) as? AllRoomsCollectionViewCell {
                selectedCell.isSelected = true
            }
            let selectedRoom = rooms[indexPath.row]
            selectedRoomId = selectedRoom.roomId
            print("selectedRoomId  at cell \(selectedRoomId)")
            fetchDeviceByRoomId()

         
            selectedCategoryIndex = IndexPath(item: 0, section: 0)
            catagaryCollectionView.reloadData()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.catagaryCollectionView.selectItem(at: self.selectedCategoryIndex, animated: true, scrollPosition: [])
                if !self.cartagarys.isEmpty {
                    self.updateStackViewForCategory(self.cartagarys[0])
                }
            }

        case catagaryCollectionView:
            let previousIndex = selectedCategoryIndex
            selectedCategoryIndex = indexPath
            var reloadIndexPaths = [indexPath]
            if let previous = previousIndex, previous != indexPath {
                reloadIndexPaths.append(previous)
            }
            catagaryCollectionView.reloadItems(at: reloadIndexPaths)
            let selectedCategory = cartagarys[indexPath.item]
            updateStackViewForCategory(selectedCategory)

        case roomSceneCollectionView:
            
            // Reset all visible cells
            for visibleCell in collectionView.visibleCells {
                if let cell = visibleCell as? RoomsSceneCollectionViewCell {
                    cell.setSelected(false)
                }
            }

            // Set selected cell border
            if let selectedCell = collectionView.cellForItem(at: indexPath) as? RoomsSceneCollectionViewCell {
                selectedCell.setSelected(true)
            }

            let selectedScene = defaultRoomScenes[indexPath.row]
            print("Selected Scene: \(selectedScene) at index \(indexPath.row)")
            
            triggerScene(indexPath.row)
            
            print("devices at scene \(devices)")
            
        case lockCollectionView:

            let selectedLock = tuyaLockDevices[indexPath.row]
            print("🔐 Selected Lock:", selectedLock.deviceName)

            let storyboard = UIStoryboard(name: "Main", bundle: nil)

            guard let lockVC = storyboard.instantiateViewController(
                withIdentifier: "LockScreenVc"
            ) as? LockScreenVc else { return }

            let device = ThingSmartDevice(deviceId: selectedLock.deviceId)
                lockVC.deviceModel = device?.deviceModel

            lockVC.selectedLock = selectedLock

            self.navigationController?.pushViewController(lockVC, animated: true)

        default:
            break
        }
    }
    
    func triggerScene(_ sceneIndex: Int) {
        guard sceneIndex < defaultRoomScenes.count else {
            print("❌ Scene index out of range")
            return
        }

        let sceneName = defaultRoomScenes[sceneIndex]
        print("🚀 Triggering Scene: \(sceneName) at index \(sceneIndex)")

       
        for device in devices {
            let uniqueId = device.uniqueId
            let controlNo = "\(sceneIndex + 1)" // index + 1
            publishScene(to: uniqueId, controlNo: controlNo)
        }
    }

  
    func publishScene(to uniqueId: String, controlNo: String) {
        let topic = uniqueId
        let scenePubParameters: [String: Any] = [
            "control": "scene_control",
            "no": Int(controlNo) ?? 0,
            "from": "A",
            "topic": topic
        ]

        if let theJSONData = try? JSONSerialization.data(withJSONObject: scenePubParameters, options: []),
           let theJSONText = String(data: theJSONData, encoding: .utf8) {

            print("📤 Publishing to \(topic)/HA/A/req:\n\(theJSONText)")
            showPopupUpdate()
            let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
            iotDataManager.publishString(theJSONText, onTopic: topic + "/HA/A/req", qoS: .messageDeliveryAttemptedAtMostOnce)
        } else {
            print("❌ Failed to create JSON for device scene: \(uniqueId)")
        }
    }
    @objc func showPopupUpdate() {
        showPopupPresenter.showPopup1(
            on: self.view,
            animationName: "coffee 2",
            title: "scene Set",
            subtitle: "Secen Set successfully."
        )
    }

    @objc func handleSceneLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            let point = gesture.location(in: roomSceneCollectionView)
            
            if let indexPath = roomSceneCollectionView.indexPathForItem(at: point),
               indexPath.row < mergedScenes.count {

                let selectedScene = mergedScenes[indexPath.row]

                print("Long pressed scene: \(selectedScene.sceneName) at index \(indexPath.row)")

                navigateToEditSceneVC(
                    sceneName: selectedScene.sceneName,
                    sceneIcon: selectedScene.sceneIcon,
                    index: indexPath.row
                )
            }
        }
    }

    func navigateToEditSceneVC(sceneName: String, sceneIcon: String, index: Int) {
        if let editVC = storyboard?.instantiateViewController(withIdentifier: "ConfigureRoomSecensViewController") as? ConfigureRoomSecensViewController {
            editVC.sceneName = sceneName
            editVC.sceneIconName = sceneIcon // pass icon
            editVC.sceneIndex = index
            editVC.devices =  devices
            editVC.receivedDeviceStates =  receivedDeviceStates
            navigationController?.pushViewController(editVC, animated: true)
        }
    }


}
extension UIColor {
    convenience init(hex: String, alpha: CGFloat = 1.0) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if hexSanitized.hasPrefix("#") {
            hexSanitized.remove(at: hexSanitized.startIndex)
        }

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b, alpha: alpha)
    }
}



extension AllRoomsViewController
{
    func connetion_aws_function() {
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType:AWS_REGION,
                                                                identityPoolId:IDENTITY_POOL_ID)
        initializeControlPlane(credentialsProvider: credentialsProvider)
        initializeDataPlane(credentialsProvider: credentialsProvider)
        
        if (connected == false) {
            handleConnectViaCert()
            
        } else {
            handleDisconnect()
            
        }
        
    }
    
    func handleDisconnect() {
        self.connectButton?.isHidden = false
        self.connectIoTDataWebSocket?.isHidden = false
        
        logTextView?.text = "Disconnecting..."
        
        DispatchQueue.global(qos: .default).async {
            self.iotDataManager.disconnect()
            DispatchQueue.main.async {
                self.connected = false
            }
        }
    }

    func handleConnectViaCert() {
        
        let defaults = UserDefaults.standard
        let certificateId = defaults.string( forKey: "certificateId")
        if (certificateId == nil) {
            DispatchQueue.main.async {
                
            }
            let certificateIdInBundle = searchForExistingCertificateIdInBundle()
            
            if (certificateIdInBundle == nil) {
                DispatchQueue.main.async {
                    
                }
                createCertificateIdAndStoreinNSUserDefaults(onSuccess: {generatedCertificateId in
                    let uuid = UUID().uuidString
                    
                    self.iotDataManager.connect( withClientId: uuid, cleanSession:true, certificateId:generatedCertificateId, statusCallback: self.mqttEventCallback)
                }, onFailure: {error in
                    print("Received error: \(error)")
                })
            }
        } else {
            let uuid = UUID().uuidString;
            // Connect to the AWS IoT data plane service w/ certificate
            iotDataManager.connect( withClientId: uuid, cleanSession:true, certificateId:certificateId!, statusCallback: self.mqttEventCallback)
        }
    }
    
    func createCertificateIdAndStoreinNSUserDefaults(onSuccess:  @escaping (String)->Void,
                                                     onFailure: @escaping (Error) -> Void) {
        let defaults = UserDefaults.standard
        let csrDictionary = [ "commonName": CertificateSigningRequestCommonName,
                              "countryName": CertificateSigningRequestCountryName,
                              "organizationName": CertificateSigningRequestOrganizationName,
                              "organizationalUnitName": CertificateSigningRequestOrganizationalUnitName]
        
        self.iotManager.createKeysAndCertificate(fromCsr: csrDictionary) { (response) -> Void in
            guard let response = response else {
                DispatchQueue.main.async {
                    self.connectButton.isEnabled = true
                    // self.activityIndicatorView.stopAnimating()
                    self.logTextView.text = "Unable to create keys and/or certificate, check values in Constants.swift"
                }
                onFailure(NSError(domain: "No response on iotManager.createKeysAndCertificate", code: -2, userInfo: nil))
                return
            }
            defaults.set(response.certificateId, forKey:"certificateId")
            defaults.set(response.certificateArn, forKey:"certificateArn")
            let certificateId = response.certificateId
            print("response: [\(String(describing: response))]")
            
            let attachPrincipalPolicyRequest = AWSIoTAttachPrincipalPolicyRequest()
            attachPrincipalPolicyRequest?.policyName = POLICY_NAME
            attachPrincipalPolicyRequest?.principal = response.certificateArn
            
            // Attach the policy to the certificate
            self.iot.attachPrincipalPolicy(attachPrincipalPolicyRequest!).continueWith (block: { (task) -> AnyObject? in
                if let error = task.error {
                    print("Failed: [\(error)]")
                    onFailure(error)
                } else  {
                    print("result: [\(String(describing: task.result))]")
                    DispatchQueue.main.asyncAfter(deadline: .now()+0.5, execute: {
                        if let certificateId = certificateId {
                            onSuccess(certificateId)
                        } else {
                            onFailure(NSError(domain: "Unable to generate certificate id", code: -1, userInfo: nil))
                        }
                    })
                }
                return nil
            })
        }
    }
    func mqttEventCallback( _ status: AWSIoTMQTTStatus ) {
        DispatchQueue.main.async {
            let iot_sample_vc = Iot_sample_ViewController()
            print("connection status = \(status.rawValue)")
            
            switch status {
            case .connecting:
                iot_sample_vc.mqttStatus = "Connecting..."
                print( iot_sample_vc.mqttStatus )
                
                
            case .connected:
                iot_sample_vc.mqttStatus = "Connected"
               
                self.connected = true
                
                let uuid = UUID().uuidString;
                let defaults = UserDefaults.standard
                let certificateId = defaults.string( forKey: "certificateId")
                
                
            case .disconnected:
                iot_sample_vc.mqttStatus = "Disconnected"
                
                print( iot_sample_vc.mqttStatus )
                
            case .connectionRefused:
                iot_sample_vc.mqttStatus = "Connection Refused"
                print( iot_sample_vc.mqttStatus )
                
            case .connectionError:
                iot_sample_vc.mqttStatus = "Connection Error"
                print( iot_sample_vc.mqttStatus )
                
            case .protocolError:
                iot_sample_vc.mqttStatus = "Protocol Error"
                print( iot_sample_vc.mqttStatus )
                
            default:
                iot_sample_vc.mqttStatus = "Unknown State"
                print("unknown state: \(status.rawValue)")
                
            }
            
            NotificationCenter.default.post( name: Notification.Name(rawValue: "connectionStatusChanged"), object: self )
        }
    }
    
    
    
    func searchForExistingCertificateIdInBundle() -> String? {
        let defaults = UserDefaults.standard
        
        let myBundle = Bundle.main
        let myImages = myBundle.paths(forResourcesOfType: "p12" as String, inDirectory:nil)
        let uuid = UUID().uuidString
        
        guard let certId = myImages.first else {
            let certificateId = defaults.string(forKey: "certificateId")
            return certificateId
        }
        
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: certId)) else {
            print("[ERROR] Found PKCS12 File in bundle, but unable to use it")
            let certificateId = defaults.string( forKey: "certificateId")
            return certificateId
        }
        
        DispatchQueue.main.async {
            self.logTextView.text = "found identity \(certId), importing..."
        }
        if AWSIoTManager.importIdentity( fromPKCS12Data: data, passPhrase:"", certificateId:certId) {
            
            defaults.set(certId, forKey:"certificateId")
            defaults.set("from-bundle", forKey:"certificateArn")
            DispatchQueue.main.async {
                self.logTextView.text = "Using certificate: \(certId))"
                self.iotDataManager.connect( withClientId: uuid,
                                             cleanSession:true,
                                             certificateId:certId,
                                             statusCallback: self.mqttEventCallback)
            }
        }
        
        let certificateId = defaults.string( forKey: "certificateId")
        return certificateId
    }
    
    func initializeDataPlane(credentialsProvider: AWSCredentialsProvider) {
        
        
        let iotEndPoint = AWSEndpoint(urlString: IOT_ENDPOINT)
        
        
        let iotDataConfiguration = AWSServiceConfiguration(region: AWS_REGION,
                                                           endpoint: iotEndPoint,
                                                           credentialsProvider: credentialsProvider)
        
        AWSIoTDataManager.register(with: iotDataConfiguration!, forKey: AWS_IOT_DATA_MANAGER_KEY)
        iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
    }
    
    
    func initializeControlPlane(credentialsProvider: AWSCredentialsProvider) {
        
        let controlPlaneServiceConfiguration = AWSServiceConfiguration(region:AWS_REGION, credentialsProvider:credentialsProvider)
        
        
        AWSServiceManager.default().defaultServiceConfiguration = controlPlaneServiceConfiguration
        iotManager = AWSIoTManager.default()
        iot = AWSIoT.default()
    }
    
    
  
}
extension Notification.Name {
    static let masterSliderSwiped = Notification.Name("masterSliderSwiped")
    /// Posted after Manage Shortcut save + local DB sync; All tab clears button cache and reloads.
    static let allTabShortcutsDidChange = Notification.Name("allTabShortcutsDidChange")
}

struct DeviceWithState {
    var device: Device
    var state: DeviceStateArray?
}

extension AllRoomsViewController: EditDeviceButtonDelegate {

    func didUpdateDeviceButtons() {
        print("✅ Button updated → refreshing UI")

        fetchDeviceByRoomId()

        deviceListTableView.reloadData()
        curtaintableView.reloadData()
    }
}


func debugLog(_ message: String) {
    #if DEBUG
    print(message)
    #endif
}
