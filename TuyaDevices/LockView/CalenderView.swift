//
//  CalenderView.swift
//  SkromanIsra
//
//  Created by Admin on 14/04/26.
//

import Foundation

import Foundation
import UIKit
class DatePickerViewController: UIViewController {

    var onDateSelected: ((Date) -> Void)?

    private let picker = UIDatePicker()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        // ✅ FIX 1: enable date + time
        picker.datePickerMode = .dateAndTime

        // ✅ FIX 2: allow current time (NOT start of day)
        picker.minimumDate = Date()

        if #available(iOS 14.0, *) {
            picker.preferredDatePickerStyle = .wheels   // better for time
        }

        let selectButton = UIButton(type: .system)
        selectButton.setTitle("Select", for: .normal)
        selectButton.addTarget(self, action: #selector(selectTapped), for: .touchUpInside)

        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)

        let buttonStack = UIStackView(arrangedSubviews: [cancelButton, selectButton])
        buttonStack.axis = .horizontal
        buttonStack.distribution = .fillEqually
        buttonStack.spacing = 16

        let mainStack = UIStackView(arrangedSubviews: [picker, buttonStack])
        mainStack.axis = .vertical
        mainStack.spacing = 16
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(mainStack)

        NSLayoutConstraint.activate([
            mainStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            mainStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            mainStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }

    @objc private func selectTapped() {
        // ✅ FIX 3: DO NOT strip time
        onDateSelected?(picker.date)
        dismiss(animated: true)
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
}
