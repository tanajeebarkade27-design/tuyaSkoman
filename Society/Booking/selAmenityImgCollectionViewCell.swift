//
//  selAmenityImgCollectionViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 09/02/26.
//

import UIKit

class selAmenityImgCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var amenityImageView: UIImageView!
    
    @IBOutlet weak var cellabckgroundView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        cellabckgroundView.cornerRadius =  10
        cellabckgroundView.clipsToBounds = true
        cellabckgroundView.backgroundColor =  UIColor.white.withAlphaComponent(0.05)
    }

}
