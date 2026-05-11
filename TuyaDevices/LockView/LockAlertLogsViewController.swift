//
//  LockAlertLogsViewController.swift
//  SkromanIsra
//
//  Created by Admin on 13/04/26.
//

import UIKit
import ThingSmartHomeKit
import ThingSmartLockKit
class LockAlertLogsViewController: UIViewController {
    
   
    @IBOutlet weak var Alerts: UIButton!
    
    @IBOutlet weak var alertsTableView: UITableView!
    
    @IBOutlet weak var OpertionLogs: UIButton!
    var deviceId : String?
    
    private var device: ThingSmartDevice?
    private var allLogs: [TuyaLog] = []
    private var logs: [TuyaLog] = []

    
    override func viewDidLoad() {
        super.viewDidLoad()
        let backgroundImage = UIImageView(image: UIImage(named: "Screen Background"))
               backgroundImage.contentMode = .scaleAspectFill
                view.insertSubview(backgroundImage, at: 0)
               backgroundImage.translatesAutoresizingMaskIntoConstraints = false
               backgroundImage.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
               backgroundImage.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
               backgroundImage.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
               backgroundImage.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        setupTable()
         
        getUnlockRecords()
        
        Alerts.tintColor = .white
    }
    

    
    private func setupTable() {
        alertsTableView.dataSource = self
        alertsTableView.delegate = self
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
    
    let request = ThingSmartRequest()

    private func getUnlockRecords(offset: Int = 0, limit: Int = 30) {

        guard let devId = deviceId else {
            print("❌ Device ID missing")
            return
        }

        let request = ThingSmartRequest()

        request.request(
            withApiName: "tuya.m.device.lock.log.list",
            postData: [
                "devId": devId,
                "offset": offset,
                "limit": limit
            ],
            version: "1.0",
            success: { [weak self] (result: Any?) in
                print("✅ Cloud unlock records:", result ?? "nil")
                self?.parseUnlockRecords(result)
            },
            failure: { error in
                print("❌ Cloud API error:", error?.localizedDescription ?? "")
            }
        )
    }
    
    

    private func parseUnlockRecords(_ result: Any?) {

        guard
            let dict = result as? [String: Any],
            let records = dict["records"] as? [[String: Any]]
        else {
            print("❌ Invalid cloud log format")
            return
        }

        var tempLogs: [TuyaLog] = []

        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy, hh:mm a"

        for item in records {

            let timeStamp = item["time"] as? Int ?? 0
            let category = item["logCategory"] as? String ?? ""
            let logType = item["logType"] as? String ?? ""
            let data = item["data"] as? String ?? ""

            let date = Date(timeIntervalSince1970: TimeInterval(timeStamp / 1000))
            let dateTime = formatter.string(from: date)

            let readableType = readableLogType(
                category: category,
                type: logType,
                data: data
            )

            tempLogs.append(
                TuyaLog(
                    logType: readableType,
                    dateTime: dateTime,
                    category: category
                )
            )
        }

        DispatchQueue.main.async {
            self.allLogs = tempLogs
            self.showOperationLogs()
        }
    }
    private func showOperationLogs() {
        logs = allLogs.filter { $0.category == "unlock_record" }
        alertsTableView.reloadData()
    }

    private func showAlertLogs() {
        logs = allLogs.filter { $0.category == "alarm_record" }
        alertsTableView.reloadData()
    }

    private func updateButtonUI(isAlertSelected: Bool) {
        Alerts.alpha = isAlertSelected ? 1.0 : 0.5
        OpertionLogs.alpha = isAlertSelected ? 0.5 : 1.0
    }
    
    
    @IBAction func alertsTapped(_ sender: UIButton) {
        showAlertLogs()
        updateButtonUI(isAlertSelected: true)
    }

    @IBAction func operationLogsTapped(_ sender: UIButton) {
        showOperationLogs()
        updateButtonUI(isAlertSelected: false)
    }
    
    
    func readableLogType(category: String, type: String, data: String) -> String {

        // 🔓 Unlock logs
        if category == "unlock_record" {
            switch type {
            case "fingerprint":
                return "Unlocked by Fingerprint"
            case "password":
                return "Unlocked by Password"
            case "card":
                return "Unlocked by Card"
            case "face":
                return "Unlocked by Face"
            case "remote":
                return "Unlocked Remotely"
            case "temporary":
                return "Unlocked by Temp Password"
            default:
                return "Unlocked (\(type))"
            }
        }

       
        if category == "alarm_record" {
            switch type {
            case "low_battery":
                return "Low Battery Alert"
            case "tamper":
                return "Tamper Alert"
            case "wrong_password":
                return "Wrong Password Attempt"
            case "hijack":
                return "Hijack Alert"
            default:
                return "Alarm (\(type))"
            }
        }

        return "Unknown"
    }
    

}
extension LockAlertLogsViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return logs.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "LogCell")
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: "LogCell")

        let log = logs[indexPath.row]

        
        cell.textLabel?.text = log.logType
        cell.textLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        cell.textLabel?.textColor = .white   // 🔥 white text

        
        cell.detailTextLabel?.text = log.dateTime
        cell.detailTextLabel?.font = .systemFont(ofSize: 13)
        cell.detailTextLabel?.textColor = .white.withAlphaComponent(0.7)

        
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear   // 🔥 important

        
        cell.selectionStyle = .none

        return cell
    }
}

struct TuyaLog {
    let logType: String
    let dateTime: String
    let category: String   // 🔥 important for filtering
}
