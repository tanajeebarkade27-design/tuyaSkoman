//
//  DeviceMenuCollectionViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 13/02/25.
//

import UIKit

class DeviceMenuCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var menuImageView: UIImageView!
    @IBOutlet weak var menuOptionLabel: UILabel!
    @IBOutlet weak var cellBackGroundView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        setupCellAppearance()
        applyGradientBackground()
        menuOptionLabel.textColor = UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? .white : .white
        }
    }

    func setupCellAppearance() {
        // Corner Radius
        cellBackGroundView.layer.cornerRadius = 8
        cellBackGroundView.layer.masksToBounds = true
        
        // Shadow Effect
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = 0.3  // Adjust opacity as needed
        self.layer.shadowOffset = CGSize(width: 3, height: 3) // X, Y shadow position
        self.layer.shadowRadius = 4 // Blurriness of shadow
        self.layer.masksToBounds = false
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        applyGradientBackground()
    }

    
    func applyGradientBackground() {
        let cellGradientLayer = CAGradientLayer()
        cellGradientLayer.frame = cellBackGroundView.bounds
        cellGradientLayer.cornerRadius = 8
        
        if traitCollection.userInterfaceStyle == .dark {
            // Dark mode gradient (Black to Dark Gray)
            cellGradientLayer.colors = [UIColor.black.cgColor, UIColor.darkGray.cgColor]
        } else {
            // Light mode gradient (Soft Blue to Light Gray)
            cellGradientLayer.colors = [
                UIColor.systemBlue.withAlphaComponent(0.2).cgColor,  // Light Blue Tint
                UIColor.systemGray6.cgColor  // Soft Gray
            ]
        }
        
        cellGradientLayer.startPoint = CGPoint(x: 0, y: 0)  // Top-left
        cellGradientLayer.endPoint = CGPoint(x: 1, y: 1)    // Bottom-right
        
        cellBackGroundView.layer.sublayers?.removeAll { $0 is CAGradientLayer } // Remove old gradient
        cellBackGroundView.layer.insertSublayer(cellGradientLayer, at: 0)
    }
}
