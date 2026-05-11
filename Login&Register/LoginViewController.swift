//
//  LoginViewController.swift
//  SkromanIsra
//
//  Created by Admin on 21/01/25.
//
import UIKit
import SwiftKeychainWrapper
import NVActivityIndicatorView
import Alamofire

enum APIErrorLogin: Error {
    case custom(message: String)
}

typealias LoginHandler = (Result<Any?, APIErrorLogin>) -> Void

class LoginViewController: UIViewController {
    
   
    @IBOutlet weak var backgroundimage: UIImageView!
    
    @IBOutlet weak var appBackgroundView: UIView!
    @IBOutlet weak var emailTextfiled: UITextField!
    @IBOutlet weak var loginView: UIView!
    @IBOutlet weak var passwordTextFiled: UITextField!
    
    @IBOutlet weak var getstartbutton: UIButton!
    private let showPasswordButton = UIButton(type: .custom)
    
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

        appBackgroundView.borderWidth =  0.5
        appBackgroundView.borderColor =  .green
        appBackgroundView.cornerRadius =  15
        appBackgroundView.clipsToBounds =  true
        
        loginView.borderWidth =  0.5
        loginView.borderColor =  .green
        loginView.cornerRadius =  15
        loginView.clipsToBounds =  true

        setupPasswordField()
        
        // Capsule text fields
        emailTextfiled.placeholder = "Enter Your Registered E-mail address"
        passwordTextFiled.placeholder = "Please Enter Correct Password"
        emailTextfiled.applyCapsuleStyle(textColor: UIColor.white)
        passwordTextFiled.applyCapsuleStyle(textColor: UIColor.white)
        emailTextfiled.keyboardType = .emailAddress
        emailTextfiled.autocapitalizationType = .none
        emailTextfiled.autocorrectionType = .no
        
        getstartbutton.tintColor = .white
        loginView.clipsToBounds = true
      
        getstartbutton.backgroundColor = .white
        getstartbutton.setTitleColor(.black, for: .normal) // text color
        getstartbutton.layer.cornerRadius = 10
        getstartbutton.layer.masksToBounds = true
        

        emailTextfiled.textAlignment = .left
        passwordTextFiled.textAlignment = .left

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow),
                                               name: UIResponder.keyboardWillShowNotification, object: nil)
        
        let tapGesture = UITapGestureRecognizer(
                target: self,
                action: #selector(dismissKeyboard)
            )
            tapGesture.cancelsTouchesInView = false
            view.addGestureRecognizer(tapGesture)
        
        disableSmartFeatures()

    }
    @objc func keyboardWillShow(notification: Notification) {
        if view.frame.origin.y == 0 {
            view.frame.origin.y -= 150   
        }
    }
    private func styleTextFields() {
        [emailTextfiled, passwordTextFiled].forEach {
            $0?.backgroundColor = .clear
            $0?.borderStyle = .none
            $0?.layer.borderWidth = 0
            $0?.layer.cornerRadius = 0
        }
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }


    func disableSmartFeatures() {
        let fields = [emailTextfiled, passwordTextFiled]

        fields.forEach { field in
            field?.autocorrectionType = .no
            field?.autocapitalizationType = .none
            field?.spellCheckingType = .no
            field?.smartQuotesType = .no
            field?.smartDashesType = .no
            field?.smartInsertDeleteType = .no
        }

        emailTextfiled.keyboardType = .emailAddress
        passwordTextFiled.keyboardType = .default
        passwordTextFiled.textContentType = .oneTimeCode  // best for no suggestions
    }

    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
      
 
       
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    
   
   
    
    func setupPasswordField() {
        let eyeClosedImage = UIImage(systemName: "eye.slash")?.withTintColor(.gray, renderingMode: .alwaysOriginal)
        let eyeOpenImage = UIImage(systemName: "eye")?.withTintColor(.gray, renderingMode: .alwaysOriginal)
        
        showPasswordButton.setImage(eyeClosedImage, for: .normal)
        showPasswordButton.setImage(eyeOpenImage, for: .selected)
        showPasswordButton.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
        showPasswordButton.addTarget(self, action: #selector(togglePasswordVisibility), for: .touchUpInside)
        
        passwordTextFiled.rightView = showPasswordButton
        passwordTextFiled.rightViewMode = .always
        passwordTextFiled.isSecureTextEntry = true
        passwordTextFiled.layer.cornerRadius = 8.0
    }
    
    @objc func togglePasswordVisibility() {
        passwordTextFiled.isSecureTextEntry.toggle()
        showPasswordButton.isSelected.toggle()
    }
    func addGradientBorder(to view: UIView, cornerRadius: CGFloat, lineWidth: CGFloat) {
        // Remove existing gradient layer (if any)
        view.layer.sublayers?.removeAll(where: { $0.name == "GradientBorder" })

        let gradientLayer = CAGradientLayer()
        gradientLayer.name = "GradientBorder"
        gradientLayer.colors = [
            UIColor.green.withAlphaComponent(0.5).cgColor,
            UIColor.blue.withAlphaComponent(0.5).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 1) // bottom-left
        gradientLayer.endPoint = CGPoint(x: 1, y: 0)   // top-right
        gradientLayer.frame = view.bounds

        // Create border shape path
        let shapeLayer = CAShapeLayer()
        let insetRect = view.bounds.insetBy(dx: lineWidth / 2, dy: lineWidth / 2)
        shapeLayer.path = UIBezierPath(roundedRect: insetRect, cornerRadius: cornerRadius).cgPath
        shapeLayer.lineWidth = lineWidth
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = UIColor.black.cgColor

        // Apply the mask to only stroke edges
        gradientLayer.mask = shapeLayer

        view.layer.addSublayer(gradientLayer)
    }



    @IBAction func emailTextField(_ sender: Any) {
    }
    
    @IBAction func passwordTextField(_ sender: Any) {
    }
    
    @IBAction func loginButton(_ sender: Any) {
        let email = emailTextfiled.text
        let password = passwordTextFiled.text
        
    let save_login_password = KeychainWrapper.standard.set(passwordTextFiled.text!, forKey: "login_password")
        
        let modelLogin = LoginModel(emailId: email!, password: password!)
        loginMethod(login: modelLogin) { (result) in
            
            switch result {
                
            case .success(let json):
                
                print(json as AnyObject)
                
            case .failure(let err):
                
                print(err.localizedDescription)
            }
            
        }
    }
    
    
    
    func startAnimating() {
      let loading = NVActivityIndicatorView(frame: .zero, type: .ballRotateChase, color: .white, padding: 0)
        
        loading.translatesAutoresizingMaskIntoConstraints = false
        
        
        view.addSubview(loading)
        
        NSLayoutConstraint.activate([
            
            loading.widthAnchor.constraint(equalToConstant: 40),
            loading.heightAnchor.constraint(equalToConstant: 40),
            
            loading.topAnchor.constraint(equalTo: view.centerYAnchor, constant: 150),
            loading.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loading.centerYAnchor.constraint(equalTo: view.topAnchor)
            
        ])
        
        loading.startAnimating()
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
            
            loading.stopAnimating()
            
        }
    }
    
    @IBAction func forgetpasswordbutton(_ sender: Any) {
        navigateforgetpassword()
    }
    
    @IBAction func registerButton(_ sender: Any) {
        
        navigateToRegister()
    }
}


extension LoginViewController {
    func loginMethod(login: LoginModel, completionHandler: @escaping LoginHandler) {
        guard let userEmail = self.emailTextfiled.text, !userEmail.isEmpty else {
            self.showAlert(title: "Alert", message: "Please enter an email")
            return
        }
        guard let userPassword = self.passwordTextFiled.text, !userPassword.isEmpty else {
            self.showAlert(title: "Alert", message: "Please enter a password")
            return
        }

        let loginParams: Image_Parameters = [
            "emailId": userEmail,
            "password": userPassword
        ]

        print("loginParams: \(loginParams)")

        AF.request(MainApi.loginUrl, method: .post, parameters: loginParams, encoding: JSONEncoding.default).response { response in
            debugPrint(response)

            switch response.result {
            case .success(let data):
                do {
                    guard let data = data else {
                        self.showAlert(title: "Alert", message: "No response from server")
                        return
                    }

                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let msg = json["msg"] as? String {
                        
                        DispatchQueue.main.async {
                            if msg == "enter vaild password" {
                                self.showAlert(title: "Alert", message: msg)
                                
                            } else if msg == "success match password" || msg == "Succes match Password and test user" {
                                // ✅ success login message
                                self.showAlertSuccess(title: "Success", message: "OTP has been sent to your email")

                                 
//                                KeychainWrapper.standard.set(userEmail, forKey: "emailId")
//                                KeychainWrapper.standard.set(userPassword, forKey: "login_password")

                                // TODO: Navigate to next screen if needed
                                // self.navigateToHome()

                            } else if msg == "User is not Registered" {
                                self.showAlert(title: "Not Registered", message: "User not registered")
                                
                            } else {
                                self.showAlert(title: "Alert", message: "Please check the details")
                            }
                        }
                    } else {
                        self.showAlert(title: "Alert", message: "Invalid response from server")
                    }
                } catch {
                    print("❌ JSON parse error: \(error.localizedDescription)")
                    completionHandler(.failure(.custom(message: "Please check the details")))
                }

            case .failure(let err):
                print("❌ Request error: \(err.localizedDescription)")
                completionHandler(.failure(.custom(message: "Please check the details")))
            }
        }.resume()
    }

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
                self.navigateToOTP()
            }
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }


    
    private func navigateforgetpassword(){
          let forgetPaawordVc =  storyboard?.instantiateViewController(withIdentifier: "ForgetPasswordViewController")as! ForgetPasswordViewController
          navigationController?.pushViewController(forgetPaawordVc, animated: true)
      }
    private func navigateToRegister(){
          let forgetPaawordVc =  storyboard?.instantiateViewController(withIdentifier: "RegisterViewController")as! RegisterViewController
          navigationController?.pushViewController(forgetPaawordVc, animated: true)
      }
    
    private func navigateToOTP(){
          let oTPvc =  storyboard?.instantiateViewController(withIdentifier: "OTPVerificationViewController")as! OTPVerificationViewController
        oTPvc.emailId = emailTextfiled.text
        oTPvc.password = passwordTextFiled.text
          navigationController?.pushViewController(oTPvc, animated: true)
      }
    
}




struct LoginModel: Encodable {
    
    let emailId : String
    let password : String
}
