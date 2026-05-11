//
//  ModeSelection.swift
//  SkromanIsra
//
//  Created by Admin on 28/04/26.
//

import Foundation
import UIKit

class ModeSelectionPopup: UIView {

    var onModeSelected: ((String) -> Void)?

    private let container = UIView()
    private let ezButton = UIButton(type: .system)
    private let apButton = UIButton(type: .system)
    private let ezBulbImageView = UIImageView()
    private let apBulbImageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {

        self.backgroundColor = UIColor.black.withAlphaComponent(0.35)

        // Transparent-ish bottom sheet container
        container.backgroundColor = UIColor.white.withAlphaComponent(0.10)
        container.layer.cornerRadius = 16
        container.translatesAutoresizingMaskIntoConstraints = false
        addSubview(container)

        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            container.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            container.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -40)
        ])
        
       
      

        let title = UILabel()
        title.text = "Select mode"
        title.numberOfLines = 0
        title.textAlignment = .center
        title.textColor = .white
        title.font = UIFont.systemFont(ofSize: 15, weight: .semibold)

        let subtitle = UILabel()
        subtitle.text = "Choose as per your device blink/beep"
        subtitle.numberOfLines = 0
        subtitle.textAlignment = .center
        subtitle.textColor = UIColor.white.withAlphaComponent(0.75)
        subtitle.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        
        configureModeButton(
            button: ezButton,
            bulbImageView: ezBulbImageView,
            title: "EZ",
            background: UIColor.systemGreen.withAlphaComponent(0.22)
        )
        ezButton.addTarget(self, action: #selector(ezTapped), for: .touchUpInside)
        
        configureModeButton(
            button: apButton,
            bulbImageView: apBulbImageView,
            title: "AP",
            background: UIColor.systemBlue.withAlphaComponent(0.22)
        )
        apButton.addTarget(self, action: #selector(apTapped), for: .touchUpInside)
        
        let buttonsRow = UIStackView(arrangedSubviews: [ezButton, apButton])
        buttonsRow.axis = .horizontal
        buttonsRow.alignment = .center
        buttonsRow.distribution = .equalSpacing
        buttonsRow.spacing = 18
        buttonsRow.translatesAutoresizingMaskIntoConstraints = false
        
        let stack = UIStackView(arrangedSubviews: [title, subtitle, buttonsRow])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16),
            
            ezButton.widthAnchor.constraint(equalToConstant: 70),
            ezButton.heightAnchor.constraint(equalToConstant: 90),
            apButton.widthAnchor.constraint(equalToConstant: 70),
            apButton.heightAnchor.constraint(equalToConstant: 90),
        ])
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleDismiss))
        tap.cancelsTouchesInView = false
        tap.delegate = self
        self.addGestureRecognizer(tap)
        
        // Start subtle blinking on both bulbs (fast for EZ, slow for AP)
        startBlinking(imageView: ezBulbImageView, speed: 0.2)
        startBlinking(imageView: apBulbImageView, speed: 0.8)
    }

    @objc private func handleDismiss() {
        dismiss()
    }
    // MARK: - Actions

    @objc private func ezTapped() {
        onModeSelected?("EZ")
    }

    @objc private func apTapped() {
        onModeSelected?("AP")
    }

    // MARK: - Animation

    private func startBlinking(imageView: UIImageView, speed: TimeInterval) {
        imageView.layer.removeAllAnimations()
        imageView.alpha = 1.0
        
        UIView.animate(
            withDuration: speed,
            delay: 0,
            options: [.autoreverse, .repeat, .allowUserInteraction],
            animations: {
                imageView.alpha = 0.2
            }
        )
    }

    func dismiss() {
        ezBulbImageView.layer.removeAllAnimations()
        apBulbImageView.layer.removeAllAnimations()
        self.removeFromSuperview()
    }
    
    private func configureModeButton(
        button: UIButton,
        bulbImageView: UIImageView,
        title: String,
        background: UIColor
    ) {
        button.backgroundColor = background
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.18).cgColor
        button.clipsToBounds = true
        button.setTitle("", for: .normal)
        button.tintColor = .white
        
        bulbImageView.image = UIImage(systemName: "lightbulb.fill")
        bulbImageView.tintColor = .systemYellow
        bulbImageView.contentMode = .scaleAspectFit
        bulbImageView.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(bulbImageView)
        
        let label = UILabel()
        label.text = title
        label.textAlignment = .center
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(label)
        
        NSLayoutConstraint.activate([
            bulbImageView.topAnchor.constraint(equalTo: button.topAnchor, constant: 14),
            bulbImageView.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            bulbImageView.widthAnchor.constraint(equalToConstant: 26),
            bulbImageView.heightAnchor.constraint(equalToConstant: 26),
            
            label.topAnchor.constraint(equalTo: bulbImageView.bottomAnchor, constant: 10),
            label.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 6),
            label.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -6)
        ])
    }
}

extension ModeSelectionPopup: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // Tap outside container dismisses; tap inside does not.
        if touch.view?.isDescendant(of: container) == true {
            return false
        }
        return true
    }
}
