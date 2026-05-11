//
//  AddNewHomePopUp.swift
//  SkromanIsra
//
//  Created by Admin on 02/06/25.
//

 

import UIKit
import SwiftKeychainWrapper
protocol AddHomePopupViewDelegate: AnyObject {
    func showSuccessPopup()
}

class AddHomePopupView: UIView {
    
    var userID: String?
    weak var delegate: AddHomePopupViewDelegate?

    // UI Elements
    private let label: UILabel = {
        let label = UILabel()
        label.text = "Enter Home Name"
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let textField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Home Name"
        textField.borderStyle = .roundedRect
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let okButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("OK", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .white
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()


    
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("X", for: .normal)
        button.setTitleColor(.systemYellow, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let loading = UIActivityIndicatorView(style: .medium)
    
    // Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupActions()
        loadUserID()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        setupActions()
        loadUserID()
    }
    
    private func loadUserID() {
        if let savedUserID = KeychainWrapper.standard.string(forKey: "userId") {
            self.userID = savedUserID
            print("Saved User ID: \(savedUserID)")
        } else {
            print("No user ID found in Keychain")
        }
    }
    
    private func setupView() {
        self.backgroundColor = UIColor(white: 0.10, alpha: 1.0)
        self.layer.cornerRadius = 12
        self.layer.shadowColor = UIColor.systemGray.cgColor
        self.layer.shadowOpacity = 0.3
        self.layer.shadowOffset = CGSize(width: 0, height: 2)
        self.layer.shadowRadius = 6

        // Capsule text field
        textField.applyCapsuleStyle(
            height: 44,
            backgroundColor: UIColor.white.withAlphaComponent(0.10),
            borderColor: UIColor.white.withAlphaComponent(0.14),
            textColor: UIColor.white,
            placeholderColor: UIColor.white.withAlphaComponent(0.55)
        )
        
        self.addSubview(label)
        self.addSubview(textField)
        self.addSubview(okButton)
        self.addSubview(closeButton)
        loading.translatesAutoresizingMaskIntoConstraints = false
        loading.hidesWhenStopped = true
        loading.color = .white
        addSubview(loading)
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: self.topAnchor, constant: 20),
            label.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            
            textField.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 20),
            textField.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            textField.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20),
            textField.heightAnchor.constraint(equalToConstant: 40),
            
            okButton.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 20),
            okButton.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            okButton.heightAnchor.constraint(equalToConstant: 40),
            okButton.widthAnchor.constraint(equalToConstant: 100),
            
            loading.centerYAnchor.constraint(equalTo: okButton.centerYAnchor),
            loading.leadingAnchor.constraint(equalTo: okButton.trailingAnchor, constant: 10),
            
            closeButton.topAnchor.constraint(equalTo: self.topAnchor, constant: 10),
            closeButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -10)
        ])
    }
    
    private func setupActions() {
        okButton.addTarget(self, action: #selector(handleOkButton), for: .touchUpInside)
        closeButton.addTarget(self, action: #selector(handleCloseButton), for: .touchUpInside)
    }
    
    @objc private func handleOkButton() {
        guard let homeName = textField.text, !homeName.isEmpty else {
            print("Please enter a home name.")
            return
        }
        
        print("Entered Home Name: \(homeName)")
        print("User ID in Popup: \(userID ?? "No User ID")")
        
        
        // Keep popup alive while API runs (prevents blur getting stuck).
        okButton.isEnabled = false
        closeButton.isEnabled = false
        loading.startAnimating()
        
        if let userId = userID {
            uploadHomeWithoutImage(userId: userId, homeName: homeName)
        } else {
            print("User ID is missing.")
            NotificationCenter.default.post(name: .addHomePopupDismissed, object: nil)
            self.removeFromSuperview()
        }
    }

    @objc private func handleCloseButton() {
        NotificationCenter.default.post(name: .addHomePopupDismissed, object: nil)
        self.removeFromSuperview()
    }


    func uploadHomeWithoutImage(userId: String, homeName: String) {
        let url = MainApi.url("skroman/homeapi/v2/home")
        
        let parameters: [String: Any] = [
            "userId": userId,
            "homeName": homeName
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: parameters, options: []) else {
            print("Failed to encode JSON")
            return
        }
        
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.loading.stopAnimating()
                    self.okButton.isEnabled = true
                    self.closeButton.isEnabled = true
                    NotificationCenter.default.post(name: .addHomePopupDismissed, object: nil)
                    self.removeFromSuperview()
                }
                return
            }
            
           
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 Status Code: \(httpResponse.statusCode)")
                print("📨 Headers: \(httpResponse.allHeaderFields)")
            }
            
           
            if let data = data {
                let raw = String(data: data, encoding: .utf8)
                print("📥 Raw Response Body:\n\(raw ?? "Unable to decode")")
                
                do {
                    if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        print("📦 Parsed JSON Response: \(jsonResponse)")
                        
                        if let msg = jsonResponse["msg"] as? String, msg == "Home inserted success" {
                            
                            if let homeServerId = jsonResponse["homeId"] as? String {
                                let homeName = jsonResponse["homeName"] as? String
                                let homeUrl: String? = nil
                                
                                print("🏠 Inserted Home ID: \(homeServerId)")
                                
                                SkromanIsraDatabaseHelper.shared.insertHome(
                                    homeServerId: homeServerId,
                                    homeName: homeName,
                                    homeUrl: homeUrl, tuyaHomeId: -1, isFamilyHome: 0
                                )
                                
                                SkromanIsraDatabaseHelper.shared.updateHome(
                                    homeServerId: homeServerId,
                                    newHomeName: homeName ?? "",
                                    newHomeUrl: homeUrl, tuyaHomeId: -1
                                )
                                
                                DispatchQueue.main.async {
                                    self.delegate?.showSuccessPopup()
                                    NotificationCenter.default.post(name: .homeAdded, object: nil)
                                    NotificationCenter.default.post(name: .addHomePopupDismissed, object: nil)
                                    self.removeFromSuperview()
                                }
                            }
                        }
                    }
                } catch {
                    print("❌ Error parsing JSON: \(error)")
                    DispatchQueue.main.async {
                        self.loading.stopAnimating()
                        self.okButton.isEnabled = true
                        self.closeButton.isEnabled = true
                        NotificationCenter.default.post(name: .addHomePopupDismissed, object: nil)
                        self.removeFromSuperview()
                    }
                }
            }
        }.resume()
    }



   
//    @objc func showPopup() {
//        DispatchQueue.main.async {
//            self.delegate?.showSuccessPopup()
//        }
//    }



}

extension Notification.Name {
    static let homeAdded = Notification.Name("homeAdded")
    static let addHomePopupDismissed = Notification.Name("addHomePopupDismissed")
}
