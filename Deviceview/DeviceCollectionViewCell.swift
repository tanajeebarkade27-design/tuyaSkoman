//
//  DeviceCollectionViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 06/02/25.
//

import UIKit

class DeviceCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var CellbackgroundView: UIView!
    @IBOutlet weak var DeviceNumberLabel: UILabel!
    @IBOutlet weak var DeviceNameLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        CellbackgroundView.layer.cornerRadius =  8
        CellbackgroundView.layer.masksToBounds =  true
        CellbackgroundView.layer.borderColor =  UIColor.yellow.cgColor
        
        CellbackgroundView.layer.borderWidth = 1
        applyGradientBackground()
    }
    
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            applyGradientBackground()  // Reapply gradient on theme change
        }
    }

    
    
    func applyGradientBackground() {
        let cellGradientLayer = CAGradientLayer()
        cellGradientLayer.frame = CellbackgroundView.bounds
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
        
        CellbackgroundView.layer.sublayers?.removeAll { $0 is CAGradientLayer } // Remove old gradient
        CellbackgroundView.layer.insertSublayer(cellGradientLayer, at: 0)
    }
    

}
