//
//  LockScreenVc.swift
//  SkromanIsra
//
//  Created by Admin on 11/04/26.
//

import UIKit
import ThingSmartHomeKit
import ThingSmartActivatorKit
import ThingSmartLockKit
class LockScreenVc: UIViewController {
    var selectedLock: TuyaDeviceModel?
    var lockDevice: ThingSmartLockDevice?
    var deviceModel: ThingSmartDeviceModel?
    
    @IBOutlet weak var batteryLevel: UILabel!
   
    @IBOutlet weak var tempPasswordView: UIView!
    
    @IBOutlet weak var unlockBtn: UIImageView!
    
    @IBOutlet weak var lockAlertView: UIView!
    
    @IBOutlet weak var offlinePassword: UIView!
    @IBOutlet weak var offlinePasswordTitleLabel: UILabel!
    @IBOutlet weak var offlinePasswordSubtitleLabel: UILabel!

    @IBOutlet weak var Bellpress: UIView!

    private var bellpressHoldLabel: UILabel?
    private var isVideoLockUnlocking = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let deviceId = selectedLock?.deviceId else { return }

        

          lockDevice = ThingSmartLockDevice(deviceId: deviceId)
//           lockDevice?.delegate = self

           DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {

               self.deviceModel = ThingSmartDevice(deviceId: deviceId)?.deviceModel

               guard let dps = self.deviceModel?.dps else {
                   print("❌ DPS nil")
                   return
               }

               print("📦 Initial DPS:", dps)

               self.updateBattery(from: dps)
           }
        printAllDPSchema()

        configureBellpressForLockType()
        
        let backgroundImage = UIImageView(image: UIImage(named: "Screen Background"))
               backgroundImage.contentMode = .scaleAspectFill
                view.insertSubview(backgroundImage, at: 0)
               backgroundImage.translatesAutoresizingMaskIntoConstraints = false
               backgroundImage.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
               backgroundImage.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
               backgroundImage.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
               backgroundImage.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        print("deviceModel:", deviceModel)
        print("schema:", deviceModel?.schemaArray)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(tempPasswordTapped))
        tempPasswordView.isUserInteractionEnabled = true
        tempPasswordView.addGestureRecognizer(tap)
        tempPasswordView.layer.cornerRadius = 12
        tempPasswordView.clipsToBounds = true
        tempPasswordView.backgroundColor = UIColor.white.withAlphaComponent(0.10)
        
        lockAlertView.backgroundColor = UIColor.white.withAlphaComponent(0.10)
        lockAlertView.layer.cornerRadius = 12
        lockAlertView.clipsToBounds = true
        let tap1 = UITapGestureRecognizer(target: self, action: #selector(AlertPasswordTapped))
        lockAlertView.isUserInteractionEnabled = true
        lockAlertView.addGestureRecognizer(tap1)
        
        let tap2 = UITapGestureRecognizer(target: self, action: #selector(offlinePasswordTapped))
        offlinePassword.isUserInteractionEnabled = true
        offlinePassword.addGestureRecognizer(tap2)
        offlinePassword.backgroundColor = UIColor.white.withAlphaComponent(0.10)
        offlinePassword.layer.cornerRadius = 12
        offlinePassword.clipsToBounds = true
        configureOfflinePasswordRow()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard isVideoLockCategory() else { return }
        Bellpress.layer.cornerRadius = Bellpress.bounds.width / 2
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }

    @IBAction func backButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    
    @IBAction func menuBtn(_ sender: Any) {
        
        let alert = UIAlertController(title: "Device Options",
                                      message: nil,
                                      preferredStyle: .actionSheet)
        
       
        let editAction = UIAlertAction(title: "Edit Device", style: .default) { _ in
            self.openEditDevice()
        }
        
       
        let deleteAction = UIAlertAction(title: "Delete Device", style: .destructive) { _ in
            self.deleteDevice()
        }
        
        // ❌ Cancel
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(editAction)
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        
        // For iPad (important)
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX,
                                                  y: self.view.bounds.midY,
                                                  width: 0,
                                                  height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        self.present(alert, animated: true)
    }
    func openEditDevice() {
        guard let lock = selectedLock else { return }

        let popup = EditDeviceNamePopup(currentName: lock.deviceName)
        popup.onSubmit = { [weak self] newName in
            self?.submitDeviceNameChange(newName, popup: popup)
        }
        popup.present(on: view)
    }

    private func submitDeviceNameChange(_ newName: String, popup: EditDeviceNamePopup) {
        guard let lock = selectedLock else { return }
        guard let device = ThingSmartDevice(deviceId: lock.deviceId) else {
            presentNameAlert(title: "Edit Device", message: "Device not available.")
            return
        }

        popup.setSubmitting(true)

        device.updateName(newName, success: { [weak self] in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.applyLocalDeviceNameUpdate(newName, for: lock)
                popup.dismiss()
            }
        }, failure: { [weak self] error in
            DispatchQueue.main.async {
                popup.setSubmitting(false)
                self?.presentNameAlert(
                    title: "Edit Device",
                    message: error?.localizedDescription ?? "Could not update name."
                )
            }
        })
    }

    private func applyLocalDeviceNameUpdate(_ newName: String, for lock: TuyaDeviceModel) {
        let updated = TuyaDeviceModel(
            tuyaHomeId: lock.tuyaHomeId,
            tuyaRoomId: lock.tuyaRoomId,
            deviceId: lock.deviceId,
            deviceName: newName,
            deviceCategory: lock.deviceCategory
        )
        selectedLock = updated
        navigationItem.title = newName

        SkromanIsraDatabaseHelper.shared.insertTuyaDevice(
            tuyaHomeId: lock.tuyaHomeId,
            tuyaRoomId: lock.tuyaRoomId,
            deviceId: lock.deviceId,
            deviceName: newName,
            deviceCategory: lock.deviceCategory
        )

        let managerDevices = TuyaDeviceManager.shared.devices
        if let index = managerDevices.firstIndex(where: { $0.deviceId == lock.deviceId }) {
            var devices = managerDevices
            devices[index] = updated
            TuyaDeviceManager.shared.setDevices(devices)
        }
    }

    private func presentNameAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    
    func deleteDevice() {
        print("🗑 Delete Device tapped")
        
        guard let deviceId = selectedLock?.deviceId else { return }
        
        let confirm = UIAlertController(title: "Delete Device",
                                        message: "Are you sure you want to delete this device?",
                                        preferredStyle: .alert)
        
        confirm.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        confirm.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { [weak self] _ in
            self?.performDeviceRemoval(deviceId: deviceId)
        }))
        
        self.present(confirm, animated: true)
    }

    private func performDeviceRemoval(deviceId: String) {
        guard let device = ThingSmartDevice(deviceId: deviceId) else {
            presentNameAlert(title: "Delete Device", message: "Device not available.")
            return
        }

        device.remove({
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                print("✅ Device deleted")
                self.handleDeviceDeleted(deviceId: deviceId)
                self.navigationController?.popViewController(animated: true)
            }
        }, failure: { [weak self] error in
            DispatchQueue.main.async {
                print("❌ Delete failed:", error?.localizedDescription ?? "")
                self?.presentNameAlert(
                    title: "Delete Device",
                    message: error?.localizedDescription ?? "Could not delete device."
                )
            }
        })
    }

    private func handleDeviceDeleted(deviceId: String) {
        SkromanIsraDatabaseHelper.shared.deleteTuyaDevice(deviceId: deviceId)

        let remaining = TuyaDeviceManager.shared.devices.filter { $0.deviceId != deviceId }
        TuyaDeviceManager.shared.setDevices(remaining)
    }
    
    @objc func unlockTapped() {
        guard !isVideoLockCategory() else { return }
        performStandardLockUnlock()
    }

    @objc private func bellpressLongPressed(_ gesture: UILongPressGestureRecognizer) {
        guard isVideoLockCategory() else { return }

        switch gesture.state {
        case .began:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            UIView.animate(withDuration: 0.15) {
                self.Bellpress.transform = CGAffineTransform(scaleX: 0.94, y: 0.94)
                self.Bellpress.layer.borderColor = UIColor.systemGreen.cgColor
            }
        case .ended:
            UIView.animate(withDuration: 0.15) {
                self.Bellpress.transform = .identity
            }
            performVideoLockUnlock()
        case .cancelled, .failed:
            UIView.animate(withDuration: 0.15) {
                self.Bellpress.transform = .identity
            }
        default:
            break
        }
    }

    private func configureBellpressForLockType() {
        Bellpress.backgroundColor = UIColor.white.withAlphaComponent(0.10)
        Bellpress.clipsToBounds = true
        Bellpress.isUserInteractionEnabled = true

        if isVideoLockCategory() {
            configureVideoLockBellpress()
        } else {
            configureStandardLockBellpress()
        }
    }

    private func configureStandardLockBellpress() {
        Bellpress.layer.borderWidth = 0
        Bellpress.layer.cornerRadius = 60
        unlockBtn.transform = .identity
        bellpressHoldLabel?.removeFromSuperview()
        bellpressHoldLabel = nil

        Bellpress.gestureRecognizers?
            .filter { $0 is UILongPressGestureRecognizer }
            .forEach { Bellpress.removeGestureRecognizer($0) }

        unlockBtn.isUserInteractionEnabled = true
        unlockBtn.gestureRecognizers?.forEach { unlockBtn.removeGestureRecognizer($0) }
        let unlockTap = UITapGestureRecognizer(target: self, action: #selector(unlockTapped))
        unlockBtn.addGestureRecognizer(unlockTap)
    }

    private func configureVideoLockBellpress() {
        Bellpress.layer.borderWidth = 2.5
        Bellpress.layer.borderColor = UIColor.systemGreen.cgColor
        Bellpress.layer.cornerRadius = 60

        unlockBtn.isUserInteractionEnabled = false
        unlockBtn.gestureRecognizers?.forEach { unlockBtn.removeGestureRecognizer($0) }
        unlockBtn.transform = CGAffineTransform(translationX: 0, y: -10)

        bellpressHoldLabel?.removeFromSuperview()
        let label = UILabel()
        label.text = "Hold to unlock"
        label.textColor = .white
        label.font = .systemFont(ofSize: 11, weight: .semibold)
        label.textAlignment = .center
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        Bellpress.addSubview(label)
        bellpressHoldLabel = label

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: Bellpress.leadingAnchor, constant: 10),
            label.trailingAnchor.constraint(equalTo: Bellpress.trailingAnchor, constant: -10),
            label.bottomAnchor.constraint(equalTo: Bellpress.bottomAnchor, constant: -12)
        ])

        Bellpress.gestureRecognizers?
            .filter { $0 is UILongPressGestureRecognizer }
            .forEach { Bellpress.removeGestureRecognizer($0) }

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(bellpressLongPressed(_:)))
        longPress.minimumPressDuration = 0.55
        Bellpress.addGestureRecognizer(longPress)
    }

    private func performStandardLockUnlock() {
        guard let devId = selectedLock?.deviceId else { return }

        print("🔓 Sending unlock request...")
        lockDevice?.setRemoteVoiceUnlockWithDevId(
            devId,
            open: true,
            pwd: "",
            success: { _ in
                print("📡 Request sent")
            },
            failure: { error in
                print("❌ Request failed: \(error?.localizedDescription ?? "")")
            }
        )
    }

    private func performVideoLockUnlock() {
        guard !isVideoLockUnlocking else { return }
        guard let devId = selectedLock?.deviceId else { return }

        isVideoLockUnlocking = true
        print("🔓 Video lock hold-to-unlock for \(devId)")

        let lock = ThingSmartWiFiLockDevice(deviceId: devId)
        lock.remoteLock(
            withDevId: devId,
            open: true,
            confirm: true,
            success: { [weak self] isSuccess in
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.isVideoLockUnlocking = false
                    UINotificationFeedbackGenerator().notificationOccurred(isSuccess ? .success : .warning)
                    self.showUnlockResultPopup(success: isSuccess)
                }
            },
            failure: { [weak self] error in
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.isVideoLockUnlocking = false
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                    self.presentNameAlert(
                        title: "Unlock Failed",
                        message: error?.localizedDescription ?? "Could not unlock the door."
                    )
                }
            }
        )
    }

    private func showUnlockResultPopup(success: Bool) {
        let title = success ? "Unlocked" : "Unlock"
        let message = success
            ? "The door has been unlocked successfully."
            : "Unlock was not confirmed. Please try again."
        presentNameAlert(title: title, message: message)
    }

    private func printAllDPSchema() {
        for schema in deviceModel?.schemaArray ?? [] {
            print("""
            🔹 DP Code: \(schema.code)
               Type: \(schema.type)
               Mode: \(schema.mode)
               Property: \(schema.property)
            """)
        }
    }
    
    @objc func tempPasswordTapped() {
        print("🔑 Temp Password View Tapped")

        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        guard let vc = storyboard.instantiateViewController(
            withIdentifier: "TempPassVC"
        ) as? TempPassVC else {
            print("❌ TempPassVC not found")
            return
        }

        vc.deviceCatgory =  selectedLock?.deviceCategory
        vc.deviceId = selectedLock?.deviceId

        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    
    private func isVideoLockCategory() -> Bool {
        selectedLock?.deviceCategory.lowercased() == "videolock"
    }

    private func configureOfflinePasswordRow() {
        guard isVideoLockCategory() else { return }

        offlinePasswordTitleLabel?.text = "Video Surveillance"
        offlinePasswordSubtitleLabel?.text = "Live camera"
    }

    @objc func offlinePasswordTapped() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        if isVideoLockCategory() {
            guard let vc = storyboard.instantiateViewController(
                withIdentifier: "VideoSurveillanceVc"
            ) as? VideoSurveillanceVc else {
                print("❌ VideoSurveillanceVc not found")
                return
            }

            vc.deviceId = selectedLock?.deviceId
            vc.deviceName = selectedLock?.deviceName
            navigationController?.pushViewController(vc, animated: true)
            return
        }

        guard let vc = storyboard.instantiateViewController(
            withIdentifier: "OfflinePassListVC"
        ) as? OfflinePassListVC else {
            print("❌ OfflinePassListVC not found")
            return
        }

        vc.deviceCatgory = selectedLock?.deviceCategory
        vc.deviceId = selectedLock?.deviceId
        navigationController?.pushViewController(vc, animated: true)
    }
   
    
    @objc func AlertPasswordTapped() {
        print("🔑 Temp Password View Tapped")

        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        guard let vc = storyboard.instantiateViewController(
            withIdentifier: "LockAlertLogsViewController"
        ) as? LockAlertLogsViewController else {
            print("❌ TempPassVC not found")
            return
        }

     
        vc.deviceId = selectedLock?.deviceId

        self.navigationController?.pushViewController(vc, animated: true)
    }

    
    func updateBattery(from dps: [AnyHashable: Any]) {

        if let val = dps["45"] as? Int {
            batteryLevel.text = "\(val)%"
            return
        }

        if let val = dps["45"] as? String {
            batteryLevel.text = "\(val)%"
            return
        }

        if let val = dps["12"] as? Int {
            batteryLevel.text = "\(val)%"
            return
        }

        batteryLevel.text = "N/A"
    }
}

extension LockScreenVc {


    func device(_ device: ThingSmartDevice!,
                didUpdateDps dps: [AnyHashable : Any]!) {

        print("🔋 DPS Update:", dps ?? [:])

        DispatchQueue.main.async {

                   self.updateBattery(from: dps)
               
        }
    }

   
    func device(_ device: ThingSmartLockDevice,
                didReceiveRemoteUnlockRequest seconds: Int) {

        print("⏳ Remote unlock request for \(seconds) seconds")

        guard seconds > 0 else { return }

        DispatchQueue.main.async {

            let alert = UIAlertController(
                title: "Unlock Request",
                message: "Someone is requesting to unlock the door",
                preferredStyle: .alert
            )

            alert.addAction(UIAlertAction(title: "Reject", style: .cancel))

            alert.addAction(UIAlertAction(title: "Unlock", style: .default, handler: { _ in
                
                // 👉 Approve unlock
              //device.acceptRemoteUnlockRequest(true)
                print("✅ Unlock approved")
            }))

            self.present(alert, animated: true)
        }
    }
    
   
}
