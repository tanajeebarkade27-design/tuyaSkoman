//
//  ButtonCollectionViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 14/02/25.
//

import UIKit

class ButtonCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var buttonView: UIView!
    @IBOutlet weak var specialButtonImageView: UIImageView!
    
    @IBOutlet weak var specailButtonNameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        buttonView.layer.cornerRadius =  8
        buttonView.layer.masksToBounds =  true
        buttonView.layer.borderColor =  UIColor.gray.cgColor
        
        buttonView.layer.borderWidth = 1
    }

}
