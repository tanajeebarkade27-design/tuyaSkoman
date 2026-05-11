//
//  FamilyMemberListViewController.swift
//  SkromanIsra
//
//  Created by Admin on 14/11/25.
//

import UIKit
import SwiftKeychainWrapper
class FamilyMemberListViewController: UIViewController, URLSessionDelegate, UITextFieldDelegate {
    
    
    @IBOutlet weak var backButton: UIButton!
    
    @IBOutlet weak var addMemButton: UIButton!
    var familyMembers: [[String: Any]] = []
    var otpTextFields: [UITextField] = []
    var emailIdForPopup: String?

    @IBOutlet weak var familyMemTableView: UITableView!
    var popupBackgroundView: UIView!
        var popupView: UIView!
        var emailTextField: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let userId = KeychainWrapper.standard.string(forKey: "userId") ?? "Nothing"
        let userData =  SkromanIsraDatabaseHelper.shared.fetchUserById(userId: userId)
            print("userData at home: \(userData)")
        getFamilyMemberList()
        registerCell()
    }
    
    @IBAction func addMemButton(_ sender: Any) {
        showAddMemberPopup()
    }
    
    
 
    @IBAction func backButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }


}

extension FamilyMemberListViewController {
    
    func showAddMemberPopup() {
       
        // Background dim view
        popupBackgroundView = UIView(frame: self.view.bounds)
        popupBackgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        self.view.addSubview(popupBackgroundView)
        
        // Popup white box
        popupView = UIView(frame: CGRect(x: 40, y: self.view.frame.height/2 - 150,
                                         width: self.view.frame.width - 80, height: 240))
        popupView.backgroundColor = UIColor.white.withAlphaComponent(0.5)
        popupView.layer.cornerRadius = 15
        popupView.clipsToBounds = true
        self.view.addSubview(popupView)
        
        // Title Label
        let titleLabel = UILabel(frame: CGRect(x: 0, y: 20,
                                               width: popupView.frame.width, height: 25))
        titleLabel.text = "Enter Member Email ID"
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.boldSystemFont(ofSize: 17)
        titleLabel.textColor =  .white
        popupView.addSubview(titleLabel)
        
        // Text field
        emailTextField = UITextField(frame: CGRect(x: 20, y: 70,
                                                   width: popupView.frame.width - 40, height: 40))
        emailTextField.placeholder = "Enter email"
        emailTextField.borderStyle = .roundedRect
        popupView.addSubview(emailTextField)
        
        // Submit button
        // Submit button
        let buttonWidth: CGFloat = 150
        let buttonHeight: CGFloat = 40

        let submitBtn = UIButton(frame: CGRect(
            x: (popupView.frame.width - buttonWidth) / 2,
            y: 140,
            width: buttonWidth,
            height: buttonHeight
        ))

        
        submitBtn.setTitle("Submit", for: .normal)
        submitBtn.setTitleColor(.black, for: .normal)
        submitBtn.tintColor = .black
        submitBtn.backgroundColor = .white
        
        submitBtn.layer.cornerRadius = 10
        submitBtn.addTarget(self, action: #selector(submitMemberEmail), for: .touchUpInside)
        
        popupView.addSubview(submitBtn)
        
        popupView.addSubview(submitBtn)
        
        // Animation
        popupView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        popupView.alpha = 0
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(closePopupOnOutsideTap))
        popupBackgroundView.addGestureRecognizer(tapGesture)

        UIView.animate(withDuration: 0.3) {
            self.popupView.alpha = 1
            self.popupView.transform = CGAffineTransform.identity
        }
    }
    @objc func closePopupOnOutsideTap() {
        closePopup()
    }

    
    @objc func submitMemberEmail() {
        guard let email = emailTextField.text, !email.isEmpty else {
            print("Email empty")
            return
        }
        getRegister()
        print("Submitted email:", email)
        
        closePopup()
    }
    
    func closePopup() {
        UIView.animate(withDuration: 0.3, animations: {
            self.popupView.alpha = 0
            self.popupBackgroundView.alpha = 0
        }) { _ in
            self.popupView.removeFromSuperview()
            self.popupBackgroundView.removeFromSuperview()
        }
    }
    
    
    func registerCell(){
       
        let uiNib = UINib(nibName: "FamilyMemberListTableViewCell", bundle: nil)
        familyMemTableView.register(uiNib, forCellReuseIdentifier: "FamilyMemberListTableViewCell")
        familyMemTableView.dataSource =  self
        familyMemTableView.delegate =  self
        
    }
    
    
    
    
    
    func getRegister() {
        let urlString = MainApi.url("skroman/userapi/registration")
        
        guard let emailId = emailTextField.text, isValidEmail(emailId) else {
            showAlert(title: "Invalid Email", message: "Please enter a valid email address.")
            return
        }
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL.")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "emailId": emailId,
            "password": "Skroman@12",
            "confirmPassword": "Skroman@12",
            "loginType": "skroman"
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
        } catch {
            print("Error creating JSON data: \(error)")
            return
        }
        
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error during request: \(error)")
                return
            }
            
            guard let data = data else {
                print("No data received.")
                return
            }
            
            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let message = jsonResponse["msg"] as? String {
                    DispatchQueue.main.async {
                        print("JSON family member response: \(jsonResponse)")
                        switch message {
                        case "User Registration Successfull":
                           self.getOTP()
                            self.emailIdForPopup = emailId
                               
                            self.showSuccessAlert {
                                self.showOTPEntryPopup()
                            }

                            
                        case "Email Address is already registered":
                            self.emailIdForPopup = emailId
                            self.getOTP()
                            self.showSuccessAlert {
                                self.showOTPEntryPopup()
                            }
                            self.showAlert(title: "", message: "Email Address is already registered.")
                            
                        default:
                            print("Unexpected response: \(jsonResponse)")
                        }
                    }
                }
            } catch {
                print("Error parsing JSON response: \(error)")
            }
        }
        
        task.resume()
    }
    
    
    func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            if title == "Registration Failed" {
                // If it's a registration failure alert and the message is about already registered email, navigate to login screen
                if message == "Email Address is already registered. Please go to the login page." {
                    
                }
            }
        }
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
    
    func showSuccessAlert(completion: @escaping () -> Void) {
        let alert = UIAlertController(title: "Success",
                                      message: "otp send sucessfully ",
                                      preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            completion()
        }))
        
        present(alert, animated: true, completion: nil)
    }

    
    
    func showOTPEntryPopup() {
        // Background dim
        popupBackgroundView = UIView(frame: self.view.bounds)
        popupBackgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        self.view.addSubview(popupBackgroundView)
        
        // Popup box
        popupView = UIView(frame: CGRect(x: 30,
                                         y: self.view.frame.height/2 - 130,
                                         width: self.view.frame.width - 60,
                                         height: 240))
        popupView.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        popupView.layer.cornerRadius = 12
        popupBackgroundView.addSubview(popupView)
        
        // Title Label
        
        let titleLabel = UILabel(frame: CGRect(x: 20, y: 20,
                                               width: popupView.frame.width - 40,
                                               height: 25))
        titleLabel.text = "Enter OTP"
        titleLabel.textColor =  .white
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        popupView.addSubview(titleLabel)
        
        // OTP BOXES (4 digits)
        let boxWidth: CGFloat = 50
        let gap: CGFloat = 15
        let startX = (popupView.frame.width - (boxWidth * 4 + gap * 3)) / 2
        
        var otpFields: [UITextField] = []
        
        for i in 0..<4 {
            let tf = UITextField(frame: CGRect(x: startX + CGFloat(i) * (boxWidth + gap),
                                               y: titleLabel.frame.maxY + 25,
                                               width: boxWidth,
                                               height: 50))
            tf.textAlignment = .center
            tf.font = UIFont.systemFont(ofSize: 22, weight: .bold)
            tf.layer.cornerRadius = 8
            tf.layer.borderWidth = 1
            tf.layer.borderColor = UIColor.gray.cgColor
            tf.keyboardType = .numberPad
            tf.delegate = self
            tf.tag = i
            tf.textColor = .white
            
            popupView.addSubview(tf)
            otpFields.append(tf)
        }
        
        self.otpTextFields = otpFields
        
        
       
        let buttonWidth: CGFloat = 150
        let buttonHeight: CGFloat = 40

        let verifyBtn = UIButton(frame: CGRect(
            x: (popupView.frame.width - buttonWidth) / 2,
            y: 140,
            width: buttonWidth,
            height: buttonHeight
        ))
        
        verifyBtn.setTitle("Verify OTP", for: .normal)
        verifyBtn.setTitleColor(.black, for: .normal)
        verifyBtn.backgroundColor = .white
        verifyBtn.layer.cornerRadius = 10
       verifyBtn.addTarget(self, action: #selector(verifyOTPPressed), for: .touchUpInside)
        popupView.addSubview(verifyBtn)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(closePopupOnOutsideTap))
        popupView.addGestureRecognizer(tapGesture)
    }
    @objc func verifyOTPPressed() {
           let otp = otpTextFields.map { $0.text ?? "" }.joined()

           if otp.count != 4 {
               showAlert(title: "Invalid OTP", message: "Please enter your 4-digit OTP")
               return
           }

           print("OTP entered:", otp)
        getVerifyOTP()

           popupBackgroundView.removeFromSuperview()
       }
    
    func getOTP(){
        
        let urlString = MainApi.url("skroman/userapi/forgotpassOTP")
        guard let emailId = emailTextField.text, !emailId.isEmpty else { return }
        guard let url = URL(string: urlString) else {
            print("Invalid URL.")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "emailId": emailId
            
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
        } catch {
            print("Error creating JSON data: \(error)")
            return
        }
        
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error during request: \(error)")
                return
            }
            
            guard let data = data else {
                print("No data received.")
                return
            }
            
            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let message = jsonResponse["msg"] as? String {
                    DispatchQueue.main.async {
                        print(" OTP for family member : \(jsonResponse)")
                        switch message {
                        case "OTP send sucessfully":
                            print("otp send sucessfully ")
                            
                        default:
                            print("Unexpected response: \(jsonResponse)")
                        }
                    }
                }
            } catch {
                print("Error parsing JSON response: \(error)")
            }
        }
        
        task.resume()
        
    }
    
    
    func getFamilyMemberList() {
        let urlString = MainApi.url("skroman/userapi/getAllFamilyMembers")
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL.")
            return
        }
        
        let userId = KeychainWrapper.standard.string(forKey: "userId") ?? "Nothing"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "userId": userId
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
        } catch {
            print("Error creating JSON data: \(error)")
            return
        }
        
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        let task = session.dataTask(with: request) { data, response, error in
            
            if let error = error {
                print("Error during request: \(error)")
                return
            }
            
            guard let data = data else {
                print("No data received.")
                return
            }
            
            // 🔥 PRINT RAW RESPONSE
            if let rawString = String(data: data, encoding: .utf8) {
                print("RAW JSON RESPONSE:\n\(rawString)")
            }
            
            // 🔥 Continue with normal JSON parsing
            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    
                    if let familyData = jsonResponse["familyData"] as? [[String: Any]] {
                        self.familyMembers = familyData
                        
                        for familyMember in familyData {
                            if let familyUserId = familyMember["familyUserId"] as? String,
                               let familyUserEmail = familyMember["familyUserEmail"] as? String,
                               let islimited = familyMember["isLimited"] {
                                print("Family User ID: \(familyUserId), Email: \(familyUserEmail), isLimited: \(islimited)")
                            }
                        }
                        
                        DispatchQueue.main.async {
                            self.familyMemTableView.reloadData()
                        }
                    } else {
                        print("No family data found.")
                    }
                }
            } catch {
                print("Error parsing JSON response: \(error)")
            }
        }
        
        task.resume()
    }

    func getVerifyOTP() {
        let urlString = MainApi.url("skroman/userapi/addMember")
        
        // Ensure OTP fields are filled
        let otp = otpTextFields.map { $0.text ?? "" }.joined()
        
        if otp.count != 4 {
            showAlertotp(title: "Error", message: "Please enter a valid 4-digit OTP")
            return
        }
        
        guard let emailId = emailIdForPopup,
              !emailId.isEmpty else {
            showAlertotp(title: "Error", message: "Email not found.")
            return
        }
        
        let userId = KeychainWrapper.standard.string(forKey: "userId") ?? "Nothing"
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL.")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "emailId": emailId,
            "otp": otp,
            "userId": userId
        ]
        
        print("OTP request body:", body)
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
        } catch {
            print("Error creating JSON:", error)
            return
        }
        
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        let task = session.dataTask(with: request) { [weak self] data, response, error in
            
            if let error = error {
                print("Error during request:", error)
                return
            }
            
            guard let data = data else {
                print("No data received.")
                return
            }
            
            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let message = jsonResponse["msg"] as? String {
                    print("jsonResponse family\(jsonResponse)")
                    DispatchQueue.main.async {
                        switch message {
                            
                        case "Family member already added":
                            self?.showAlertFamilyAccess(message: "This family member has already been added.")
                            
                        case "Family member added successfully":
                            self?.showAlertFamilyAccess(message: "Family member added successfully.")
                            
                        case "OTP does not match":
                            self?.showAlertotp(title: "Error", message: "Incorrect OTP. Please try again.")
                            
                        default:
                            self?.showAlertAtAccessError(message: message)
                        }
                    }
                }
            } catch {
                print("Error parsing JSON:", error)
            }
        }
        
        task.resume()
    }

    func showAlertFamilyAccess(message: String) {
        let alert = UIAlertController(title: "Success", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
           // self?.navigateToFamilyAccess()
        })
        present(alert, animated: true, completion: nil)
    }
    
    func showAlertotp(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true)
    }
    func showAlertAtAccessError(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

}


extension FamilyMemberListViewController {
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {

        // Only allow 1 digit
        if string.count > 1 { return false }

        // If user enters a digit
        if string.count == 1 {
            textField.text = string
            
            // Move to next
            if textField.tag < otpTextFields.count - 1 {
                otpTextFields[textField.tag + 1].becomeFirstResponder()
            } else {
                textField.resignFirstResponder()
            }
            return false
        }

        // Allow deleting
        return true
    }
}


extension FamilyMemberListViewController : UITableViewDataSource, UITableViewDelegate{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return familyMembers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FamilyMemberListTableViewCell", for: indexPath) as!
        FamilyMemberListTableViewCell
        let familyMember = familyMembers[indexPath.row]
        cell.selectionStyle = .none
        
        if let familyUserEmail = familyMember["familyUserEmail"] as? String {
            cell.memberEmailLabel.text = familyUserEmail
        }
         return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let familyMember = familyMembers[indexPath.row]
        let familyUserId =  familyMember["familyUserId"]  as? String
        guard let email = familyMember["familyUserEmail"] as? String else {
            print("Email not found for selected family member")
            return
        }

       
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "AlloctedDeviceViewController") as? AlloctedDeviceViewController {

            vc.selectedFamilyData = familyMember
           

            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 10
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }

    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
}
