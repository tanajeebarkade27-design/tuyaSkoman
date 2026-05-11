import UIKit
import AWSCore
import AWSIoT
import Alamofire
import Lottie


class DiimingSettingViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {

    @IBOutlet var backgroundview: UIView!
    @IBOutlet weak var diimmingView: UIView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var dimmingViewHeight: NSLayoutConstraint!
    @IBOutlet weak var pwmView: UIView!
    @IBOutlet weak var zcdView: UIView!
    @IBOutlet weak var typeView: UIView!
    @IBOutlet weak var selectDriverlabel: UILabel!
    var devices: [Device] = []
    var selectedDevice: Device?
    @IBOutlet weak var step1Start: UITextField!
    @IBOutlet weak var step2Start: UITextField!
    @IBOutlet weak var step3Start: UITextField!
    @IBOutlet weak var step4Start: UITextField!
   
    
    @IBOutlet weak var step1End: UITextField!
    @IBOutlet weak var step2End: UITextField!
    @IBOutlet weak var step3End: UITextField!
    @IBOutlet weak var step4End: UITextField!
    
    var deviceUinqueId: String?
    let defaultValues: [String: String] = [
        "s1Value": "7800",
        "s2value": "5850",
        "s3value": "4500",
        "s4Value": "120",
        "e1value": "1800",
        "e2value": "3750",
        "e3value": "5100",
        "e4value": "9000"
    ]
    
    var dropdown: UISegmentedControl!
    var tableView: UITableView!
    var isDropdownVisible = false
    let drivers = ["Driver 1", "Driver 2", "Driver 3", "Driver 4", "Driver 5"]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        backButton.setTitle("", for: .normal)
        setupSegmentedControl()
        setupDropdownTableView()
        setupTapGestures()
        diimmingView.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        diimmingView.cornerRadius = 15
       print("devices at dim\(selectedDevice)")
        pwmView.isHidden = true
        zcdView.isHidden = false
        tableView.isHidden = true
        dimmingViewHeight.constant = 480
       
        deviceCornerView()
        assignTextFieldDelegates()
    registerForKeyboardNotifications()
        
        
        if let firstScene = devices.first {
            deviceUinqueId = firstScene.uniqueId
        } else {
            deviceUinqueId = nil
        }
    }
  
    
  
    
    func setDefaultValues() {
        step1Start.text = defaultValues["s1Value"]
        step2Start.text = defaultValues["s2value"]
        step3Start.text = defaultValues["s3value"]
        step4Start.text = defaultValues["s4Value"]
        step1End.text = defaultValues["e1value"]
        step2End.text = defaultValues["e2value"]
        step3End.text = defaultValues["e3value"]
        step4End.text = defaultValues["e4value"]
    }
    
    

    func deviceCornerView() {
        let views = [diimmingView, pwmView, zcdView]
        
        for view in views {
            view?.layer.cornerRadius = 10
            view?.clipsToBounds = true
            view?.layer.borderWidth = 1
            view?.layer.borderColor = UIColor.gray.cgColor
        }
    }
    
    func setupSegmentedControl() {
        dropdown = UISegmentedControl(items: ["ZCD", "PWM"])
        dropdown.selectedSegmentIndex = 0
        dropdown.translatesAutoresizingMaskIntoConstraints = false
        dropdown.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        
        typeView.addSubview(dropdown)
        
        NSLayoutConstraint.activate([
            dropdown.centerXAnchor.constraint(equalTo: typeView.centerXAnchor),
            dropdown.centerYAnchor.constraint(equalTo: typeView.centerYAnchor),
            dropdown.widthAnchor.constraint(equalTo: typeView.widthAnchor, multiplier: 0.9),
            dropdown.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    func setupDropdownTableView() {
        tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.isHidden = true
        tableView.layer.borderWidth = 1
        tableView.layer.borderColor = UIColor.gray.cgColor
        tableView.layer.cornerRadius = 5
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")

        // Add tableView to the main view (self.view) instead of diimmingView
        self.view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: pwmView.bottomAnchor, constant: 5),
            tableView.leadingAnchor.constraint(equalTo: pwmView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: pwmView.trailingAnchor),
            tableView.heightAnchor.constraint(equalToConstant: 200)
        ])
    }

    @IBAction func resetButton(_ sender: Any) {
        
        guard let topic = selectedDevice?.uniqueId  else {
            print("Error: PUB_TOPIC_ is nil. Cannot subscribe to MQTT topic.")
            return
        }
        
        
        let payload: Parameters = [
            "control": "set_zcd_steps",
            "step_1_s": Int(step1Start.text ?? "0") ?? 0,
            "step_1_e": Int(step1End.text ?? "0") ?? 0,
            "step_2_s": Int(step2Start.text ?? "0") ?? 0,
            "step_2_e": Int(step2End.text ?? "0") ?? 0,
            "step_3_s": Int(step3Start.text ?? "0") ?? 0,
            "step_3_e": Int(step3End.text ?? "0") ?? 0,
            "step_4_s": Int(step4Start.text ?? "0") ?? 0,
            "step_4_e": Int(step4End.text ?? "0") ?? 0,
            "from": "A",
            "topic": topic
        ]
        
        
        if let theJSONData = try? JSONSerialization.data(withJSONObject: payload,options: []) {
            
            let theJSONText = String(data: theJSONData,
                                     encoding: .ascii)
            print("JSON string = \(theJSONText!)")
            showPopupDim()
            
            let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
            
            let iot_sample_vc = Iot_sample_ViewController()
            
            iotDataManager.publishString(theJSONText!, onTopic: topic + "/HA/A/req", qoS:.messageDeliveryAttemptedAtMostOnce)
            
            
        }
        
    }
    
    
    
    @IBAction func configureButton(_ sender: Any) {
        guard let topic = selectedDevice?.uniqueId else {
            print("Error: deviceID is nil. Cannot publish MQTT message.")
            return
        }

        let payload: Parameters = [
            "control": "set_zcd_steps",
            "step_1_s": Int(step1Start.text ?? "0") ?? 0,
            "step_1_e": Int(step1End.text ?? "0") ?? 0,
            "step_2_s": Int(step2Start.text ?? "0") ?? 0,
            "step_2_e": Int(step2End.text ?? "0") ?? 0,
            "step_3_s": Int(step3Start.text ?? "0") ?? 0,
            "step_3_e": Int(step3End.text ?? "0") ?? 0,
            "step_4_s": Int(step4Start.text ?? "0") ?? 0,
            "step_4_e": Int(step4End.text ?? "0") ?? 0,
            "from": "A",
            "topic": topic
        ]

        if let theJSONData = try? JSONSerialization.data(withJSONObject: payload, options: []) {
            let theJSONText = String(data: theJSONData, encoding: .ascii)
            print("Sending JSON: \(theJSONText!)")
            showPopupDim()

            let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
            iotDataManager.publishString(theJSONText!, onTopic: topic + "/HA/A/req", qoS: .messageDeliveryAttemptedAtMostOnce)
        }
    }

    
    
    func setupTapGestures() {
        // Tap on PWM view to toggle dropdown
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleDropdown))
        pwmView.addGestureRecognizer(tapGesture)
        pwmView.isUserInteractionEnabled = true
        
        // Tap anywhere to close dropdown
        let dismissTapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissDropdown))
        dismissTapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(dismissTapGesture)
    }

    @objc func toggleDropdown() {
        isDropdownVisible.toggle()
        tableView.isHidden = !isDropdownVisible
        
        if isDropdownVisible {
            tableView.reloadData()  // Reload to ensure data is populated
        }
    }

   


    @objc func dismissDropdown() {
        if isDropdownVisible {
            isDropdownVisible = false
            tableView.isHidden = true
        }
    }

    @objc func segmentChanged() {
        let dimmingTypePayload = dropdown.selectedSegmentIndex == 0 ? "zcd" : "PWM"

        if dropdown.selectedSegmentIndex == 1 {
            pwmView.isHidden = false
            zcdView.isHidden = true
            dimmingViewHeight.constant = 200
        } else {
            pwmView.isHidden = true
            zcdView.isHidden = false
            dimmingViewHeight.constant = 480
            isDropdownVisible = false
            tableView.isHidden = true
        }

        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
        callPostAPI(deviceID: selectedDevice?.uniqueId ?? "", dimmingType: dimmingTypePayload)
        sendDimmingType(dimmingTypePayload)
    }

    func sendDimmingType(_ dimmingTypePayload: String) {
        guard let deviceID = selectedDevice?.uniqueId else {
            print("Error: deviceID is nil")
            return
        }

        let payload: Parameters = [
            "control": "config_dimming_type",
            "T": dimmingTypePayload,
            "from": "A",
            "topic": deviceID
        ]

        print("payload at \(payload)")
        if let theJSONData = try? JSONSerialization.data(withJSONObject: payload, options: []) {
            let theJSONText = String(data: theJSONData, encoding: .ascii)
            print("Sending JSON: \(theJSONText!)")
            showPopupType()
            let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
            iotDataManager.publishString(theJSONText!, onTopic: deviceID + "/HA/A/req", qoS: .messageDeliveryAttemptedAtMostOnce)
        }
    }

    func callPostAPI(deviceID: String, dimmingType: String) {
        let url = "http://3.7.18.55:3000/skroman/deviceapi/v2/deviceupdate"
        let parameters: Parameters = [
            "unique_id": deviceID,
            "deviceDimmingType": dimmingType
        ]
        
        AF.request(url, method: .put, parameters: parameters, encoding: JSONEncoding.default)
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    print("POST API Response: \(value)")
                    
                  
                  
                case .failure(let error):
                    print("POST API Error: \(error.localizedDescription)")
                   
                }
            }
    }
    
    func sendDriverSelection(_ driverIndex: Int) {
        guard let deviceID = selectedDevice?.uniqueId else {
            print("Error: deviceID is nil")
            return
        }

        let payload: Parameters = [
            "control": "set_pwm_driver",
            "no": driverIndex,
            "from": "A",
            "topic": deviceID
        ]

        if let theJSONData = try? JSONSerialization.data(withJSONObject: payload, options: []) {
            let theJSONText = String(data: theJSONData, encoding: .ascii)
            print("Sending JSON: \(theJSONText!)")
            showPopupDim()
            let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
            iotDataManager.publishString(theJSONText!, onTopic: deviceID + "/HA/A/req", qoS: .messageDeliveryAttemptedAtMostOnce)
        }
    }


    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return drivers.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = drivers[indexPath.row]
        cell.selectionStyle = .none
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedDriver = drivers[indexPath.row]
        let driverIndex = indexPath.row + 1
        
        selectDriverlabel.text = selectedDriver
        isDropdownVisible = false
        tableView.isHidden = true
        
        sendDriverSelection(driverIndex)
    }


    @IBAction func backButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    func assignTextFieldDelegates() {
        let textFields = [step1Start, step2Start, step3Start, step4Start, step1End, step2End, step3End, step4End]
        
        textFields.forEach { textField in
            textField?.delegate = self
            textField?.keyboardType = .numberPad
        }
    }

       func registerForKeyboardNotifications() {
           NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
           NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
       }

       @objc func keyboardWillShow(_ notification: Notification) {
           if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
               let keyboardHeight = keyboardFrame.height
               self.view.frame.origin.y = -keyboardHeight / 2  // Move the view up
           }
       }

       @objc func keyboardWillHide(_ notification: Notification) {
           self.view.frame.origin.y = 0  // Reset view position
       }

       func textFieldShouldReturn(_ textField: UITextField) -> Bool {
           textField.resignFirstResponder()  // Close keyboard when return key is pressed
           return true
       }

       deinit {
           NotificationCenter.default.removeObserver(self)
       }
    
    
    @objc func showPopupDim() {
        
        showPopupPresenter.showPopup1(on: self.view,
                                     animationName: "light",
                                     title: "Success!",
                                     subtitle: "Dimming setting done")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.dismiss(animated: true, completion: nil)
            }
    }
    
    @objc func showPopupType() {
        let selectedDimmingType = dropdown.selectedSegmentIndex == 0 ? "ZCD" : "PWM"

        showPopupPresenter.showPopup1(on: self.view,
                                      animationName: "light",
                                      title: "Type",
                                      subtitle: "\(selectedDimmingType) Dimming Type is Selected")
    }

    
}
