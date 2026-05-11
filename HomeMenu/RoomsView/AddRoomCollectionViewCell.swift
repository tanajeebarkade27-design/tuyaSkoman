//
//  AddRoomCollectionViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 17/02/25.
//

import UIKit

class AddRoomCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var cellbackgroundView: UIView!
    @IBOutlet weak var roomImage: UIImageView!
    @IBOutlet weak var roomNameLabel: UILabel!
    
    @IBOutlet weak var isSelectedRoom: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
       
        cellbackgroundView.layer.cornerRadius =  8
        cellbackgroundView.layer.masksToBounds =  true
        cellbackgroundView.layer.borderColor =  UIColor.gray.cgColor
        cellbackgroundView.layer.borderWidth = 1
//        let diameter = min(cellbackgroundView.bounds.width, cellbackgroundView.bounds.height)
//           cellbackgroundView.layer.cornerRadius = diameter / 2
    }
    
    
    func applyGradientBackground() {
        //         Gradient for cellbackgroundView
        let cellGradientLayer = CAGradientLayer()
        cellGradientLayer.frame = cellbackgroundView.bounds
        cellGradientLayer.colors = [UIColor.black.cgColor, UIColor.gray.cgColor] // Better transition than white
        cellGradientLayer.startPoint = CGPoint(x: 0, y: 0)
        cellGradientLayer.endPoint = CGPoint(x: 1, y: 1)   
        cellGradientLayer.cornerRadius = 8
        cellbackgroundView.layer.insertSublayer(cellGradientLayer, at: 0)
        cellbackgroundView.layer.cornerRadius = 8
        cellbackgroundView.layer.masksToBounds = true
        
    }

}
