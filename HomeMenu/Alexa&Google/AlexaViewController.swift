//
//  AlexaViewController.swift
//  SkromanIsra
//
//  Created by Admin on 24/03/25.
//

import UIKit
import SwiftKeychainWrapper
import Alamofire

class AlexaViewController: UIViewController {

    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var alexaEmail: UITextField!
    @IBOutlet weak var alexaPassword: UITextField!
    @IBOutlet weak var forgetPassword: UIButton!
    @IBOutlet weak var DicoverButton: UIButton!
    @IBOutlet weak var submitButton: UIButton!
    
    @IBOutlet weak var alexaView: UIView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
            // alexaView.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        fetchUserData()
    }

    func fetchUserData() {
        let userId = KeychainWrapper.standard.string(forKey: "userId") ?? ""
        
        guard !userId.isEmpty else {
            print("User ID is missing")
            return
        }
        
        let users = SkromanIsraDatabaseHelper.shared.fetchUserById(userId: userId)
        
        if let user = users.first {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.alexaEmail.text = user.emailId
                self.alexaPassword.text = user.password
               // self.alexaPassword.text =  user.
                print("User data loaded successfully: \(user)")
                
                if user.verifyAlexa?.lowercased() == "true" {
                    self.submitButton.isHidden = true
                    print("Alexa is enabled. Hiding submit button.")
                } else {
                    self.submitButton.isHidden = false
                    print("Alexa is not enabled. Showing submit button.")
                }
            }
        } else {
            print("No user found for userId: \(userId)")
        }
    }
    
    @IBAction func backButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }

    func setupTextFields() {

        let textFields = [alexaEmail, alexaPassword]

        for field in textFields {
            guard let tf = field else { continue }

            tf.backgroundColor = .clear
            tf.layer.cornerRadius = 15
            tf.layer.borderWidth = 1
            tf.layer.borderColor = UIColor.green.cgColor
            tf.clipsToBounds = true
 
        }

        alexaPassword.isSecureTextEntry = true
    }
    
    @IBAction func DiscoverButton(_ sender: Any) {
        print(" Discover button tapped")
        discoverAlexa()
    }

    @IBAction func forgetPassword(_ sender: Any) {
        print(" Forgot Password tapped")
        forget_alexa_password_send_otp()
    }

    @IBAction func submitButton(_ sender: Any) {
        print("Submit button tapped")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    func discoverAlexa(){
        
        let savedLoginEmail = KeychainWrapper.standard.string(forKey: "emailId")

        let paramsAlexa : Parameters = [
            "emailId" : savedLoginEmail ?? ""
        ]
        
        AF.request("http://3.7.18.55:3000/skroman/lambda/devicedetails", method: .post, parameters: paramsAlexa, encoding: JSONEncoding.default, headers: nil).response { [self] response in
            debugPrint(response)
            
            switch response.result
            {
            case .success(let data) :
                do {
                    
                    let jsonOne = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary
                    if response.response?.statusCode == 200 {
                        print(jsonOne!)
                        if let parseJson = jsonOne, let msg = parseJson["msg"] as? String {
                            showPopupSync()
                           
                        }
                        else{
                            self.All_Alert_Type(alertTitle: "Alert", alertMessage: "Unknown error")
                        }
                    }
                    else {
                        print("Error")
                    }
                }
                catch {
                    print(error.localizedDescription)
                    
                }
            case .failure(let err):
                print(err.localizedDescription)
                
            }
        }.resume()
    }
    
    
    @objc func showPopupSync() {
        
        showPopupPresenter.showPopup1(on: self.view,
                                     animationName: "success",
                                     title: "Success!",
                                     subtitle: "Successfully Discover Alexa Devices")
        
       
    }
    func All_Alert_Type(alertTitle : String, alertMessage : String) {
        
        let allAlertBox = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
        
        
        
        let when = DispatchTime.now() + 1.0
        
        DispatchQueue.main.asyncAfter(deadline: when) {
            
            allAlertBox.dismiss(animated: true, completion: nil)
            
        }
        
        
        
        allAlertBox.view.tintColor = UIColor.white
        allAlertBox.view.subviews.first?.subviews.first?.subviews.first?.backgroundColor = UICOLOR_CONTAINER_BG
        
        
        allAlertBox.setValue(NSAttributedString(string: allAlertBox.title!, attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 20, weight: UIFont.Weight.medium), NSAttributedString.Key.foregroundColor : UIColor.white]), forKey: "attributedTitle")
        
        allAlertBox.setValue(NSAttributedString(string: allAlertBox.message ?? "", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.medium), NSAttributedString.Key.foregroundColor : UIColor.white]), forKey: "attributedMessage")
        self.present(allAlertBox, animated: true)
        
    }
    
    func forget_alexa_password_send_otp() {
        guard let email_id = alexaEmail.text, !email_id.isEmpty else {
            showAlert(message: "Please enter your email address.")
            return
        }
        
        let params: Parameters = [
            "emailId": email_id
        ]
        
        AF.request("http://3.7.18.55:3000/skroman/userapi/resendconformAlexa",
                   method: .post,
                   parameters: params,
                   encoding: JSONEncoding.default,
                   headers: nil)
            .validate()
            .responseJSON { response in
                debugPrint(response)
                
                switch response.result {
                case .success(let data):
                    if let json = data as? [String: Any],
                       let msg = json["msg"] as? String {
                        
                        print("✅ API Response: \(json)")
                        
                        if msg == "Resend Alexa confirmation code" {
                            DispatchQueue.main.async {
                                self.showAlert(message: "OTP has been sent to your email.")
                                
                                // Navigate to the top ViewController after a delay
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                    self.navigateToOTP()
                                }
                            }
                        } else {
                            DispatchQueue.main.async {
                                self.showAlert(message: msg)
                            }
                        }
                    }
                    
                case .failure(let error):
                    print("❌ API Request Failed: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.showAlert(message: "Failed to send OTP. Please try again.")
                    }
                }
            }
    }

    
    func showAlert(message: String, title: String = "Alert") {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }

    
    func   navigateToOTP(){
        let vc =  storyboard?.instantiateViewController(withIdentifier: "PasswordResetViewController") as! PasswordResetViewController
        vc.emailId = alexaEmail.text
        navigationController?.pushViewController(vc, animated: true)
        
    }
    
    }

