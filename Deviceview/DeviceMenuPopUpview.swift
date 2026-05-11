//
//  DeviceMenuPopUpview.swift
//  SkromanIsra
//
//  Created by Admin on 28/02/25.
//
import UIKit
class DimmSettingsPopupViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.7)

        let popupView = UIView()
        popupView.backgroundColor = .white
        popupView.layer.cornerRadius = 12
        popupView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(popupView)

        // Close Button with 'X' icon
        let closeButton = UIButton()
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .black
        closeButton.addTarget(self, action: #selector(closePopup), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false

        // Title Label
        let titleLabel = UILabel()
        titleLabel.text = " Dimming Settings"
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        // Separator Line
        let separator = UIView()
        separator.backgroundColor = .lightGray
        separator.translatesAutoresizingMaskIntoConstraints = false

        // Type Label
        let typeLabel = UILabel()
        typeLabel.text = "Type:"
        typeLabel.font = UIFont.systemFont(ofSize: 16)
        typeLabel.translatesAutoresizingMaskIntoConstraints = false

        // Scale Label
        let scaleLabel = UILabel()
        scaleLabel.text = "Scale:"
        scaleLabel.font = UIFont.systemFont(ofSize: 16)
        scaleLabel.translatesAutoresizingMaskIntoConstraints = false

        // Dropdown (Picker)
        let dropdown = UISegmentedControl(items: ["ZCD", "PWM"])
        dropdown.selectedSegmentIndex = 0
        dropdown.translatesAutoresizingMaskIntoConstraints = false

        popupView.addSubview(closeButton)
        popupView.addSubview(titleLabel)
        popupView.addSubview(separator)
        popupView.addSubview(typeLabel)
        popupView.addSubview(scaleLabel)
        popupView.addSubview(dropdown)

        NSLayoutConstraint.activate([
            popupView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            popupView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            popupView.widthAnchor.constraint(equalToConstant: 300),
            popupView.heightAnchor.constraint(equalToConstant: 200),

            titleLabel.topAnchor.constraint(equalTo: popupView.topAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: popupView.leadingAnchor, constant: 10),

            closeButton.topAnchor.constraint(equalTo: popupView.topAnchor, constant: 10),
            closeButton.trailingAnchor.constraint(equalTo: popupView.trailingAnchor, constant: -10),

            separator.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            separator.leadingAnchor.constraint(equalTo: popupView.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: popupView.trailingAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1),

            typeLabel.topAnchor.constraint(equalTo: separator.bottomAnchor, constant: 15),
            typeLabel.leadingAnchor.constraint(equalTo: popupView.leadingAnchor, constant: 10),

            scaleLabel.topAnchor.constraint(equalTo: separator.bottomAnchor, constant: 15),
            scaleLabel.leadingAnchor.constraint(equalTo: typeLabel.trailingAnchor, constant: 50),

            dropdown.topAnchor.constraint(equalTo: typeLabel.bottomAnchor, constant: 10),
            dropdown.leadingAnchor.constraint(equalTo: popupView.leadingAnchor, constant: 10),
            dropdown.trailingAnchor.constraint(equalTo: popupView.trailingAnchor, constant: -10),
            dropdown.heightAnchor.constraint(equalToConstant: 30)
        ])
    }

    @objc func closePopup() {
        self.dismiss(animated: true, completion: nil)
    }
}


