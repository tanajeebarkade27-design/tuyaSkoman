

import UIKit

class Esp_ViewController: UIViewController {
    
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    
    @IBOutlet weak var centerImage: UIImageView!
    @IBOutlet weak var appVersionLabel: UILabel!
    @IBOutlet weak var settingsButton: UIButton!
    
    var prov_flag : Bool!
    
    var esp_deviceName : String!
    var esp_deviceU_id : String!
    
    let userDefault = UserDefaults()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        //        print(prov_flag!)
        
        userDefault.set(prov_flag, forKey: "provisioning_flag")
        
        
        
        
              navigationController?.setNavigationBarHidden(true, animated: false)
        appVersionLabel.text = "App Version - v" + appVersion + " (\(espGitVersion))"
    }
    
        override func viewWillAppear(_ animated: Bool) {
            if Utility.shared.espAppSettings.appSettingsEnabled {
                settingsButton.isHidden = false
            } else {
                settingsButton.isHidden = true
            }
            switch Utility.shared.espAppSettings.deviceType {
            case .both:
                centerImage.image = UIImage(named: "main_logo")
            case .ble:
                centerImage.image = UIImage(named: "ble_main_logo")
            case .softAp:
                centerImage.image = UIImage(named: "softap_main_logo")
            }
    
        }
    
    @IBAction func addNewDevice(_ sender: Any) {
                if Utility.shared.espAppSettings.appAllowsQrCodeScan {
                    let scannerVC = self.storyboard?.instantiateViewController(withIdentifier: "scannerVC") as! ScanQRViewController
                    navigationController?.pushViewController(scannerVC, animated: false)
                } else {
                    switch Utility.shared.espAppSettings.deviceType {
                    case .both:
                        let deviceTypeVC = self.storyboard?.instantiateViewController(withIdentifier: "deviceTypeVC") as! DeviceTypeViewController
                        navigationController?.pushViewController(deviceTypeVC, animated: false)
                    case .ble:
                        let bleLandingVC = self.storyboard?.instantiateViewController(withIdentifier: "bleLandingVC") as! BLELandingViewController
                        navigationController?.pushViewController(bleLandingVC, animated: false)
                    case .softAp:
                        let softAPLandingVC = self.storyboard?.instantiateViewController(withIdentifier: "softAPLandingVC") as! SoftAPLandingViewController
                        navigationController?.pushViewController(softAPLandingVC, animated: false)
                    }
                }
        
        
                let landing_vc : BLELandingViewController = self.storyboard?.instantiateViewController(withIdentifier: "bleLandingVC") as! BLELandingViewController
        
        
                self.navigationController?.pushViewController(landing_vc, animated: true)
        
            }
        
        
    }
    

