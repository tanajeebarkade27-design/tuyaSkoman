import UIKit
import Alamofire

class PasswordResetViewController: UIViewController {
    var emailId: String?
    
    @IBOutlet weak var oTPText: UITextField!
    @IBOutlet weak var newPassword: UITextField!
    @IBOutlet weak var confrimPassword: UITextField!

    @IBOutlet weak var backButton: UIButton!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        backButton.setTitle("", for: .normal)
        setupUI()
    }
    
    
    func setupUI() {
      
        oTPText.keyboardType = .numberPad
        
      
        oTPText.addTarget(self, action: #selector(otpTextChanged(_:)), for: .editingChanged)
    }

    @objc func otpTextChanged(_ textField: UITextField) {
        if let text = textField.text, text.count > 6 {
            textField.text = String(text.prefix(6)) // Limit OTP input to 6 digits
        }
    }
    
    @IBAction func backButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    

    @IBAction func submitButton(_ sender: Any) {
        guard let otp = oTPText.text, otp.count == 6 else {
            showAlert(message: "Please enter a valid 6-digit OTP.")
            return
        }
        
        guard let newPassword = newPassword.text, let confirmPassword = confrimPassword.text else {
            showAlert(message: "Please enter your new password.")
            return
        }

        // Validate password
        if !isValidPassword(newPassword) {
            showAlert(message: "Password must be at least 8 characters long, contain at least 1 uppercase letter, 1 number, and 1 special character (except @).")
            return
        }

        // Check if passwords match
        if newPassword != confirmPassword {
            showAlert(message: "New password and confirm password do not match.")
            return
        }

        verify_otp(otp: otp, newPassword: newPassword)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    func verify_otp(otp: String, newPassword: String) {
        let verify_otp_params: Parameters = [
            "emailId": emailId ?? "",
            "otp": otp,
            "newPassword": newPassword
        ]
        
        AF.request("http://3.7.18.55:3000/skroman/userapi/forgotGooglePass",
                   method: .post,
                   parameters: verify_otp_params,
                   encoding: JSONEncoding.default,
                   headers: nil)
            .validate()
            .responseJSON { response in
                debugPrint(response)
                
                switch response.result {
                case .success(let data):
                    if let json = data as? [String: Any], let msg = json["msg"] as? String {
                        DispatchQueue.main.async {
                            self.showAlert(message: msg)
                        }
                        
                      
                    }
                case .failure(let error):
                    print("API Request Failed: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.showAlert(message: "Password reset failed. Please try again.")
                    }
                }
            }
    }

    func isValidPassword(_ password: String) -> Bool {
        let passwordRegex = "^(?=.*[A-Z])(?=.*[0-9])(?=.*[^A-Za-z0-9@]).{8,}$"
        return NSPredicate(format: "SELF MATCHES %@", passwordRegex).evaluate(with: password)
    }

    func showAlert(message: String, title: String = "Alert") {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
}
