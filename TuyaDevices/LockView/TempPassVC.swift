//
//  TempPassViewC.swift
//  SkromanIsra
//
//  Created by Admin on 14/04/26.
//

import UIKit
import ThingSmartLockKit
import ThingSmartHomeKit
class TempPassVC: UIViewController {
    var deviceId : String?
    private var passwords: [TempPassword] = []
    
    @IBOutlet weak var tempPasswordTableView: UITableView!
   

    var lockDevice: ThingSmartLockDevice?
    var passwordList: [[String: Any]] = []
    var deviceCatgory: String?
    

    override func viewDidLoad() {
        super.viewDidLoad()
        print("🔐 Temp Password Device ID:", deviceId)
         let backgroundImage = UIImageView(image: UIImage(named: "Screen Background"))
                backgroundImage.contentMode = .scaleAspectFill
                 view.insertSubview(backgroundImage, at: 0)
                backgroundImage.translatesAutoresizingMaskIntoConstraints = false
                backgroundImage.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
                backgroundImage.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
                backgroundImage.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
                backgroundImage.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
         

            guard let deviceId = deviceId else {
                print("❌ No deviceId")
                return
            }

            lockDevice = ThingSmartLockDevice(deviceId: deviceId)

           
      
    }
    

    @IBAction func backbtn(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
        fetchOnlineTempPasswordList()
        setupTableView()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    func setupTableView() {
        tempPasswordTableView.delegate = self
        tempPasswordTableView.dataSource = self
        let uinib = UINib(nibName: "TempPassCell", bundle: nil)
        tempPasswordTableView.register(uinib, forCellReuseIdentifier: "TempPassCell")
    }
    
    private func fetchOnlineTempPasswordList() {

        guard let devId = deviceId,
              let lock = ThingSmartLockDevice(deviceId: devId) else {
            print("❌ Invalid device")
            return
        }

        lock.getLockTempPwdList { list in
            print("✅ Temp password list:", list)

            var tempPasswords: [TempPassword] = []

            let formatter = DateFormatter()
            formatter.dateFormat = "dd MMM yyyy, hh:mm a"

            for model in list {

                let name = model.name ?? "Temp Password"

                let startDate = Date(timeIntervalSince1970: TimeInterval(model.effectiveTime))
                let endDate   = Date(timeIntervalSince1970: TimeInterval(model.invalidTime))

                let status = self.passwordStatus(
                    effectiveTime: Int(model.effectiveTime),
                    invalidTime: Int(model.invalidTime)
                )

                tempPasswords.append(
                    TempPassword(
                        name: name,
                        startTime: formatter.string(from: startDate),
                        endTime: formatter.string(from: endDate),
                        status: status
                    )
                )
            }

            DispatchQueue.main.async {
                self.passwords = tempPasswords
                self.tempPasswordTableView.reloadData()
            }
        }
    }
    
   
    private func mapStatus(_ status: Int) -> String {
        switch status {
        case 0:
            return "Unused"
        case 1:
            return "Used"
        case 2:
            return "Expired"
        case 3:
            return "Frozen"
        default:
            return "Unknown"
        }
    }
    private func passwordStatus(
        effectiveTime: Int,
        invalidTime: Int
    ) -> String {

        let now = Int(Date().timeIntervalSince1970)

        if now < effectiveTime {
            return "Not Active Yet"
        }

        if now >= effectiveTime && now <= invalidTime {
            return "Active"
        }

        if now > invalidTime {
            return "Expired"
        }

        return "Unknown"
    }

    @IBAction func addPasswordBtnTapped(_ sender: UIButton) {
            navigateToOnlinePW()
        }

        private func navigateToOnlinePW() {
            guard let vc = storyboard?
                .instantiateViewController(withIdentifier: "AddOnlinePwVC")
                as? AddOnlinePwVC else {
               
                fatalError("❌ OnLinePWViewController not found")
            }
            vc.tuyaDeviceId = self.deviceId
            vc.deviceCategory = self.deviceCatgory
            navigationController?.pushViewController(vc, animated: true)
        }

}

extension TempPassVC: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return passwords.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "TempPassCell", for: indexPath) as! TempPassCell

        let pw = passwords[indexPath.row]

        cell.passwordName?.text = pw.name
        cell.passwordName?.textColor = .white
        cell.passwordDate?.text =
        "Valid: \(pw.startTime) → \(pw.endTime)"
        cell.status.text = pw.status
      
       

       
        switch pw.status {
        case "Active":
            cell.status.textColor = .systemGreen
        case "Expired":
            cell.status.textColor = .systemRed
        case "Not Active Yet":
            cell.status.textColor = .systemOrange
        default:
            cell.status.textColor = .lightGray
        }

        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        cell.detailTextLabel?.numberOfLines = 0

        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
         return 90
    }
}

struct TempPassword {
    let name: String
    let startTime: String
    let endTime: String
    let status: String
}

