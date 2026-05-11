//
//  QRPopupViewController.swift
//  SkromanIsra
//
//  Created by Admin on 16/02/26.
//


import UIKit

class QRPopupViewController: UIViewController {
    var qrData: QRPopupData?
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let qrImageView = UIImageView()
    private let validLabel = UILabel()
    private let shareButton = UIButton(type: .system)
    private let closeButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    func setupUI() {

        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)

        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 15
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)

        NSLayoutConstraint.activate([
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 300)
        ])

        // Title
        titleLabel.text = "Share QR Code With Visitor"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        titleLabel.textAlignment = .center

        // QR
        qrImageView.contentMode = .scaleAspectFit
        let payload = makeQRPayload(from: qrData)
        qrImageView.image = generateQRCode(from: payload)

        // Valid date
        validLabel.text = "Valid till: \(formatDate(qrData?.expiresAt))"

        validLabel.font = UIFont.systemFont(ofSize: 14)
        validLabel.textAlignment = .center
        validLabel.textColor = .black

        // Share button
        shareButton.setTitle("Share", for: .normal)
        shareButton.backgroundColor = .systemGreen
        shareButton.setTitleColor(.white, for: .normal)
        shareButton.layer.cornerRadius = 8
        shareButton.addTarget(self, action: #selector(shareTapped), for: .touchUpInside)

        // Close button
        closeButton.setTitle("Close", for: .normal)
        closeButton.setTitleColor(.systemRed, for: .normal)
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [
            titleLabel,
            qrImageView,
            validLabel,
            shareButton,
          
        ])

        stack.axis = .vertical
        stack.spacing = 15
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20),

            qrImageView.heightAnchor.constraint(equalToConstant: 180),
            shareButton.heightAnchor.constraint(equalToConstant: 44),
            
        ])
        
        closeButton.setTitle("✕", for: .normal)
        closeButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        closeButton.setTitleColor(.black, for: .normal)
        closeButton.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(closeButton)

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            closeButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30)
        ])

    }
    
    
    func makeQRPayload(from data: QRPopupData?) -> String {

        guard let data = data else { return "" }

        let dict: [String: Any] = [
            "visitorId": data.visitorId ?? "",
            "residentMemberId": data.residentMemberId ?? "",
            "visitorType": data.visitorType ?? "",
            "personName": data.personName ?? "",
            "mobileNo": data.mobileNo ?? "",
            "flatNo": data.flatNo ?? "",
            "expiresAt": data.expiresAt ?? "",
            "qrCode": data.qrCode ?? ""
        ]

        if let jsonData = try? JSONSerialization.data(withJSONObject: dict),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }

        return ""
    }



    @objc func closeTapped() {
        dismiss(animated: true)
    }

    @objc func shareTapped() {

        guard let image = qrImageView.image else { return }

        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        present(activityVC, animated: true)
    }

    // MARK: QR Generator

    func generateQRCode(from string: String) -> UIImage? {

        guard let data = string.data(using: .utf8),
              let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }

        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("Q", forKey: "inputCorrectionLevel")

        guard let ciImage = filter.outputImage else { return nil }

        let scaled = ciImage.transformed(by: CGAffineTransform(scaleX: 6, y: 6))
        let context = CIContext()

        guard let cg = context.createCGImage(scaled, from: scaled.extent) else { return nil }

        return UIImage(cgImage: cg)
    }
    func formatDate(_ iso: String?) -> String {

        guard let iso = iso else { return "" }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let date = formatter.date(from: iso) else { return "" }

        let out = DateFormatter()
        out.dateFormat = "yyyy-MM-dd hh:mm a"   // ✅ 12-hour format
        out.timeZone = TimeZone(secondsFromGMT: 0) // keeps same UTC time

        return out.string(from: date)
    }
    func updateExpiryLabel() {
        validLabel.text = "Valid till: \(formatDate(qrData?.expiresAt))"
    }
}
