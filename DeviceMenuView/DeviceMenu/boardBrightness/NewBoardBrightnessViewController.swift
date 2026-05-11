

import UIKit
import AWSCore
import AWSIoT
import Alamofire
class NewBoardBrightnessViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    
    @IBOutlet var boardView: UIView!
    @IBOutlet weak var boardbackview: UIView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var ResetToDefault: UIButton!
    @IBOutlet weak var colorButton: UIButton!
    @IBOutlet weak var modeButton: UIButton!
    @IBOutlet weak var typeDropDown: UIView!
    @IBOutlet weak var NumberDropDwonView: UIView!
    @IBOutlet weak var bulbImge: UIImageView!
    @IBOutlet var colorPicker: SwiftHSVColorPicker!
    @IBOutlet weak var numberLabel: UILabel!
    @IBOutlet weak var typeLabel: UILabel!
    
    @IBOutlet weak var backgroundimage: UIImageView!
    
    
    
    var selectedDevice: Device?
    var devicestate: [DeviceStateArray] = []
    var deviceVc : DeviceViewController?
    var devices: [Device] = []
    var deviceUinqueId: String?
    
    var colorUpdateTimer: Timer?
    var lastSentColor: UIColor?

    
    
    let typeOptions = ["ALL", "Lights", "Fan", "Master"]
    let numberOptions = Array(1...15).map { "\($0)" }
    
    var dropdownTableView: UITableView?
    var isTypeDropDownActive = false
    var isDropdownVisible = false // Track if dropdown is visible
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        backgroundimage.contentMode = .scaleAspectFill
        backgroundimage.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            backgroundimage.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundimage.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundimage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundimage.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        
        let buttons: [UIButton] = [ colorButton, ResetToDefault]
        for button in buttons {
            button.backgroundColor = .white
            button.setTitleColor(.black, for: .normal)
            button.layer.cornerRadius = 20
            button.layer.masksToBounds = true
        }
        boardView.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        boardView.cornerRadius = 10
        closeButton.setTitle("", for: .normal)
        closeButton.setTitleColor(.black, for: .normal) // Set text color
        
        if let image = UIImage(named: "close")?.resized(to: CGSize(width: 20, height: 20)) {
            closeButton.setImage(image, for: .normal)
        }
        colorPicker.setViewColor(.white)
        
        setupUI()
        addTapGestures()
        addDismissTapGesture()
        colorButton.backgroundColor =  .blue
        colorButton.tintColor =  .white
        colorButton.cornerRadius = 20
        colorButton.clipsToBounds =  true
        
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            let selectedColor = self.colorPicker.color
            self.updateBulbColor(selectedColor ?? .white)
        }
        
        
        if let firstScene = devices.first {
            deviceUinqueId = firstScene.uniqueId
        } else {
            deviceUinqueId = nil
        }
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }

   
    
    
    @IBAction func modeButton(_ sender: Any) {
        let vc = storyboard?.instantiateViewController(withIdentifier: "BoardBrightnessViewController")  as! BoardBrightnessViewController
        vc.devicestate =  self.devicestate
        vc.selectedDevice =  self.selectedDevice
     
      
        navigationController?.pushViewController(vc, animated: true)
        
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
        colorUpdateTimer?.invalidate()
        colorUpdateTimer = nil
    }
    @IBAction func closedButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    func setupUI() {
        [typeDropDown, NumberDropDwonView, boardbackview].forEach {
            $0?.layer.cornerRadius = 10
            $0?.clipsToBounds = true
        }
    }
    
    func addTapGestures() {
        let typeTapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleTypeDropdown))
        typeDropDown.addGestureRecognizer(typeTapGesture)
        
        let numberTapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleNumberDropdown))
        NumberDropDwonView.addGestureRecognizer(numberTapGesture)
    }
    
    // Tap anywhere outside to dismiss dropdown
    func addDismissTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissDropdown))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    
    
    @objc func toggleTypeDropdown() {
        if isDropdownVisible {
            hideDropdown()
        } else {
            isTypeDropDownActive = true
            showDropdown(for: typeDropDown, options: typeOptions)
        }
    }
    
    @objc func toggleNumberDropdown() {
        if isDropdownVisible {
            hideDropdown()
        } else {
            isTypeDropDownActive = false
            showDropdown(for: NumberDropDwonView, options: numberOptions)
        }
    }
    
    @objc func dismissDropdown(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: view)
        if let dropdown = dropdownTableView, !dropdown.frame.contains(location) {
            hideDropdown()
        }
    }
    
    
    
    func showDropdown(for sourceView: UIView, options: [String]) {
        hideDropdown() // Hide existing dropdown before opening a new one
        
        let sourceFrame = sourceView.superview?.convert(sourceView.frame, to: self.view) ?? sourceView.frame
        
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        let rowHeight: CGFloat = 44
        let maxHeight: CGFloat = rowHeight * CGFloat(options.count)
        let dropdownHeight = min(maxHeight, 200)
        
        tableView.frame = CGRect(x: sourceFrame.origin.x,
                                 y: sourceFrame.maxY + 5,
                                 width: sourceFrame.width,
                                 height: dropdownHeight)
        
        tableView.layer.cornerRadius = 10
        tableView.clipsToBounds = true
        tableView.isScrollEnabled = options.count > 5
        
        view.addSubview(tableView)
        dropdownTableView = tableView
        isDropdownVisible = true
        
        // 🔹 Reload data before selecting first row
        dropdownTableView?.reloadData()
        
        // 🔹 Select the first row automatically
        let indexPath = IndexPath(row: 0, section: 0)
        dropdownTableView?.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        
        // 🔹 Update the label with the first value
        let firstValue = options.first ?? ""
        if isTypeDropDownActive {
            typeLabel.text = firstValue
        } else {
            numberLabel.text = firstValue
        }
    }


    func hideDropdown() {
        dropdownTableView?.removeFromSuperview()
        dropdownTableView = nil
        isDropdownVisible = false
    }
    
    // TableView Delegates
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isTypeDropDownActive ? typeOptions.count : numberOptions.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = isTypeDropDownActive ? typeOptions[indexPath.row] : numberOptions[indexPath.row]
        print("Cell Created: \(cell.textLabel?.text ?? "Unknown")")
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedValue = isTypeDropDownActive ? typeOptions[indexPath.row] : numberOptions[indexPath.row]

        if isTypeDropDownActive {
            typeLabel.text = selectedValue
        } else {
            numberLabel.text = selectedValue
        }

        hideDropdown()
        
        // Start the timer only if both Type and Number are selected
        if let typeText = typeLabel.text, !typeText.isEmpty,
           let numberText = numberLabel.text, !numberText.isEmpty {
            startColorUpdateTimer()
        }
    }

    func triggerColorUpdate(with color: UIColor) {
        guard let topic = selectedDevice?.uniqueId else {
            print("Error: PUB_TOPIC_ is nil.")
            return
        }

        let typeMapping: [String: String] = [
            "ALL": "ALL",
            "Master": "M_ST",
            "Lights": "L_ST",
            "Fan": "F_ST"
        ]

        let selectedType = typeLabel.text ?? "ALL" // Default to "ALL"
        let tValue = typeMapping[selectedType] ?? "ALL"

        let selectedNumber = Int(numberLabel.text ?? "") ?? 0 // Default to empty

        let colorComponents = color.cgColor.components ?? [1, 1, 1] // ✅ FIXED: Use 'color' parameter

        // Ensure at least 3 components (RGB)
        let red = colorComponents.count > 0 ? colorComponents[0] : 1.0
        let green = colorComponents.count > 1 ? colorComponents[1] : 1.0
        let blue = colorComponents.count > 2 ? colorComponents[2] : 1.0

        // Scale to 100 as expected
        let all_params: Parameters = [
            "control": "ctrl_board_button_rgb_color",
            "T": tValue,  // Type
            "N": selectedNumber, // Number
            "R": red * 100,
            "G": green * 100,
            "B": blue * 100, // ✅ No more index out of range error
            "H": "255",
            "from": "A",
            "topic": topic
        ]

        print("MQTT Params: \(all_params)")

        if let theJSONData = try? JSONSerialization.data(withJSONObject: all_params, options: []) {
            let theJSONText = String(data: theJSONData, encoding: .ascii)
            showPopupScene()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
                iotDataManager.publishString(
                    theJSONText!,
                    onTopic: topic + "/HA/A/req",
                    qoS: .messageDeliveryAttemptedAtMostOnce
                )
            }
        }
    }

    
    func updateBulbColor(_ color: UIColor) {
        bulbImge.image = (bulbImge.image ?? UIImage(named: "bulb"))?.withRenderingMode(.alwaysTemplate)
        bulbImge.tintColor = color
    }
    
    
    func isColorDifferent(from newColor: UIColor) -> Bool {
        guard let lastColor = lastSentColor else { return true }
        
        let lastComponents = lastColor.cgColor.components ?? [1, 1, 1, 1] // Ensure at least 4 values
        let newComponents = newColor.cgColor.components ?? [1, 1, 1, 1]   // Ensure at least 4 values

        let redOld = lastComponents.count > 0 ? lastComponents[0] : 1.0
        let greenOld = lastComponents.count > 1 ? lastComponents[1] : 1.0
        let blueOld = lastComponents.count > 2 ? lastComponents[2] : 1.0

        let redNew = newComponents.count > 0 ? newComponents[0] : 1.0
        let greenNew = newComponents.count > 1 ? newComponents[1] : 1.0
        let blueNew = newComponents.count > 2 ? newComponents[2] : 1.0

        let threshold: CGFloat = 5.0 // Adjust threshold to fine-tune sensitivity

        return abs(redOld * 100 - redNew * 100) > threshold ||
               abs(greenOld * 100 - greenNew * 100) > threshold ||
               abs(blueOld * 100 - blueNew * 100) > threshold
    }

    
    @IBAction func defaultButton(_ sender: Any) {
        guard let topic = selectedDevice?.uniqueId else {
            print("Error: PUB_TOPIC_ is nil.")
            return
        }
        
        
        let all_params: Parameters = [
            "control": "set_board_button_rgb_settings",
            "from": "A",
            "topic": topic
        ]
        
        if let theJSONData = try? JSONSerialization.data(withJSONObject: all_params, options: []) {
            let theJSONText = String(data: theJSONData, encoding: .ascii)
            print("JSON string = \(theJSONText!)")
            showPopupScene()
           
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
                iotDataManager.publishString(
                    theJSONText!,
                    onTopic: topic + "/HA/A/req",
                    qoS: .messageDeliveryAttemptedAtMostOnce
                )
            }
        }
    }
    
    
    func startColorUpdateTimer() {
        colorUpdateTimer?.invalidate() // Prevent multiple timers
        colorUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            let selectedColor = self.colorPicker.color
            self.updateBulbColor(selectedColor ?? .white)

            // Prevent unnecessary MQTT updates
            if self.lastSentColor == nil || self.isColorDifferent(from: selectedColor ?? .white) {
                self.lastSentColor = selectedColor
                self.triggerColorUpdate(with: selectedColor ?? .white)
            }
        }
    }

    
    @objc func showPopupScene() {
        
        showPopupPresenter.showPopup1(on: self.view,
                                     animationName: "color",
                                     title: "Success!",
                                     subtitle: "Board color has been chnage")
        
       
    }
    
    
}
