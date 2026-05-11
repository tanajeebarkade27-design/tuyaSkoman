//
//  CurtainSlider.swift
//  SkromanIsra
//
//  Created by Admin on 07/06/25.
//
import  UIKit
class CurtainSliderView: UIView {

    private let leftThumb = UIView()
    private let leftThumbImageView = UIImageView()
    private let rightThumb = UIView()
    private let rightThumbImageView = UIImageView()
    private let arrowImageView = UIImageView()

    // Add these two labels
    private let leftLabel = UILabel()
    private let rightLabel = UILabel()
    var onLeftTap: (() -> Void)?
       var onRightTap: (() -> Void)?
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }


    private func setupUI() {
        self.backgroundColor = UIColor.black
        self.layer.cornerRadius = 15
        self.clipsToBounds = true

        // Left thumb
        leftThumb.backgroundColor = .white
        leftThumb.layer.cornerRadius = 12
        addSubview(leftThumb)

        leftThumbImageView.contentMode = .scaleAspectFit
        leftThumbImageView.image = UIImage(named: "curtainOpen")
        leftThumb.addSubview(leftThumbImageView)

        let leftTap = UITapGestureRecognizer(target: self, action: #selector(leftThumbTapped))
        leftThumb.addGestureRecognizer(leftTap)
        leftThumb.isUserInteractionEnabled = true

        // Right thumb
        rightThumb.backgroundColor = .white
        rightThumb.layer.cornerRadius = 12
        addSubview(rightThumb)

        rightThumbImageView.contentMode = .scaleAspectFit
        rightThumbImageView.image = UIImage(named: "curtainsClosed")
        rightThumb.addSubview(rightThumbImageView)

        let rightTap = UITapGestureRecognizer(target: self, action: #selector(rightThumbTapped))
        rightThumb.addGestureRecognizer(rightTap)
        rightThumb.isUserInteractionEnabled = true

        // Arrow image
        arrowImageView.contentMode = .scaleAspectFit
        addSubview(arrowImageView)

        // Setup left label
        leftLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        leftLabel.textColor = .white
        leftLabel.textAlignment = .center
        addSubview(leftLabel)

        // Setup right label
        rightLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        rightLabel.textColor = .white
        rightLabel.textAlignment = .center
        addSubview(rightLabel)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let thumbSize: CGFloat = 24
        let y = (bounds.height - thumbSize) / 2

        leftThumb.frame = CGRect(x: 5, y: y, width: thumbSize, height: thumbSize)
        leftThumbImageView.frame = CGRect(x: 2, y: 2, width: thumbSize - 4, height: thumbSize - 4)

        rightThumb.frame = CGRect(x: bounds.width - thumbSize - 5, y: y, width: thumbSize, height: thumbSize)
        rightThumbImageView.frame = CGRect(x: 2, y: 2, width: thumbSize - 4, height: thumbSize - 4)

        arrowImageView.frame = CGRect(x: (bounds.width - 20)/2, y: (bounds.height - 20)/2, width: 20, height: 20)

        // Position labels below thumbs (or wherever you prefer)
        leftLabel.frame = CGRect(x: leftThumb.frame.minX - 10, y: leftThumb.frame.maxY + 2, width: 40, height: 15)
        rightLabel.frame = CGRect(x: rightThumb.frame.minX - 10, y: rightThumb.frame.maxY + 2, width: 40, height: 15)
    }

    // Add this method to update labels
    func setThumbLabels(left: String, right: String) {
        leftLabel.text = left
        rightLabel.text = right
    }

    @objc private func leftThumbTapped() {
            print("Left thumb tapped")
            arrowImageView.image = UIImage(named: "back-3")
            addGlow(to: leftThumb, color: UIColor.green)
            removeGlow(from: rightThumb)

            onLeftTap?()  
        }

        @objc private func rightThumbTapped() {
            print("Right thumb tapped")
            arrowImageView.image = UIImage(named: "right-2")
            addGlow(to: rightThumb, color: UIColor.green)
            removeGlow(from: leftThumb)

            onRightTap?()  // ✅ Trigger callback
        }

    private func addGlow(to view: UIView, color: UIColor) {
        view.layer.borderWidth = 2
        view.layer.borderColor = color.cgColor
        view.layer.shadowColor = color.cgColor
        view.layer.shadowRadius = 4
        view.layer.shadowOpacity = 0.8
        view.layer.shadowOffset = .zero
    }

    private func removeGlow(from view: UIView) {
        view.layer.borderWidth = 0
        view.layer.shadowOpacity = 0
    }
    

   
    func updateThumbState(for controlName: String, isOn: Bool, nextValueIsOn: Bool) {
        print("⚠️ updateThumbState called with controlName='\(controlName)' | isOn=\(isOn), nextValueIsOn=\(nextValueIsOn)")

        if isOn {
            // 🔄 REVERSED: If curtain is OPEN → highlight CLOSE side (left)
            addGlow(to: leftThumb, color: UIColor.orange)
            removeGlow(from: rightThumb)
            arrowImageView.image = UIImage(named: "back-3")

        } else if nextValueIsOn {
            // 🔄 REVERSED: If curtain is CLOSED → highlight OPEN side (right)
            addGlow(to: rightThumb, color: UIColor.green)
            removeGlow(from: leftThumb)
            arrowImageView.image = UIImage(named: "right-2")

        } else {
            removeGlow(from: leftThumb)
            removeGlow(from: rightThumb)
            arrowImageView.image = nil
        }
    }


    private func animateArrow(to direction: ArrowDirection) {
        // Arrow movement parameters
        let arrowWidth: CGFloat = 20
        let yPos = (bounds.height - arrowWidth) / 2
        let leftX: CGFloat = 10
        let rightX: CGFloat = bounds.width - arrowWidth - 10
        let centerX: CGFloat = (bounds.width - arrowWidth) / 2

        // Prepare the arrow image and transform
        arrowImageView.image = UIImage(named: "right-2") // your arrow image pointing right

        let targetX: CGFloat
        let flipTransform: CGAffineTransform

        switch direction {
        case .right:
            targetX = rightX
            flipTransform = .identity // no flip, arrow points right
        case .left:
            targetX = leftX
            flipTransform = CGAffineTransform(scaleX: -1, y: 1) // flip horizontally to point left
        case .center:
            targetX = centerX
            flipTransform = .identity
        }

        // Animate position and flip transform
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut]) {
            self.arrowImageView.frame.origin.x = targetX
            self.arrowImageView.transform = flipTransform
        }
    }

    // Arrow directions enum
    private enum ArrowDirection {
        case left
        case right
        case center
    }
    func setLeftThumbState(isOn: Bool) {
        if isOn {
            addGlow(to: leftThumb, color: UIColor.orange)
            removeGlow(from: rightThumb)
            arrowImageView.image = UIImage(named: "back-3")
        } else {
            removeGlow(from: leftThumb)
        }
    }

    func setRightThumbState(isOn: Bool) {
        if isOn {
            addGlow(to: rightThumb, color: UIColor.green)
            removeGlow(from: leftThumb)
            arrowImageView.image = UIImage(named: "right-2")
        } else {
            removeGlow(from: rightThumb)
        }
    }

    

}
