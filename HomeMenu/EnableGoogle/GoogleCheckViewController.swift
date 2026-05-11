//
//  GoogleCheckViewController.swift
//  SkromanIsra
//
//  Created by Admin on 26/03/25.
//

import UIKit
import SwiftKeychainWrapper
import Alamofire


class GoogleCheckViewController: UIViewController {
    
    @IBOutlet weak var backButton: UIButton!
    
    @IBOutlet weak var emailIdText: UITextField!
    
    @IBOutlet weak var submitButton: UIButton!
    
    @IBOutlet weak var passwordText: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        fetchUserData()
    }
  
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
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
                self.emailIdText.text = user.emailId
                self.passwordText.text = user.password
               // self.alexaPassword.text =  user.
                print("User data loaded successfully: \(user)")
                
                if user.verifyGoogle?.lowercased() == "true" {
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
    

    @IBAction func submitButton(_ sender: Any) {
    }
    
    
    
}
