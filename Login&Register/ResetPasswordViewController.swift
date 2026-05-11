

import UIKit
import Alamofire
import SwiftKeychainWrapper

class ResetPasswordViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var firstOtpDigit: UITextField!
    @IBOutlet weak var secondOtpDigit: UITextField!
    @IBOutlet weak var thirdOtpDigit: UITextField!
    @IBOutlet weak var fourthOtpDigit: UITextField!
    @IBOutlet weak var enterPasswordText: UITextField!
    @IBOutlet weak var confirmPasswordText: UITextField!
    @IBOutlet weak var resetPasswordButton: UIButton!
    
    
    @IBOutlet weak var backgroundimage: UIImageView!
    @IBOutlet weak var viewBackground: UIView!
    
    @IBOutlet weak var imgeView: UIView!
    var emailId: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        backgroundimage.contentMode = .scaleAspectFill
        backgroundimage.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            backgroundimage.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundimage.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundimage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundimage.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        
        resetPasswordButton.backgroundColor = .white
        resetPasswordButton.setTitleColor(.black, for: .normal) // text color
        resetPasswordButton.layer.cornerRadius = 10
        resetPasswordButton.layer.masksToBounds = true
        
        let gray6 = UIColor(named: "systemGray6") ?? UIColor.systemGray

        confirmPasswordText.attributedPlaceholder = NSAttributedString(
            string: "Enter Password",
            attributes: [NSAttributedString.Key.foregroundColor: gray6]
        )
        enterPasswordText.attributedPlaceholder = NSAttributedString(
            string: "Enter Confirm Password",
            attributes: [NSAttributedString.Key.foregroundColor: gray6]
        )
        
        setupTextFields()
       
        // Register keyboard notifications
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    deinit {
        // Remove observers to avoid memory leaks
        NotificationCenter.default.removeObserver(self)
    }
    
    
    @IBAction func backbtn(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    

    // MARK: - Setup OTP & Password Fields
    func setupTextFields() {
        let otpFields = [firstOtpDigit, secondOtpDigit, thirdOtpDigit, fourthOtpDigit]
        for textField in otpFields {
            textField?.delegate = self
            textField?.keyboardType = .numberPad // Ensures numeric keyboard
            textField?.textAlignment = .center
            textField?.addTarget(self, action: #selector(textDidChange(_:)), for: .editingChanged)
        }
        
        // Allow normal input for password fields
        enterPasswordText.delegate = self
        confirmPasswordText.delegate = self
        enterPasswordText.keyboardType = .default
        confirmPasswordText.keyboardType = .default
    }

    // MARK: - Handle OTP Input (Auto-move cursor)
    @objc func textDidChange(_ textField: UITextField) {
        guard let text = textField.text, text.count == 1 else { return }
        
        switch textField {
        case firstOtpDigit:
            secondOtpDigit.becomeFirstResponder()
        case secondOtpDigit:
            thirdOtpDigit.becomeFirstResponder()
        case thirdOtpDigit:
            fourthOtpDigit.becomeFirstResponder()
        case fourthOtpDigit:
            fourthOtpDigit.resignFirstResponder()
        default:
            break
        }
    }

    
    func addGradientappBorder(to view: UIView, cornerRadius: CGFloat, lineWidth: CGFloat) {
        // Remove old gradient layer if present
        view.layer.sublayers?.removeAll(where: { $0.name == "GradientBorder" })

        let gradientLayer = CAGradientLayer()
        gradientLayer.name = "GradientBorder"

        // Set gradient colors (green → blue) with some transparency
        gradientLayer.colors = [
            UIColor.green.withAlphaComponent(0.5).cgColor,
            UIColor.blue.withAlphaComponent(0.5).cgColor
        ]

        // Set gradient direction: top-left to bottom-right
        gradientLayer.startPoint = CGPoint(x: 0, y: 0) // top-left
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)   // bottom-right

        gradientLayer.frame = view.bounds

        // Mask with shape path (rounded border only)
        let shapeLayer = CAShapeLayer()
        let insetRect = view.bounds.insetBy(dx: lineWidth / 2, dy: lineWidth / 2)
        shapeLayer.path = UIBezierPath(roundedRect: insetRect, cornerRadius: cornerRadius).cgPath
        shapeLayer.lineWidth = lineWidth
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = UIColor.black.cgColor

        gradientLayer.mask = shapeLayer

        view.layer.addSublayer(gradientLayer)
    }

    // MARK: - Handle OTP Input (Only 1 character allowed)
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == enterPasswordText || textField == confirmPasswordText {
            return true // Allow normal text input for passwords
        }
        
        if string.isEmpty { // Handle backspace
            textField.text = ""
            switch textField {
            case secondOtpDigit:
                firstOtpDigit.becomeFirstResponder()
            case thirdOtpDigit:
                secondOtpDigit.becomeFirstResponder()
            case fourthOtpDigit:
                thirdOtpDigit.becomeFirstResponder()
            default:
                break
            }
            return false
        }
        
        return textField.text!.isEmpty && string.rangeOfCharacter(from: CharacterSet.decimalDigits) != nil
    }

    // MARK: - Combine OTP Digits
    func getOTPString() -> String {
        return (firstOtpDigit.text ?? "") +
               (secondOtpDigit.text ?? "") +
               (thirdOtpDigit.text ?? "") +
               (fourthOtpDigit.text ?? "")
    }

    // MARK: - Reset Password API Call
    func resetPasswordAPI() {
//        guard let email = KeychainWrapper.standard.string(forKey: "emailId") else {
//            print("No email found in Keychain")
//            return
//        }
        
        let otpText = getOTPString()
        guard let newPassword = enterPasswordText.text, !newPassword.isEmpty,
              let confirmPassword = confirmPasswordText.text, !confirmPassword.isEmpty else {
            showAlert(title: "Error", message: "Please enter a new password")
            return
        }
        
        if otpText.count < 4 {
            showAlert(title: "Error", message: "Please enter a valid 4-digit OTP")
            return
        }
        
        if newPassword != confirmPassword {
            showAlert(title: "Error", message: "Passwords do not match")
            return
        }
        let email = emailId
        let params: [String: Any] = [
            "emailId": email,
            "otp": otpText,
            "password": newPassword,
            "confirmPassword": confirmPassword
        ]
        
        AF.request(MainApi.forgotpassword, method: .post, parameters: params, encoding: JSONEncoding.default, headers: nil).response { response in
            debugPrint(response)
            
            switch response.result {
            case .success(let data):
                do {
                    if let jsonOne = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary,
                       let msg = jsonOne["msg"] as? String {
                        DispatchQueue.main.async {
                            if msg == "success reset Password" {
                                self.showAlertSuccess(title: "Success", message: "Password reset successfully")
                            } else {
                                self.showAlert(title: "Error", message: msg)
                            }
                        }
                    } else {
                        self.showAlert(title: "Error", message: "Invalid response from server")
                    }
                } catch {
                    self.showAlert(title: "Error", message: "Failed to parse response")
                }
                
            case .failure(let err):
                self.showAlert(title: "Error", message: "Network error. Please check your connection.")
            }
        }.resume()
    }

    // MARK: - Keyboard Handling
    @objc func keyboardWillShow(notification: NSNotification) {
        if enterPasswordText.isFirstResponder || confirmPasswordText.isFirstResponder,
           let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            let keyboardHeight = keyboardFrame.height
            self.view.frame.origin.y = -keyboardHeight / 2
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if enterPasswordText.isFirstResponder || confirmPasswordText.isFirstResponder {
            self.view.frame.origin.y = 0
        }
    }

    // Dismiss keyboard when pressing return key
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    // MARK: - Alert Functions
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    func showAlertSuccess(title: String, message: String) {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default) { _ in
                self.navigateTologin() // Call navigateToHome when "OK" is tapped
            }
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }

    
    private func navigateTologin(){
          let homeVc =  storyboard?.instantiateViewController(withIdentifier: "LoginViewController")as! LoginViewController
          navigationController?.pushViewController(homeVc, animated: true)
      }
    

    @IBAction func resetPasswordButtonTapped(_ sender: Any) {
        resetPasswordAPI()
    }
}
