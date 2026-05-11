//
//  SettingsViewController.swift
//  SkromanIsra
//
//  Created by Admin on 27/01/25.
//



import UIKit

// Class to change and manage provisioning settings
class SettingsViewController: UIViewController {

    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var pickerToolbar: UIToolbar!
    @IBOutlet weak var selectionLabel: UILabel!
    @IBOutlet weak var securityLabel: UILabel!
    @IBOutlet weak var securityToggle: UISwitch!
    
    // MARK: - Overriden Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        selectionLabel.text = Utility.shared.espAppSettings.deviceType.value
        
        switch Utility.shared.espAppSettings.securityMode {
        case .secure:
            securityLabel.text = "Secured"
            securityToggle.setOn(true, animated: true)
        case .unsecure:
            securityLabel.text = "Unsecured"
            securityToggle.setOn(false, animated: true)
        
        case .secure2: break
            
        }
        
    }
    
    // MARK: - IBActions
    
    @IBAction func cancel(_ sender: Any) {
        hidePickerView()
    }
    
    @IBAction func done(_ sender: Any) {
        selectionLabel.text = DeviceType.allCases[pickerView.selectedRow(inComponent: 0)].value
        Utility.shared.espAppSettings.deviceType = DeviceType.allCases[pickerView.selectedRow(inComponent: 0)]
        Utility.shared.saveAppSettings()
        hidePickerView()
    }
    
    @IBAction func showPickerView(_ sender: Any) {
        pickerView.selectRow(Utility.shared.espAppSettings.deviceType.rawValue, inComponent: 0, animated: true)
        pickerView.isHidden = false
        pickerToolbar.isHidden = false
    }
    
    @IBAction func togglePressed(_ sender: UISwitch) {
        if sender.isOn {
            Utility.shared.espAppSettings.securityMode = .secure
            securityLabel.text = "Secured"
        } else {
            Utility.shared.espAppSettings.securityMode = .unsecure
            securityLabel.text = "Unsecured"
        }
        Utility.shared.saveAppSettings()
    }
    
    @IBAction func backButtonPresses(_ sender: Any) {
        navigationController?.popViewController(animated: false)
    }
    
    // MARK: - Others
    
    func hidePickerView() {
        pickerToolbar.isHidden = true
        pickerView.isHidden = true
    }
    
}

extension SettingsViewController: UIPickerViewDelegate  {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return DeviceType.allCases[row].value
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 50.0
    }
}

extension SettingsViewController:UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return DeviceType.allCases.count
    }
    
    
}
