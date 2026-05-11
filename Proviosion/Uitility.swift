
import Foundation
//import MBProgressHUD
import ESPProvision

enum DeviceType: Int, CaseIterable {
    case both = 0
    case ble
    case softAp
    
    var value: String {
        switch self {
        case .both:
            return "Both"
        case .ble:
            return "BLE"
        case .softAp:
            return "SoftAP"
        }
    }
    
}

class Utility {
    private static var overlayView: UIView?
    private static var indicator: UIActivityIndicatorView?
    /// Member to access singleton object of class.
    static let shared = Utility()
    
    var deviceNamePrefix = UserDefaults.standard.value(forKey: "com.espressif.prefix") as? String ?? (Bundle.main.infoDictionary?["BLEDeviceNamePrefix"] as? String ?? "SK_")
    var espAppSettings:ESPAppSettings
    
    
    init() {
        espAppSettings = ESPAppSettings(appAllowsQrCodeScan: true, appSettingsEnabled: true, deviceType: .both, securityMode: .secure, allowPrefixSearch: true)
        if let json = UserDefaults.standard.value(forKey: "com.espressif.example") as? [String: Any] {
            espAppSettings.allowPrefixSearch = json["allowPrefixSearch"] as! Bool
            espAppSettings.appAllowsQrCodeScan = json["allowQrCodeScan"] as! Bool
            espAppSettings.appSettingsEnabled = json["appSettingsEnabled"] as! Bool
            espAppSettings.deviceType = DeviceType(rawValue: json["deviceType"] as! Int)!
            espAppSettings.securityMode = ESPSecurity(rawValue: json["securityMode"] as! Int)
        } else {
            if let settingInfo  = Bundle.main.infoDictionary?["ESP Application Setting"] as? [String:String] {
                if let allowPrefix = settingInfo["ESP Allow Prefix Search"] {
                    espAppSettings.allowPrefixSearch = allowPrefix.lowercased() == "no" ? false:true
                }
                if let appAllowsQrCodeScan = settingInfo["ESP Allow QR Code Scan"] {
                    espAppSettings.appAllowsQrCodeScan = appAllowsQrCodeScan.lowercased() == "no" ? false:true
                }
                if let appSettingsEnabled = settingInfo["ESP Enable Setting"] {
                    espAppSettings.appSettingsEnabled = appSettingsEnabled.lowercased() == "no" ? false:true
                }
                if let securityMode = settingInfo["ESP Securtiy Mode"] {
                    espAppSettings.securityMode = securityMode.lowercased() == "unsecure" ? .unsecure:.secure
                }
                if let deviceType = settingInfo["ESP Device Type"] {
                    if deviceType.lowercased() == "softap" {
                        espAppSettings.deviceType = .softAp
                    } else if deviceType.lowercased() == "ble" {
                        espAppSettings.deviceType = .ble
                    } else {
                        espAppSettings.deviceType = .both
                    }
                }
            }
        }
    }
    
    func saveAppSettings() {
        let json:[String: Any] = ["allowQrCodeScan":espAppSettings.appAllowsQrCodeScan,"appSettingsEnabled":espAppSettings.appSettingsEnabled,"deviceType":espAppSettings.deviceType.rawValue,"allowPrefixSearch":espAppSettings.allowPrefixSearch,"securityMode":espAppSettings.securityMode.rawValue]
        UserDefaults.standard.set(json, forKey: "com.espressif.example")
    }
    
    /// This method can be invoked from any ViewController and will present MBProgressHUD loader with the given message
    ///
    /// - Parameters:
    ///   - message: Text to be showed inside the loader
    ///   - view: View in which loader is added
    
    class func showLoader(view: UIView) {
        DispatchQueue.main.async {
            if overlayView == nil {
                let overlay = UIView(frame: view.bounds)
                overlay.backgroundColor = UIColor.black.withAlphaComponent(0.3)
                overlay.translatesAutoresizingMaskIntoConstraints = false

                let spinner = UIActivityIndicatorView(style: .large)
                spinner.color = .white
                spinner.translatesAutoresizingMaskIntoConstraints = false

                overlay.addSubview(spinner)
                view.addSubview(overlay)

                NSLayoutConstraint.activate([
                    overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                    overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                    overlay.topAnchor.constraint(equalTo: view.topAnchor),
                    overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),

                    spinner.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
                    spinner.centerYAnchor.constraint(equalTo: overlay.centerYAnchor)
                ])

                overlayView = overlay
                indicator = spinner
            }

            overlayView?.isHidden = false
            indicator?.startAnimating()
            view.isUserInteractionEnabled = false
        }
    }

    class func hideLoader(view: UIView) {
        DispatchQueue.main.async {
            indicator?.stopAnimating()
            overlayView?.isHidden = true
            view.isUserInteractionEnabled = true
        }
    }
    class func showAlertWith(message: String = "", viewController: UIViewController) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
        viewController.present(alert, animated: true, completion: nil)
    }
}

extension UIView {
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }

    @IBInspectable var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }

    @IBInspectable var borderColor: UIColor? {
        get {
            return UIColor(cgColor: layer.borderColor!)
        }
        set {
            layer.borderColor = newValue?.cgColor
        }
    }
}

extension UITextField {
    func togglePasswordVisibility() {
        isSecureTextEntry = !isSecureTextEntry

        if let existingText = text, isSecureTextEntry {
            /* When toggling to secure text, all text will be purged if the user
             continues typing unless we intervene. This is prevented by first
             deleting the existing text and then recovering the original text. */
            deleteBackward()

            if let textRange = textRange(from: beginningOfDocument, to: endOfDocument) {
                replace(textRange, withText: existingText)
            }
        }

        /* Reset the selected text range since the cursor can end up in the wrong
         position after a toggle because the text might vary in width */
        if let existingSelectedTextRange = selectedTextRange {
            selectedTextRange = nil
            selectedTextRange = existingSelectedTextRange
        }
    }
}
