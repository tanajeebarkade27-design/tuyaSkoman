//
//  EditDeviceNamePopup.swift
//  SkromanIsra
//

import UIKit

final class EditDeviceNamePopup: UIView {

    var onSubmit: ((String) -> Void)?

    private let blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    private let dimView = UIView()
    private let container = UIView()
    private let nameField = UITextField()
    private let okButton = UIButton(type: .system)

    init(currentName: String) {
        super.init(frame: .zero)
        nameField.text = currentName
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = .clear

        blurEffectView.translatesAutoresizingMaskIntoConstraints = false
        blurEffectView.isUserInteractionEnabled = true
        addSubview(blurEffectView)

        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.25)
        dimView.translatesAutoresizingMaskIntoConstraints = false
        dimView.isUserInteractionEnabled = true
        addSubview(dimView)

        container.backgroundColor = UIColor.white.withAlphaComponent(0.12)
        container.layer.cornerRadius = 16
        container.translatesAutoresizingMaskIntoConstraints = false
        addSubview(container)

        NSLayoutConstraint.activate([
            blurEffectView.topAnchor.constraint(equalTo: topAnchor),
            blurEffectView.bottomAnchor.constraint(equalTo: bottomAnchor),
            blurEffectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurEffectView.trailingAnchor.constraint(equalTo: trailingAnchor),

            dimView.topAnchor.constraint(equalTo: topAnchor),
            dimView.bottomAnchor.constraint(equalTo: bottomAnchor),
            dimView.leadingAnchor.constraint(equalTo: leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])

        let tapOutside = UITapGestureRecognizer(target: self, action: #selector(dismissPopup))
        dimView.addGestureRecognizer(tapOutside)

        let titleLabel = UILabel()
        titleLabel.text = "Edit Name"
        titleLabel.textAlignment = .center
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        nameField.borderStyle = .roundedRect
        nameField.backgroundColor = UIColor.white.withAlphaComponent(0.92)
        nameField.textColor = .black
        nameField.font = .systemFont(ofSize: 16)
        nameField.autocapitalizationType = .words
        nameField.clearButtonMode = .whileEditing
        nameField.returnKeyType = .done
        nameField.delegate = self
        nameField.translatesAutoresizingMaskIntoConstraints = false

        okButton.setTitle("OK", for: .normal)
        okButton.setTitleColor(.white, for: .normal)
        okButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        okButton.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.85)
        okButton.layer.cornerRadius = 10
        okButton.translatesAutoresizingMaskIntoConstraints = false
        okButton.addTarget(self, action: #selector(okTapped), for: .touchUpInside)

        container.addSubview(titleLabel)
        container.addSubview(nameField)
        container.addSubview(okButton)

        NSLayoutConstraint.activate([
            container.centerXAnchor.constraint(equalTo: centerXAnchor),
            container.centerYAnchor.constraint(equalTo: centerYAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 32),
            container.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -32),

            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),

            nameField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            nameField.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            nameField.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            nameField.heightAnchor.constraint(equalToConstant: 44),

            okButton.topAnchor.constraint(equalTo: nameField.bottomAnchor, constant: 16),
            okButton.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            okButton.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            okButton.heightAnchor.constraint(equalToConstant: 44),
            okButton.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -20)
        ])
    }

    func present(on view: UIView) {
        frame = view.bounds
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        alpha = 0
        view.addSubview(self)

        UIView.animate(withDuration: 0.25) {
            self.alpha = 1
        }

        nameField.becomeFirstResponder()
    }

    func dismiss() {
        nameField.resignFirstResponder()
        UIView.animate(withDuration: 0.2, animations: {
            self.alpha = 0
        }, completion: { _ in
            self.removeFromSuperview()
        })
    }

    func setSubmitting(_ submitting: Bool) {
        okButton.isEnabled = !submitting
        nameField.isEnabled = !submitting
        okButton.alpha = submitting ? 0.6 : 1
        dimView.isUserInteractionEnabled = !submitting
    }

    @objc private func okTapped() {
        let trimmed = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmed.isEmpty else {
            shakeNameField()
            return
        }
        onSubmit?(trimmed)
    }

    @objc private func dismissPopup() {
        dismiss()
    }

    private func shakeNameField() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.values = [-8, 8, -6, 6, -3, 3, 0]
        animation.duration = 0.35
        nameField.layer.add(animation, forKey: "shake")
    }
}

extension EditDeviceNamePopup: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        okTapped()
        return true
    }
}
