//
//  ManageShortcutViewController.swift
//  SkromanIsra
//
//  Created by Admin on 06/08/25.
//

import UIKit
import  Alamofire

class ManageShortcutViewController: UIViewController {

    @IBOutlet weak var shortcutbuttonsTableView: UITableView!
    
    @IBOutlet weak var saveBtn: UIButton!
    
    var selectedSwitchType: SwitchType?
    var buttonDetails: [ButtonDetails] = []
       var deviceStates: [DeviceStateArray] = []
       var filteredDevices: [Device] = []

    var selectedIndexbutton: Int?
    // Dictionary to store selections per device
    var allSelectedServerIdsPerDevice: [String: Set<String>] = [:]

    var switchList: [SwitchItem] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        saveBtn.tintColor =  .white
        print("at manage selectedIndexbutton at \(selectedIndexbutton ?? -1)")
        print("at manage buttonDetails at shortcut \(buttonDetails)")
        print("at manage filteredDevices at shortcut  \(filteredDevices)")
        print("at manage deviceStates  at shortcut \(deviceStates)")

        saveBtn.backgroundColor = .white
        saveBtn.setTitleColor(.black, for: .normal)
        saveBtn.layer.cornerRadius = 8
        saveBtn.clipsToBounds = true
      
        switchList.removeAll()

        guard let selectedType = selectedSwitchType else {
            print("❌ selectedSwitchType is nil")
            return
        }

        for device in filteredDevices {

            guard let state = deviceStates.first(where: { $0.uniqueID == device.uniqueId }) else {
                continue
            }

            let details = buttonDetails.filter {
                $0.uniqueId == device.uniqueId
            }

            let allSwitches = createSwitches(from: state, buttonDetails: details)

            // 🔥 FILTER HERE BASED ON TYPE
            let filteredSwitches = allSwitches.filter { switchItem in
                switch selectedType {
                case .light:
                    return switchItem.type == .light

                case .fan:
                    return switchItem.type == .fan

                case .ac:
                    return switchItem.type == .ac

                case .master:
                    return switchItem.type == .master
                }
            }

            switchList.append(contentsOf: filteredSwitches)
        }

        print("✅ Final switchList after filtering:", switchList)

        shortcutbuttonsTableView.backgroundColor = .clear
        let nib = UINib(nibName: "ManageShortcutTableViewCell", bundle: nil)
        shortcutbuttonsTableView.register(nib, forCellReuseIdentifier: "ManageShortcutTableViewCell")
        shortcutbuttonsTableView.dataSource = self
        shortcutbuttonsTableView.delegate = self

        shortcutbuttonsTableView.reloadData()
        print("✅ Final switchList: \(switchList)")
    }


    
    @IBAction func backButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    
    @IBAction func saveButton(_ sender: Any) {
        let payload = buildShortcutsSyncPayload()
        guard !payload.isEmpty else {
            showErrorPopup(message: "Nothing to save for this category.")
            return
        }
        submitShortcuts(shortcutsPayload: payload)
    }

    /// Same category filter as `ManageShortcutTableViewCell.filteredSwitchList` for the current `selectedIndexbutton`.
    private func switchesInCategory(for device: Device) -> [SwitchItem] {
        let forDevice = switchList.filter { $0.uniqueID == device.uniqueId }
        guard let category = selectedIndexbutton else { return forDevice }

        switch category {
        case 0:
            return forDevice.filter {
                $0.buttonDetail?.buttonControlName == "L" && $0.configDim == "0"
            }
        case 1:
            return forDevice.filter {
                guard let controlName = $0.buttonDetail?.buttonControlName else { return false }
                return ["O", "C", "Q", "Y"].contains(controlName) && $0.isShortcut == 1
            }
        case 2:
            return forDevice.filter {
                $0.buttonDetail?.buttonControlName == "L" && $0.configDim == "1"
            }
        case 3:
            return forDevice.filter { $0.buttonDetail?.buttonControlName == "F" }
        case 4:
            return forDevice.filter { $0.buttonDetail?.buttonControlName == "A" }
        default:
            return forDevice
        }
    }

    /// API + local DB: every managed button gets explicit `isShortcut` 1 or 0 (adds and removals).
    private func buildShortcutsSyncPayload() -> [[String: Any]] {
        var rows: [[String: Any]] = []

        for device in filteredDevices {
            let selectedForDevice = allSelectedServerIdsPerDevice[device.uniqueId] ?? []

            for sw in switchesInCategory(for: device) {
                guard let bd = sw.buttonDetail else { continue }
                let serverId = bd.deviceServerId
                let isOn = selectedForDevice.contains(serverId) ? 1 : 0
                rows.append([
                    "deviceServerId": serverId,
                    "isShortcut": isOn
                ])
            }
        }

        return rows
    }

    private func applyLocalShortcutDatabaseSync() {
        for device in filteredDevices {
            let selectedForDevice = allSelectedServerIdsPerDevice[device.uniqueId] ?? []

            for sw in switchesInCategory(for: device) {
                guard let bd = sw.buttonDetail else { continue }
                let serverId = bd.deviceServerId
                let isShortcut = selectedForDevice.contains(serverId) ? 1 : 0
                SkromanIsraDatabaseHelper.shared.updateShortcutFlag(buttonId: bd.buttonId, isShortcut: isShortcut)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    func fetchButtonDetails(uniqueId: String) -> [ButtonDetails] {
        return SkromanIsraDatabaseHelper.shared.fetchButtonDetails(uniqueId: uniqueId)
    }

   
    
    
    func createSwitches(from deviceState: DeviceStateArray, buttonDetails: [ButtonDetails]) -> [SwitchItem] {
        var switches: [SwitchItem] = []
        let lightRelevantChars: Set<Character> = ["L", "O", "D", "Q", "R", "A"]

        // ------------------------
        // 1️⃣ Create LIGHT switches
        // ------------------------
        for (index, char) in deviceState.cNm.enumerated() {
            // Only allow valid chars
            guard lightRelevantChars.contains(char),
                  index < deviceState.lightState.count,
                  index < deviceState.cL.count else { continue }

            let isOn = deviceState.lightState[deviceState.lightState.index(deviceState.lightState.startIndex, offsetBy: index)] == "1" ? 1 : 0
            let isChildLocked = deviceState.cL[deviceState.cL.index(deviceState.cL.startIndex, offsetBy: index)] == "1" ? 1 : 0

            let configDimChar = index < deviceState.cDim.count
                ? String(deviceState.cDim[deviceState.cDim.index(deviceState.cDim.startIndex, offsetBy: index)])
                : nil

            let speedChar = index < deviceState.lightSpeed.count
                ? String(deviceState.lightSpeed[deviceState.lightSpeed.index(deviceState.lightSpeed.startIndex, offsetBy: index)])
                : nil

            // ✅ Match by buttonNo instead of index
            let buttonDetail = buttonDetails.first(where: { $0.buttonNo == index + 1 })

           
            var nextState: Int? = nil
            if let cIndex = deviceState.cNm.firstIndex(of: "C") {
                let intIndex = deviceState.cNm.distance(from: deviceState.cNm.startIndex, to: cIndex)
                if intIndex < deviceState.lightState.count {
                    let cState = deviceState.lightState[deviceState.lightState.index(deviceState.lightState.startIndex, offsetBy: intIndex)]
                    nextState = (cState == "1" ? 1 : 0)
                }
            }
            if let yIndex = deviceState.cNm.firstIndex(of: "Y") {
                let intIndex = deviceState.cNm.distance(from: deviceState.cNm.startIndex, to: yIndex)
                if intIndex < deviceState.lightState.count {
                    let yState = deviceState.lightState[deviceState.lightState.index(deviceState.lightState.startIndex, offsetBy: intIndex)]
                    nextState = (yState == "1" ? 1 : 0)
                }
            }

            let switchType: SwitchType
            let switchName: String

            if char == "A" {
                switchType = .ac
                switchName = "AC\(index + 1)"
            } else {
                switchType = .light
                switchName = "L\(index + 1)"
            }

            
            
            switches.append(SwitchItem(
                name: switchName,
                type: switchType,
                switchIndex: index + 1,
                isOnState: isOn,
                isChildLocked: isChildLocked,
                speed: speedChar,
                uniqueID: deviceState.uniqueID,
                buttonDetail: buttonDetail,
                configDim: configDimChar,
                destButton: index + 1,
                fanDest: nil,
                isShortcut: buttonDetail?.isShortcut,
                nextState: nextState,
                rRegulator: deviceState.rRegulator
            ))

        }
        // ---------------------
        // 2️⃣ Create FAN switches (match buttonControlName == "F")
        // ---------------------
        let fanButtons = buttonDetails
            .filter { $0.buttonControlName == "F" }
            .sorted { $0.buttonNo < $1.buttonNo }

        for (index, fanChar) in deviceState.fanState.enumerated() {
            let isOn = fanChar == "1" ? 1 : 0

            let speedChar = index < deviceState.fanSpeed.count
                ? String(deviceState.fanSpeed[deviceState.fanSpeed.index(deviceState.fanSpeed.startIndex, offsetBy: index)])
                : nil

            let isChildLocked = index < deviceState.cF.count
                ? (deviceState.cF[deviceState.cF.index(deviceState.cF.startIndex, offsetBy: index)] == "1" ? 1 : 0)
                : 0

            let buttonDetail = fanButtons.count > index ? fanButtons[index] : nil

            switches.append(SwitchItem(
                name: "F\(index + 1)",
                type: .fan,
                switchIndex: index + 1,
                isOnState: isOn,
                isChildLocked: isChildLocked,
                speed: speedChar,
                uniqueID: deviceState.uniqueID,
                buttonDetail: buttonDetail,
                configDim: nil,
                destButton: nil,
                fanDest: index + 1,
                isShortcut: buttonDetail?.isShortcut, rRegulator: deviceState.rRegulator
            ))
        }

      
        if let masterChar = deviceState.cM.first {
            let isOn = (deviceState.master == 1) ? 1 : 0
            let isChildLocked = (masterChar == "1") ? 1 : 0
            let masterButton = buttonDetails.first { $0.buttonControlName == "M" }

            switches.append(SwitchItem(
                name: "Master",
                type: .master,
                switchIndex: 1,
                isOnState: isOn,
                isChildLocked: isChildLocked,
                speed: nil,
                uniqueID: deviceState.uniqueID,
                buttonDetail: masterButton,
                configDim: nil,
                destButton: nil,
                fanDest: nil,
                isShortcut: masterButton?.isShortcut, rRegulator: deviceState.rRegulator
            ))
        }

        debugLog("✅ All switches created: \(switches)")
        return switches
    }
    
    
    
    private func submitShortcuts(shortcutsPayload: [[String: Any]]) {
        let url = "http://3.7.18.55:3000/skroman/editButtonShortcuts"

        let parameters: [String: Any] = [
            "shortcuts": shortcutsPayload
        ]
        print("parameters at \(parameters)")

        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default)
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    print("✅ API Success: \(value)")

                    DispatchQueue.main.async {
                        self.applyLocalShortcutDatabaseSync()
                        NotificationCenter.default.post(name: .allTabShortcutsDidChange, object: nil)
                        self.showSuccessPopup(message: "Shortcuts updated successfully.") { [weak self] in
                            self?.navigationController?.popViewController(animated: true)
                        }
                    }

                case .failure(let error):
                    print("❌ API Error: \(error.localizedDescription)")

                    DispatchQueue.main.async {
                        self.showErrorPopup(message: "Failed to update shortcuts. Try again.")
                    }
                }
            }
    }

    func showSuccessPopup(message: String, onOK: (() -> Void)? = nil) {
        let alert = UIAlertController(title: "Success",
                                      message: message,
                                      preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            onOK?()
        })

        present(alert, animated: true)
    }

    func showErrorPopup(message: String) {
        let alert = UIAlertController(title: "Error",
                                      message: message,
                                      preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))

        present(alert, animated: true)
    }


}


extension ManageShortcutViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        let devicesWithSwitch = filteredDevices.filter { device in
            switchList.contains { $0.uniqueID == device.uniqueId }
        }

        return devicesWithSwitch.count
    }
       
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "ManageShortcutTableViewCell",
            for: indexPath
        ) as? ManageShortcutTableViewCell else {
            return UITableViewCell()
        }

        let devicesWithSwitch = filteredDevices.filter { device in
            switchList.contains { $0.uniqueID == device.uniqueId }
        }

        let device = devicesWithSwitch[indexPath.row]

        let deviceSwitches = switchList.filter {
            $0.uniqueID == device.uniqueId
        }

        cell.delegate = self
        cell.selectedIndexbutton = selectedIndexbutton
        cell.configure(with: device, switches: deviceSwitches)

        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 400
        
    }
    
    
}

extension ManageShortcutViewController: ManageShortcutCellDelegate {

    func manageShortcutCell(_ cell: ManageShortcutTableViewCell, didUpdateSelectedServerIds serverIds: Set<String>) {
        guard let deviceId = cell.currentDevice?.uniqueId else { return }

        // 1️⃣ Update selection for this device
        allSelectedServerIdsPerDevice[deviceId] = serverIds

        print("📌 Updated selections per device: \(allSelectedServerIdsPerDevice)")

       
        let combinedSelectedServerIds: [String] = allSelectedServerIdsPerDevice
            .values                         // all sets
            .reduce(into: Set<String>()) { $0.formUnion($1) } // merge into one set
            .sorted()                       // optional: sort
        print("📌 Combined selectedServerIds: \(combinedSelectedServerIds)")

       
    }
}




