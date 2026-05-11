
import UIKit
import SwiftKeychainWrapper
import Alamofire

class ChangeEmailViewController: UIViewController {

    @IBOutlet weak var backButton: UIButton!
    
    @IBOutlet weak var previousEmailText: UITextField!
    
    @IBOutlet weak var newEmailText: UITextField!
    
    @IBOutlet weak var conatctNumberText: UITextField!
    @IBOutlet weak var confirmEmailText: UITextField!
    
    @IBOutlet weak var onemiabutton: UIButton!
    
    @IBOutlet weak var onContcatbutton: UIButton!
    
    var isEmailSelected = true
    override func viewDidLoad() {
        super.viewDidLoad()
        onemiabutton.setTitle("", for: .normal)
        onContcatbutton.setTitle("", for: .normal)
        backButton.setTitle("", for: .normal)
        fetchUserdata()
        if let image = UIImage(named: "isSelected")?.resized(to: CGSize(width: 30, height: 30)) {
            onemiabutton.setImage(image, for: .normal)
            
        }
        if let image = UIImage(named: "Unselect")?.resized(to: CGSize(width: 30, height: 30)) {
            onContcatbutton.setImage(image, for: .normal)
            
        }
        conatctNumberText.isHidden = true
    }
    

    func fetchUserdata(){
        
        let userId = KeychainWrapper.standard.string(forKey: "userId") ?? ""
        guard !userId.isEmpty else {
            print("User ID is missing")
            return
        }
        
        let users = SkromanIsraDatabaseHelper.shared.fetchUserById(userId: userId)
        if let user = users.first {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
               
                self.previousEmailText.text =  user.emailId
               
            }
        } else {
            print("⚠️ No user found for userId: \(userId)")
        }
    }
   
    @IBAction func backButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
        
    }
    
    
    @IBAction func submitButton(_ sender: Any) {
        guard let userId = KeychainWrapper.standard.string(forKey: "userId"),
              let newEmail = newEmailText.text, !newEmail.isEmpty,
              let confirmEmail = confirmEmailText.text, !confirmEmail.isEmpty else {
            showAlert(message: "Please fill all required fields.")
            return
        }

        // Validate email format
        if !isValidEmail(newEmail) || !isValidEmail(confirmEmail) {
            showAlert(message: "Please enter a valid email address.")
            return
        }
        
        // Check if emails match
        if newEmail != confirmEmail {
            showAlert(message: "New email and confirm email do not match.")
            return
        }

        if isEmailSelected {
            let userEmailId = previousEmailText.text ?? ""
            requestEmailChange(userId: userId, userEmailId: userEmailId, newEmail: newEmail, confirmEmail: confirmEmail)
        } else {
            let mobileNumber = conatctNumberText.text ?? ""
            emailChangeByContact(userId: userId, mobileNumber: mobileNumber, newEmail: newEmail, confirmEmail: confirmEmail)
        }
    }

    func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }

    @IBAction func emailButton(_ sender: Any) {
        isEmailSelected = true
        conatctNumberText.isHidden = true
                updateButtonImages()
        
    }
    
    @IBAction func onContactButton(_ sender: Any) {
        
        isEmailSelected = false
        conatctNumberText.isHidden = false
               updateButtonImages()
    }
    func updateButtonImages() {
            let selectedImage = UIImage(named: "isSelected")?.resized(to: CGSize(width: 30, height: 30))
            let unselectedImage = UIImage(named: "Unselect")?.resized(to: CGSize(width: 30, height: 30))

        onemiabutton.setImage(isEmailSelected ? selectedImage : unselectedImage, for: .normal)
        onContcatbutton.setImage(isEmailSelected ? unselectedImage : selectedImage, for: .normal)
        }
    
    
    
    func requestEmailChange(userId: String, userEmailId: String, newEmail: String, confirmEmail: String) {
            let url = "http://3.7.18.55:3000/skroman/profileapi/sendotp"
            let params: [String: Any] = [
                "userId": userId,
                "emailId": userEmailId,
                "newEmailId": newEmail,
                "confirmEmail": confirmEmail
            ]

            AF.request(url, method: .post, parameters: params, encoding: JSONEncoding.default)
                .validate()
                .response { response in
                    self.handleAPIResponse(response: response, newEmail: newEmail)
                }
        }

        /// Request email change via contact number
        func emailChangeByContact(userId: String, mobileNumber: String, newEmail: String, confirmEmail: String) {
            let url = "http://3.7.18.55:3000/skroman/profileapi/numberotp"
            let params: [String: Any] = [
                "userId": userId,
                "mobileNumber": mobileNumber,
                "newEmailId": newEmail,
                "confirmEmail": confirmEmail
            ]

            AF.request(url, method: .post, parameters: params, encoding: JSONEncoding.default)
                .validate()
                .response { response in
                    self.handleAPIResponse(response: response, newEmail: newEmail)
                }
        }

        /// Handles API response for both email and contact-based requests
        private func handleAPIResponse(response: AFDataResponse<Data?>, newEmail: String) {
            switch response.result {
            case .success(let data):
                do {
                    if let jsonObject = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [String: Any] {
                        print("API Response: \(jsonObject)")

                        if let msg = jsonObject["msg"] as? String {
                            print("API Message: \(msg)")

                            if msg.contains("Success Send OTP") {
                                let sessionId = jsonObject["sessionIdParse"] as? String ?? ""
                                DispatchQueue.main.async {
                                    self.navigateToOTPScreen(newemail: newEmail, sessionId: sessionId)
                                }
                            } else {
                                DispatchQueue.main.async {
                                    self.showAlert(message: msg)
                                }
                            }
                        }
                    }
                } catch {
                    print("JSON Parsing Error: \(error.localizedDescription)")
                }
            case .failure(let error):
                print("API Request Failed: \(error.localizedDescription)")
            }
        }

        /// Navigates to OTP screen
        func navigateToOTPScreen(newemail: String, sessionId: String) {
            print("Navigating to OTP screen with \(newemail) and session \(sessionId)")
            let  vc =  storyboard?.instantiateViewController(withIdentifier: "OTPEmailViewController") as! OTPEmailViewController
            vc.newEnail = newemail
            navigationController?.pushViewController(vc, animated: true)
        }

        /// Shows alert with message
        func showAlert(message: String) {
            let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    
}
