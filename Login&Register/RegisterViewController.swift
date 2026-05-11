
import UIKit
import Alamofire
import SwiftKeychainWrapper


enum SignUpAPIError: Error {
    case custom(message: String)
}

typealias SignUpHandler = (Swift.Result<Any?, SignUpAPIError>) -> Void

class RegisterViewController: UIViewController, UITextFieldDelegate {
    
    
    @IBOutlet weak var backgroundimage: UIImageView!
    
    
    

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confrimTextField: UITextField!
    @IBOutlet weak var ContactNumberTextFiled: UITextField!
    @IBOutlet weak var registerButton: UIButton!
   
    @IBOutlet weak var appImageView: UIView!
    
    
     
    
    @IBOutlet weak var registerView: UIView!
    
    @IBOutlet weak var backButton: UIButton!
    private var isPasswordVisible = false
        private var isConfirmPasswordVisible = false

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
    
        
        registerButton.backgroundColor = .white
        registerButton.setTitleColor(.black, for: .normal)
        registerButton.layer.cornerRadius = 10
        registerButton.layer.masksToBounds = true

       
        registerButton.tintColor =  .white
        
        configurePasswordField(passwordTextField, isPasswordVisible: &isPasswordVisible)
        configurePasswordField(confrimTextField, isPasswordVisible: &isConfirmPasswordVisible)

        // Set keyboard type for Contact Number
        ContactNumberTextFiled.keyboardType = .numberPad

        // Assign delegates
        emailTextField.delegate = self
        passwordTextField.delegate = self
        confrimTextField.delegate = self
        ContactNumberTextFiled.delegate = self
        
        // Fix for keyboard hang / constraint spam:
        // Disable iOS input assistant (Next/Previous/Done) bar which can produce
        // unsatisfiable constraints like ButtonWrapper.width == 0 on some layouts.
        [emailTextField, passwordTextField, confrimTextField, ContactNumberTextFiled].forEach {
            $0?.disableInputAssistant()
        }
        
        // Keyboard + typing defaults
        emailTextField.keyboardType = .emailAddress
        emailTextField.autocapitalizationType = .none
        emailTextField.autocorrectionType = .no

        // Capsule text fields
        emailTextField.applyCapsuleStyle(textColor: UIColor.white)
        passwordTextField.applyCapsuleStyle(textColor: UIColor.white)
        confrimTextField.applyCapsuleStyle(textColor: UIColor.white)
        ContactNumberTextFiled.applyCapsuleStyle(textColor: UIColor.white)
        
        let gray6 = UIColor(named: "systemGray6") ?? UIColor.systemGray

        emailTextField.attributedPlaceholder = NSAttributedString(
            string: "Enter E-mail Address",
            attributes: [NSAttributedString.Key.foregroundColor: gray6]
        )

        passwordTextField.attributedPlaceholder = NSAttributedString(
            string: "Enter Password",
            attributes: [NSAttributedString.Key.foregroundColor: gray6]
        )

        confrimTextField.attributedPlaceholder = NSAttributedString(
            string: "Enter Confirm Password",
            attributes: [NSAttributedString.Key.foregroundColor: gray6]
        )

        ContactNumberTextFiled.attributedPlaceholder = NSAttributedString(
            string: "Contact Number(optional)",
            attributes: [NSAttributedString.Key.foregroundColor: gray6]
        )

        
        
        emailTextField.setIcon(UIImage(named: "Mail-100")?.withRenderingMode(.alwaysTemplate) ?? UIImage())
        passwordTextField.setIcon(UIImage(named: "Lock-100")?.withRenderingMode(.alwaysTemplate) ?? UIImage())
        confrimTextField.setIcon(UIImage(named: "Lock-100")?.withRenderingMode(.alwaysTemplate) ?? UIImage())
        ContactNumberTextFiled.setIcon(UIImage(named: "contact")?.withRenderingMode(.alwaysTemplate) ?? UIImage())

       
        let dynamicColor = UIColor.label
        emailTextField.leftView?.tintColor = dynamicColor
        passwordTextField.leftView?.tintColor = dynamicColor
        confrimTextField.leftView?.tintColor = dynamicColor
        ContactNumberTextFiled.leftView?.tintColor = dynamicColor

       

       
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        emailTextField.textAlignment = .left
        passwordTextField.textAlignment = .left
        confrimTextField.textAlignment =  .left
        ContactNumberTextFiled.textAlignment = .left
        
        
        appImageView.borderWidth =  0.5
        appImageView.borderColor =  .green
        appImageView.cornerRadius =  15
        appImageView.clipsToBounds =  true
        
        registerView.borderWidth =  0.5
        registerView.borderColor =  .green
        registerView.cornerRadius =  15
        registerView.clipsToBounds =  true
        
       
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
       
      
       
    }

    
    
  
    
    
    @objc func keyboardWillShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        
        // Calculate how much space the keyboard covers
        let keyboardHeight = keyboardFrame.height

        // Move the whole view up only if it hasn’t already moved
        if self.view.frame.origin.y == 0 {
            // Adjust movement depending on which text field is active
            if confrimTextField.isFirstResponder || ContactNumberTextFiled.isFirstResponder {
                self.view.frame.origin.y -= keyboardHeight / 2.2
            } else {
                self.view.frame.origin.y -= keyboardHeight / 3
            }
        }
    }

    @objc func keyboardWillHide(_ notification: Notification) {
        // Reset to original position
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
    }

    
    
    @IBAction func backButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    private func configurePasswordField(_ textField: UITextField, isPasswordVisible: inout Bool) {
           textField.isSecureTextEntry = true
           let toggleButton = UIButton(type: .custom)
           toggleButton.setImage(UIImage(systemName: "eye.slash.fill"), for: .normal)
           toggleButton.setImage(UIImage(systemName: "eye.fill"), for: .selected)
           toggleButton.addTarget(self, action: #selector(togglePasswordVisibility(_:)), for: .touchUpInside)
           toggleButton.tag = textField == passwordTextField ? 1 : 2 // Tag for identifying which text field
           textField.rightView = toggleButton
           textField.rightViewMode = .always
        toggleButton.tintColor =  .gray
       }
       
       @objc private func togglePasswordVisibility(_ sender: UIButton) {
           sender.isSelected.toggle()
           if sender.tag == 1 {
               isPasswordVisible.toggle()
               passwordTextField.isSecureTextEntry = !isPasswordVisible
           } else if sender.tag == 2 {
               isConfirmPasswordVisible.toggle()
               confrimTextField.isSecureTextEntry = !isConfirmPasswordVisible
           }
       }

    deinit {
        // Remove observers
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    



    

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Only apply the restriction to ContactNumberTextFiled
        if textField == ContactNumberTextFiled {
            let currentText = textField.text ?? ""
            let newText = (currentText as NSString).replacingCharacters(in: range, with: string)

            // Allow only numbers and restrict to exactly 10 digits
            let allowedCharacters = CharacterSet.decimalDigits
            let characterSet = CharacterSet(charactersIn: string)

            return allowedCharacters.isSuperset(of: characterSet) && newText.count <= 10
        }
        return true
    }


    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    // MARK: - Register Button Action

    @IBAction func registerButton(_ sender: Any) {
        guard let email = emailTextField.text, !email.isEmpty else {
            self.allAlert(alertTitle: "Email text field is empty", alertMessage: "Please fill in your email.")
            return
        }

        if !email.isValidEmail {
            self.allAlert(alertTitle: "Invalid Email", alertMessage: "Please enter a valid email address.")
            return
        }

        guard let password = passwordTextField.text, !password.isEmpty else {
            self.allAlert(alertTitle: "Password text field is empty", alertMessage: "Please fill in your password.")
            return
        }

        guard password_is_valid(password: password) else {
            self.allAlert(
                alertTitle: "Invalid Password",
                alertMessage: """
                Password must meet the following criteria:
                - At least 6 characters
                - Maximum 16 characters
                - At least one special character
                - At least one lowercase letter
                """
            )
            return
        }

        guard let confirmPassword = confrimTextField.text, !confirmPassword.isEmpty else {
            self.allAlert(alertTitle: "Confirm password text field is empty", alertMessage: "Please confirm your password.")
           
            return
        }

        if password != confirmPassword {
            self.allAlert(alertTitle: "Passwords do not match", alertMessage: "Please ensure your passwords match.")
            return
        }

       

        let contactNumber = ContactNumberTextFiled.text ?? ""

        if !contactNumber.isEmpty {
            if contactNumber.count != 10 || !contactNumber.allSatisfy({ $0.isNumber }) {
                self.allAlert(
                    alertTitle: "Invalid Contact Number",
                    alertMessage: "Please enter a valid 10-digit contact number."
                )
                return
            }
        }


       
        let modelSignUP = SignUpModel(emailId: email, password: password, confirmPassword: confirmPassword, loginType: "skroman")
        setupPostMethod(signUp: modelSignUP) { (result) in
            switch result {
            case .success(let json):
                print(json as AnyObject)
            case .failure(let err):
                print(err.localizedDescription)
            }
        }
    }

    // MARK: - Password Validation Function

    func password_is_valid(password: String) -> Bool {
        let password_reg_ex = "^(?=.*[a-z])(?=.*[$@$#%*?&])[A-Za-z\\d$@$#%*?&]{6,16}$"
        let password_test = NSPredicate(format: "SELF MATCHES %@", password_reg_ex)
        return password_test.evaluate(with: password)
    }

    // MARK: - Alert Function
    
    
    
    @objc func showPopup() {
        PopupPresenter.showPopup(
            on: self.view,
            animationName: "success",
            title: "Success!",
            subtitle: "Registration successful."
        )
    }
    
    
    @objc func showPopupError() {
        PopupPresenter.showPopup(
            on: self.view,
            animationName: "error",
            title: "Error",
            subtitle: "Registration successful."
        )
    }

    func allAlert(alertTitle : String, alertMessage : String) {
        let allAlertBox = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
        allAlertBox.view.tintColor = UIColor.white
        allAlertBox.view.subviews.first?.subviews.first?.subviews.first?.backgroundColor = UICOLOR_CONTAINER_BG
        allAlertBox.setValue(NSAttributedString(string: allAlertBox.title!, attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 20, weight: UIFont.Weight.heavy), NSAttributedString.Key.foregroundColor : UIColor.white]), forKey: "attributedTitle")
        allAlertBox.setValue(NSAttributedString(string: allAlertBox.message!, attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.heavy), NSAttributedString.Key.foregroundColor : UIColor.white]), forKey: "attributedMessage")
        self.present(allAlertBox, animated: true)
        let when = DispatchTime.now() + 4.0
        DispatchQueue.main.asyncAfter(deadline: when) {
            allAlertBox.dismiss(animated: true, completion: nil)
        }
    }
}

private extension UITextField {
    func disableInputAssistant() {
        let item = inputAssistantItem
        item.leadingBarButtonGroups = []
        item.trailingBarButtonGroups = []
    }
}

// MARK: - Networking Setup

extension RegisterViewController {
    func setupPostMethod(signUp: SignUpModel, completionHandler: @escaping SignUpHandler) {
        let params: Parameters = [
            "emailId": signUp.emailId,
            "password": signUp.password,
            "confirmPassword": signUp.confirmPassword,
            "loginType": signUp.loginType
        ]
        print("parameter at register \(params)_")
        AF.request(MainApi.registration, method: .post, parameters: params, encoding: JSONEncoding.default, headers: nil).response { response in
            debugPrint(response)
            switch response.result {
            case .success(let data):
                do {
                    let jsonOne = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary
                    if let parse_json = jsonOne, let msg = parse_json["msg"] as? String {
                        if msg == "Email Address is already registered" {
                            self.allAlert(alertTitle: "Email Address is already registered", alertMessage: "")
                        }else if msg == "User Registration Successfull" {
                            //self.allAlert(alertTitle: "Success", alertMessage: "User Registration Successfully")
                            self.showPopup()
                            // Add a delay of 200ms before navigating to login
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                self.navigateToLogIn()
                            }
                        }
                        
                    }
                } catch {
                    print(error.localizedDescription)
                    completionHandler(.failure(.custom(message: "Please Check Details")))
                }
            case .failure(let err):
                print(err.localizedDescription)
                completionHandler(.failure(.custom(message: "Please Check Details")))
            }
        }.resume()
    }
    
  private func navigateToLogIn(){
        let loginVc =  storyboard?.instantiateViewController(withIdentifier: "LoginViewController")as! LoginViewController
        navigationController?.pushViewController(loginVc, animated: true)
    }
}

// MARK: - Extensions

extension String {
    var isValidEmail: Bool {
        let regularExpressionForEmail = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"
        let testEmail = NSPredicate(format: "SELF MATCHES %@", regularExpressionForEmail)
        return testEmail.evaluate(with: self)
    }
}

extension UITextField {
    func setIcon(_ image: UIImage) {
           let iconSize: CGFloat = 20 // Set a proper icon size
           let padding: CGFloat = 10  // Add left padding

           let iconView = UIImageView(frame: CGRect(x: padding, y: 5, width: iconSize, height: iconSize))
           iconView.image = image.withRenderingMode(.alwaysTemplate) // Ensure tint works
           iconView.tintColor = UIColor.label // ✅ Dynamic color for light & dark mode
           iconView.contentMode = .scaleAspectFit // Ensure it scales correctly

           let iconContainerWidth = iconSize + (2 * padding) // Proper width with padding
           let iconContainerView = UIView(frame: CGRect(x: 0, y: 0, width: iconContainerWidth, height: iconSize + 10))
           iconContainerView.addSubview(iconView)

           leftView = iconContainerView
           leftViewMode = .always
       }
}

struct SignUpModel: Encodable {
    let emailId: String
    let password: String
    let confirmPassword: String
    let loginType: String
}

// MARK: - Extension to Find First Responder

extension UIView {
    var firstResponder: UIResponder? {
        if self.isFirstResponder {
            return self
        }
        for subview in self.subviews {
            if let responder = subview.firstResponder {
                return responder
            }
        }
        return nil
    }
}
