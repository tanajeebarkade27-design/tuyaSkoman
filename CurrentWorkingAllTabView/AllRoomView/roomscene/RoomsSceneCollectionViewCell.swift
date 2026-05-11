//
//  RoomsSceneCollectionViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 13/08/25.
//

import UIKit

class RoomsSceneCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var cellBackgroundView: UIView!
    @IBOutlet weak var sceneNameLabel: UILabel!
    @IBOutlet weak var sceneImage: UIImageView!
    @IBOutlet weak var imagebackgroundView: UIView!
    
    private var gradientBorderLayer: CAGradientLayer?
    private var shapeLayer: CAShapeLayer?

    override func awakeFromNib() {
        super.awakeFromNib()
        imagebackgroundView.clipsToBounds = true
        imagebackgroundView.backgroundColor = UIColor.white.withAlphaComponent(0.10)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        imagebackgroundView.layer.cornerRadius = imagebackgroundView.frame.height / 2
        if isSelected {
            applyGradientBorder()
        } else {
            removeGradientBorder()
        }
    }
    
    /// 🔹 Call when cell is selected/deselected
    func setSelected(_ selected: Bool) {
        if selected {
            applyGradientBorder()
        } else {
            removeGradientBorder()
        }
    }
    
    private func applyGradientBorder() {
        removeGradientBorder() // avoid duplicates

        let gradient = CAGradientLayer()
        gradient.frame = imagebackgroundView.bounds
        gradient.colors = [
            UIColor.systemBlue.cgColor,
            UIColor.green.cgColor,
            UIColor.systemGreen.cgColor
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        
        let shape = CAShapeLayer()
        shape.lineWidth = 3
        shape.path = UIBezierPath(roundedRect: imagebackgroundView.bounds, cornerRadius: imagebackgroundView.bounds.height/2).cgPath
        shape.fillColor = UIColor.clear.cgColor
        shape.strokeColor = UIColor.black.cgColor
        
        gradient.mask = shape
        
        imagebackgroundView.layer.addSublayer(gradient)
        
        gradientBorderLayer = gradient
        shapeLayer = shape
    }
    
    private func removeGradientBorder() {
        gradientBorderLayer?.removeFromSuperlayer()
        gradientBorderLayer = nil
        shapeLayer = nil
    }
}
