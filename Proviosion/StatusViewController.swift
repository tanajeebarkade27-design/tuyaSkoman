//
//  StatusViewController.swift
//  SkromanIsra
//
//  Created by Admin on 27/01/25.
//

import ESPProvision
import Foundation
import UIKit
import Alamofire
import SwiftKeychainWrapper


// Class that applies Wi-Fi credentials to device and show provisioning status.
class StatusViewController: UIViewController {
   
    
    var ssid: String!
    var passphrase: String!
    var step1Failed = false
    var espDevice: ESPDevice!
    var message = ""

    var userDefault = UserDefaults()
    
  //  var homeVC = HomeViewController()
    
    
    @IBOutlet var step1Image: UIImageView!
    @IBOutlet var step2Image: UIImageView!
    @IBOutlet var step1Indicator: UIActivityIndicatorView!
    @IBOutlet var step2Indicator: UIActivityIndicatorView!
    @IBOutlet var step1ErrorLabel: UILabel!
    @IBOutlet var step2ErrorLabel: UILabel!
    @IBOutlet var finalStatusLabel: UILabel!
    @IBOutlet var okayButton: UIButton!

    // MARK: - Overriden Methods
    
//MARK: == FOR MAIN PROVISIONING VARIABLES ==
    
    var status_VC_room_id : String!
    var status_VC_home_id : String!
    var status_VC_user_id : String!
    var status_VC_unique_id : String!
    var status_VC_device_pop : String!
    var status_VC_model_no : String!
    var status_VC_device_type : String!
    
    var status_VC_SSID : String!
    
    
    var status_VC_device_flag : Bool!
    
    //-------------------------
    
//MARK: == FOR UPDATE PROVISIONING VARIABLES ==
    
    var status_VC_UD_device_u_id : String!
    var status_VC_UD_device_unique_id : String!
    var status_VC_UD_connected_password : String!
    var deviceVersion_Vc_Ud : String!
    
    //-------------------------
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("ssid :: >>", ssid ?? "")
        
        if step1Failed {
            step1FailedWithMessage(message: message)
        } else {
            startProvisioning()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
//    MARK: == GETTING DATA FROM USER DEFAULT FOR MAIN PROVISIONING ==
        
        let user_id = KeychainWrapper.standard.string(forKey: "userId")
        
        let room_id = userDefault.string(forKey: "room_id")
        let home_id = userDefault.string(forKey: "home_id")
        let unique_id = userDefault.string(forKey: "device_uni_id")
        let device_pop = userDefault.string(forKey: "device_pop")
        let model_no = userDefault.string(forKey: "model_no")
        let device_type = userDefault.string(forKey: "device_type")
        
        let get_ssid = userDefault.string(forKey: "ssid")
        
        status_VC_room_id = room_id
        status_VC_home_id = home_id
        status_VC_user_id = user_id
        status_VC_unique_id = unique_id
        status_VC_device_pop = device_pop
        status_VC_model_no = model_no
        status_VC_device_type = device_type
        status_VC_SSID = get_ssid
        
        
        
//        print("GOT ROOM ID : == ",status_VC_room_id!)
//        print("GOT ROOM ID : == ",status_VC_home_id!)
//        print("GOT ROOM ID : == ",status_VC_user_id!)
//        print("GOT ROOM ID : == ",status_VC_unique_id!)
//        print("GOT ROOM ID : == ",status_VC_device_pop!)
//        print("GOT ROOM ID : == ",status_VC_model_no!)
//        print("GOT ROOM ID : == ",status_VC_device_type!)
//        print("GOT SSID : ==",status_VC_SSID!)
        
            //------------------
        
//    MARK: == GETTING DATA FROM USER DEFAULT FOR UPDATE PROVISIONING ==
        
        let device_u_id = userDefault.string(forKey: "device_u_id")
        let device_unique_id = userDefault.string(forKey: "device_unique_id")
        let device_connected_wifi_password = userDefault.string(forKey: "wifi_password")
        let deviceVersion = userDefault.string(forKey: "deviecVersion")
        
        
        status_VC_UD_device_u_id = device_u_id
        status_VC_UD_device_unique_id = device_unique_id
        status_VC_UD_connected_password = device_connected_wifi_password
      
        deviceVersion_Vc_Ud = deviceVersion
        
            //------------------

        //        navigationController?.navigationBar.isHidden = true
        
        let provisioning_flag = userDefault.bool(forKey: "provisioning_flag")
        
        status_VC_device_flag = provisioning_flag
        
        
        print("Here is the flag for provision : =====",status_VC_device_flag!)
        
      
    }

    // MARK: - IBActions
    
    @IBAction func goToFirstView(_ sender: UIButton!) {

        if status_VC_device_flag == false {
        
            self.navigationController?.viewControllers.removeLast(5)
                
        }
        else {
            
            self.navigationController?.viewControllers.removeLast(7)
            
        }
        
        
    }
    
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    // MARK: - Provisioning
    
    func startProvisioning() {
        step1Image.isHidden = true
        step1Indicator.isHidden = false
        step1Indicator.startAnimating()

        espDevice.provision(ssid: ssid, passPhrase: passphrase) { status in
            DispatchQueue.main.async {
                switch status {
                case .success:
                    self.step2Indicator.stopAnimating()
                    self.step2Image.image = UIImage(named: "checkbox_checked")
                    self.step2Image.isHidden = false
                    self.provisionFinsihedWithStatus(message: "Device has been successfully provisioned!")
                    
                    if self.status_VC_device_flag == false {


                        self.Update_Device_Function()
                        
                        

                    }
                    else  {

                        self.Add_Device_Function()

                    }
                    
                    
                    
                case let .failure(error):
                    switch error {
                    case .configurationError:
                        self.step1FailedWithMessage(message: "Failed to apply ``network`` configuration to device")
                    case .sessionError:
                        self.step1FailedWithMessage(message: "Session is not established")
                    case .wifiStatusDisconnected:
                        self.step2FailedWithMessage(error: error)
                    default:
                        self.step2FailedWithMessage(error: error)
                    }
                case .configApplied:
                    self.step2applyConfigurations()
                }
            }
        }
    }

    func step2applyConfigurations() {
        DispatchQueue.main.async {
            self.step1Indicator.stopAnimating()
            self.step1Image.image = UIImage(named: "checkbox_checked")
            self.step1Image.isHidden = false
            self.step2Image.isHidden = true
            self.step2Indicator.isHidden = false
            self.step2Indicator.startAnimating()
        }
    }

    func step1FailedWithMessage(message: String) {
        DispatchQueue.main.async {
            self.step1Indicator.stopAnimating()
            self.step1Image.image = UIImage(named: "error_icon")
            self.step1Image.isHidden = false
            self.step1ErrorLabel.text = message
            self.step1ErrorLabel.isHidden = false
            self.provisionFinsihedWithStatus(message: "Reboot your board and try again.")
        }
    }

    func step2FailedWithMessage(error: ESPProvisionError) {
        DispatchQueue.main.async {
            self.step2Indicator.stopAnimating()
            self.step2Image.image = UIImage(named: "error_icon")
            self.step2Image.isHidden = false
            var errorMessage = ""
            switch error {
            case .wifiStatusUnknownError, .wifiStatusDisconnected, .wifiStatusNetworkNotFound, .wifiStatusAuthenticationError:
                errorMessage = error.description
            case .wifiStatusError:
                errorMessage = "Unable to fetch Wi-Fi state."
            default:
                errorMessage = "Unknown error."
            }
            self.step2ErrorLabel.text = errorMessage
            self.step2ErrorLabel.isHidden = false
            self.provisionFinsihedWithStatus(message: "Reset your board to factory defaults and retry.")
        }
    }

    func provisionFinsihedWithStatus(message: String) {
        okayButton.isEnabled = true
        okayButton.alpha = 1.0
        finalStatusLabel.text = message
        finalStatusLabel.isHidden = false
    }
    
//MARK: ===== ALERT FUNCTION =====
    
    func All_Alert_Type(alertTitle : String, alertMessage : String) {
        
        let allAlertBox = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
        
        
        self.present(allAlertBox, animated: true)
        
        
        DispatchQueue.main.async {
            self.dismiss(animated: true)
        }
        
    }
    
    
    
    func Alert_box() {
        
        
        let alert = UIAlertController(title: "Device Added successfully", message: "", preferredStyle: .alert)
        
        let ok = UIAlertAction(title: "OK", style: .default) { (action) in
            
            self.navigationController?.viewControllers.remove(at: 3)
            
            
        }
        
        alert.addAction(ok)
        alert.addAction(UIAlertAction(title: "Cancel", style: .destructive))
        
        self.present(alert, animated: true)
        
        
    }
    
    
}






extension StatusViewController {
    
    
        func Add_Device_Function() {
//
        guard let roomId = self.status_VC_room_id else { return }
        guard let homeID = self.status_VC_home_id else { return }
        guard let userId = self.status_VC_user_id else { return }
        guard let unique_id = self.status_VC_unique_id else { return }
        guard let POP = self.status_VC_device_pop else { return }
        guard let deviceModelNo = self.status_VC_model_no else { return }
        guard let wifi_name = self.status_VC_SSID else { return }
        guard let device_type = self.status_VC_device_type else { return }
            guard let device_Version = self.deviceVersion_Vc_Ud else {return}
        
//        guard let deviceType = self.status_VC_device_type else { return }

        
        let add_device_parameters : Image_Parameters = [
            
            "roomId" : roomId,
            "homeId" : homeID,
            "userId" : userId,
            "deviceName" : device_type,
            "unique_id" : unique_id,
            "POP" : POP,
            "deviceModelNo" : deviceModelNo,
            "deviceType" : "Switch Box",
            "deviceMacAddress" : "N/A",
            "connectedSsid" : wifi_name,
            "connectedPassword" : "",
            "favouriteDevice" : "",
           "deviceCategory": device_Version ,
            "deviceDimmingType" :"zcd"
            
        ]
        
            
        AF.request("http://3.7.18.55:3000/skroman/deviceapi/device", method: .post, parameters: add_device_parameters, encoding: JSONEncoding.default, headers: nil).response { response in
            debugPrint(response)
            
            switch response.result
            {
            case .success(let data) :
                do {
                    
                    let jsonOne = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary
                    
                    if response.response?.statusCode == 200 {
                        print("json at deviceApi\(jsonOne!)")
                        
                        
                        if let parseJson = jsonOne, let msg = parseJson["msg"] as? String {
                            
                            if msg == "device is already exists." {
                                self.All_Alert_Type(alertTitle: "Alert", alertMessage: "Device is already exists.")
                                
                                
                            }
                            
                            else {
                                
                                
                                
//                                self.All_Alert_Type(alertTitle: "Congrats", alertMessage: "Device Added Successfully")
                                self.Alert_box()
                              //  self.homeVC.GetData()
                                
                                
                            }
                            
                        }
                    }
                    
                    else {
                        
                        print("Error  at wifi state ")
                        
                        
                    }
                }
                
                catch {
                    
                    print("error at provising \(error.localizedDescription)")
                    
                }
                
                
            case .failure(let err):
                print(err.localizedDescription)
                
            }
        }.resume()
        
    }
}


extension StatusViewController {
    
    
        func Update_Device_Function() {
            
            guard  let deviceUiD = status_VC_UD_device_u_id else { return }
            guard  let deviceUniqueID = status_VC_UD_device_unique_id else { return }
            guard  let connectedSSID = ssid else { return }
            guard  let connetedPassword = status_VC_UD_connected_password else { return }
            
            let update_parameters : Image_Parameters = [
            
                "deviceUid" : deviceUiD,
                "unique_id" : deviceUniqueID,
                "connectedSsid" : connectedSSID,
                "connectedPassword": connetedPassword
            
            ]
            
            
        AF.request("http://3.7.18.55:3000/skroman/deviceapi/deviceBleProvision", method: .put, parameters: update_parameters, encoding: JSONEncoding.default, headers: nil).response { response in
            debugPrint(response)
            
            switch response.result
            {
            case .success(let data) :
                do {
                    
                    let jsonOne = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary
                    
                    if response.response?.statusCode == 200 {
                        print(jsonOne!)
                        
                        
                        if let parseJson = jsonOne, let msg = parseJson["msg"] as? String {
                            
                            if msg == "Update Device BLE provision Successfully" {
                            
                            self.All_Alert_Type(alertTitle: "Connected device has been changed", alertMessage: "")
                            
                            }
                        }
                    }
                    
                    else {
                        
                        print("Error")
                        
                        
                    }
                }
                
                catch {
                    print(error.localizedDescription)
                    
                }
                
                
            case .failure(let err):
                print(err.localizedDescription)
                
            }
        }.resume()
        
    }
}

