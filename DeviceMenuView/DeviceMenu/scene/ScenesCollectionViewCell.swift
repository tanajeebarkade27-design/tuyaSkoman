//
//  ScenesCollectionViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 14/02/25.
//

import UIKit

class ScenesCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var cellbackgroundview: UIView!
    
    @IBOutlet weak var deviceNamelabel: UILabel!
    
    @IBOutlet weak var deviceImageView: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        cellbackgroundview.layer.cornerRadius =  10
        cellbackgroundview.layer.masksToBounds =  true
        cellbackgroundview.layer.borderColor =  UIColor.gray.cgColor
        
    }

}
