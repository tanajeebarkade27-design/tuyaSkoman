//
//  LockOpenVC.swift
//  SkromanIsra
//
//  Created by Admin on 14/04/26.
//

import UIKit
import ThingSmartLockKit
import ThingSmartHomeKit
import ThingSmartBaseKit

class LockOpenVC: UIViewController, ThingSmartLockDeviceDelegate , ThingSmartWiFiLockDeviceDelegate{
    
    var masterSliderView: MasterButtonSliderView?
    var deviceId: String?
    var selectedLock: TuyaDeviceModel?
    var device: ThingSmartDevice?
    var lock: ThingSmartLockDevice?
    var pendingUnlockDevice: ThingSmartLockDevice?
    @IBOutlet weak var accessView: UIView!
    @IBOutlet weak var bellbackView: UIView!
    @IBOutlet weak var timercountdown: UILabel!
   
    override func viewDidLoad() {
        super.viewDidLoad()
        bellbackView.layer.cornerRadius = bellbackView.frame.height / 2
        print("📲 Received deviceId:", deviceId ?? "nil")

        guard let devId = deviceId, !devId.isEmpty else {
            print("❌ deviceId is nil or empty")
            return
        }

        print("✅ Valid deviceId:", devId)

       
        lock = ThingSmartLockDevice(deviceId: devId)
        lock?.delegate = self

        
        device = ThingSmartDevice(deviceId: devId)
        device?.delegate = self
        
        
        print("✅ Device & Lock initialized")

        
      

        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSwipe(_:)),
            name: .masterSliderSwiped,
            object: nil
        )

       

        bellbackView.layer.cornerRadius = bellbackView.frame.height / 2
        bellbackView.backgroundColor = UIColor.white.withAlphaComponent(0.15)
    }
    
    
    @IBAction func unclockbtn(_ sender: Any) {
    }
    
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.isUnlockVCShown = false
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        setupMasterSlider()

        let backgroundImage = UIImageView(image: UIImage(named: "Screen Background"))
        backgroundImage.contentMode = .scaleAspectFill
        view.insertSubview(backgroundImage, at: 0)

        backgroundImage.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            backgroundImage.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImage.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundImage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImage.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        guard let devId = deviceId else {
            print("❌ deviceId missing")
            return
        }

        let lock = ThingSmartLockDevice(deviceId: devId)
        lock?.delegate = self
        self.lock = lock
        
       

            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                self.pendingUnlockDevice = appDelegate.pendingUnlockDevice
                print("🔄 Updated device in VC:", self.pendingUnlockDevice != nil)
            }
        
    }
    
    func triggerUnlockFromModel() {
        
    }
    
    // MARK: - Slider Setup
    private func setupMasterSlider() {
        let slider = MasterButtonSliderView()
        slider.translatesAutoresizingMaskIntoConstraints = false
        accessView.addSubview(slider)
        print("✅ Slider added to view:", accessView.subviews)
        NSLayoutConstraint.activate([
            slider.centerXAnchor.constraint(equalTo: accessView.centerXAnchor),
            slider.centerYAnchor.constraint(equalTo: accessView.centerYAnchor),
            slider.leadingAnchor.constraint(equalTo: accessView.leadingAnchor, constant: 20),
            slider.trailingAnchor.constraint(equalTo: accessView.trailingAnchor, constant: -20),
            slider.heightAnchor.constraint(equalToConstant: 50)
        ])

        self.masterSliderView = slider
    }

    // MARK: - Swipe Action (Unlock)
    @objc func handleSwipe(_ notification: Notification) {

        guard let devId = deviceId else {
            print("❌ Missing devId")
            return
        }

        guard let devId = deviceId else { return }

        let lockDevice = ThingSmartWiFiLockDevice(deviceId: devId)
        lockDevice.delegate = self
        

        lockDevice.remoteLock(
            withDevId: devId,
            open: true,
            confirm: true,
            success: { isSuccess in
                print("✅ Door unlocked via model: \(isSuccess)")
            },
            failure: { error in
                //print("❌ Unlock failed: \(error.localizedDescription)")
            }
        )
    }

    
    
    // MARK: - Doorbell DPS Listener
    func device(_ device: ThingSmartDevice?, didReceiveData data: [AnyHashable: Any]?) {

        print("📡 Incoming DPS:", data ?? [:])
        if let dps = data?["dps"] as? [String: Any] {
               print("📊 DPS VALUES:", dps)
           }

        if let dps = data?["dps"] as? [String: Any],
           let doorbell = dps["53"] as? Int,
           doorbell == 1 {

            print("🔔 Doorbell pressed")
        }
    }

    // MARK: - Deny Access
    func denyAccess() {
        print("🚫 Access Denied")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.dismiss(animated: true)
        }
    }
    
    
    func device(_ device: ThingSmartLockDevice, didReceiveRemoteUnlockRequest seconds: Int) {
        print("📩 Remote unlock request received:", seconds)
        guard seconds > 0 else { return }

        self.pendingUnlockDevice = device
    }
       
    
}
