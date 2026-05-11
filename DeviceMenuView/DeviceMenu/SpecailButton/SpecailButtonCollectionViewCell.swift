//
//  SpecailButtonCollectionViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 14/02/25.
//

import UIKit

class SpecailButtonCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var deviceImageView: UIImageView!
    
    @IBOutlet weak var dimmingImage: UIImageView!
    @IBOutlet weak var deviceView: UIView!
    
    @IBOutlet weak var deviceNameLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        deviceView.layer.cornerRadius =  8
        deviceView.layer.masksToBounds =  true
        deviceView.layer.borderColor =  UIColor.gray.cgColor
        
        deviceView.layer.borderWidth = 1
        deviceNameLabel.adjustsFontForContentSizeCategory = false
        deviceNameLabel.numberOfLines = 1
        deviceNameLabel.lineBreakMode = .byTruncatingTail
        deviceNameLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

}
