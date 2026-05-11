//
//  TermsAndConditionsViewController.swift
//  SkromanIsra
//
//  Created by Admin on 29/04/26.
//

import UIKit

final class TermsAndConditionsViewController: UIViewController {
    
    var onAccepted: (() -> Void)?
    /// When `true`, this screen becomes read-only (shows only terms text).
    var isReadOnly: Bool = false
    
    private let backButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let scrollView = UIScrollView()
    private let contentLabel = UILabel()
    
    private let checkboxButton = UIButton(type: .system)
    private let acceptLabel = UILabel()
    
    private let acceptButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)
    
    private var scrollViewBottomToCheckboxConstraint: NSLayoutConstraint?
    private var scrollViewBottomToSafeAreaConstraint: NSLayoutConstraint?
    
    private var isAccepted = false {
        didSet { updateAcceptanceUI() }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        let backgroundImage = UIImageView(image: UIImage(named: "Screen Background"))
        backgroundImage.contentMode = .scaleAspectFill
        view.insertSubview(backgroundImage, at: 0)
        backgroundImage.translatesAutoresizingMaskIntoConstraints = false
        backgroundImage.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        backgroundImage.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        backgroundImage.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        backgroundImage.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
    }
    
    private func setupUI() {
        view.backgroundColor = .clear
        acceptButton.backgroundColor = .white
        
        backButton.setTitle("Back", for: .normal)
        backButton.setTitleColor(.white, for: .normal)
        backButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        backButton.contentHorizontalAlignment = .leading
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backButton)
        titleLabel.text = "Terms & Conditions"
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        contentLabel.text = Self.termsText
        contentLabel.textColor = UIColor.white.withAlphaComponent(0.92)
        contentLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        contentLabel.numberOfLines = 0
        contentLabel.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentLabel)
        
        checkboxButton.setTitle("☐", for: .normal)
        checkboxButton.titleLabel?.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        checkboxButton.tintColor = .white
        checkboxButton.setTitleColor(.white, for: .normal)
        checkboxButton.addTarget(self, action: #selector(toggleAccepted), for: .touchUpInside)
        checkboxButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(checkboxButton)
        
        acceptLabel.text = "I accept the terms and conditions"
        acceptLabel.textColor = UIColor.white.withAlphaComponent(0.9)
        acceptLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        acceptLabel.numberOfLines = 0
        acceptLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(acceptLabel)
        
        acceptButton.setTitle("Accept & Submit", for: .normal)
        acceptButton.backgroundColor = UIColor.systemBlue
        acceptButton.setTitleColor(.white, for: .normal)
        acceptButton.layer.cornerRadius = 12
        acceptButton.addTarget(self, action: #selector(acceptTapped), for: .touchUpInside)
        acceptButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(acceptButton)
        
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.backgroundColor = UIColor.white.withAlphaComponent(0.18)
        cancelButton.setTitleColor(.white, for: .normal)
        cancelButton.layer.cornerRadius = 12
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cancelButton)
        
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            scrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            contentLabel.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentLabel.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentLabel.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentLabel.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            checkboxButton.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 12),
            checkboxButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            checkboxButton.widthAnchor.constraint(equalToConstant: 30),
            checkboxButton.heightAnchor.constraint(equalToConstant: 30),
            
            acceptLabel.centerYAnchor.constraint(equalTo: checkboxButton.centerYAnchor),
            acceptLabel.leadingAnchor.constraint(equalTo: checkboxButton.trailingAnchor, constant: 10),
            acceptLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            cancelButton.topAnchor.constraint(equalTo: checkboxButton.bottomAnchor, constant: 16),
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            cancelButton.heightAnchor.constraint(equalToConstant: 46),
            
            acceptButton.topAnchor.constraint(equalTo: checkboxButton.bottomAnchor, constant: 16),
            acceptButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            acceptButton.heightAnchor.constraint(equalToConstant: 46),
            
            cancelButton.trailingAnchor.constraint(equalTo: view.centerXAnchor, constant: -8),
            acceptButton.leadingAnchor.constraint(equalTo: view.centerXAnchor, constant: 8),
            
            acceptButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -14),
            cancelButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -14),
        ])

        scrollViewBottomToCheckboxConstraint = scrollView.bottomAnchor.constraint(equalTo: checkboxButton.topAnchor, constant: -12)
        scrollViewBottomToSafeAreaConstraint = scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -14)
        scrollViewBottomToCheckboxConstraint?.isActive = true
        
        updateAcceptanceUI()
        applyReadOnlyModeIfNeeded()
    }
    
    private func applyReadOnlyModeIfNeeded() {
        guard isReadOnly else { return }
        
        checkboxButton.isHidden = true
        acceptLabel.isHidden = true
        acceptButton.isHidden = true
        cancelButton.isHidden = true
        
        scrollViewBottomToCheckboxConstraint?.isActive = false
        scrollViewBottomToSafeAreaConstraint?.isActive = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }

    private func updateAcceptanceUI() {
        guard !isReadOnly else { return }
        checkboxButton.setTitle(isAccepted ? "☑︎" : "☐", for: .normal)
        acceptButton.isEnabled = isAccepted
        acceptButton.alpha = isAccepted ? 1.0 : 0.5
    }
    
    @objc private func toggleAccepted() {
        guard !isReadOnly else { return }
        isAccepted.toggle()
    }
    
    @objc private func acceptTapped() {
        guard !isReadOnly else { return }
        guard isAccepted else { return }
        onAccepted?()
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func cancelTapped() {
        guard !isReadOnly else { return }
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    private static let termsText = """
    1. Free Service Visit (Initial Period)
    • From the date of installation, no visiting charges will be applicable during the initial one-year period.

    2. Service Visit Charges (After 1 Year)
    • After the initial one-year period, a visit charge of ₹500 per visit will be applicable.
    • (This charge will be valid for 3 months for the same device.)

    3. Installation Charges
    • The first installation is provided free of cost.
    • Any subsequent installation or reinstallation will be charged at ₹1500 per device/lock.
    • If the product is removed or reinstalled by the customer, the warranty will be void.

    4. Warranty Void Conditions & Repair Charges
    • The warranty will be considered void under the following conditions:
      • Physical damage
      • Mishandling
      • Water damage
      • Removal or tampering of the home automation system by the customer

    • In such cases:
      • Repair charges will be ₹2000 per device/lock
      • A 1-year warranty will be provided after repair

    5. Post Warranty (After 5 Years)
    • Repair charges: ₹2000 per lock
    • No additional warranty will be applicable

    6. Dummy Point Activation Charges
    • Activation of the first dummy point: ₹2500
    • Activation of additional dummy points on the same device: ₹1000 per point
    """
}

