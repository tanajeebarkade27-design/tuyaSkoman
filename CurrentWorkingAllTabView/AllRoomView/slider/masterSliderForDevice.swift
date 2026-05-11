//
//  masterSliderForDevice.swift
//  SkromanIsra
//
//  Created by Admin on 24/07/25.
//

import Foundation
import UIKit

class masterSlideDevicerButton: UIButton {

    private let thumbView = UIView()
    private let powerImageView = UIImageView()
    private let statusLabel = UILabel()

    private var thumbLeadingConstraint: NSLayoutConstraint!
    private var thumbTrailingConstraint: NSLayoutConstraint!
    private var statusLabelLeadingConstraint: NSLayoutConstraint?
    private var statusLabelTrailingConstraint: NSLayoutConstraint?

    private(set) var isOn = false
    var onToggle: ((Bool) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = .black
        layer.cornerRadius = 15
        translatesAutoresizingMaskIntoConstraints = false

        let thumbSize: CGFloat = 20
        let thumbPadding: CGFloat = 4

        thumbView.backgroundColor = .white
        thumbView.layer.cornerRadius = thumbSize / 2
        thumbView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(thumbView)

        NSLayoutConstraint.activate([
            thumbView.centerYAnchor.constraint(equalTo: centerYAnchor),
            thumbView.widthAnchor.constraint(equalToConstant: thumbSize),
            thumbView.heightAnchor.constraint(equalToConstant: thumbSize)
        ])

        thumbLeadingConstraint = thumbView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: thumbPadding)
        thumbTrailingConstraint = thumbView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -thumbPadding)
        thumbLeadingConstraint.isActive = true

        // Power icon
        powerImageView.image = UIImage(named: "SKLogo")

        
        powerImageView.contentMode = .scaleAspectFit
        powerImageView.translatesAutoresizingMaskIntoConstraints = false
        thumbView.addSubview(powerImageView)

        NSLayoutConstraint.activate([
            powerImageView.leadingAnchor.constraint(equalTo: thumbView.leadingAnchor),
            powerImageView.trailingAnchor.constraint(equalTo: thumbView.trailingAnchor),
            powerImageView.topAnchor.constraint(equalTo: thumbView.topAnchor),
            powerImageView.bottomAnchor.constraint(equalTo: thumbView.bottomAnchor)
        ])
        powerImageView.contentMode = .scaleAspectFill
        powerImageView.clipsToBounds = true


        // Status label
        statusLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        statusLabel.textColor = .white
        statusLabel.text = "M"
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(statusLabel)

        NSLayoutConstraint.activate([
            statusLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        statusLabelTrailingConstraint = statusLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8)
        statusLabelLeadingConstraint = statusLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8)
        statusLabelTrailingConstraint?.isActive = true

        // Gestures
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(userDidTap))
        thumbView.addGestureRecognizer(tapGesture)
        thumbView.isUserInteractionEnabled = true

        addTarget(self, action: #selector(userDidTap), for: .touchUpInside)
    }

    // ✅ Only called by user taps
    @objc private func userDidTap() {
        toggleState(sendCallback: true)
    }

   
     
    func setState(_ on: Bool, sendCallback: Bool = true) {
        isOn = on
        updateStyle(animated: false) // update UI immediately
        if sendCallback {
            DispatchQueue.main.async { [weak self] in
                self?.onToggle?(on)
            }
        }
    }

    private func toggleState(sendCallback: Bool) {
        updateStyle(animated: true)

        if sendCallback {
            onToggle?(isOn)  // ✅ Only publish if user tapped
        }
    }

    private func updateStyle(animated: Bool) {
        let updates = {
            if self.isOn {
                self.thumbLeadingConstraint.isActive = false
                self.thumbTrailingConstraint.isActive = true
                self.statusLabelTrailingConstraint?.isActive = false
                self.statusLabelLeadingConstraint?.isActive = true
                self.statusLabel.text = "ON"
                self.thumbView.layer.borderWidth = 2
                self.thumbView.layer.borderColor = UIColor.green.cgColor
                self.thumbView.layer.shadowColor = UIColor.green.cgColor
                self.thumbView.layer.shadowRadius = 4
                self.thumbView.layer.shadowOpacity = 0.8
                self.thumbView.layer.shadowOffset = .zero
            } else {
                self.thumbTrailingConstraint.isActive = false
                self.thumbLeadingConstraint.isActive = true
                self.statusLabelLeadingConstraint?.isActive = false
                self.statusLabelTrailingConstraint?.isActive = true
                self.statusLabel.text = "OFF"
                self.thumbView.layer.borderWidth = 0
                self.thumbView.layer.shadowOpacity = 0
            }
            self.layoutIfNeeded()
        }

        if animated {
            UIView.animate(withDuration: 0.3, animations: updates)
        } else {
            updates()
        }
    }
}
