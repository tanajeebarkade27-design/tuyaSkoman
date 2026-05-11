//
//  BLELandingViewController.swift
//  SkromanIsra
//
//  Created by Admin on 27/01/25.
//


import CoreBluetooth
import Foundation
//import MBProgressHUD
import UIKit
import ESPProvision


protocol BLEStatusProtocol {
    func peripheralDisconnected()
}

class BLELandingViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var activityView: UIActivityIndicatorView?
    var grayView: UIView?
    var delegate: BLEStatusProtocol?
    var bleConnectTimer = Timer()
    var bleDeviceConnected = false
    var bleDevices:[ESPDevice]?
    var uniqueId: String?
    var devicePop: String?

    @IBOutlet var tableview: UITableView!
    @IBOutlet var prefixTextField: UITextField!
    @IBOutlet var prefixlabel: UILabel!
    @IBOutlet var prefixView: UIView!
    @IBOutlet var textTopConstraint: NSLayoutConstraint!
    
    
    @IBOutlet weak var scanAgainBtn: UIButton!
    
    // MARK: - Overriden Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        prefixTextField.layer.borderWidth = 1
        prefixTextField.layer.borderColor = UICOLOR_TXTFIELD_BORDER_COLOR.cgColor
      
    print(devicePop)
        if let uniqueIdValue = uniqueId {
            prefixTextField.text = uniqueIdValue
            print("uniqueid at ble: \(uniqueIdValue)")
        } else {
            prefixTextField.text = Utility.shared.deviceNamePrefix
            print("uniqueid is nil, using default prefix")
        }
        
        
        scanAgainBtn.backgroundColor = .white
        scanAgainBtn.setTitleColor(.black, for: .normal)
        scanAgainBtn.layer.cornerRadius = 8
        scanAgainBtn.clipsToBounds = true
        
//        prefixTextField.setLeftPaddingPoints(20)
//        navigationItem.title = "Connect"
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        // Scan for bluetooth devices

        // UI customization
        prefixlabel.layer.masksToBounds = true
        tableview.tableFooterView = UIView()

        // Adding tap gesture to hide keyboard on outside touch
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)

        // Checking whether filtering by prefix header is allowed
        prefixTextField.text = uniqueId
        if Utility.shared.espAppSettings.allowPrefixSearch {
            prefixView.isHidden = false
        } else {
            textTopConstraint.constant = -10
            view.layoutIfNeeded()
        }
        
        scanBleDevices()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillDisappear), name: UIResponder.keyboardWillHideNotification, object: nil)
        self.tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    
       

    // MARK: - IBActions
    
    @IBAction func backButtonPressed(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func cancelPressed(_ sender: Any) {
        navigationController?.popToRootViewController(animated: true)
    }
    
    @IBAction func rescanBLEDevices(_: Any) {
        bleDevices?.removeAll()
        tableview.reloadData()
        scanBleDevices()
    }
    
    func scanBleDevices() {
        showLoader()
        ESPProvisionManager.shared.searchESPDevices(devicePrefix: Utility.shared.deviceNamePrefix, transport: .ble) { bleDevices, error in
            DispatchQueue.main.async {
                self.hideLoader()
                self.bleDevices = bleDevices
                self.tableview.reloadData()
            }
        }
    }
    
    // MARK: - Notifications
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc func keyboardWillDisappear() {
        if let prefix = prefixTextField.text {
            UserDefaults.standard.set(prefix, forKey: "com.espressif.prefix")
            Utility.shared.deviceNamePrefix = prefix
            rescanBLEDevices(self)
        }
    }
    
    // MARK: - Helper Methods
    
    func goToProvision(device: ESPDevice) {
        DispatchQueue.main.async {
            self.hideLoader()
            let provisionVC = self.storyboard?.instantiateViewController(withIdentifier: "provision") as! ProvisionViewController
            provisionVC.espDevice = device
            print ("device at prov\(device)")
            self.navigationController?.pushViewController(provisionVC, animated: true)
        }
    }
    
    private func showAlert(error: String, action: UIAlertAction) {
        let alertController = UIAlertController(title: "Error!", message: error, preferredStyle: .alert)
        alertController.addAction(action)
        self.present(alertController, animated: true, completion: nil)
    }
    
    private func connectDevice(device: ESPDevice) {
        device.connect(delegate: self) { status in
            DispatchQueue.main.async {
                self.hideLoader()
            }

            switch status {
            case .connected:
                DispatchQueue.main.async {
                    self.goToProvision(device: device)
                }

            case let .failedToConnect(error):
                DispatchQueue.main.async {
                    let action = UIAlertAction(title: "Retry", style: .default, handler: nil)
                    self.showAlert(error: error.description + "\nCheck if POP is correct.", action: action)
                }

            default:
                DispatchQueue.main.async {
                    let action = UIAlertAction(title: "Retry", style: .default, handler: nil)
                    self.showAlert(error: "Device disconnected", action: action)
                }
            }
        }
    }
    
    
    // MARK: - UITableView
    
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        guard let peripherals = self.bleDevices else {
            return 0
        }
        print("peripherals device at bl \(peripherals.count)")
        return peripherals.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "bleDeviceCell", for: indexPath) as! BLEDeviceListViewCell
        if let peripheral = self.bleDevices?[indexPath.row] {
            cell.deviceName.text = peripheral.name
        }

        return cell
    }

    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        return 60
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        showLoader()
        self.connectDevice(device: self.bleDevices![indexPath.row])
    }
    
    // MARK: - Activity Indicator

    func showLoader() {
        if grayView == nil {
            let overlay = UIView(frame: view.bounds)
            overlay.backgroundColor = UIColor.black.withAlphaComponent(0.3)
            overlay.translatesAutoresizingMaskIntoConstraints = false

            let indicator = UIActivityIndicatorView(style: .large)
            indicator.color = .white
            indicator.translatesAutoresizingMaskIntoConstraints = false

            overlay.addSubview(indicator)
            view.addSubview(overlay)

            NSLayoutConstraint.activate([
                overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                overlay.topAnchor.constraint(equalTo: view.topAnchor),
                overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),

                indicator.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
                indicator.centerYAnchor.constraint(equalTo: overlay.centerYAnchor)
            ])

            grayView = overlay
            activityView = indicator
        }

        activityView?.startAnimating()
        grayView?.isHidden = false
        view.isUserInteractionEnabled = false
    }

    func hideLoader() {
        activityView?.stopAnimating()
        grayView?.isHidden = true
        view.isUserInteractionEnabled = true
    }

    
}

extension BLELandingViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_: UITextField) -> Bool {
        view.endEditing(true)
        return false
    }
}

extension BLELandingViewController: ESPDeviceConnectionDelegate {
    func getUsername(forDevice: ESPDevice, completionHandler: @escaping (String?) -> Void) {
        return
    }
    
    func getProofOfPossesion(forDevice: ESPDevice, completionHandler: @escaping (String) -> Void) {
        let connectVC = self.storyboard?.instantiateViewController(withIdentifier: "connectVC") as! ConnectViewController
        connectVC.espDevice = forDevice
        connectVC.popHandler = completionHandler
        connectVC.pop = devicePop ?? ""
        self.navigationController?.pushViewController(connectVC, animated: true)
    }
}
