import UIKit
import CoreBluetooth
import ThingSmartHomeKit
import ThingSmartBusinessExtensionKit
import ThingSmartBLEKit
import Lottie

class BLEmethodViewController: UIViewController {

    // MARK: - Variables

    var tuyaHomeId: Int64 = 0
    var tuyaRoomId: Int64?

    var ssid: String = ""
    var password: String = ""

    var animationView: LottieAnimationView?
    
    @IBOutlet weak var pairProcessView: UIView!
    
    private var btManager: CBCentralManager?
    private var bleWifiActivator: ThingSmartBLEWifiActivator?
    private var discoveredDevices: [ThingBLEAdvModel] = []
    private var hasAssignedDeviceToRoom = false
    private var isPairing = false
    private var addedDeviceId: String?
    private var pairingProductId: String?
    private var knownDeviceIdsBeforePairing = Set<String>()
    private var watchPollCount = 0

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        btManager = CBCentralManager(delegate: self, queue: .main)
        setupSearchingAnimation()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(deviceAdded(_:)),
            name: NSNotification.Name("ThingSmartDeviceAddedNotification"),
            object: nil
        )
        
        let backgroundImage = UIImageView(image: UIImage(named: "Screen Background"))
               backgroundImage.contentMode = .scaleAspectFill
                view.insertSubview(backgroundImage, at: 0)
               backgroundImage.translatesAutoresizingMaskIntoConstraints = false
               backgroundImage.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
               backgroundImage.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
               backgroundImage.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
               backgroundImage.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
    
    }
    
    
    @IBAction func backBtn(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        ThingSmartBLEManager.sharedInstance().delegate = nil
        ThingSmartBLEManager.sharedInstance().stopListening(true)
    }

    @objc private func deviceAdded(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let devId = userInfo["devId"] as? String,
              isCloudDevId(devId) else { return }

        print("✅ Cloud device added (notification): \(devId)")
        scheduleRoomAssignment(devId: devId)
    }

    /// BLE uuid (32 hex) is NOT valid for `addDevice(withDeviceId:)`. Cloud id looks like `d7e149dfb5c612db133mgd`.
    private func isCloudDevId(_ devId: String) -> Bool {
        let isBleUuid = devId.range(of: "^[0-9a-fA-F]{32}$", options: .regularExpression) != nil
        return !isBleUuid && devId.count >= 18
    }

    private func scheduleRoomAssignment(devId: String) {
        guard !hasAssignedDeviceToRoom else { return }
        addedDeviceId = devId
        DispatchQueue.main.asyncAfter(deadline: .now() + 8) { [weak self] in
            self?.tryAssignDeviceToRoom(devId: devId, attempt: 0)
        }
    }
}

 

// MARK: - Bluetooth

extension BLEmethodViewController: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {

        switch central.state {

        case .poweredOn:

            print("🔵 Bluetooth ON")

            startBLEScan()

        default:

            print("⚠️ Bluetooth State => \(central.state.rawValue)")
        }
    }
}

// MARK: - Scan

extension BLEmethodViewController {

    func startBLEScan() {

        ThingSmartBLEManager.sharedInstance().delegate = self

        ThingSmartBLEManager.sharedInstance().startListening(true)

        print("🚀 Start BLE Scan")
    }
}

// MARK: - Discovery

extension BLEmethodViewController: ThingSmartBLEManagerDelegate {

    func didDiscoveryDevice(withDeviceInfo deviceInfo: ThingBLEAdvModel) {

        print("===================================")
        print("✅ DEVICE FOUND")
       
        print("ProductId => \(deviceInfo.productId ?? "")")
        print("BLE Type => \(deviceInfo.bleType.rawValue)")
        print("===================================")

        let exists = discoveredDevices.contains {
            $0.uuid == deviceInfo.uuid
        }

        if exists {
            return
        }

        discoveredDevices.append(deviceInfo)

        guard !isPairing else { return }
        pairBLEWifiDevice(deviceInfo)
    }
    
    
    func setupSearchingAnimation() {

        animationView = LottieAnimationView(name: "scan_nearby")

        guard let animationView = animationView else { return }

        animationView.translatesAutoresizingMaskIntoConstraints = false
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = .loop
        animationView.play()

        pairProcessView.addSubview(animationView)

        NSLayoutConstraint.activate([
            animationView.topAnchor.constraint(equalTo: pairProcessView.topAnchor),
            animationView.bottomAnchor.constraint(equalTo: pairProcessView.bottomAnchor),
            animationView.leadingAnchor.constraint(equalTo: pairProcessView.leadingAnchor),
            animationView.trailingAnchor.constraint(equalTo: pairProcessView.trailingAnchor)
        ])
    }

    func stopAnimation() {
        animationView?.stop()
        animationView?.removeFromSuperview()
    }
    
    
}

// MARK: - Pair BLE + WiFi Device

 
    extension BLEmethodViewController {

        func pairBLEWifiDevice(_ deviceInfo: ThingBLEAdvModel) {

            print("🚀 Start BLE + WiFi Pairing")
            print("ℹ️ BLE uuid=\(deviceInfo.uuid ?? "") — room assign needs cloud devId after Wi‑Fi activation")

            isPairing = true
            pairingProductId = deviceInfo.productId

            snapshotKnownDevices { [weak self] in
                self?.startBLEConfig(deviceInfo: deviceInfo)
            }
        }

        private func snapshotKnownDevices(completion: @escaping () -> Void) {
            guard let home = ThingSmartHome(homeId: tuyaHomeId) else {
                completion()
                return
            }
            home.getDataWithSuccess({ [weak self] _ in
                self?.knownDeviceIdsBeforePairing = Set((home.deviceList ?? []).compactMap(\.devId))
                print("📋 Devices in home before pair: \(self?.knownDeviceIdsBeforePairing.count ?? 0)")
                completion()
            }, failure: { [weak self] _ in
                self?.knownDeviceIdsBeforePairing = []
                completion()
            })
        }

        private func startBLEConfig(deviceInfo: ThingBLEAdvModel) {

            guard let activator = ThingSmartActivator.sharedInstance() else {
                print("❌ Activator Nil")
                isPairing = false
                return
            }

            activator.getTokenWithHomeId(
                tuyaHomeId,
                success: { [weak self] token in

                    guard let self = self else { return }

                    guard let token = token else {

                        print("❌ Token Empty")

                        return
                    }

                    print("🪪 Activation Token => \(token)")

                    let pairConfig = ThingSmartBLEPairConfiguration()

                    pairConfig.uuid = deviceInfo.uuid
                    pairConfig.pid = deviceInfo.productId
                    pairConfig.ssid = self.ssid
                    pairConfig.pwd = self.password
                    pairConfig.token = token
                    pairConfig.homeId = NSNumber(value: self.tuyaHomeId)
                    pairConfig.timeout = 120

                    let activator = ThingSmartBLEWifiActivator()
                    activator.bleWifiDelegate = self
                    self.bleWifiActivator = activator

                    activator.startConfigBLEWifiDevice(
                        with: pairConfig,
                        success: {
                            print("ℹ️ BLE Wi‑Fi config started (waiting for cloud devId…)")
                        },
                        failure: {
                            print("❌ DEVICE PAIR FAILED")
                            self.isPairing = false
                        }
                    )

                    self.startWatchingForCloudDevice()

                },
                failure: { [weak self] error in
                    print("❌ Token Failed")
                    print(error?.localizedDescription ?? "")
                    self?.isPairing = false
                }
            )
        }

        private func startWatchingForCloudDevice() {
            watchPollCount = 0
            pollForCloudDevice()
        }

        private func pollForCloudDevice() {
            guard !hasAssignedDeviceToRoom, watchPollCount < 60 else { return }
            watchPollCount += 1

            guard let home = ThingSmartHome(homeId: tuyaHomeId),
                  let targetRoomId = tuyaRoomId else { return }

            home.getDataWithSuccess({ [weak self] _ in
                guard let self else { return }

                if let cloudDevice = self.findLockNeedingRoom(in: home.deviceList ?? [], targetRoomId: targetRoomId),
                   let devId = cloudDevice.devId {
                    print("✅ Cloud lock found: \(devId) (roomId=\(cloudDevice.roomId), target=\(targetRoomId))")
                    self.scheduleRoomAssignment(devId: devId)
                    return
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.pollForCloudDevice()
                }
            }, failure: { [weak self] _ in
                guard let self else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.pollForCloudDevice()
                }
            })
        }

        private func findLockNeedingRoom(
            in devices: [ThingSmartDeviceModel],
            targetRoomId: Int64
        ) -> ThingSmartDeviceModel? {

            let needsRoom = devices.filter { model in
                guard let devId = model.devId, isCloudDevId(devId) else { return false }
                if let pid = pairingProductId, !pid.isEmpty, model.productId != pid { return false }
                // devId in home ≠ in room; roomId 0 = default “no room” until addDevice runs
                return model.roomId != targetRoomId
            }

            if let newlyPaired = needsRoom.first(where: {
                guard let id = $0.devId else { return false }
                return !knownDeviceIdsBeforePairing.contains(id)
            }) {
                return newlyPaired
            }

            return needsRoom.last
        }
    }

// MARK: - BLE WiFi Activator Delegate

extension BLEmethodViewController: ThingSmartBLEWifiActivatorDelegate {

    func bleWifiActivator(
        _ activator: ThingSmartBLEWifiActivator,
        didReceiveBLEWifiConfigDevice deviceModel: ThingSmartDeviceModel?,
        error: Error?
    ) {
        if let device = deviceModel {
            print("✅ Device Found: \(device.name ?? "")")
            print("✅ Device ID: \(device.devId ?? "nil")")

            guard let devId = device.devId, !devId.isEmpty else {
                print("❌ Device Found but devId is nil/empty")
                return
            }

            guard isCloudDevId(devId) else {
                print("ℹ️ Delegate returned BLE uuid, not cloud id — waiting for poll")
                return
            }

            scheduleRoomAssignment(devId: devId)
        } else if let error = error {
            print("❌ BLE Pairing Failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - Add Device To Room

extension BLEmethodViewController {

    private func tryAssignDeviceToRoom(devId: String, attempt: Int) {
        if hasAssignedDeviceToRoom { return }

        guard tuyaHomeId > 0,
              let roomId = tuyaRoomId,
              roomId > 0 else {
            print("❌ Missing Home / Room Id")
            return
        }

        if attempt == 0 {
            let cached = ThingSmartDeviceModel(deviceID: devId)
            print("🧩 Target mapping — devId=\(devId), tuyaHomeId=\(tuyaHomeId), tuyaRoomId=\(roomId), cachedHomeId=\(cached.homeId), cachedRoomId=\(cached.roomId)")
        } else {
            print("🧩 Retry \(attempt) — devId=\(devId), tuyaHomeId=\(tuyaHomeId), tuyaRoomId=\(roomId)")
        }

        guard let home = ThingSmartHome(homeId: tuyaHomeId) else {
            print("❌ Invalid Tuya Home")
            return
        }

        home.getDataWithSuccess({ [weak self] (_: ThingSmartHomeModel?) in
            guard let self else { return }

            let devices = home.deviceList ?? []
            let rooms = home.roomList ?? []

            let deviceExists = devices.contains { $0.devId == devId }
            let roomExists = rooms.contains { $0.roomId == roomId }

            let model = devices.first { $0.devId == devId }
            let currentRoom = model?.roomId ?? -1
            print("🔎 Assign attempt \(attempt) — deviceExists=\(deviceExists), roomExists=\(roomExists)")
            print("   device.roomId=\(currentRoom) (0 = not in a room yet) → assigning to tuyaRoomId=\(roomId)")

            if model?.roomId == roomId {
                print("✅ Already in target room")
                hasAssignedDeviceToRoom = true
                isPairing = false
                DispatchQueue.main.async { self.stopAnimation() }
                return
            }

            guard deviceExists, roomExists else {
                if attempt < 6 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        self.tryAssignDeviceToRoom(devId: devId, attempt: attempt + 1)
                    }
                } else {
                    print("❌ Device/Room not ready after retries — giving up")
                }
                return
            }

            guard let room = ThingSmartRoom(roomId: roomId, homeId: tuyaHomeId) else {
                print("❌ Invalid Tuya Room — roomId=\(roomId), homeId=\(tuyaHomeId)")
                return
            }

            room.addDevice(withDeviceId: devId, success: { [weak self] in
                guard let self else { return }

                self.hasAssignedDeviceToRoom = true
                self.isPairing = false
                print("✅ Device successfully added to room \(roomId)")

                home.updateReleations(success: {
                    print("✅ home.updateReleations success")
                }, failure: { error in
                    print("⚠️ home.updateReleations failed: \(error?.localizedDescription ?? "")")
                })

                DispatchQueue.main.async {
                    self.stopAnimation()

                    let alert = UIAlertController(
                        title: "Success",
                        message: "Lock was added to your room successfully.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                        ThingSmartHome(homeId: self.tuyaHomeId)?
                            .getDataWithSuccess({ _ in
                                NotificationCenter.default.post(
                                    name: Notification.Name("ReloadHomeData"),
                                    object: nil
                                )
                                self.navigationController?.popViewController(animated: true)
                            }, failure: { error in
                                print(error?.localizedDescription ?? "")
                            })
                    })
                    self.present(alert, animated: true)
                }
            }, failure: { [weak self] error in
                guard let self else { return }
                print("❌ addDevice failed: \(error?.localizedDescription ?? "")")

                room.saveBatchRoomRelation(withDeviceGroupList: [devId], success: { [weak self] in
                    guard let self else { return }
                    self.hasAssignedDeviceToRoom = true
                    self.isPairing = false
                    print("✅ saveBatchRoomRelation success")
                    home.updateReleations(success: nil, failure: nil)
                    DispatchQueue.main.async { self.stopAnimation() }
                }, failure: { batchError in
                    print("❌ saveBatchRoomRelation failed: \(batchError?.localizedDescription ?? "")")
                    if attempt < 6 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            self.tryAssignDeviceToRoom(devId: devId, attempt: attempt + 1)
                        }
                    }
                })
            })
        }, failure: { [weak self] error in
            print("❌ getHomeData failed:", error?.localizedDescription ?? "")
            if let self, attempt < 6 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    self.tryAssignDeviceToRoom(devId: devId, attempt: attempt + 1)
                }
            }
        })
    }
}
