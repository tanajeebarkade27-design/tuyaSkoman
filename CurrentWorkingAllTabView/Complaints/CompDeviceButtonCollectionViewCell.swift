//
//  CompDeviceButtonCollectionViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 01/12/25.
//

import UIKit

class CompDeviceButtonCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var cellBackgroundCell: UIView!
    
    @IBOutlet weak var ButtonImage: UIImageView!
    
    @IBOutlet weak var buttonName: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        cellBackgroundCell.cornerRadius =  10
        cellBackgroundCell.clipsToBounds =  true
        cellBackgroundCell.borderColor =  .white
        cellBackgroundCell.borderWidth =  1
        cellBackgroundCell.backgroundColor =  UIColor.white.withAlphaComponent(0.01)
    }

}
