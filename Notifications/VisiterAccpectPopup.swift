//
//  VisiterAccpectPopup.swift
//  SkromanIsra
//
//  Created by Admin on 25/02/26.
//

import Foundation
import UIKit

class VisitorPopupView: UIView {

    private let container = UIView()

    private let titleLabel = UILabel()
    private let societyLabel = UILabel()
    private let imageView = UIImageView()
    private let visitorTypeLabel = UILabel()
    private let gateLabel = UILabel()

    let allowButton = UIButton(type: .system)
    let rejectButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    private func setupUI() {

        backgroundColor = UIColor.black.withAlphaComponent(0.4)

        container.backgroundColor = .white
        container.layer.cornerRadius = 16
        container.translatesAutoresizingMaskIntoConstraints = false
        addSubview(container)

        NSLayoutConstraint.activate([
            container.centerXAnchor.constraint(equalTo: centerXAnchor),
            container.centerYAnchor.constraint(equalTo: centerYAnchor),
            container.widthAnchor.constraint(equalToConstant: 300)
        ])

        titleLabel.text = "Visitor at Gate"
        titleLabel.font = .boldSystemFont(ofSize: 18)
        titleLabel.textAlignment = .center

        societyLabel.textAlignment = .center
        societyLabel.font = .systemFont(ofSize: 14)

        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 40
        imageView.clipsToBounds = true
        imageView.backgroundColor = .lightGray

        visitorTypeLabel.textAlignment = .center
        gateLabel.textAlignment = .center

        allowButton.setTitle("Allow", for: .normal)
        allowButton.backgroundColor = .systemGreen
        allowButton.setTitleColor(.white, for: .normal)
        allowButton.layer.cornerRadius = 8

        rejectButton.setTitle("Reject", for: .normal)
        rejectButton.backgroundColor = .systemRed
        rejectButton.setTitleColor(.white, for: .normal)
        rejectButton.layer.cornerRadius = 8

        let buttonStack = UIStackView(arrangedSubviews: [rejectButton, allowButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 12
        buttonStack.distribution = .fillEqually

        let stack = UIStackView(arrangedSubviews: [
            titleLabel,
            societyLabel,
            imageView,
            visitorTypeLabel,
            gateLabel,
            buttonStack
        ])

        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(stack)

        imageView.heightAnchor.constraint(equalToConstant: 80).isActive = true

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16)
        ])
    }

    // MARK: - Set Data

    func configure(society: String,
                   flat: String,
                   imageUrl: String,
                   visitorType: String,
                   gate: String) {

        societyLabel.text = "\(society) • Flat \(flat)"
        visitorTypeLabel.text = "Visitor Type: \(visitorType)"
        gateLabel.text = "Gate: \(gate)"

        if let url = URL(string: imageUrl) {
            DispatchQueue.global().async {
                if let data = try? Data(contentsOf: url) {
                    DispatchQueue.main.async {
                        self.imageView.image = UIImage(data: data)
                    }
                }
            }
        }
    }
}
