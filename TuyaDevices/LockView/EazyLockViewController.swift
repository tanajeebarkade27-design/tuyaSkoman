//
//  EazyLockViewController.swift
//  SkromanIsra
//
//  Created by Admin on 16/04/26.
//

//
//  EazyLockViewController.swift
//

import UIKit
import ThingSmartHomeKit
import ThingSmartActivatorKit
import CoreLocation
import NetworkExtension
import Lottie

class EazyLockViewController: UIViewController, ThingSmartActivatorDelegate {

    // MARK: - Variables

    var roomId: String?
    var addedDeviceId: String?

    var ssid: String?
    var password: String?

    var tuyaHomeId: Int64?
    var tuyaRoomId: Int64?

    @IBOutlet weak var serchingView: UIView!

    var pairingStartTime: Date?
    var hasStartedPairing = false
    private var hasAssignedDeviceToRoom = false

    var animationView: LottieAnimationView?

    let locationManager = CLLocationManager()

    lazy var activator: ThingSmartActivator = {
        let act = ThingSmartActivator()
        act.delegate = self
        return act
    }()

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(deviceAdded(_:)),
            name: NSNotification.Name("ThingSmartDeviceAddedNotification"),
            object: nil
        )

        setupSearchingAnimation()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        tabBarController?.tabBar.isHidden = true

        if !hasStartedPairing {
            hasStartedPairing = true
            startEZMode()
        }
    }
    
    

    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Back

    @IBAction func backbtn(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }

    // MARK: - Lottie

    func setupSearchingAnimation() {

        animationView = LottieAnimationView(name: "scan_nearby")

        guard let animationView = animationView else { return }

        animationView.translatesAutoresizingMaskIntoConstraints = false
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = .loop
        animationView.play()

        serchingView.addSubview(animationView)

        NSLayoutConstraint.activate([
            animationView.topAnchor.constraint(equalTo: serchingView.topAnchor),
            animationView.bottomAnchor.constraint(equalTo: serchingView.bottomAnchor),
            animationView.leadingAnchor.constraint(equalTo: serchingView.leadingAnchor),
            animationView.trailingAnchor.constraint(equalTo: serchingView.trailingAnchor)
        ])
    }

    func stopAnimation() {
        animationView?.stop()
        animationView?.removeFromSuperview()
    }

    // MARK: - Start Pairing

    func startEZMode() {

        pairingStartTime = Date()

        guard let homeId = tuyaHomeId,
              let ssid = ssid,
              let password = password else {
            print("❌ Missing Data")
            return
        }

        activator.getTokenWithHomeId(homeId, success: { [weak self] token in

            guard let self = self,
                  let token = token else { return }

            self.activator.startConfigWiFi(
                .EZ,
                ssid: ssid,
                password: password,
                token: token,
                timeout: 180
            )

            print("🚀 Pairing Started")

        }) { error in
            print("❌ Token Error: \(error?.localizedDescription ?? "")")
        }
    }

    // MARK: - Pairing Result

    func activator(_ activator: ThingSmartActivator,
                   didReceiveDevice deviceModel: ThingSmartDeviceModel?,
                   error: Error?) {

        if let device = deviceModel {

            print("✅ Device Found: \(device.name ?? "")")
            print("✅ Device ID: \(device.devId ?? "nil")")

            activator.stopConfigWiFi()
            guard let devId = device.devId, !devId.isEmpty else {
                print("❌ Device Found but devId is nil/empty")
                return
            }

            addedDeviceId = devId
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                self.tryAssignDeviceToRoom(devId: devId, attempt: 0)
            }

        } else if let error = error {
            print("❌ Pairing Failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Notification

    @objc func deviceAdded(_ notification: Notification) {

        guard let userInfo = notification.userInfo,
              let devId = userInfo["devId"] as? String else { return }

        print("✅ Device Added In Home: \(devId)")
        addedDeviceId = devId
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            self.tryAssignDeviceToRoom(devId: devId, attempt: 0)
        }
    }

    // MARK: - Add Device To Room

    private func tryAssignDeviceToRoom(devId: String, attempt: Int) {
        if hasAssignedDeviceToRoom { return }

        guard let homeId = tuyaHomeId,
              let roomId = tuyaRoomId,
              roomId > 0 else {
            print("❌ Missing Home / Room Id")
            return
        }

        if attempt == 0 {
            let cached = ThingSmartDeviceModel(deviceID: devId)
            print("🧩 Target mapping — devId=\(devId), tuyaHomeId=\(homeId), tuyaRoomId=\(roomId), cachedHomeId=\(cached.homeId), cachedRoomId=\(cached.roomId)")
        } else {
            print("🧩 Retry \(attempt) — devId=\(devId), tuyaHomeId=\(homeId), tuyaRoomId=\(roomId)")
        }
        
        // Ensure Tuya home has refreshed and the device exists before moving to room.
        guard let home = ThingSmartHome(homeId: homeId) else {
            print("❌ Invalid Tuya Home")
            return
        }
        home.getDataWithSuccess({ [weak self] (homeModel: ThingSmartHomeModel?) in
            guard let self else { return }
            
            let devices = home.deviceList ?? []
            let rooms = home.roomList ?? []
            
            let deviceExists = devices.contains { $0.devId == devId }
            let roomExists = rooms.contains { $0.roomId == roomId }
            
            print("🔎 Assign attempt \(attempt) — deviceExists=\(deviceExists), roomExists=\(roomExists)")
            
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
            
            guard let room = ThingSmartRoom(roomId: roomId, homeId: homeId) else {
                print("❌ Invalid Tuya Room — roomId=\(roomId), homeId=\(homeId)")
                return
            }
            room.addDevice(withDeviceId: devId, success: { [weak self] in
                guard let self else { return }
                self.hasAssignedDeviceToRoom = true
                print("✅ addDevice success — roomId=\(roomId), devId=\(devId)")

                // Refresh relations so UI/portal reflect the mapping ASAP.
                home.updateReleations(success: {
                    print("✅ home.updateReleations success")
                }, failure: { error in
                    print("⚠️ home.updateReleations failed: \(error?.localizedDescription ?? "")")
                })

                DispatchQueue.main.async { self.stopAnimation() }
            }, failure: { [weak self] error in
                guard let self else { return }
                print("❌ addDevice failed — roomId=\(roomId), devId=\(devId), error=\(error?.localizedDescription ?? "")")

                // Fallback: batch-save room relation (often more reliable right after pairing).
                room.saveBatchRoomRelation(withDeviceGroupList: [devId], success: { [weak self] in
                    guard let self else { return }
                    self.hasAssignedDeviceToRoom = true
                    print("✅ saveBatchRoomRelation success — roomId=\(roomId), devId=\(devId)")

                    home.updateReleations(success: {
                        print("✅ home.updateReleations success (after saveBatchRoomRelation)")
                    }, failure: { error in
                        print("⚠️ home.updateReleations failed (after saveBatchRoomRelation): \(error?.localizedDescription ?? "")")
                    })

                    DispatchQueue.main.async { self.stopAnimation() }
                }, failure: { batchError in
                    print("❌ saveBatchRoomRelation failed — roomId=\(roomId), devId=\(devId), error=\(batchError?.localizedDescription ?? "")")
                    if attempt < 6 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            self.tryAssignDeviceToRoom(devId: devId, attempt: attempt + 1)
                        }
                    }
                })
            })
            
        }, failure: { error in
            print("❌ getHomeData failed:", error?.localizedDescription ?? "")
            if attempt < 6 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    self.tryAssignDeviceToRoom(devId: devId, attempt: attempt + 1)
                }
            }
        })
    }
}


extension EazyLockViewController: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager,
                         didChangeAuthorization status: CLAuthorizationStatus) {

        print("Permission Changed: \(status.rawValue)")

        if status == .authorizedWhenInUse ||
            status == .authorizedAlways {

            locationManager.startUpdatingLocation()
        }
    }
}
