
import UIKit
import Alamofire
import SwiftKeychainWrapper


class OTPEmailViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var backButton: UIButton!
    
    @IBOutlet weak var firstTextField: UITextField!
    
    @IBOutlet weak var secondTextField: UITextField!
    
    @IBOutlet weak var thirdTextField: UITextField!
    
    @IBOutlet weak var verifyButton: UIButton!
    @IBOutlet weak var fourthTextField: UITextField!
    
    var  newEnail : String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    func setupTextFields() {
        let textFields = [firstTextField, secondTextField, thirdTextField, fourthTextField]
        
        for textField in textFields {
            textField?.delegate = self
            textField?.keyboardType = .numberPad
            textField?.textAlignment = .center
            textField?.addTarget(self, action: #selector(textDidChange(_:)), for: .editingChanged)
        }
    }
    
    @objc func textDidChange(_ textField: UITextField) {
        guard let text = textField.text, text.count == 1 else { return }
        
        switch textField {
        case firstTextField:
            secondTextField.becomeFirstResponder()
        case secondTextField:
            thirdTextField.becomeFirstResponder()
        case thirdTextField:
            fourthTextField.becomeFirstResponder()
        case fourthTextField:
            fourthTextField.resignFirstResponder()
            verifyButton.isEnabled = true
        default:
            break
        }
    }
    
    
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string.isEmpty { // Handle backspace
            switch textField {
            case secondTextField:
                firstTextField.becomeFirstResponder()
            case thirdTextField:
                secondTextField.becomeFirstResponder()
            case fourthTextField:
                fourthTextField.becomeFirstResponder()
            default:
                break
            }
            textField.text = ""
            return false
        }
        return textField.text!.count < 1
    }
    
    func getOTPString() -> String {
        return (firstTextField.text ?? "") +
               (secondTextField.text ?? "") +
               (thirdTextField.text ?? "") +
               (fourthTextField.text ?? "")
    }
    
    @IBAction func backButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func verifyButton(_ sender: Any) {
        VerificationOTP()
    }
    
    
    @IBAction func resend(_ sender: Any) {
        VerificationOTP()
    }
    
    func VerificationOTP() {
        guard let email = KeychainWrapper.standard.string(forKey: "emailId") else {
            print("No email found in Keychain")
            return
        }
        
        let otpText = getOTPString()
        if otpText.count < 4 {
            print("Invalid OTP")
            showAlert(title: "Error", message: "Please enter a valid 4-digit OTP")
            return
        }

        let params: [String: Any] = [
            "emailId": newEnail,
            "otp": otpText
        ]

        AF.request(MainApi.verifyOtp, method: .post, parameters: params, encoding: JSONEncoding.default, headers: nil).response { response in
            debugPrint(response)

            switch response.result {
            case .success(let data):
                do {
                    if let jsonString = String(data: data!, encoding: .utf8) {
                        print("JSON Response: \(jsonString)")
                    }

                    let jsonOne = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary
                    
                    if let msg = jsonOne?["msg"] as? String {
                        DispatchQueue.main.async {
                            if msg == "Match OTP" {
                                if let parseJson = jsonOne?["result"] as? NSDictionary {
                                    // ✅ Store user data in Keychain
                                    KeychainWrapper.standard.set(parseJson["_id"] as? String ?? "", forKey: "_id")
                                    KeychainWrapper.standard.set(parseJson["userId"] as? String ?? "", forKey: "userId")
                                    KeychainWrapper.standard.set(parseJson["emailId"] as? String ?? "", forKey: "emailId")
                                    KeychainWrapper.standard.set(parseJson["verifyAlexa"] as? String ?? "", forKey: "verifyAlexa")
                                    KeychainWrapper.standard.set(parseJson["verifyGoogle"] as? String ?? "", forKey: "verifyGoogle")

                                    print("User Verified Successfully!")
                                    print("User ID: \(parseJson["userId"] ?? "N/A")")
                                    print("Email: \(parseJson["emailId"] ?? "N/A")")
                                    
                                    // ✅ Show success alert and navigate to home
                                    self.showAlertSuccess(title: "Success", message: "Login Successfully")
                                }
                            } else if msg == "Not match OTP" {
                             
                                self.showAlert(title: "Incorrect", message: "Incorrect OTP. Please try again.")
                            }
                        }
                    } else {
                        print(" Invalid response structure")
                        self.showAlert(title: "Error", message: "Invalid response from server")
                    }
                } catch {
                    print(" JSON Parsing Error: \(error.localizedDescription)")
                    self.showAlert(title: "Error", message: "Failed to parse response")
                }

            case .failure(let err):
                print(" API Request Failed: \(err.localizedDescription)")
                self.showAlert(title: "Error", message: "Network error. Please check your connection.")
            }
        }.resume()
    }
   
    
}



extension OTPEmailViewController {
    func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }

    func showAlertSuccess(title: String, message: String) {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default) { _ in
                self.navigateToHome()
            }
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    
    private func navigateToHome(){
          let homeVc =  storyboard?.instantiateViewController(withIdentifier: "HomeScreenViewController")as! HomeScreenViewController
          navigationController?.pushViewController(homeVc, animated: true)
      }
}
