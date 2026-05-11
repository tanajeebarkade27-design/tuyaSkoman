//
//  ConnectViewController.swift
//  SkromanIsra
//
//  Created by Admin on 27/01/25.
//

import ESPProvision
import UIKit
//import SKNeumorphKit

// Class to let user enter the POP and establish connection with the device.
class ConnectViewController: UIViewController {
    
    @IBOutlet var popTextField: UITextField!
    @IBOutlet var headerLabel: UILabel!
    @IBOutlet var nextButton: UIButton!
    
    var popHandler: ((String) -> Void)?
    var capabilities: [String]?
    var espDevice: ESPDevice!
    var pop = ""

    let userDefault = UserDefaults()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let device_pop = pop
        
        popTextField.layer.borderColor = UICOLOR_TXTFIELD_BORDER_COLOR.cgColor
        popTextField.layer.borderWidth = 1
       // popTextField.setLeftPaddingPoints(20)
        
        
//        popTextField.makeNeuromorphic(superView: self.view)
//        popTextField.shadowType = .inner
//        popTextField.bevel = 5
//        popTextField.themeColor = (UIColor(red: 44, green: 45, blue: 54))
//        popTextField.upperShadowColor = UIColor.white.withAlphaComponent(0.025)
//        popTextField.lowerShadowColor = UIColor.black.withAlphaComponent(0.10)
        
//        nextButton.makeNeuromorphic(superView: self.view)
//        nextButton.shadowType = .outer
//        nextButton.bevel = 5
//        nextButton.themeColor = (UIColor(red: 44, green: 45, blue: 54))
//        nextButton.upperShadowColor = UIColor.white.withAlphaComponent(0.025)
//        nextButton.lowerShadowColor = UIColor.black.withAlphaComponent(0.10)
        
        
        
//        popTextField.setLeftPaddingPoints(20)
        
        
        popTextField.text = device_pop
        headerLabel.text = "Enter your proof of possession PIN for \n" + espDevice.name
    }

    // MARK: - IBActions
    
    // On click of cancel button, terminate the provisioning and go to first screen.
    @IBAction func cancelClicked(_: Any) {
        espDevice.disconnect()
        navigationController?.popToRootViewController(animated: true)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    
    // On click of next button, establish session with device using connect API.
    @IBAction func nextBtnClicked(_: Any) {
        pop = popTextField.text ?? ""
        print("POP typed by user: \(pop)")
        Utility.showLoader(view: view)

            espDevice.security = Utility.shared.espAppSettings.securityMode
            espDevice.connect(delegate: self) { status in
                DispatchQueue.main.async {
                    Utility.hideLoader(view: self.view)
                    switch status {
                    case .connected:
                        self.goToProvision()
                    case let .failedToConnect(error):
                        self.showStatusScreen(error: error)
                    default:
                        let action = UIAlertAction(title: "Retry", style: .default, handler: nil)
                        self.showAlert(error: "Device disconnected", action: action)
                    }
            }
        }
    }
    
    // MARK: - Navigation
    
    // Show status screen, called when device connection fails.
    func showStatusScreen(error: ESPSessionError) {
            let statusVC = self.storyboard?.instantiateViewController(withIdentifier: "statusVC") as! StatusViewController
            statusVC.espDevice = self.espDevice
            statusVC.step1Failed = true
            statusVC.message = error.description
            self.navigationController?.pushViewController(statusVC, animated: true)

    }

    // Go to provision screen, called when device is connected.
    func goToProvision() {
        DispatchQueue.main.async {
            Utility.hideLoader(view: self.view)
            let provisionVC = self.storyboard?.instantiateViewController(withIdentifier: "provision") as! ProvisionViewController
            provisionVC.espDevice = self.espDevice
            self.navigationController?.pushViewController(provisionVC, animated: true)
        }
    }

    // MARK: - Helper Methods
    
    func showAlert(error: String, action: UIAlertAction) {
        let alertController = UIAlertController(title: "Error!", message: error, preferredStyle: .alert)
        alertController.addAction(action)
        present(alertController, animated: true, completion: nil)
    }
    
    
    
    @IBAction func button(_ sender: UIButton) {
        
        navigationController?.viewControllers.remove(at: 3)
        
        
    }
    
}

extension ConnectViewController: ESPDeviceConnectionDelegate {
    func getUsername(forDevice: ESPDevice, completionHandler: @escaping (String?) -> Void) {
        return
    }
    
        func getProofOfPossesion(forDevice: ESPDevice, completionHandler: @escaping (String) -> Void) {
            completionHandler(pop)
        }
    }
