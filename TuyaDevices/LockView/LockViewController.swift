//
//  LockViewController.swift
//  SkromanIsra
//
//  Created by Admin on 31/03/26.
//

import UIKit
import ThingSmartHomeKit
import SwiftKeychainWrapper


class LockViewController: UIViewController {
    
    var homeId: String?
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var otpTextField: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("📌 Received homeId:", homeId ?? "nil")
        
       
    }
    

    
    
    @IBAction func email(_ sender: Any) {
    }
    
    
    @IBAction func password(_ sender: Any) {
    }
    
    @IBAction func sendOTP(_ sender: Any) {
        
        guard let email = emailTextField.text, !email.isEmpty else {
            print("❌ Enter email")
            return
        }
        
        ThingSmartUser.sharedInstance().sendVerifyCode(
            withUserName: email,
            region: "EU",
            countryCode: "91",
            type: 1,                  
           
            success: {
                print("✅ OTP sent")
                
                self.showAlert(title: "Success", message: "OTP sent to your email")
                
            },
            failure: { error in
                print("❌ OTP failed:", error?.localizedDescription ?? "")
                
                self.showAlert(
                    title: "Error",
                    message: error?.localizedDescription ?? "Failed to send OTP"
                )
            }
        )
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    @IBAction func register(_ sender: Any) {
        guard let email = emailTextField.text, !email.isEmpty else {
            print(" Enter email\(email)")
            return
        }
        guard let password = passwordTextField.text, !email.isEmpty else {
            print("password \(password)")
            return
        }
        
        ThingSmartUser.sharedInstance().login(
            byEmail: "91",
            email: email,
            password: password,
            success: {
                print("✅ Tuya registration success")
                
            },
            failure: { error in
                let msg = error?.localizedDescription.lowercased() ?? ""
                print("Registration failed:", msg)
                
                
                
                
                
                self.showAlert(
                    title: "Registration Failed",
                    message: error?.localizedDescription ?? "Please try again"
                )
            }
        )
    }
        
    func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
    
    
   
}
