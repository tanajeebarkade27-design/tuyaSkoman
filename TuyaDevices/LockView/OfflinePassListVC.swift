//
//  OfflinePassListVC.swift
//  SkromanIsra
//
//  Created by Admin on 18/04/26.
//

 
import UIKit
import ThingSmartLockKit
import ThingSmartHomeKit
import ThingSmartBaseKit

class OfflinePassListVC: UIViewController {
    var deviceId : String?
    var deviceCatgory: String?
    var OfflinePassword : [OfflinePasswordModel] = []
    
    @IBOutlet weak var offlineListTableview: UITableView!
    
    
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
        
        offlineListTableview.dataSource =  self
        offlineListTableview.delegate = self
         let uiNib = UINib(nibName: "OfflinePwdCell", bundle: nil)
        offlineListTableview.register(uiNib, forCellReuseIdentifier: "OfflinePwdCell")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.tabBarController?.tabBar.isHidden = true
        
        fetchOfflinePasswords()   // ✅ ADD THIS
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    

    @IBAction func backBtn(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    
    @IBAction func addpaasword(_ sender: Any) {
        let vc = storyboard?.instantiateViewController(withIdentifier: "AddOfflinePassListVC") as! AddOfflinePassListVC
        
        vc.deviceId = deviceId
        vc.deviceCategory = deviceCatgory
        
        navigationController?.pushViewController(vc, animated: true)
    }
    
    
    func fetchOfflinePasswords() {

        guard let deviceId = deviceId else { return }

        let api = ThingSmartLockApi()

        api.getOfflinePasswordList(
            withDevId: deviceId,
            pwdType: "0",     // 0 = all types (or based on your use case)
            status: 1,
            offset: 0,      // pagination start
            limit: 50,      // number of records
            success: { result in

                print("✅ Offline list:", result ?? "")

                var listData: [OfflinePasswordModel] = []

                if let list = result as? [[String: Any]] {

                    let formatter = DateFormatter()
                    formatter.dateFormat = "dd MMM yyyy, hh:mm a"

                    for item in list {

                        let name = item["pwdName"] as? String ?? "Offline"
                        let pwd = item["pwd"] as? String ?? "****"
                        let pwdId = item["pwdId"] as? String ?? ""

                        let start = item["gmtStart"] as? Double ?? 0
                        let end   = item["gmtExpired"] as? Double ?? 0

                        let startDate = Date(timeIntervalSince1970: start)
                        let endDate   = Date(timeIntervalSince1970: end)
                        let status = item["status"] as? Int ?? 0
                        listData.append(
                            OfflinePasswordModel(
                                pwd: pwd,
                                pwdId: pwdId,
                                name: name,
                                startTime: formatter.string(from: startDate),
                                endTime: formatter.string(from: endDate), status: status
                            )
                        )
                    }
                }

                DispatchQueue.main.async {
                    self.OfflinePassword = listData
                    self.offlineListTableview.reloadData()
                }

            },
            failure: { error in
                print("❌ Offline fetch failed:", error as Any)
            }
        )
    }
}



extension OfflinePassListVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return OfflinePassword.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "OfflinePwdCell", for: indexPath) as! OfflinePwdCell
        
        let item = OfflinePassword[indexPath.row]
        
        cell.name.text = item.name
        cell.date.text = "Valid: \(item.startTime) → \(item.endTime)"
        cell.status.text = mapStatus(item.status)
        switch item.status {
        case 1:
            cell.status.textColor = .systemGreen
        case 2:
            cell.status.textColor = .systemOrange
        case 3:
            cell.status.textColor = .systemRed
        default:
            cell.status.textColor = .gray
        }

        return cell
    }
    
    func mapStatus(_ status: Int) -> String {
        switch status {
        case 1: return "Active"
        case 2: return "Used"
        case 3: return "Expired"
        default: return "Unknown"
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 110
    }
}

struct OfflinePasswordModel {
    let pwd: String
    let pwdId: String
    let name: String
    let startTime: String
    let endTime: String
    let status: Int   // ✅ ADD THIS
}
