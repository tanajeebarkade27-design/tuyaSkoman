//
//  schdeuleTypeViewController.swift
//  SkromanIsra
//
//  Created by Admin on 11/03/25.
//

import UIKit
import AWSCore
import AWSIoT
import Alamofire


class schdeuleTypeViewController: UIViewController {
    
    
    
    @IBOutlet var backgroundView: UIView!
    
    @IBOutlet weak var backButon: UIButton!
    var updatedDeviceStates: [(name: String, type: String, status: String)] = []
    
    @IBOutlet weak var daysViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var scheduleView: UIView!
    var selectedDevice: Device?
    @IBOutlet weak var daysView: UIView!
    var devicestate: [DeviceStateArray] = []
    var deviceVc : DeviceViewController?
    var devices: [Device] = []
    var deviceScene: [DeviceScene] = []
    var buttonItems: [(name: String, type: String, status: String)] = []
    var daysArray = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    var selectedDays: [String] = []
    
    
    
    @IBOutlet weak var daysCollectionView: UICollectionView!
    
    
    @IBOutlet weak var datePicker: UIDatePicker!
    
    @IBOutlet weak var timePicker: UIDatePicker!
    
    @IBOutlet weak var dateViewHeight: NSLayoutConstraint!
    @IBOutlet weak var dateView: UIView!
    
    @IBOutlet weak var timeViewHeight: NSLayoutConstraint!
    @IBOutlet weak var timeView: UIView!
    var schedule_type_string : String!
    var deviceUinqueId: String?
    var newDate : String!
    var schdeuleNumber: String?
    
    
    @IBOutlet weak var weekyBtn: UIButton!
    
    @IBOutlet weak var dailyBtn: UIButton!
    
    
    @IBOutlet weak var perticularDaybtn: UIButton!
    
    
    @IBOutlet weak var perviousBtn: UIButton!
    
    @IBOutlet weak var configureBtn: UIButton!
    
    @IBOutlet weak var backgroundimage: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        let buttons: [UIButton] = [ weekyBtn,dailyBtn, perticularDaybtn , perviousBtn, configureBtn]
        for button in buttons {
            button.backgroundColor = .white
            button.setTitleColor(.black, for: .normal)
            button.layer.cornerRadius = 20
            button.layer.masksToBounds = true
        }
        backgroundimage.contentMode = .scaleAspectFill
        backgroundimage.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            backgroundimage.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundimage.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundimage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundimage.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        scheduleView.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        scheduleView.cornerRadius = 15
        backButon.setTitle("", for: .normal)
        backButon.setTitleColor(.black, for: .normal) // Set text color
        
        if let image = UIImage(named: "close")?.resized(to: CGSize(width: 20, height: 20)) {
            backButon.setImage(image, for: .normal)
        }
        daysCollectionView.dataSource = self
        daysCollectionView.delegate = self
        print("devices at the\(devicestate)")
        print("selectedDevice at\(selectedDevice)")
        xibFile()
        daysView.isHidden = true
        dateView.isHidden =  true
        timeView.isHidden =  true
        daysViewHeightConstraint.constant = 0
        dateViewHeight.constant =  0
        timeViewHeight.constant = 0
        
        print("")
        print("schdeuleNumber\(schdeuleNumber)")
        print("devicestate at she type \(buttonItems)")
        print("deivices info\(devices)")
        
        deviceUinqueId = selectedDevice?.uniqueId
        
        
        datePicker.minimumDate = Date()
        
        // Make date & time pickers white
        datePicker.overrideUserInterfaceStyle = .light
        timePicker.overrideUserInterfaceStyle = .light

        datePicker.backgroundColor = UIColor.white
        timePicker.backgroundColor = UIColor.white

        datePicker.tintColor = .white
        timePicker.tintColor = .white

    }
    
    
    
    
    
    func xibFile(){
        let nib = UINib(nibName: "DaysCollectionViewCell", bundle: nil)
        daysCollectionView.register(nib, forCellWithReuseIdentifier: "DaysCollectionViewCell")
    }
    
    @IBAction func backbutton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    
    @IBAction func weekly(_ sender: Any) {
        schedule_type_string = "W"  // Set schedule type to Weekly
        toggleDaysView(show: true)
        toggleDateView(show: false)
        toggletimeView(show: true)
        print("Schedule Type: \(schedule_type_string!)") // Debug print
    }
    
    @IBAction func Daily(_ sender: Any) {
        schedule_type_string = "D"  // Set schedule type to Daily
        toggleDaysView(show: false)
        toggleDateView(show: false)
        toggletimeView(show: true)
        
        print("Schedule Type: \(schedule_type_string!)") // Debug print
    }
    
    @IBAction func PerticularDay(_ sender: Any) {
        schedule_type_string = "P"  // Set schedule type to "Particular Day"
        toggleDaysView(show: false)
        toggleDateView(show: true)
        toggletimeView(show: true)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yy"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        newDate = formatter.string(from: Date())
        
        print("Default Date Set: \(newDate!)")
    }
    
    
    @IBAction func previousButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    @IBAction func comfigureButton(_ sender: Any) {
        var L_state = ""
        var fan_state = ""
        var master_state = ""
        
        let additionalTypes = ["S", "W", "X", "G", "H", "I", "J"]
        
        
        for item in buttonItems {
            switch item.type {
            case "L", "O", "C", "D", "Q" ,"Y":
                L_state.append(item.status)
            case "F":
                fan_state = item.status
            case "M":
                master_state = item.status  // Assign Master state separately
            default:
                break
            }
        }
        
        // Check devicestate for cNm and include S, W, X, G, H, I, J states
        if let device = devicestate.first {
            for (index, char) in device.cNm.enumerated() {
                if additionalTypes.contains(String(char)), index < device.lightState.count {
                    let stateIndex = device.lightState.index(device.lightState.startIndex, offsetBy: index)
                    L_state.append(device.lightState[stateIndex])
                    
                }
            }
        }
        
        
        
        
        var week_schedule = "0000000"
        
        if schedule_type_string == "D" {  // Daily
            week_schedule = "1111111"
        } else if schedule_type_string == "W" {  // Weekly
            week_schedule = generateWeekSchedule()
        }
        
        // Call the function with updated week_schedule
        publish_schedule_config(
            no: schdeuleNumber! ,
            sch_type: schedule_type_string ?? "",
            week_schedule: week_schedule,
            time: formattedTimeString(),
            L_state: L_state,
            fan_state: fan_state
        )
        
        
        add_time_schedule(time: formattedTimeString(), master: master_state, L_State: L_state, F_State: fan_state, sheduleNumber: schdeuleNumber!,  week_schedule: week_schedule)
        
        print("Schedule L_state: \(L_state), Fan_state: \(fan_state), Master_state: \(master_state), Week_schedule: \(week_schedule) ")
    }
    
    
    func generateWeekSchedule() -> String {
        let daysOrder = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        var weekBinary = ""
        
        for day in daysOrder {
            if selectedDays.contains(day) {
                weekBinary.append("1")
            } else {
                weekBinary.append("0")
            }
        }
        
        return weekBinary
    }
    
    func formattedTimeString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: timePicker.date)
    }
    
    
    func toggleDaysView(show: Bool) {
        UIView.animate(withDuration: 0.3) {
            self.daysView.isHidden = !show
            self.daysViewHeightConstraint.constant = show ? 60 : 0
            self.view.layoutIfNeeded()
        }
    }
    
    func toggleDateView(show: Bool) {
        UIView.animate(withDuration: 0.3) {
            self.dateView.isHidden = !show
            self.dateViewHeight.constant = show ? 60 : 0
            self.view.layoutIfNeeded()
        }
    }
    
    
    
    func toggletimeView(show: Bool) {
        UIView.animate(withDuration: 0.3) {
            self.timeView.isHidden = !show
            self.timeViewHeight.constant = show ? 60 : 0
            self.view.layoutIfNeeded()
        }
    }
    
    @IBAction func datePickerValueChanged(_ sender: UIDatePicker) {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yy"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        newDate = formatter.string(from: sender.date)
        print("Selected Date: \(newDate!)") // Debug print
    }
    
    
    
    
    
    
    
    func publish_schedule_config(no: String, sch_type: String, week_schedule: String, time: String, L_state: String, fan_state: String) {
        guard let device = devicestate.first else { return }
        let topic = device.uniqueID
        
        var P_Date = "00/00/00"
        
        if schedule_type_string == "P" {
            guard let validDate = newDate, !validDate.isEmpty else {
                print("Error: newDate is nil or empty")
                return
            }
            
            // **Reformat before publishing**
            let formatter = DateFormatter()
            formatter.dateFormat = "MM/dd/yy"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            
            if let dateObj = formatter.date(from: validDate) {
                P_Date = formatter.string(from: dateObj) // Ensure correct format
            } else {
                print("Error: Invalid date format")
            }
        }
        
        
        
        let fanStateToPass = (fan_state.isEmpty || fan_state == "NA") ? "00" : fan_state
        
        let schedule_set_params: Parameters = [
            "control": "scheduler_config",
            "no": no,
            "date": P_Date, // Now correctly formatted
            "sch_type": sch_type,
            "week_schedule": week_schedule,
            "time": time,
            "L_state": L_state,
            "L_speed": "6666",
            "F_state": fanStateToPass,
            "F_speed": "4",
            "m_state": 0,
            "from": "A",
            "topic": topic ?? ""
        ]
        
        print("Schedule Params: \(schedule_set_params)") // Debugging
        
        do {
            let theJSONData = try JSONSerialization.data(withJSONObject: schedule_set_params, options: .prettyPrinted)
            if var theJSONText = String(data: theJSONData, encoding: .utf8) {
                theJSONText = theJSONText.replacingOccurrences(of: "\\/", with: "/")
                print("Clean JSON string = \(theJSONText)")
                showPopup()
                let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
                iotDataManager.publishString(theJSONText, onTopic: topic + "/HA/A/req", qoS: .messageDeliveryAttemptedAtMostOnce)
            }
        } catch {
            print("Error serializing JSON: \(error.localizedDescription)")
        }
    }
    
    @objc func showPopup() {
        
        showPopupPresenter.showPopup1(on: self.view,
                                      animationName: "schedule",
                                      title: "Success!",
                                      subtitle: "Schedule set sucessfully..")
        
        
    }
    
    func add_time_schedule(time: String, master: String, L_State: String, F_State: String, sheduleNumber: String, week_schedule: String) {
        
        var P_Date = "00/00/00"
        
        if schedule_type_string == "P" {
            guard let validDate = newDate, !validDate.isEmpty else {
                print("Error: newDate is nil or empty")
                return
            }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "MM/dd/yy"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            
            if let dateObj = formatter.date(from: validDate) {
                P_Date = formatter.string(from: dateObj)
            } else {
                print("Error: Invalid date format")
            }
        }
        
        guard let deviceState = devicestate.first else {
            print("Error: No device states available")
            return
        }
        
        guard let firstScene = selectedDevice else {
            print("Error: No device scene available.")
            return
        }
        
        // ✅ Extract L_speed dynamically from deviceState
        var L_speed = ""
        for (index, char) in deviceState.cNm.enumerated() {
            if ["L", "O", "C", "Q", "Y", "D"].contains(String(char)), index < deviceState.lightSpeed.count {
                let speedIndex = deviceState.lightSpeed.index(deviceState.lightSpeed.startIndex, offsetBy: index)
                L_speed.append(deviceState.lightSpeed[speedIndex])
            }
        }
        
        // ✅ Build parameters using dynamic L_speed
        let add_schedule_params: Parameters = [
            "deviceUid": firstScene.deviceUid ?? "",
            "week_schedule": week_schedule,
            "sheduleNumber": sheduleNumber,
            "date": P_Date,
            "time": time,
            "unique_id": firstScene.uniqueId ?? "",
            "modelNo": firstScene.deviceModelNo ?? "",
            "master": master,
            "config_buttons": deviceState.cNm,
            "dest_button": deviceState.deviceNumber,
            "L_state": L_State,
            "L_speed": L_speed,  // ✅ dynamic value
            "F_state": F_State,
            "F_speed": "4",
            "fan_dest": "1",
            "sceneId": ""
        ]
        
        AF.request("http://3.7.18.55:3000/skroman/timeshedule", method: .post, parameters: add_schedule_params, encoding: JSONEncoding.default, headers: nil).response { response in
            debugPrint(response)
            switch response.result {
            case .success(let data):
                do {
                    let jsonOne = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary
                    print("jsonOne -- >>", jsonOne ?? [:])
                } catch {
                    print("error at schedule api \(error.localizedDescription)")
                }
            case .failure(let err):
                print("error at schedule api \(err.localizedDescription)")
            }
        }.resume()
    }
}
extension schdeuleTypeViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return daysArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DaysCollectionViewCell", for: indexPath) as! DaysCollectionViewCell
        let day = daysArray[indexPath.item]
        
        cell.dayNamelabel.text = day
        cell.layer.cornerRadius = 10
        cell.layer.borderWidth = 1
        cell.layer.borderColor = UIColor.gray.cgColor
        cell.backgroundColor = selectedDays.contains(day) ? UIColor.systemBlue : UIColor.clear
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedDay = daysArray[indexPath.item]
        
        if let index = selectedDays.firstIndex(of: selectedDay) {
            selectedDays.remove(at: index)
        } else {
            selectedDays.append(selectedDay)
        }
        
        collectionView.reloadItems(at: [indexPath])
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let itemWidth = (collectionView.frame.width - 40) / 3  // 3 columns
        return CGSize(width: itemWidth, height: 50)
    }
}
