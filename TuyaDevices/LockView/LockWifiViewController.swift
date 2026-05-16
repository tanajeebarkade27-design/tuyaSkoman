//
//  LockWifiViewController.swift
//  SkromanIsra
//
//  Created by Admin on 07/04/26.
//

import UIKit

class LockWifiViewController: UIViewController {
    var ssid: String?
    var password: String?
    var tuyaHomeId: Int64?
    var tuyaRoomId: Int64?
    var isConfirmed = false
    var roomName: String?
    @IBOutlet weak var conformImage: UIButton!
    
    
    @IBOutlet weak var backbtn: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
print ("ssid\(ssid) password\(password) tuyaHomeId\(tuyaHomeId) tuyaRoomId\(tuyaRoomId) " )
        let backgroundImage = UIImageView(image: UIImage(named: "Screen Background"))
               backgroundImage.contentMode = .scaleAspectFill
                view.insertSubview(backgroundImage, at: 0)
               backgroundImage.translatesAutoresizingMaskIntoConstraints = false
               backgroundImage.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
               backgroundImage.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
               backgroundImage.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
               backgroundImage.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
    }
    
    
    
    
    @IBAction func backbtn(_ sender: Any) {
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
    
    @IBAction func confirmImageTapped(_ sender: UIButton) {

        isConfirmed.toggle()

        let imageName = isConfirmed ? "checkmark.circle.fill" : "circle"

        conformImage.setImage(UIImage(systemName: imageName), for: .normal)

        print("✅ Confirm toggled:", isConfirmed)
    }
    
    
    @IBAction func nextbtn(_ sender: Any) {

        guard isConfirmed else {
            showAlert("Error", "Please confirm first")
            return
        }

        guard let ssid = ssid,
              let password = password,
              let homeId = tuyaHomeId,
              let roomId = tuyaRoomId else {
            print("❌ Missing data")
            return
        }

        
        let popup = ModeSelectionPopup(frame: self.view.bounds)

        popup.onModeSelected = { mode in
            print("Selected Mode:", mode)

            popup.dismiss()

            if mode == "EZ" {

                let vc = self.storyboard?.instantiateViewController(
                    identifier: "EazyLockViewController"
                ) as! EazyLockViewController

                vc.ssid = ssid
                vc.password = password
                vc.tuyaHomeId = homeId
                vc.tuyaRoomId = roomId
                 print  ("passing parameter \(ssid)  password \(password) homeId:\(homeId) roomId\(roomId)")

                self.navigationController?.pushViewController(vc, animated: true)

            } else if mode == "AP" {

                let vc = self.storyboard?.instantiateViewController(
                    identifier: "APLockViewController"
                ) as! APLockViewController

                vc.ssid = ssid
                vc.password = password
                vc.tuyaHomeId = homeId
                vc.tuyaRoomId = roomId

                self.navigationController?.pushViewController(vc, animated: true)

            } else if mode == "BLE" {
                self.navigateToBLEMethod(
                    ssid: ssid,
                    password: password,
                    homeId: homeId,
                    roomId: roomId
                )
            }
        }

        self.view.addSubview(popup)
    }
    
    
    @IBAction func BleBtn(_ sender: Any) {
        guard isConfirmed else {
            showAlert("Error", "Please confirm first")
            return
        }

        guard let ssid = ssid,
              let password = password,
              let homeId = tuyaHomeId,
              let roomId = tuyaRoomId else {
            print("❌ Missing data")
            return
        }

        navigateToBLEMethod(ssid: ssid, password: password, homeId: homeId, roomId: roomId)
    }

    private func navigateToBLEMethod(ssid: String, password: String, homeId: Int64, roomId: Int64) {
        let vc = storyboard?.instantiateViewController(
            identifier: "BLEmethodViewController"
        ) as! BLEmethodViewController

        vc.ssid = ssid
        vc.password = password
        vc.tuyaHomeId = homeId
        vc.tuyaRoomId = roomId
        print("passing parameter \(ssid) password \(password) homeId:\(homeId) roomId:\(roomId)")

        navigationController?.pushViewController(vc, animated: true)
    }
    
    
    
    func showAlert(_ title: String, _ message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
enum LockMode {
    case ez
    case ap
    case ble
}
