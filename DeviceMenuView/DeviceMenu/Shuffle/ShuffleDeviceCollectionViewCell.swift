//
//  ShuffleDeviceCollectionViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 04/03/25.
//

import UIKit

class ShuffleDeviceCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var dimImageView: UIImageView!
    @IBOutlet weak var deviceImageView: UIImageView!
    @IBOutlet weak var cellbackgroundview: UIView!
    @IBOutlet weak var deviceNamelabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        
        cellbackgroundview.layer.cornerRadius =  8
        cellbackgroundview.layer.masksToBounds =  true
        cellbackgroundview.layer.borderColor =  UIColor.white.cgColor
        cellbackgroundview.layer.borderWidth = 1
    }

}
