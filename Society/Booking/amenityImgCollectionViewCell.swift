//
//  amenityImgCollectionViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 09/02/26.
//

import UIKit

class amenityImgCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var cellabckgroundView: UIView!
    
    @IBOutlet weak var amenityImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        cellabckgroundView.cornerRadius =  10
        cellabckgroundView.clipsToBounds = true
        cellabckgroundView.backgroundColor =  UIColor.white.withAlphaComponent(0.05)
    }

}
