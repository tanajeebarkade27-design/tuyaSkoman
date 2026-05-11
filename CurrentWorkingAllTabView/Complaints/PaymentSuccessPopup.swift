//
//  PaymentSuccessPopup.swift
//  SkromanIsra
//
//  Created by Admin on 29/04/26.
//

import UIKit

final class PaymentSuccessPopup: UIView {
    
    struct Details {
        let transactionId: String
        let totalAmount: Double
        let couponOffAmount: Double
        let gstAmount: Double
        let finalAmount: Double
    }
    
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    private let dimView = UIView()
    private let container = UIView()
    private let closeButton = UIButton(type: .system)
    
    private let titleLabel = UILabel()
    private let transactionLabel = UILabel()
    private let totalLabel = UILabel()
    private let couponLabel = UILabel()
    private let gstLabel = UILabel()
    private let finalLabel = UILabel()
    
    private lazy var inrFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 2
        return f
    }()
    
    private func formatINR(_ value: Double) -> String {
        let number = NSNumber(value: value)
        let formatted = inrFormatter.string(from: number) ?? "\(value)"
        return "₹\(formatted)"
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        backgroundColor = .clear
        
        blurView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(blurView)
        
        // Extra dim on top of blur for readability/contrast.
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.25)
        dimView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(dimView)
        let tap = UITapGestureRecognizer(target: self, action: #selector(closeTapped))
        dimView.addGestureRecognizer(tap)
        
        container.backgroundColor = UIColor(white: 0.10, alpha: 1.0)
        container.layer.cornerRadius = 18
        container.translatesAutoresizingMaskIntoConstraints = false
        addSubview(container)
        
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .white
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(closeButton)
        
        titleLabel.text = "Payment Success"
        titleLabel.textColor = .systemGreen
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(titleLabel)
        
        [transactionLabel, totalLabel, couponLabel, gstLabel, finalLabel].forEach {
            $0.textColor = UIColor.white.withAlphaComponent(0.92)
            $0.font = UIFont.systemFont(ofSize: 14, weight: .regular)
            $0.numberOfLines = 0
            $0.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview($0)
        }
        
        finalLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            dimView.topAnchor.constraint(equalTo: topAnchor),
            dimView.leadingAnchor.constraint(equalTo: leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: trailingAnchor),
            dimView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            container.centerYAnchor.constraint(equalTo: centerYAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            container.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18),
            
            closeButton.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            closeButton.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30),
            
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: closeButton.leadingAnchor, constant: -10),
            
            transactionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 14),
            transactionLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            transactionLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            
            totalLabel.topAnchor.constraint(equalTo: transactionLabel.bottomAnchor, constant: 10),
            totalLabel.leadingAnchor.constraint(equalTo: transactionLabel.leadingAnchor),
            totalLabel.trailingAnchor.constraint(equalTo: transactionLabel.trailingAnchor),
            
            couponLabel.topAnchor.constraint(equalTo: totalLabel.bottomAnchor, constant: 10),
            couponLabel.leadingAnchor.constraint(equalTo: transactionLabel.leadingAnchor),
            couponLabel.trailingAnchor.constraint(equalTo: transactionLabel.trailingAnchor),
            
            gstLabel.topAnchor.constraint(equalTo: couponLabel.bottomAnchor, constant: 10),
            gstLabel.leadingAnchor.constraint(equalTo: transactionLabel.leadingAnchor),
            gstLabel.trailingAnchor.constraint(equalTo: transactionLabel.trailingAnchor),
            
            finalLabel.topAnchor.constraint(equalTo: gstLabel.bottomAnchor, constant: 12),
            finalLabel.leadingAnchor.constraint(equalTo: transactionLabel.leadingAnchor),
            finalLabel.trailingAnchor.constraint(equalTo: transactionLabel.trailingAnchor),
            finalLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16),
        ])
    }
    
    func configure(with details: Details) {
        transactionLabel.text = "Transaction ID: \(details.transactionId)"
        totalLabel.text = "Total Amount: \(formatINR(details.totalAmount))"
        couponLabel.text = "Coupon Off: -\(formatINR(details.couponOffAmount))"
        gstLabel.text = "GST: \(formatINR(details.gstAmount))"
        finalLabel.text = "Paid Amount: \(formatINR(details.finalAmount))"
    }
    
    func present(in parent: UIView) {
        frame = parent.bounds
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        alpha = 0
        parent.addSubview(self)
        UIView.animate(withDuration: 0.2) {
            self.alpha = 1
        }
    }
    
    @objc private func closeTapped() {
        UIView.animate(withDuration: 0.18, animations: {
            self.alpha = 0
        }, completion: { _ in
            self.removeFromSuperview()
        })
    }
}

