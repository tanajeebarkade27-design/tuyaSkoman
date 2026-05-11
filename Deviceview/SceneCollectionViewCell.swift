//
//  SceneCollectionViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 06/02/25.
//

import UIKit

class SceneCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var cellBackGroundView: UIView!
    
    @IBOutlet weak var SceneNumberllabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        cellBackGroundView.layer.cornerRadius =  8
        cellBackGroundView.layer.masksToBounds =  true
        cellBackGroundView.layer.borderColor =  UIColor.yellow.cgColor
        
        cellBackGroundView.layer.borderWidth = 1
        //applyGradientBackground()
    }

    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            applyGradientBackground()  // Reapply gradient on theme change
        }
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
