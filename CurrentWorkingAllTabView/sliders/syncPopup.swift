//
//  syncPopup.swift
//  SkromanIsra
//
//  Created by Admin on 12/03/26.
//

import Foundation
import UIKit

class SyncProcessingPopup: UIView {

    private let container = UIView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let progressView = UIProgressView(progressViewStyle: .default)
    private let iconImageView = UIImageView()
    private var timer: Timer?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        startAnimatingProgress()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        startAnimatingProgress()
    }

    private func setupUI() {

        backgroundColor = UIColor.black.withAlphaComponent(0.4)

        container.backgroundColor = UIColor.black
        container.layer.cornerRadius = 14
        container.translatesAutoresizingMaskIntoConstraints = false
        container.borderColor = .systemGray2
        container.borderWidth = 0.5
        addSubview(container)

        // Image setup
        iconImageView.image = UIImage(named: "AppIcon1") // your image name
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            iconImageView.widthAnchor.constraint(equalToConstant: 50),
            iconImageView.heightAnchor.constraint(equalToConstant: 50)
        ])

        titleLabel.font = .boldSystemFont(ofSize: 18)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .white

        messageLabel.font = .systemFont(ofSize: 15)
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.textColor = .white

        progressView.progressTintColor = .green
        progressView.trackTintColor = UIColor.systemGray5
        progressView.progress = 0
        progressView.transform = CGAffineTransform(scaleX: 1, y: 1.5)

        // Stack with image on top
        let stack = UIStackView(arrangedSubviews: [
            iconImageView,
            progressView,
            titleLabel,
            messageLabel
        ])

        stack.axis = .vertical
        stack.spacing = 14
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)

        NSLayoutConstraint.activate([
            
            container.centerXAnchor.constraint(equalTo: centerXAnchor),
            container.centerYAnchor.constraint(equalTo: centerYAnchor),
            container.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.8),

            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 25),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -25),

            // IMPORTANT: make progress bar full width
            progressView.widthAnchor.constraint(equalTo: stack.widthAnchor)
        ])
    }
    func configure(title: String, message: String) {
        titleLabel.text = title
        messageLabel.text = message
    }

    private func startAnimatingProgress() {

        timer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { _ in
            self.progressView.progress += 0.01

            if self.progressView.progress >= 1 {
                self.progressView.progress = 0
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }
}
