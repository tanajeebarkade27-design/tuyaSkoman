//
//  InlineDatePickerViewController.swift
//  SkromanIsra
//
//  Created by Admin on 16/02/26.
//


import UIKit

class InlineDatePickerViewController: UIViewController {

    var onDateSelected: ((Date) -> Void)?

    private let container = UIView()
    private let datePicker = UIDatePicker()
    private let doneButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    func setupUI(){
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        container.backgroundColor = .white
        container.layer.cornerRadius = 15
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)

        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15),
            container.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10)
        ])

        datePicker.datePickerMode = .dateAndTime
        datePicker.preferredDatePickerStyle = .inline
        datePicker.minimumDate = Date()

        doneButton.setTitle("Done", for: .normal)
        doneButton.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)

        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)

        let buttonStack = UIStackView(arrangedSubviews: [cancelButton, doneButton])
        buttonStack.distribution = .equalSpacing

        let stack = UIStackView(arrangedSubviews: [datePicker, buttonStack])
        stack.axis = .vertical
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 15),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 15),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -15),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -15)
        ])
    }

    @objc func doneTapped() {
        onDateSelected?(datePicker.date)
        dismiss(animated: true)
    }

    @objc func cancelTapped() {
        dismiss(animated: true)
    }
}
