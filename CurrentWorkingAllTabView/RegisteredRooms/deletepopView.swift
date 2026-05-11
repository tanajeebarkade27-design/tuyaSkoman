//
//  deletepopView.swift
//  SkromanIsra
//
//  Created by Admin on 31/07/25.
//

import Foundation
import UIKit

class DeleteRoomPopupView: UIView {

    var onCancel: (() -> Void)?
    var onConfirm: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupPopup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupPopup()
    }

    private func setupPopup() {
        backgroundColor = UIColor.white
        layer.cornerRadius = 10
        layer.borderColor = UIColor.lightGray.cgColor
        layer.borderWidth = 1
        translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = "Delete Room?"
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)

        let confirmButton = UIButton(type: .system)
        confirmButton.setTitle("OK", for: .normal)
        confirmButton.translatesAutoresizingMaskIntoConstraints = false
        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)

        addSubview(label)
        addSubview(cancelButton)
        addSubview(confirmButton)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            label.centerXAnchor.constraint(equalTo: centerXAnchor),

            cancelButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            cancelButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),

            confirmButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            confirmButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
        ])
    }

    @objc private func cancelTapped() {
        onCancel?()
        self.removeFromSuperview()
    }

    @objc private func confirmTapped() {
        onConfirm?()
        self.removeFromSuperview()
    }
}
