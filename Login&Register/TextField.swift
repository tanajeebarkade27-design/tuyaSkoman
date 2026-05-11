//
//  TextField.swift
//  SkromanIsra
//
//  Created by Admin on 15/10/25.
//

import Foundation
 import UIKit
class PaddedTextField: UITextField {
    let padding = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: 0)

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }

    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
}

// MARK: - Capsule Style (global)
extension UITextField {
    /// Applies a modern capsule-style appearance with padding.
    func applyCapsuleStyle(
        height: CGFloat = 46,
        backgroundColor: UIColor = UIColor.white.withAlphaComponent(0.08),
        borderColor: UIColor = UIColor.white.withAlphaComponent(0.16),
        textColor: UIColor = UIColor.white,
        placeholderColor: UIColor = UIColor.white.withAlphaComponent(0.55)
    ) {
        translatesAutoresizingMaskIntoConstraints = false
        
        self.backgroundColor = backgroundColor
        layer.cornerRadius = height / 2
        layer.masksToBounds = true
        layer.borderWidth = 1
        layer.borderColor = borderColor.cgColor
        
        self.textColor = textColor
        tintColor = textColor
        borderStyle = .none
        
        if !constraints.contains(where: { $0.firstAttribute == .height && $0.relation == .equal }) {
            heightAnchor.constraint(equalToConstant: height).isActive = true
        }
        
        setLeftPadding(14)
        setRightPadding(12)
        
        if let placeholder, !placeholder.isEmpty {
            attributedPlaceholder = NSAttributedString(
                string: placeholder,
                attributes: [.foregroundColor: placeholderColor]
            )
        }
    }
    
    func setLeftPadding(_ value: CGFloat) {
        let v = UIView(frame: CGRect(x: 0, y: 0, width: value, height: 1))
        leftView = v
        leftViewMode = .always
    }
    
    func setRightPadding(_ value: CGFloat) {
        if let rv = rightView, rightViewMode != .never {
            let container = UIView(frame: CGRect(x: 0, y: 0, width: rv.bounds.width + value, height: max(rv.bounds.height, 1)))
            rv.frame.origin.x = 0
            container.addSubview(rv)
            rightView = container
            rightViewMode = .always
            return
        }
        
        let v = UIView(frame: CGRect(x: 0, y: 0, width: value, height: 1))
        rightView = v
        rightViewMode = .always
    }
}
