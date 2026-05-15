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
    
    
    @IBOutlet weak var Bellpress: UIView!
    
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
       
        Bellpress.backgroundColor = UIColor.white.withAlphaComponent(0.10)
        Bellpress.layer.cornerRadius = 60
        Bellpress.clipsToBounds = true
        
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
        
        let unlockTap = UITapGestureRecognizer(target: self, action: #selector(unlockTapped))
        unlockBtn.isUserInteractionEnabled = true
        unlockBtn.addGestureRecognizer(unlockTap)
        
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
        print("✏️ Edit Device tapped")
        
          
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "EditLockNameVC") as? EditLockNameVC {
            vc.deviceId = selectedLock?.deviceId
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    
    func deleteDevice() {
        print("🗑 Delete Device tapped")
        
        guard let deviceId = selectedLock?.deviceId else { return }
        
        let confirm = UIAlertController(title: "Delete Device",
                                        message: "Are you sure you want to delete this device?",
                                        preferredStyle: .alert)
        
        confirm.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
//        confirm.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
//            
//            ThingSmartHomeManager().removeDevice(withDeviceId: deviceId, success: {
//                print("✅ Device deleted")
//                self.navigationController?.popViewController(animated: true)
//            }) { error in
//                print("❌ Delete failed:", error?.localizedDescription ?? "")
//            }
//        }))
        
        self.present(confirm, animated: true)
    }
    
    @objc func unlockTapped() {
        guard let devId = selectedLock?.deviceId else { return }

        print("🔓 Sending unlock request...")

        lockDevice?.setRemoteVoiceUnlockWithDevId(
            devId,
            open: true,
            pwd: "",
            success: {_ in 
                print("📡 Request sent")
            },
            failure: { error in
                print("❌ Request failed: \(error?.localizedDescription)")
            }
        )
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
    
    
    @objc func offlinePasswordTapped() {
        print("🔑 Temp Password View Tapped")

        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        guard let vc = storyboard.instantiateViewController(
            withIdentifier: "OfflinePassListVC"
        ) as? OfflinePassListVC else {
            print("❌ TempPassVC not found")
            return
        }

        
        
        vc.deviceCatgory =  selectedLock?.deviceCategory
        vc.deviceId = selectedLock?.deviceId

        self.navigationController?.pushViewController(vc, animated: true)
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
