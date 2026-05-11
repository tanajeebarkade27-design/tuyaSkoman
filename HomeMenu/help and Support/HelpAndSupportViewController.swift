//
//  HelpAndSupportViewController.swift
//  SkromanIsra
//
//  Created by Admin on 01/08/25.
//

import UIKit

class HelpAndSupportViewController: UIViewController {

    @IBOutlet weak var supportbackgroundView: UIView!
    @IBOutlet weak var contactNumberLabel: UILabel!
    @IBOutlet weak var gmailImage: UIImageView!
    @IBOutlet weak var whatsappImageView: UIImageView!
    @IBOutlet weak var webSiteView: UIImageView!
    @IBOutlet weak var supportView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        supportView.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        supportbackgroundView.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        supportbackgroundView.layer.cornerRadius = 15
        supportbackgroundView.clipsToBounds = true
        
        supportView.layer.cornerRadius = 10
        supportView.clipsToBounds = true
        setupWhatsAppTap()
        setupGmailTap()
        websiteTap()
        setupPhoneTap()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    private func setupGmailTap() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(gmailTapped))
        gmailImage.isUserInteractionEnabled = true
        gmailImage.addGestureRecognizer(tapGesture)
    }
    @objc private func gmailTapped() {
        let gmailURL = URL(string: "googlegmail://co?to=support@skromanglobal.com")!
        let mailtoURL = URL(string: "mailto:Support@gmail.com")!
        
        if UIApplication.shared.canOpenURL(gmailURL) {
            UIApplication.shared.open(gmailURL, options: [:], completionHandler: nil)
        } else if UIApplication.shared.canOpenURL(mailtoURL) {
            UIApplication.shared.open(mailtoURL, options: [:], completionHandler: nil)
        } else {
            
            print("Neither Gmail app nor Mail app is available.")
        }
    }

    
    private func setupWhatsAppTap() {
        print("Setting up WhatsApp Tap")
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(whatsappTapped))
        whatsappImageView.isUserInteractionEnabled = true
        whatsappImageView.addGestureRecognizer(tapGesture)
    }

    @objc private func whatsappTapped() {
        print("WhatsApp image tapped")
        let phoneNumber = "919699206295"  // REMOVE the '+'
        if let url = URL(string: "https://wa.me/\(phoneNumber)") {
            print("Opening URL: \(url)")
            UIApplication.shared.open(url)
        } else {
            print("Invalid WhatsApp URL.")
        }
    }
    private func websiteTap() {
        print("Setting up WhatsApp Tap")
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(websiteTapped))
        webSiteView.isUserInteractionEnabled = true
        webSiteView.addGestureRecognizer(tapGesture)
    }

    @objc private func websiteTapped() {
    
     
        if let url = URL(string: "https://skromanglobal.com") {
            print("Opening URL: \(url)")
            UIApplication.shared.open(url)
        } else {
            print("Invalid WhatsApp URL.")
        }
    }
    
    private func setupPhoneTap() {
        print("Setting up phone tap")
        let tap = UITapGestureRecognizer(target: self, action: #selector(phoneTapped))
        contactNumberLabel.isUserInteractionEnabled = true
        contactNumberLabel.addGestureRecognizer(tap)
    }

    @objc private func phoneTapped() {
        let phoneNumber = "9699206295"
        if let phoneURL = URL(string: "tel://\(phoneNumber)") {
            print("Dialing: \(phoneURL)")
            UIApplication.shared.open(phoneURL, options: [:], completionHandler: nil)
        } else {
            print("Invalid phone number URL.")
        }
    }



    @IBAction func backButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
}

