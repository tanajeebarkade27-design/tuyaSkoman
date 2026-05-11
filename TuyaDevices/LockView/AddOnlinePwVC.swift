 
import UIKit
import ThingSmartLockKit
import ThingSmartHomeKit
import ThingSmartBaseKit


class AddOnlinePwVC: UIViewController {
    
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
        let backgroundImage = UIImageView(image: UIImage(named: "Screen Background"))
               backgroundImage.contentMode = .scaleAspectFill
                view.insertSubview(backgroundImage, at: 0)
               backgroundImage.translatesAutoresizingMaskIntoConstraints = false
               backgroundImage.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
               backgroundImage.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
               backgroundImage.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
               backgroundImage.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
       
        setupTapToDismissKeyboard()
        
        passwordText.delegate = self
              
        setupPasswordKeyboard()
        effectivedatebtn.tintColor = .white
        expirationDatebtn.tintColor =  .white
        save.tintColor =  .white
       
        passowrdnameText.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        passowrdnameText.layer.cornerRadius = 12
        passowrdnameText.clipsToBounds = true
        passwordText.backgroundColor?.withAlphaComponent(0.1)
        passwordText.layer.cornerRadius = 12
        passwordText.clipsToBounds = true
//        effectivedatebtn.backgroundColor = UIColor.white.withAlphaComponent(0.50)
        effectivedatebtn.tintColor = .white
        expirationDatebtn.tintColor = .white
        
        passwordText.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        passwordText.textColor = .white
        passwordText.attributedPlaceholder = NSAttributedString(
            string: "Enter Password",
            attributes: [.foregroundColor: UIColor.white.withAlphaComponent(0.6)]
        )
        
        print ("deviceCategory\(deviceCategory)")
        if deviceCategory == "jtmspro" {
                passwordText.placeholder = "Enter 7 digit password"
            } else {
                passwordText.placeholder = "Enter 6–8 digit password"
            }
       
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
         
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    private func setupPasswordKeyboard() {
        passwordText.keyboardType = .numberPad
    }
    
    private func setupTapToDismissKeyboard() {
        let tapGesture = UITapGestureRecognizer(
            target: self,
            action: #selector(dismissKeyboard)
        )
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    
    
    @IBAction func backBtn(_ sender: Any) {
        
        navigationController?.popViewController(animated: true)
        
    }
    
    
    
    
    @IBAction func randomPassword(_ sender: Any) {

        let length = (deviceCategory == "jtmspro") ? 7 : Int.random(in: 6...8)

        let password = String((0..<length).map { _ in
            "0123456789".randomElement()!
        })

        passwordText.text = password
    }

    func startOfDay(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }

    func endOfDay(_ date: Date) -> Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay(date))!
    }

   
    
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {

        guard textField == passwordText else { return true }

        let currentText = textField.text ?? ""
        let updatedText = (currentText as NSString).replacingCharacters(in: range, with: string)
        if string.isEmpty { return true }
        let digits = CharacterSet.decimalDigits
        if !CharacterSet(charactersIn: string).isSubset(of: digits) {
            return false
        }

        let maxLength = (deviceCategory == "jtmspro") ? 7 : 8

        if updatedText.count > maxLength {
            return false
        }
       

        return true
    }
        
       
        
        
   
    
    @IBAction func saveButton(_ sender: Any) {

        guard let devId = tuyaDeviceId, !devId.isEmpty else {
            showAlert("Error", "Device ID not found")
            return
        }

        guard let nameInput = passowrdnameText.text, !nameInput.isEmpty else {
            showAlert("Error", "Please enter password name")
            return
        }

        guard let pwd = passwordText.text, !pwd.isEmpty else {
            showAlert("Error", "Please enter password")
            return
        }

        let digits = CharacterSet.decimalDigits
        if !CharacterSet(charactersIn: pwd).isSubset(of: digits) {
            showAlert("Error", "Password must contain only numbers")
            return
        }

       
        if deviceCategory == "jtmspro" {

            if pwd.count != 7 {
                showAlert("Error", "For this lock, password must be exactly 7 digits")
                return
            }

        } else {

            if pwd.count < 6 || pwd.count > 8 {
                showAlert("Error", "Password must be 6–8 digits")
                return
            }
        }

        let now = Date()

        guard let effectiveDate = selectedEffectiveDate else {
            showAlert("Error", "Please select effective date")
            return
        }

        guard let expirationDate = selectedExpirationDate else {
            showAlert("Error", "Please select expiration date")
            return
        }

        
        let buffer: TimeInterval = 60
        if effectiveDate < now.addingTimeInterval(-buffer) {
            showAlert("Error", "Effective time must be in future")
            return
        }

       
        if expirationDate < now {
            showAlert("Error", "Expiration cannot be in the past")
            return
        }

        // ✅ max 24 hours from now
        let maxDate = now.addingTimeInterval(86400)
        if expirationDate > maxDate {
            showAlert("Error", "Expiration must be within 24 hours from now")
            return
        }

        
        if expirationDate <= effectiveDate {
            showAlert("Error", "Expiration must be after effective time")
            return
        }
       
        let uniqueName = "\(nameInput)"

        addPhotoTempPassword(
            devId: devId,
            passwordName: uniqueName,
            password: pwd,
            effectiveDate: effectiveDate,
            expirationDate: expirationDate
        )
    }
    
    func addPhotoTempPassword(
        devId: String,
        passwordName: String,
        password: String,
        effectiveDate: Date,
        expirationDate: Date
    ) {

        let api = ThingSmartLockApi()

        let start = Int(effectiveDate.timeIntervalSince1970)   // ✅ seconds
        let end = Int(expirationDate.timeIntervalSince1970)   // ✅ seconds

        let scheduleDict: [[String: Any]] = [
            [
                "allDay": true,
                "workingDay": 127
            ]
        ]

        let jsonData = try? JSONSerialization.data(withJSONObject: scheduleDict)
        let scheduleString = String(data: jsonData ?? Data(), encoding: .utf8) ?? ""

        print("🕒 Effective:", start)
        print("🕒 Expiration:", end)
        print("📅 Schedule:", scheduleString)

        api.addPhotoLockTemporaryPassword(
            withDevId: devId,
            name: passwordName,
            phone: "",
            effectiveTime: start,
            invalidTime: end,
            password: password,
            schedule: scheduleString,
            countryCode: "91",
            availTime: 0,
            success: { result in
                DispatchQueue.main.async {
                    print("✅ Created:", result ?? "")
                    self.showSuccessAndNavigateAlert(password: password)
                    self.copyToClipboard(password)
                }
            },
            failure: { error in
                DispatchQueue.main.async {
                            let message = error?.localizedDescription ?? "Something went wrong"

                            print("❌ Error:", message)

                            // ❌ ERROR POPUP
                            self.showAlert("Error", message)
                        }
                    
            }
        )
    }
 
    private func showDatePicker() {
        let vc = DatePickerViewController()
        vc.modalPresentationStyle = .pageSheet

        if #available(iOS 15.0, *) {
            if let sheet = vc.sheetPresentationController {
                sheet.detents = [.medium()]
            }
        } else {
            // Fallback on earlier versions
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
        formatter.dateFormat = "dd MMM yyyy, HH:mm:ss.SSS" // ✅ milliseconds

        switch currentDateType {

        case .effective:
            selectedEffectiveDate = date
            effectivedatebtn.setTitle(formatter.string(from: date), for: .normal)

        case .expiration:
            selectedExpirationDate = date
            expirationDatebtn.setTitle(formatter.string(from: date), for: .normal)

        case .none:
            break
        }
    }
    private func showAlert(_ title: String, _ message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func showSuccessAndNavigateAlert(password: String) {
        
        let alert = UIAlertController(
            title: "Success",
            message: nil,
            preferredStyle: .alert
        )
        
         
        let message = NSMutableAttributedString(
            string: "Password created successfully\n\n",
            attributes: [
                .font: UIFont.systemFont(ofSize: 14)
            ]
        )
        
        let boldPassword = NSAttributedString(
            string: password,
            attributes: [
                .font: UIFont.boldSystemFont(ofSize: 20),
                .foregroundColor: UIColor.systemBlue
            ]
        )
        
        message.append(boldPassword)
        
        alert.setValue(message, forKey: "attributedMessage")
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            self.navigateToLockController()
        }))
        
        present(alert, animated: true)
    }

   

   


    private func copyToClipboard(_ text: String) {
        UIPasteboard.general.string = text
    }

    private func navigateToLockController() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
//        guard let vc = storyboard.instantiateViewController(
//            withIdentifier: "LockControllerVC"
//        ) as? LockControllerVC else {
//            return
//        }
//
//        
//        vc.tuyaDeviceId = self.tuyaDeviceId
//
//        self.navigationController?.pushViewController(vc, animated: true)
    }


}


enum DateType {
    case effective
    case expiration
}

extension AddOnlinePwVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

