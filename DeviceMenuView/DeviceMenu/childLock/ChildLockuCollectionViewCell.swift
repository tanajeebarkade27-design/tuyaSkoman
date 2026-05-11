//
//  ChildLockuCollectionViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 13/02/25.
//

import UIKit

class ChildLockuCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var cellbackgroundView: UIView!
    @IBOutlet weak var deviceImageView: UIImageView!
    @IBOutlet weak var deviceNameLabel: UILabel!
    
    
    @IBOutlet weak var childLockImage: UIImageView!
    
    @IBOutlet weak var DimmiNgLightImage: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        cellbackgroundView.layer.cornerRadius = 8
        cellbackgroundView.layer.masksToBounds = true
        cellbackgroundView.layer.borderColor = UIColor.gray.cgColor
        cellbackgroundView.layer.borderWidth = 1
    }
    
    
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        //applyGradientBackground()
    }

    
    func applyGradientBackground() {
        let cellGradientLayer = CAGradientLayer()
        cellGradientLayer.frame = cellbackgroundView.bounds
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
        
        cellbackgroundView.layer.sublayers?.removeAll { $0 is CAGradientLayer } // Remove old gradient
        cellbackgroundView.layer.insertSublayer(cellGradientLayer, at: 0)
    }
}
