//
//  AddOfflinePassListVC.swift
//  SkromanIsra
//
//  Created by Admin on 18/04/26.
//

import UIKit
import ThingSmartLockKit
import ThingSmartHomeKit
import ThingSmartBaseKit

class AddOfflinePassListVC: UIViewController {
    
    var deviceId: String?
   
    
    @IBOutlet weak var passwordText: UITextField!
    
    @IBOutlet weak var save: UIButton!
    
    
    @IBOutlet weak var effectivedatebtn: UIButton!
    
    @IBOutlet weak var expirationDatebtn: UIButton!
    
    @IBOutlet weak var passowrdnameText: UITextField!
    
    
    
    
    var currentDateType: DateType?
   
    var tuyaDeviceId: String?
    var selectedEffectiveDate: Date?
    var selectedExpirationDate: Date?
    var deviceCategory: String?
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("DeviceId:", deviceId ?? "")
        print("Category:", deviceCategory ?? "")
        
        let backgroundImage = UIImageView(image: UIImage(named: "Screen Background"))
               backgroundImage.contentMode = .scaleAspectFill
                view.insertSubview(backgroundImage, at: 0)
               backgroundImage.translatesAutoresizingMaskIntoConstraints = false
               backgroundImage.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
               backgroundImage.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
               backgroundImage.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
               backgroundImage.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
       
    }
    
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    private func showDatePicker() {
        let vc = DatePickerViewController()
        vc.modalPresentationStyle = .pageSheet
        
        if #available(iOS 15.0, *) {
            if let sheet = vc.sheetPresentationController {
                sheet.detents = [.medium()]
            }
        } else {
           
        }
        
        vc.onDateSelected = { date in
            self.applyDate(date)
        }
        
        present(vc, animated: true)
    }
    
    
    
    @IBAction func effectiveDateTapped(_ sender: UIButton) {
        currentDateType = .effective
        showDatePicker()
    }
    
    @IBAction func expirationDateTapped(_ sender: UIButton) {
        currentDateType = .expiration
        showDatePicker()
    }
    
    private func applyDate(_ date: Date) {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "dd MMM yyyy, HH:mm:ss"
        
        switch currentDateType {
        case .effective:
            
            let now = Date()
            var cal = Calendar.current
            let picked = cal.dateComponents([.year,.month,.day], from: date)
            let current = cal.dateComponents([.hour,.minute,.second], from: now)
            
            var final = DateComponents()
            final.year = picked.year
            final.month = picked.month
            final.day = picked.day
            final.hour = current.hour
            final.minute = current.minute
            final.second = current.second
            
            let finalDate = cal.date(from: final)!
            selectedEffectiveDate = finalDate
            effectivedatebtn.setTitle(formatter.string(from: finalDate), for: .normal)
            
        case .expiration:

            guard let eff = selectedEffectiveDate else {
                print("❌ Select start date first")
                return
            }

            
            if date <= eff {
                print("❌ Expiration must be after start date")

                // Optional: show alert
                let alert = UIAlertController(
                    title: "Invalid Date",
                    message: "Expiration must be after start date",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)

                return
            }

            selectedExpirationDate = date
            expirationDatebtn.setTitle(formatter.string(from: date), for: .normal)
            
        case .none:
            break
        }
        
    }
    
    @IBAction func saveTapped(_ sender: UIButton) {
        print("✅ save tapped")

        guard let deviceId = deviceId else {
            print("❌ Missing deviceId")
            return
        }

        guard let name = passowrdnameText.text, !name.isEmpty else {
            print("❌ Enter password name")
            return
        }

        guard let startDate = selectedEffectiveDate,
              let endDate = selectedExpirationDate else {
            print("❌ Dates not selected")
            return
        }



        print("🔥 All validations passed")

        let start = Int(Date().timeIntervalSince1970) - 60
        let end = Int(endDate.timeIntervalSince1970)

        createOfflinePassword(
            deviceId: deviceId,
            name: name,
            startTime: start,
            endTime: end
        )
    }
    
    
    @IBAction func backBtn(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    func createOfflinePassword(
        deviceId: String,
        name: String,
        startTime: Int,
        endTime: Int
    ) {
        print("🚀 Calling Photo Lock API")

        let api = ThingSmartLockApi()

        print("🚀 API HIT with deviceId:", deviceId)

        api.addPhotoLockOfflinePassword(
            withDevId: deviceId,
            pwdType: "0",
            gmtStart: startTime,
            gmtExpired: endTime,
            pwdName: name,
            countryCode: "91",
            mobile: "",
            success: { result in
                print("✅ SUCCESS CALLED")

                if let dict = result as? [String: Any],
                   let pwd = dict["pwd"] as? String {

                    print("🔑 Generated Password:", pwd)

                    DispatchQueue.main.async {
                        self.passwordText.text = pwd

                        // ✅ SHOW SUCCESS ALERT
                        self.showAlert(
                            title: "Success",
                            message: "Password generated: \(pwd)"
                        )
                    }

                } else {
                    DispatchQueue.main.async {
                        self.showAlert(
                            title: "Warning",
                            message: "Password created but parsing failed"
                        )
                    }
                }
            },
            failure: { error in
                print("❌ FAILURE CALLED")
                print("🧨 ERROR:", error as Any)

                let msg = (error as NSError?)?.localizedDescription ?? "Unknown error"

                DispatchQueue.main.async {
                    self.showAlert(
                        title: "Error",
                        message: msg
                    )
                }
            }
        )
    }
    
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

