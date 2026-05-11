//
//  CompImageCollectionViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 01/12/25.
//

import UIKit

class CompImageCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var cellbackgroundView: UIView!
    
    
    @IBOutlet weak var selectedImage: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        
        cellbackgroundView.cornerRadius =  10
        cellbackgroundView.clipsToBounds =  true
        cellbackgroundView.backgroundColor =  UIColor.white.withAlphaComponent(0.01)
        
    }

}
